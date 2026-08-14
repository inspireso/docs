# Claude Code 入门漫画 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 生成《第一次进入代码迷宫：Claude Code 入门冒险》中文知识漫画的完整素材、图片页面和 PDF。

**Architecture:** 使用 baoyu-comic 的标准输出结构，在 `comic/claude-code-adventure/` 下保存分析、分镜、角色设定、每页 prompt、生成图片和最终 PDF。先完成所有可复现文本资产，再选择图片生成后端生成角色参考图与 7 页页面，最后合并 PDF。

**Tech Stack:** Markdown、baoyu-comic skill、可用图片生成后端、Bun/Node 脚本 `merge-to-pdf.ts`。

---

## File Structure

- Create: `comic/claude-code-adventure/source-claude-code-adventure.md` — 保存已确认设计的源内容摘要，作为漫画生成输入。
- Create: `comic/claude-code-adventure/analysis.md` — 内容分析、受众、知识点、风格选择依据。
- Create: `comic/claude-code-adventure/storyboard.md` — 7 页分镜、视觉符号表、每页面板拆解。
- Create: `comic/claude-code-adventure/characters/characters.md` — 小岚、Claude Code 悬浮终端窗口、代码迷宫元素的角色参考图 prompt。
- Create: `comic/claude-code-adventure/characters/characters.png` — 角色参考图，由图片生成后端生成。
- Create: `comic/claude-code-adventure/prompts/00-cover-claude-code-adventure.md` — 封面图片 prompt。
- Create: `comic/claude-code-adventure/prompts/01-page-not-magic.md` — 第 1 页图片 prompt。
- Create: `comic/claude-code-adventure/prompts/02-page-clear-task.md` — 第 2 页图片 prompt。
- Create: `comic/claude-code-adventure/prompts/03-page-read-map.md` — 第 3 页图片 prompt。
- Create: `comic/claude-code-adventure/prompts/04-page-plan-first.md` — 第 4 页图片 prompt。
- Create: `comic/claude-code-adventure/prompts/05-page-command-visible.md` — 第 5 页图片 prompt。
- Create: `comic/claude-code-adventure/prompts/06-page-verify-boundary.md` — 第 6 页图片 prompt。
- Create: `comic/claude-code-adventure/00-cover-claude-code-adventure.png` — 封面图片。
- Create: `comic/claude-code-adventure/01-page-not-magic.png` — 第 1 页图片。
- Create: `comic/claude-code-adventure/02-page-clear-task.png` — 第 2 页图片。
- Create: `comic/claude-code-adventure/03-page-read-map.png` — 第 3 页图片。
- Create: `comic/claude-code-adventure/04-page-plan-first.png` — 第 4 页图片。
- Create: `comic/claude-code-adventure/05-page-command-visible.png` — 第 5 页图片。
- Create: `comic/claude-code-adventure/06-page-verify-boundary.png` — 第 6 页图片。
- Create: `comic/claude-code-adventure/claude-code-adventure.pdf` — 合并后的漫画 PDF。

---

### Task 1: 创建输出目录和源内容文件

**Files:**
- Create: `comic/claude-code-adventure/source-claude-code-adventure.md`

- [ ] **Step 1: 创建目录结构**

Run:

```bash
mkdir -p comic/claude-code-adventure/characters comic/claude-code-adventure/prompts
```

Expected: 命令成功，无输出。

- [ ] **Step 2: 写入源内容文件**

Create `comic/claude-code-adventure/source-claude-code-adventure.md` with this content:

