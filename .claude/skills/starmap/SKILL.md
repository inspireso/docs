---
name: starmap
description: 把任意指定目录一键构造成知识库——不修改原目录结构，只在目录下添加 .meta/（台账/索引/规则/星图引擎）并在目录根生成 starmap.html 星图产物。当用户说"把 X 目录变成知识库"、"给这个目录建索引"、"生成星图"、"目录扫描归档"或给出一个目录路径要求整理成知识库时使用。
allowed-tools: Bash(${CLAUDE_SKILL_DIR}/scripts/starmap.py *)
---

# starmap — 目录 → 知识库

把任意目录（项目、下载夹、素材库…）变成知识库：**原文件原结构零改动**，只添加：

```
<目标目录>/
├── (原文件，不动)
├── starmap.html        # 星图产物（双击即开，浏览器可视化检索）
└── .meta/              # 元数据（自动维护）
    ├── index/          # rules.md（规则）/ INDEX.md（人读索引）/ ledger.jsonl（台账）
    └── starmap/        # 星图引擎（template.html + extra_edges.json / extra_tags.json Claude 补充通道）
```

## 使用流程

### 1. 初始化（首次）

```bash
python3 ${CLAUDE_SKILL_DIR}/scripts/starmap.py init "<目标目录>"
```

- 自动完成：建 `.meta/` 骨架 → 扫描全部文件 → 增量登记台账 → 生成 INDEX.md → 渲染 starmap.html
- 敏感件自动识别（文件名/路径命中敏感词库 → 打码登记，不读内容）
- `${CLAUDE_SKILL_DIR}` 由 Claude Code 自动替换为当前 skill 所在目录（即 SKILL.md 同级），脚本内部亦通过自身路径定位 assets 资源，可从任意工作目录运行

### 2. 可选：LLM 增强 — subagent 并行补标签

脚本纯规则零依赖，语义由 Claude 负责。主 Claude 启动多个**并行 subagent**（Agent 工具），
每个子代理读一批文件内容，产出中文短标签，汇总到 `.meta/starmap/extra_tags.json`，
重建后生效（标签切片/详情面板自动出现）。

前置：目录有新文件时先跑一次 `build` 登记，再执行：

```bash
python3 ${CLAUDE_SKILL_DIR}/scripts/starmap.py tags "<目标目录>"
```

生成 `.meta/starmap/todo_tags.json`（按 topic 排序的待补清单，条目含 path/title/topic/fmt/bytes）。

**并行协议（主 Claude 执行）：**

1. 读 todo_tags.json，切成若干片：每片 5-10 份文件，同 topic 优先
   （清单按 topic 排序天然相邻；单 topic 超 10 份拆多片），约 140 份 → 3 批左右。
2. 用 Agent 工具并行启动 5-8 个子代理（不足分多批）。每个子代理的 prompt 含：
   - 角色：starmap 标签助手
   - 输入：本批文件清单（JSON 数组，含 path/title/topic）
   - 动作：逐个 Read 文件内容 → 每份文件给出 2-5 个中文短标签
   - 标签规范：2-6 个汉字短语或 1-3 个英文单词；具体主题（"磁盘扩容"）而非抽象类别
     （"技术文档"）；中文优先；避免与标题、topic 重复
   - 约束：只读清单内文件；清单已过滤敏感件，禁止自行搜索敏感文件；不修改、不创建任何文件
   - 输出：最终回复**仅**输出 JSON 数组
     `[{"path": "相对路径", "tags": ["标签1", "标签2"]}]`，不要代码块标记、不要多余文字
3. 收集各子代理返回的 JSON：剥离可能的 ```json 围栏 → 逐条解析 → 非法条目丢弃 → 合并为
   `[{"path": "…", "tags": […]}]` 写入 `.meta/starmap/extra_tags.json`（整体覆盖）
4. 重新执行 `build` 刷新星图。解析失败的分片可重新派一个子代理补跑，或丢弃该片（build 容忍缺失）

子代理绝不允许写台账 `ledger.jsonl`（append-only，并行写会损坏）。

### 3. 日常维护

- 目录新增文件后：`python3 ${CLAUDE_SKILL_DIR}/scripts/starmap.py build "<目标目录>"`（增量，已有台账记录不动）
- 手工补过台账（标签/关联）后：`python3 ${CLAUDE_SKILL_DIR}/scripts/starmap.py build` 刷新星图
- Claude 补充边通道：`.meta/starmap/extra_edges.json`（`[{"from": "a.md", "to": "b.md"}]`），构建时合并（reason=llm）
- Claude 补充标签通道：`.meta/starmap/extra_tags.json`（`[{"path": "a.md", "tags": ["标签"]}]`），构建时覆盖节点标签（自动清洗：去重/去空/上限 8 个）

## 关键约定

- **不修改原目录结构**：只创建 `.meta/` 与根目录 `starmap.html`，不移动/改名任何原文件
- **纯规则零依赖**：Python 3 标准库，无第三方包、无 API key、内容不出本机
- **构建忽略隐藏文件**：`.` 开头的目录/文件（`.claude/`、`.vscode/`、`.env` 等）不登记、不进索引与星图；台账保留历史记录（`tags` 子命令同样过滤）
- **敏感件闸门**：命中敏感词库（密码/密钥/账号/工资/合同/发票/简历…）的文件只按名登记并打码，不读内容
- **增量安全**：台账按 path 去重，重复 build 不产生重复记录；删除文件可用台账 `action: delete` 记录撤销

## 验收

- 目录根出现 `starmap.html`，双击打开：节点 = 文件，颜色 = 格式，右栏切片（主题=子目录/标签/类型）+ 搜索框可用
- `.meta/index/INDEX.md` 按子目录列出全部文件
- 原目录文件清单与初始化前完全一致（diff 校验）
- LLM 增强后：标签切片显示中文标签，节点详情面板显示标签
