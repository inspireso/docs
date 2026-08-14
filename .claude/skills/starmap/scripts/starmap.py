#!/usr/bin/env python3
"""starmap: 把任意目录变成知识库。

不修改原目录结构，只添加 .meta/（索引/台账/规则/星图引擎）+ 根目录 starmap.html 产物。

用法:
  python3 starmap.py init  <目录>   # 初始化：建 .meta 骨架 + 扫描登记 + 生成索引与星图
  python3 starmap.py build <目录>   # 重建：重新扫描新文件（增量登记）+ 刷新索引与星图
  python3 starmap.py tags  <目录>   # 导出待补标签清单（Claude subagent 并行补充用）

数据模型:
  .meta/index/ledger.jsonl  权威台账（每条记录 = 一个文件，可手工补充标签/梗概）
  .meta/index/INDEX.md      人读索引（按一级子目录分组）
  .meta/index/rules.md      规则模板（命名/敏感词/台账字段说明）
  .meta/starmap/extra_edges.json   Claude 补充边通道（构建时合并，reason=llm）
  .meta/starmap/extra_tags.json    Claude 补充标签通道（构建时覆盖节点 tags）
  .meta/starmap/todo_tags.json     tags 子命令产物：待补标签清单（按 topic 排序）
  <目录>/starmap.html       星图产物（双击即开）
"""
import argparse
import json
import re
import shutil
import sys
from datetime import datetime
from pathlib import Path

SKILL_DIR = Path(__file__).resolve().parent.parent
TEMPLATE = SKILL_DIR / "assets" / "template.html"
RULES_TMPL = SKILL_DIR / "assets" / "rules.md.tmpl"

FMT_BY_EXT = {
    ".md": "md", ".markdown": "md", ".txt": "md",
    ".html": "网页", ".htm": "网页", ".mhtml": "网页",
    ".pdf": "pdf",
    ".xlsx": "excel", ".xls": "excel", ".csv": "excel",
    ".png": "图片", ".jpg": "图片", ".jpeg": "图片", ".gif": "图片", ".webp": "图片",
    ".mp3": "音频", ".wav": "音频", ".m4a": "音频",
    ".mp4": "视频", ".mov": "视频", ".avi": "视频",
    ".py": "代码", ".js": "代码", ".ts": "代码", ".java": "代码", ".go": "代码",
    ".docx": "pdf", ".doc": "pdf", ".pptx": "pdf",
}
# 敏感词（文件名/路径命中即打码登记，不读内容）
SENSITIVE_KEYWORDS = ["密码", "密钥", "token", "账号", "身份证", "银行卡",
                      "体检", "病历", "工资", "合同", "发票", "简历",
                      "secret", "password", "credential", "private"]
SKIP_NAMES = {".meta", ".git", ".gitkeep", "__pycache__", ".DS_Store", ".Trash"}
# 可 LLM 通读的文本类（subagent 补标签范围）
TEXT_FMTS = {"md", "网页", "代码"}
MAX_TAG_BYTES = 200 * 1024   # 超过 200KB 不推荐 LLM 通读，不列入待补
MAX_TAGS = 8                 # 单文件标签数量上限（超出截断）


def is_sensitive(rel: str) -> bool:
    low = rel.lower()
    return any(kw in low for kw in SENSITIVE_KEYWORDS)


def is_hidden_path(rel: str) -> bool:
    """路径任一段以 . 开头即为隐藏（.claude/、.vscode/、.env 等），构建时忽略。"""
    return any(part.startswith(".") for part in rel.split("/"))


def load_extra(meta_starmap: Path, name: str) -> list:
    """读 Claude 补充通道（extra_*.json）：缺失/非法 JSON/非 list 一律容错返回 []。"""
    p = meta_starmap / name
    if not p.exists():
        return []
    try:
        data = json.loads(p.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError):
        return []
    return data if isinstance(data, list) else []