```markdown
# 第一次进入代码迷宫：Claude Code 入门冒险

## 目标

创建一部中文知识漫画，帮助完全没用过 Claude Code 的新手理解：Claude Code 是终端里的 AI 编程助手，适合用作结对编程伙伴，而不是无人驾驶魔法。

## 读者

完全新手。不假设读者熟悉终端、Git 或测试流程。

## 核心流程

明确目标 → 理解上下文 → 计划 → 小步执行 → 验证。

## 关键内容

- Claude Code 可以协助读文件、改文件、运行命令。
- 用户需要明确目标，并确认关键操作。
- 修改前应理解项目上下文。
- 复杂任务应先计划，再执行。
- 命令输出要可见、可解释。
- 完成前要检查 diff、运行测试，并尊重安全边界。

## 风格

concept-story：manga + warm + standard。采用冒险导师型叙事，并吸收工具箱教程型的模块清晰度。
```

- [ ] **Step 3: 验证源内容文件存在**

Run:

```bash
test -f comic/claude-code-adventure/source-claude-code-adventure.md
```

Expected: 命令成功，无输出。

---

### Task 2: 写入分析文档

**Files:**
- Create: `comic/claude-code-adventure/analysis.md`

- [ ] **Step 1: 写入 `analysis.md`**

Create `comic/claude-code-adventure/analysis.md` with this content:

```markdown
# 内容分析：《第一次进入代码迷宫：Claude Code 入门冒险》

## 主题

用 7 页中文知识漫画解释 Claude Code 的入门心智模型：它是终端中的 AI 编程助手，适合与开发者结对协作。

## 目标读者

- 完全没用过 Claude Code 的新手。
- 可能听说过 AI 编程，但不知道终端代理如何工作。
- 需要先理解协作方式，而不是安装步骤或完整命令手册。

## 内容信号

- AI、编程、学习工具：适合教育型漫画。
- 初学者入门：需要降低技术压迫感。
- 协作心智模型：适合用故事和视觉隐喻表达。

## 风格选择

采用 `concept-story`：manga + warm + standard。

理由：

1. manga 适合教育漫画和技术解释。
2. warm 能降低新手面对终端和代码的紧张感。
3. standard 页面结构利于 7 页短篇叙事。
4. concept-story 支持“抽象概念 → 视觉符号 → 主角应用”的成长弧线。

## 叙事方案

选择“冒险导师型”，并吸收“工具箱教程型”的模块清晰度。每页是一次迷宫探索，也对应一个明确学习点。

## 核心知识点

1. Claude Code 不是魔法，而是结对编程伙伴。
2. 清晰任务比模糊请求更有效。
3. 修改前要理解项目上下文。
4. 复杂任务要先计划。
5. 命令执行结果要可见、可解释。
6. 完成前要验证，并尊重安全边界。

## 文字策略

- 每页 1 个醒目标题。
- 对话短句控制在 8–14 个汉字左右。
- 关键命令使用大号命令卡片展示。
- 不逐字渲染复杂终端输出。

## 排除范围

不讲安装、登录、订阅、全量 slash command、MCP、Hook、Skill 高级配置、企业权限策略或具体语言框架调试教程。
```

- [ ] **Step 2: 验证 `analysis.md` 存在**

Run:

```bash
test -f comic/claude-code-adventure/analysis.md
```

Expected: 命令成功，无输出。

---

### Task 3: 写入角色设定与角色参考 prompt

**Files:**
- Create: `comic/claude-code-adventure/characters/characters.md`

- [ ] **Step 1: 写入角色参考 prompt**

Create `comic/claude-code-adventure/characters/characters.md` with this content:

