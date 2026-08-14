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
    └── starmap/        # 星图引擎（template.html + extra_edges.json Claude 补充边通道）
```

## 使用流程

### 1. 初始化（首次）

```bash
python3 ${CLAUDE_SKILL_DIR}/scripts/starmap.py init "<目标目录>"
```

- 自动完成：建 `.meta/` 骨架 → 扫描全部文件 → 增量登记台账 → 生成 INDEX.md → 渲染 starmap.html
- 敏感件自动识别（文件名/路径命中敏感词库 → 打码登记，不读内容）
- `${CLAUDE_SKILL_DIR}` 由 Claude Code 自动替换为当前 skill 所在目录（即 SKILL.md 同级），脚本内部亦通过自身路径定位 assets 资源，可从任意工作目录运行

### 2. 可选：LLM 增强（提升检索质量）

脚本为纯规则（零 API）：`synopsis` 标 `[自动登记]`，`type/subject/tags/related` 为空。
文档数量少（< 30 份）时，可让 Claude 逐份读文本文件补标签/梗概/关联，再重建：

```bash
python3 ${CLAUDE_SKILL_DIR}/scripts/starmap.py build "<目标目录>"
```

### 3. 日常维护

- 目录新增文件后：`python3 ${CLAUDE_SKILL_DIR}/scripts/starmap.py build "<目标目录>"`（增量，已有台账记录不动）
- 手工补过台账（标签/关联）后：`python3 ${CLAUDE_SKILL_DIR}/scripts/starmap.py build` 刷新星图
- Claude 补充边通道：`.meta/starmap/extra_edges.json`，构建时合并（reason=llm）

## 关键约定

- **不修改原目录结构**：只创建 `.meta/` 与根目录 `starmap.html`，不移动/改名任何原文件
- **纯规则零依赖**：Python 3 标准库，无第三方包、无 API key、内容不出本机
- **敏感件闸门**：命中敏感词库（密码/密钥/账号/工资/合同/发票/简历…）的文件只按名登记并打码，不读内容
- **增量安全**：台账按 path 去重，重复 build 不产生重复记录；删除文件可用台账 `action: delete` 记录撤销

## 验收

- 目录根出现 `starmap.html`，双击打开：节点 = 文件，颜色 = 格式，右栏切片（主题=子目录/标签/类型）+ 搜索框可用
- `.meta/index/INDEX.md` 按子目录列出全部文件
- 原目录文件清单与初始化前完全一致（diff 校验）