def load_ledger(meta_index: Path) -> dict:
    """读台账：按 path 合并，delete 行作废对应 add。"""
    recs = {}
    p = meta_index / "ledger.jsonl"
    if not p.exists():
        return recs
    for line in p.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            r = json.loads(line)
        except json.JSONDecodeError:
            continue
        path = r.get("path", "")
        if r.get("action") == "delete":
            recs.pop(path, None)
        elif r.get("action") in ("add", "move", "update"):
            recs[path] = {**recs.get(path, {}), **r}
    return recs


def scan_files(root: Path):
    """遍历目录（跳过 .meta/产物/隐藏），返回 {相对路径: Path}。"""
    found = {}
    for p in sorted(root.rglob("*")):
        if not p.is_file():
            continue
        rel = str(p.relative_to(root))
        if any(part in SKIP_NAMES for part in rel.split("/")) or is_hidden_path(rel):
            continue
        if rel == "starmap.html":  # 星图产物，不登记
            continue
        found[rel] = p
    return found


def sync_ledger(root: Path, files: dict, recs: dict) -> tuple[dict, int]:
    """增量登记：新文件 append 到台账，返回更新后的 recs 与新增数。"""
    added = 0
    now = datetime.now().strftime("%Y-%m-%dT%H:%M:%S+08:00")
    new_lines = []
    for rel, p in files.items():
        if rel in recs:
            recs[rel]["bytes"] = p.stat().st_size
            continue
        parent = Path(rel).parent
        rec = {
            "ts": now,
            "action": "add",
            "path": rel,
            "title": p.stem,
            "type": "",
            "subject": "",
            "topic": parent.name if str(parent) != "." else "",
            "tags": [],
            "related": [],
            "synopsis": "[自动登记]",
            "date": datetime.fromtimestamp(p.stat().st_mtime).strftime("%Y-%m-%d"),
            "bytes": p.stat().st_size,
            "fmt": FMT_BY_EXT.get(p.suffix.lower(), "其他"),
        }
        if is_sensitive(rel):
            rec["sensitive"] = True
            rec["synopsis"] = "[敏感件，不读内容]"
        recs[rel] = rec
        new_lines.append(json.dumps(rec, ensure_ascii=False))
        added += 1
    if new_lines:
        with open(root / ".meta" / "index" / "ledger.jsonl", "a", encoding="utf-8") as f:
            f.write("\n".join(new_lines) + "\n")
    return recs, added


def build_index(root: Path, recs: dict) -> None:
    """生成人读索引 INDEX.md（按一级子目录分组）。"""
    groups = {}
    for path, r in recs.items():
        parts = path.split("/")
        group = parts[0] if len(parts) > 1 else "（根目录）"
        groups.setdefault(group, []).append(r)

    out = [f"# 知识库目录 — {root.name}\n",
           "> 自动生成（starmap）。文件结构未被修改；索引、台账、规则均在 `.meta/`。\n"]
    for group in sorted(groups):
        rows = groups[group]
        out.append(f"## {group}/ — {len(rows)} 个文件\n")
        out.append("| 文档 | 路径 | 格式 | 日期 |\n|------|------|------|------|")
        for r in sorted(rows, key=lambda x: x.get("date", ""), reverse=True):
            sens = "（[敏感件]）" if r.get("sensitive") else ""
            out.append(f"| {r.get('title','')} | `{r['path']}` | {r.get('fmt','')} | {r.get('date','')} |{sens}")
        out.append("")
    (root / ".meta" / "index" / "INDEX.md").write_text("\n".join(out), encoding="utf-8")


def clean_tags(tags) -> list:
    """标签清洗：strip → 去空 → 保序去重 → 截断到 MAX_TAGS。"""
    if not isinstance(tags, list):
        return []
    out = []
    for t in tags:
        if not isinstance(t, str):
            continue
        t = t.strip()
        if t and t not in out:
            out.append(t)
        if len(out) >= MAX_TAGS:
            break
    return out