```markdown
---
type: character-sheet
slug: claude-code-adventure
aspect: 4:3
language: zh
style: concept-story
art: manga
tone: warm
layout: character-sheet
---

# 角色参考图 Prompt

请生成一张 4:3 横向角色参考图，用于保持多页漫画角色一致性。

## 全局风格

中文知识漫画，concept-story 风格，日式 manga 表现，温暖治愈氛围，clean line art，柔和金色光线，现代技术学习场景。画面清晰、专业、亲切，适合完全新手学习 Claude Code。

## 角色 1：小岚

- 年轻的新手程序员，亲切、好奇、略紧张。
- 现代休闲服装，浅色外套，背小包，手拿笔记本电脑或学习笔记。
- 表情需要展示三种状态：紧张困惑、认真学习、自信微笑。
- 造型统一：黑棕色短发或中短发，圆润眼睛，柔和线条。

## 角色 2：Claude Code 向导

- 不是机器人，形象是悬浮终端窗口。
- 深蓝黑色终端面板，边缘柔和蓝紫色发光。
- 屏幕上有简化表情符号和提示气泡，但不要渲染大量小字。
- 性格温和、克制、可靠，像结对编程伙伴。
- 可有小型光点、光路和命令卡片围绕。

## 环境元素

- 代码迷宫入口：由文件夹、README 卷轴、src 房间、tests 房间、Git 状态路牌组成。
- 发光地图卷轴、指南针、任务清单阶梯、绿色测试徽章、diff 放大镜、红色确认门。

## 禁止

- 不要画成科幻战斗机器人。
- 不要展示密集、不可读的终端小字。
- 不要出现真实品牌 logo。
- 不要把 Claude Code 描绘成全自动魔法师。
```

- [ ] **Step 2: 验证角色 prompt 文件存在**

Run:

```bash
test -f comic/claude-code-adventure/characters/characters.md
```

Expected: 命令成功，无输出。

---

### Task 4: 写入 storyboard

**Files:**
- Create: `comic/claude-code-adventure/storyboard.md`

- [ ] **Step 1: 写入 `storyboard.md`**

Create `comic/claude-code-adventure/storyboard.md` with this content:

```markdown
# Storyboard：《第一次进入代码迷宫：Claude Code 入门冒险》

## 基本信息

- 页数：7 页，封面 + 6 页正文
- 语言：中文
- 画风：concept-story，manga + warm + standard
- 读者：完全没用过 Claude Code 的新手
- 页面比例：3:4 竖版

## Symbol Mapping Table

| 概念 | 视觉符号 | 首次出现 | 结尾回收 |
|---|---|---|---|
| 项目上下文 | 发光地图卷轴 | 第 3 页 | 第 6 页小岚手持地图 |
| 明确任务 | 指南针 | 第 2 页 | 第 6 页指南针稳定发光 |
| 计划 | 任务清单阶梯 | 第 4 页 | 第 6 页阶梯变成出口道路 |
| 命令执行 | 大号命令卡片 | 第 5 页 | 第 6 页作为工具卡收进背包 |
| 验证 | 绿色印章、测试徽章、diff 放大镜 | 第 5 页 | 第 6 页盖章通过 |
| 安全边界 | 红色确认门 | 第 6 页 | 第 6 页作为保护门出现 |

## 角色弧线

小岚从“害怕改坏项目”的新手，成长为能主动说出目标、读上下文、看计划、跑验证的学习者。Claude Code 向导始终是悬浮终端窗口，不抢走键盘，只在关键节点提示。

## 第 0 页：封面

标题：第一次进入代码迷宫

面板：单页封面构图。小岚站在巨大代码迷宫入口，入口由文件夹、终端符号和发光路径组成。Claude Code 悬浮终端窗口在她身旁点亮道路。

画面重点：冒险感、温暖光线、代码迷宫、终端向导。

## 第 1 页：不是魔法，是协作

标题：不是魔法，是协作

面板 1：小岚紧张地看着迷宫入口，说：“它会全自动吗？”

面板 2：Claude Code 悬浮终端窗口出现，柔和发光，说：“我是你的搭档。”

面板 3：画面展示读文件、改文件、运行命令三个图标围绕终端窗口。

面板 4：小岚握住键盘，Claude Code 指向确认按钮，说：“关键操作你确认。”

学习点：Claude Code 是结对编程伙伴，不是无人驾驶。

## 第 2 页：把愿望变成任务

标题：把愿望变成任务

面板 1：小岚说：“帮我看看项目。”指南针疯狂旋转。

面板 2：Claude Code 提示：“先说清目标。”

面板 3：小岚改口：“找入口文档，再看测试。”指南针稳定指向 README 和 tests。

面板 4：迷宫中出现一条清晰道路。

学习点：清晰任务比模糊请求更有效。

## 第 3 页：先读地图

标题：先读地图

面板 1：README 卷轴展开，发出温暖光线。

面板 2：src 房间、tests 房间、配置路牌在地图上亮起。

面板 3：Claude Code 说：“先理解，再修改。”

面板 4：小岚在地图上贴标签，表情从困惑变专注。

学习点：修改前先理解项目上下文。

## 第 4 页：先计划，再行动

标题：先计划，再行动

面板 1：迷宫前方出现多条岔路。

面板 2：Claude Code 展示任务清单阶梯：读文件、定位入口、提出修改、运行测试。

面板 3：小岚确认计划，说：“一步一步来。”

面板 4：每走一步，一个清单格亮起。

学习点：复杂任务应先计划，小步推进。

## 第 5 页：命令不是黑箱

标题：命令不是黑箱

面板 1：大号命令卡片 `git status` 飞出，旁边出现变更状态图标。

面板 2：大号命令卡片 `npm test` 飞出，测试徽章先闪红再转绿。

面板 3：Claude Code 指向输出状态条，说：“结果要看得见。”

面板 4：小岚拿起 diff 放大镜查看变化。

学习点：命令可以由 Claude Code 协助运行，但输出需要用户理解。

## 第 6 页：验证与边界

标题：验证后再完成

面板 1：小岚用 diff 放大镜检查改动。

面板 2：测试徽章盖上绿色印章：“通过”。

面板 3：迷宫出口前出现红色确认门，Claude Code 说：“危险操作要确认。”

面板 4：小岚手持地图、指南针和工具卡，和悬浮终端窗口一起走向下一段路。

学习点：完成前要验证；安全边界是保护。
```

- [ ] **Step 2: 验证 storyboard 文件存在**

Run:

```bash
test -f comic/claude-code-adventure/storyboard.md
```

Expected: 命令成功，无输出。

---

### Task 5: 写入 7 个页面 prompt 文件

**Files:**
- Create: `comic/claude-code-adventure/prompts/00-cover-claude-code-adventure.md`
- Create: `comic/claude-code-adventure/prompts/01-page-not-magic.md`
- Create: `comic/claude-code-adventure/prompts/02-page-clear-task.md`
- Create: `comic/claude-code-adventure/prompts/03-page-read-map.md`
- Create: `comic/claude-code-adventure/prompts/04-page-plan-first.md`
- Create: `comic/claude-code-adventure/prompts/05-page-command-visible.md`
- Create: `comic/claude-code-adventure/prompts/06-page-verify-boundary.md`

- [ ] **Step 1: 写入封面 prompt**

Create `comic/claude-code-adventure/prompts/00-cover-claude-code-adventure.md` with this content:

```markdown
---
type: cover
slug: claude-code-adventure
page: 0
aspect: 3:4
language: zh
style: concept-story
art: manga
tone: warm
references:
  - ref_id: characters
    filename: ../characters/characters.png
    usage: direct
---

# 封面 Prompt

生成一页 3:4 竖版中文知识漫画封面，标题为《第一次进入代码迷宫》。

画面：新手程序员小岚站在巨大“代码迷宫”入口前，入口由发光文件夹、README 卷轴、src 房间标识、tests 房间标识和终端符号构成。她略紧张但好奇，背小包，手拿笔记本。Claude Code 向导是一个悬浮深蓝黑色终端窗口，边缘柔和蓝紫色发光，在她身旁照亮通往迷宫的道路。

风格：concept-story，日式 manga，温暖金色光线，清晰线稿，柔和色彩，适合完全新手的技术学习漫画。构图有冒险入口感，但不要恐怖。

文字：只出现大标题《第一次进入代码迷宫》，字要大、清晰、居中或靠上。不要出现密集小字。

禁止：不要画机器人，不要画真实品牌 logo，不要渲染大量终端文字。
```