def build_starmap(root: Path, recs: dict) -> tuple[int, int, int]:
    """渲染星图（数据内嵌，产物在目录根 starmap.html）。返回 (标签应用, 标签丢弃, llm 边)。"""
    tags_applied = tags_dropped = llm_edges = 0
    nodes, node_by_path, edges, seen = [], {}, [], set()

    for path, r in recs.items():
        node = {"id": len(nodes), "path": path, "title": r.get("title", ""),
                "type": r.get("type", ""), "subject": r.get("subject", ""),
                "topic": r.get("topic", ""), "tags": r.get("tags", []),
                "synopsis": r.get("synopsis", ""),
                "sensitive": bool(r.get("sensitive")), "bytes": r.get("bytes", 0),
                "fmt": r.get("fmt", "其他")}
        if node["sensitive"]:
            node["synopsis"] = "[敏感件，不读内容]"
        nodes.append(node)
        node_by_path[path] = node

    # Claude 补充标签通道：覆盖节点 tags（来源优先于台账）
    meta_starmap = root / ".meta" / "starmap"
    for e in load_extra(meta_starmap, "extra_tags.json"):
        node = node_by_path.get(e.get("path"))
        if node is None or node["sensitive"]:
            tags_dropped += 1
            continue
        node["tags"] = clean_tags(e.get("tags"))
        tags_applied += 1

    def add_edge(a, b, reason):
        if a == b:
            return
        key = tuple(sorted((a, b)))
        if key in seen:
            return
        seen.add(key)
        edges.append({"from": node_by_path[a]["id"], "to": node_by_path[b]["id"], "reason": reason})

    # 边：显式声明（ledger related）+ 专题归属（同 topic）
    for path, r in recs.items():
        for rel in r.get("related", []) or []:
            if rel in node_by_path:
                add_edge(path, rel, "explicit")
    groups = {}
    for path, n in node_by_path.items():
        if n["topic"]:
            groups.setdefault(n["topic"], []).append(path)
    for grp in groups.values():
        if len(grp) > 15:
            continue
        for i in range(len(grp)):
            for j in range(i + 1, len(grp)):
                add_edge(grp[i], grp[j], "topic")

    # Claude 补充边通道：reason=llm（正文引用类，add_edge 自带去重，参与 degree 计算）
    for e in load_extra(meta_starmap, "extra_edges.json"):
        a, b = e.get("from"), e.get("to")
        if a in node_by_path and b in node_by_path:
            add_edge(a, b, "llm")
            llm_edges += 1

    degree = {}
    for e in edges:
        degree[e["from"]] = degree.get(e["from"], 0) + 1
        degree[e["to"]] = degree.get(e["to"], 0) + 1
    for n in nodes:
        n["degree"] = degree.get(n["id"], 0)

    graph_json = json.dumps({"root": str(root.resolve()) + "/",
                             "nodes": nodes, "edges": edges}, ensure_ascii=False, indent=1)
    html = TEMPLATE.read_text(encoding="utf-8").replace("__GRAPH_DATA__", graph_json)
    (root / "starmap.html").write_text(encoding="utf-8", data=html)
    return tags_applied, tags_dropped, llm_edges


def export_tag_todo(root: Path, recs: dict) -> list:
    """导出待补标签清单：文本类 · 非敏感 · 台账无标签 · 未被 extra_tags 覆盖。
    按 (topic, path) 排序写入 todo_tags.json（subagent 按 topic 相邻分片）。"""
    meta_starmap = root / ".meta" / "starmap"
    covered = {e.get("path") for e in load_extra(meta_starmap, "extra_tags.json")}
    todo = []
    for r in recs.values():
        if r.get("sensitive") or r.get("fmt") not in TEXT_FMTS:
            continue
        if r.get("tags") or r.get("path") in covered:
            continue
        if r.get("bytes", 0) > MAX_TAG_BYTES:
            continue
        todo.append({"path": r["path"], "title": r.get("title", ""),
                     "topic": r.get("topic", ""), "fmt": r.get("fmt", ""),
                     "bytes": r.get("bytes", 0)})
    todo.sort(key=lambda x: (x["topic"], x["path"]))
    out = meta_starmap / "todo_tags.json"
    out.write_text(json.dumps(todo, ensure_ascii=False, indent=1), encoding="utf-8")
    return todo