- [ ] **Step 2: 写入第 1 页 prompt**

Create `comic/claude-code-adventure/prompts/01-page-not-magic.md` with this content:

```markdown
---
type: page
slug: not-magic
page: 1
aspect: 3:4
language: zh
style: concept-story
art: manga
tone: warm
references:
  - ref_id: characters
    filename: ../characters/characters.png
    usage: direct
---

# 第 1 页 Prompt：不是魔法，是协作

生成一页 3:4 竖版中文知识漫画，4 个面板，标题大字：“不是魔法，是协作”。

面板 1：小岚紧张地站在代码迷宫入口，望着复杂文件夹和终端符号，说：“会全自动吗？”

面板 2：Claude Code 以悬浮深蓝黑色终端窗口出现，边缘柔和发光，温和提示气泡：“我是你的搭档。”

面板 3：三个简洁图标围绕终端窗口：读文件、改文件、运行命令。图标要大而清楚，不要密集小字。

面板 4：小岚双手靠近键盘，Claude Code 指向一个发光确认按钮，提示：“关键操作你确认。”

风格：manga + warm，温暖光线，表情清晰，故事感强。保持小岚和悬浮终端窗口与角色参考一致。

禁止：不要把 Claude Code 画成魔法师或机器人，不要出现复杂终端输出。
```

- [ ] **Step 3: 写入第 2 页 prompt**

Create `comic/claude-code-adventure/prompts/02-page-clear-task.md` with this content:

```markdown
---
type: page
slug: clear-task
page: 2
aspect: 3:4
language: zh
style: concept-story
art: manga
tone: warm
references:
  - ref_id: characters
    filename: ../characters/characters.png
    usage: direct
---

# 第 2 页 Prompt：把愿望变成任务

生成一页 3:4 竖版中文知识漫画，4 个面板，标题大字：“把愿望变成任务”。

面板 1：小岚站在迷宫分岔路口，手里的指南针疯狂旋转。她说：“帮我看看项目。”

面板 2：Claude Code 悬浮终端窗口靠近，发出柔和光线，提示：“先说清目标。”

面板 3：小岚认真地把目标写在发光卡片上：“找入口文档，再看测试。” 指南针稳定指向 README 和 tests 路牌。

面板 4：迷宫中出现一条清晰金色道路，小岚表情放松。

风格：concept-story，日式 manga，温暖教育漫画氛围。指南针和道路是本页核心视觉隐喻。

文字必须少而大。不要出现密集说明文字。
```

- [ ] **Step 4: 写入第 3 页 prompt**

Create `comic/claude-code-adventure/prompts/03-page-read-map.md` with this content:

```markdown
---
type: page
slug: read-map
page: 3
aspect: 3:4
language: zh
style: concept-story
art: manga
tone: warm
references:
  - ref_id: characters
    filename: ../characters/characters.png
    usage: direct
---

# 第 3 页 Prompt：先读地图

生成一页 3:4 竖版中文知识漫画，4 个面板，标题大字：“先读地图”。

面板 1：README 卷轴在小岚面前展开，发出温暖光线，像迷宫地图。

面板 2：地图上三个区域亮起：README、src、tests。用大标签表示，字少而清晰。

面板 3：Claude Code 悬浮终端窗口指向地图，提示：“先理解，再修改。”

面板 4：小岚在地图上贴标签，表情从困惑变专注，背景迷宫变得有秩序。

风格：manga + warm，清晰面板分隔，发光地图是核心视觉元素。

禁止：不要出现长代码，不要渲染复杂目录树。
```

- [ ] **Step 5: 写入第 4 页 prompt**

Create `comic/claude-code-adventure/prompts/04-page-plan-first.md` with this content:

```markdown
---
type: page
slug: plan-first
page: 4
aspect: 3:4
language: zh
style: concept-story
art: manga
tone: warm
references:
  - ref_id: characters
    filename: ../characters/characters.png
    usage: direct
---

# 第 4 页 Prompt：先计划，再行动

生成一页 3:4 竖版中文知识漫画，4 个面板，标题大字：“先计划，再行动”。

面板 1：迷宫前方出现多条岔路，小岚有点犹豫。

面板 2：Claude Code 悬浮终端窗口展示任务清单阶梯，四级台阶分别用大字标识：“读文件”“定位入口”“提出修改”“运行测试”。

面板 3：小岚看着计划点头，说：“一步一步来。”

面板 4：小岚每走上一级台阶，对应清单格发光，迷宫路径变清晰。

风格：concept-story，温暖、鼓励、清晰。任务清单阶梯是本页核心视觉隐喻。

禁止：不要画成会议白板讲课，不要让角色连续站着讲解。
```

- [ ] **Step 6: 写入第 5 页 prompt**

Create `comic/claude-code-adventure/prompts/05-page-command-visible.md` with this content:

```markdown
---
type: page
slug: command-visible
page: 5
aspect: 3:4
language: zh
style: concept-story
art: manga
tone: warm
references:
  - ref_id: characters
    filename: ../characters/characters.png
    usage: direct
---

# 第 5 页 Prompt：命令不是黑箱

生成一页 3:4 竖版中文知识漫画，4 个面板，标题大字：“命令不是黑箱”。

面板 1：大号命令卡片 `git status` 从悬浮终端窗口飞出，旁边是简化的变更状态图标。

面板 2：大号命令卡片 `npm test` 飞出，测试徽章先红后绿，用动态效果表现。

面板 3：Claude Code 指向简化输出状态条，提示：“结果要看得见。”

面板 4：小岚拿起 diff 放大镜检查变化，露出理解的表情。

风格：manga + warm，命令卡片必须大、清楚、可读。复杂输出只用状态条和徽章表达。

禁止：不要出现密集终端日志，不要用小字塞满画面。
```

- [ ] **Step 7: 写入第 6 页 prompt**

Create `comic/claude-code-adventure/prompts/06-page-verify-boundary.md` with this content:

```markdown
---
type: page
slug: verify-boundary
page: 6
aspect: 3:4
language: zh
style: concept-story
art: manga
tone: warm
references:
  - ref_id: characters
    filename: ../characters/characters.png
    usage: direct
---

# 第 6 页 Prompt：验证后再完成

生成一页 3:4 竖版中文知识漫画，4 个面板，标题大字：“验证后再完成”。

面板 1：小岚用 diff 放大镜检查发光文件变化，神情认真。

面板 2：测试徽章被盖上绿色印章：“通过”。画面明亮。

面板 3：迷宫出口前出现红色确认门和护栏，Claude Code 悬浮终端窗口提示：“危险操作要确认。”

面板 4：小岚手持地图、稳定指南针和工具卡，和 Claude Code 悬浮终端窗口一起走向下一段路。所有视觉符号在背景中温暖发光。

风格：concept-story，温暖成长结尾，开放式前进感。

禁止：不要把安全边界画成惩罚或恐惧元素；它应像保护门。
```

- [ ] **Step 8: 验证 7 个 prompt 文件存在**

Run:

```bash
test -f comic/claude-code-adventure/prompts/00-cover-claude-code-adventure.md && \
test -f comic/claude-code-adventure/prompts/01-page-not-magic.md && \
test -f comic/claude-code-adventure/prompts/02-page-clear-task.md && \
test -f comic/claude-code-adventure/prompts/03-page-read-map.md && \
test -f comic/claude-code-adventure/prompts/04-page-plan-first.md && \
test -f comic/claude-code-adventure/prompts/05-page-command-visible.md && \
test -f comic/claude-code-adventure/prompts/06-page-verify-boundary.md
```