def init_kb(root: Path) -> None:
    meta = root / ".meta"
    for d in ("index", "starmap"):
        (meta / d).mkdir(parents=True, exist_ok=True)
    # 规则模板（不存在才写，用户可自定义）
    rules_dst = meta / "index" / "rules.md"
    if not rules_dst.exists() and RULES_TMPL.exists():
        shutil.copy(RULES_TMPL, rules_dst)
    # 星图引擎模板
    tmpl_dst = meta / "starmap" / "template.html"
    if not tmpl_dst.exists():
        shutil.copy(TEMPLATE, tmpl_dst)
    if not (meta / "starmap" / "extra_edges.json").exists():
        (meta / "starmap" / "extra_edges.json").write_text("[]", encoding="utf-8")
    if not (meta / "starmap" / "extra_tags.json").exists():
        (meta / "starmap" / "extra_tags.json").write_text("[]", encoding="utf-8")
    if not (meta / "index" / "ledger.jsonl").exists():
        (meta / "index" / "ledger.jsonl").write_text("", encoding="utf-8")


def main():
    ap = argparse.ArgumentParser(description="starmap: 把任意目录变成知识库（不修改原结构）")
    ap.add_argument("cmd", choices=["init", "build", "tags"],
                    help="init=初始化+首次扫描; build=重建索引与星图; tags=导出待补标签清单")
    ap.add_argument("dir", help="目标目录")
    args = ap.parse_args()

    root = Path(args.dir).expanduser().resolve()
    if not root.is_dir():
        sys.exit(f"错误: {root} 不是目录")

    if args.cmd == "tags":
        ledger_p = root / ".meta" / "index" / "ledger.jsonl"
        if not ledger_p.exists():
            sys.exit("错误: 尚未初始化，请先运行 init 或 build")
        recs = load_ledger(root / ".meta" / "index")
        recs = {k: v for k, v in recs.items() if not is_hidden_path(k)}
        todo = export_tag_todo(root, recs)
        print(f"📋 待补标签 {len(todo)} 份（文本类 · 非敏感 · 台账无标签 · 未覆盖）")
        print(f"   清单: {root}/.meta/starmap/todo_tags.json（按 topic 排序，供 subagent 分片）")
        return

    if args.cmd == "init":
        init_kb(root)
    # 共通：扫描 + 增量登记 + 索引 + 星图
    files = scan_files(root)
    recs = load_ledger(root / ".meta" / "index")
    recs, added = sync_ledger(root, files, recs)
    recs = {k: v for k, v in recs.items() if not is_hidden_path(k)}  # 构建忽略隐藏文件（台账保留历史）
    build_index(root, recs)
    tags_applied, tags_dropped, llm_edges = build_starmap(root, recs)

    sens = sum(1 for r in recs.values() if r.get("sensitive"))
    n_edges = sum(1 for r in recs.values() if r.get("related"))
    print(f"✅ {root} 已是知识库")
    print(f"   文件 {len(recs)}（本次新增 {added}）· 敏感件 {sens}")
    if tags_applied or tags_dropped or llm_edges:
        print(f"   Claude 补充: 标签 {tags_applied} 条（丢弃 {tags_dropped}）· 边 {llm_edges} 条")
    print(f"   索引: {root}/.meta/index/INDEX.md")
    print(f"   台账: {root}/.meta/index/ledger.jsonl（可手工补标签/梗概/关联）")
    print(f"   星图: {root}/starmap.html（双击即开）")


if __name__ == "__main__":
    main()