Expected: 命令成功，无输出。

---

### Task 6: 选择图片生成后端并生成角色参考图

**Files:**
- Read: `comic/claude-code-adventure/characters/characters.md`
- Create: `comic/claude-code-adventure/characters/characters.png`

- [ ] **Step 1: 按 baoyu-comic 规则选择图片生成后端**

检查当前运行环境可用的图片生成能力。优先顺序：

1. 如果可用 skill 列表包含 `imagegen`，使用 `imagegen`。
2. 如果没有 `imagegen`，但可通过 Codex CLI 或 baoyu-image-gen 调用位图生成，使用对应后端。
3. 如果没有任何位图图片生成后端，停止并向用户说明无法生成 PNG，不能用 SVG、HTML、Canvas 替代。

Expected: 明确记录选择的后端，继续或停止。

- [ ] **Step 2: 用角色 prompt 生成角色参考图**

Input prompt file: `comic/claude-code-adventure/characters/characters.md`

Output path: `comic/claude-code-adventure/characters/characters.png`

Aspect ratio: `4:3`

Expected: `characters.png` 成功生成。

- [ ] **Step 3: 验证角色参考图存在**

Run:

```bash
test -f comic/claude-code-adventure/characters/characters.png
```

Expected: 命令成功，无输出。

---

### Task 7: 批量生成 7 页漫画图片

**Files:**
- Read: all files in `comic/claude-code-adventure/prompts/*.md`
- Read: `comic/claude-code-adventure/characters/characters.png`
- Create: 7 PNG page files under `comic/claude-code-adventure/`

- [ ] **Step 1: 确认所有 prompt 已写入后再生成**

Run:

```bash
ls comic/claude-code-adventure/prompts/*.md | wc -l
```

Expected: 输出 `7`。

- [ ] **Step 2: 生成封面**

Input prompt: `comic/claude-code-adventure/prompts/00-cover-claude-code-adventure.md`

Reference image: `comic/claude-code-adventure/characters/characters.png`

Output path: `comic/claude-code-adventure/00-cover-claude-code-adventure.png`

Aspect ratio: `3:4`

Expected: 封面 PNG 生成成功。

- [ ] **Step 3: 生成第 1 页**

Input prompt: `comic/claude-code-adventure/prompts/01-page-not-magic.md`

Reference image: `comic/claude-code-adventure/characters/characters.png`

Output path: `comic/claude-code-adventure/01-page-not-magic.png`

Aspect ratio: `3:4`

Expected: 第 1 页 PNG 生成成功。

- [ ] **Step 4: 生成第 2 页**

Input prompt: `comic/claude-code-adventure/prompts/02-page-clear-task.md`

Reference image: `comic/claude-code-adventure/characters/characters.png`

Output path: `comic/claude-code-adventure/02-page-clear-task.png`

Aspect ratio: `3:4`

Expected: 第 2 页 PNG 生成成功。

- [ ] **Step 5: 生成第 3 页**

Input prompt: `comic/claude-code-adventure/prompts/03-page-read-map.md`

Reference image: `comic/claude-code-adventure/characters/characters.png`

Output path: `comic/claude-code-adventure/03-page-read-map.png`

Aspect ratio: `3:4`

Expected: 第 3 页 PNG 生成成功。

- [ ] **Step 6: 生成第 4 页**

Input prompt: `comic/claude-code-adventure/prompts/04-page-plan-first.md`

Reference image: `comic/claude-code-adventure/characters/characters.png`

Output path: `comic/claude-code-adventure/04-page-plan-first.png`

Aspect ratio: `3:4`

Expected: 第 4 页 PNG 生成成功。

- [ ] **Step 7: 生成第 5 页**

Input prompt: `comic/claude-code-adventure/prompts/05-page-command-visible.md`

Reference image: `comic/claude-code-adventure/characters/characters.png`

Output path: `comic/claude-code-adventure/05-page-command-visible.png`

Aspect ratio: `3:4`

Expected: 第 5 页 PNG 生成成功。

- [ ] **Step 8: 生成第 6 页**

Input prompt: `comic/claude-code-adventure/prompts/06-page-verify-boundary.md`

Reference image: `comic/claude-code-adventure/characters/characters.png`

Output path: `comic/claude-code-adventure/06-page-verify-boundary.png`

Aspect ratio: `3:4`

Expected: 第 6 页 PNG 生成成功。

- [ ] **Step 9: 验证 7 张页面图片存在**

Run:

```bash
test -f comic/claude-code-adventure/00-cover-claude-code-adventure.png && \
test -f comic/claude-code-adventure/01-page-not-magic.png && \
test -f comic/claude-code-adventure/02-page-clear-task.png && \
test -f comic/claude-code-adventure/03-page-read-map.png && \
test -f comic/claude-code-adventure/04-page-plan-first.png && \
test -f comic/claude-code-adventure/05-page-command-visible.png && \
test -f comic/claude-code-adventure/06-page-verify-boundary.png
```

Expected: 命令成功，无输出。

---

### Task 8: 合并 PDF 并验收

**Files:**
- Read: `comic/claude-code-adventure/*.png`
- Create: `comic/claude-code-adventure/claude-code-adventure.pdf`

- [ ] **Step 1: 确认 Bun 运行时**

Run:

```bash
if command -v bun >/dev/null 2>&1; then echo bun; elif command -v npx >/dev/null 2>&1; then echo npx-bun; else echo missing; fi
```

Expected: 输出 `bun` 或 `npx-bun`。如果输出 `missing`，停止并提示用户安装 bun 或允许使用 npx。

- [ ] **Step 2: 合并 PNG 为 PDF**

If Step 1 output is `bun`, run:

```bash
bun /Users/my/github/inspireso/docs/aix/.claude/skills/baoyu-comic/scripts/merge-to-pdf.ts \
  comic/claude-code-adventure \
  comic/claude-code-adventure/claude-code-adventure.pdf
```

If Step 1 output is `npx-bun`, run:

```bash
npx -y bun /Users/my/github/inspireso/docs/aix/.claude/skills/baoyu-comic/scripts/merge-to-pdf.ts \
  comic/claude-code-adventure \
  comic/claude-code-adventure/claude-code-adventure.pdf
```

Expected: `comic/claude-code-adventure/claude-code-adventure.pdf` 生成成功。

- [ ] **Step 3: 验证 PDF 存在**

Run:

```bash
test -f comic/claude-code-adventure/claude-code-adventure.pdf
```

Expected: 命令成功，无输出。

- [ ] **Step 4: 最终验收清单**

Verify manually:

```text
- analysis.md 存在并覆盖目标读者、知识点、风格选择。
- storyboard.md 包含 7 页结构和 Symbol Mapping Table。
- characters/characters.md 和 characters.png 存在。
- prompts/ 下有 7 个 prompt 文件。
- 根目录下有 7 张漫画 PNG。
- PDF 存在。
- 若任一图片文字严重错误，不用程序覆盖修补；更新对应 prompt 后重新生成该页。
```

Expected: 所有条目通过，向用户报告输出路径和任何未完成项。

---

## Self-Review

- Spec coverage: 本计划覆盖目标读者、7 页范围、concept-story 风格、冒险导师叙事、悬浮终端窗口角色、视觉符号系统、文字策略、prompt 先写入、角色参考图、页面生成和 PDF 合并。
- Placeholder scan: 本计划不包含 TBD、TODO、implement later 或未定义的“稍后补充”。
- Scope check: 本计划只生成一部漫画，不包含安装教程、命令手册、MCP、Hook、Skill 高级配置或企业策略。
- Execution constraint: 图片生成必须使用位图生成后端；如果没有可用后端，停止并向用户说明，不能用 SVG/HTML/Canvas 替代。
