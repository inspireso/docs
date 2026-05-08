# Claude Code 使用指南

Claude Code 是 Anthropic 官方推出的终端 AI 编程助手，支持代码编辑、文件操作、git 工作流、浏览器自动化等能力。

---

## 安装

### 前置要求

- [Node.js](https://nodejs.org/zh-cn/download/) 18+

#### Windows

- 安装 [Git for Windows](https://git-scm.com/download/win)
- 安装依赖（用于 statusline 等）：
  - [jq](https://stedolan.github.io/jq/download/)（JSON 处理）
  - [bc](https://gnuwin32.sourceforge.net/packages/bc.htm)（计算器）

#### Linux/macOS

- 安装依赖（用于 statusline 等）：
  ```bash
  # macOS
  brew install jq bc
  
  # Ubuntu/Debian
  sudo apt install jq bc
  
  # CentOS/RHEL
  sudo yum install jq bc
  ```

### 安装 Claude Code

#### Windows

```powershell
# PowerShell
npm install -g @anthropic-ai/claude-code

# 验证安装
claude --version
```

#### Linux/macOS

```bash
npm install -g @anthropic-ai/claude-code

# 验证安装
claude --version
```

### 更新

#### Windows

```powershell
npm update -g @anthropic-ai/claude-code
```

#### Linux/macOS

```bash
npm update -g @anthropic-ai/claude-code
```

---

## 配置国内模型

Claude Code 支持接入兼容 Anthropic API 的国内模型服务，在配置文件中设置 `env` 字段即可。

> **重要：** 使用国内模型前，需在配置文件中设置 `"hasCompletedOnboarding": true` 以跳过 Anthropic 认证引导。

### 配置文件位置

| 操作系统 | 配置文件路径 |
|---------|-------------|
| Windows | `%USERPROFILE%\.claude\settings.json` |
| Linux/macOS | `~/.claude/settings.json` |

| 操作系统 | 用户配置路径 |
|---------|-------------|
| Windows | `%USERPROFILE%\.claude.json` |
| Linux/macOS | `~/.claude.json` |

### DeepSeek 配置样例

```json
{
  "env": {
    "ANTHROPIC_BASE_URL": "https://api.deepseek.com/anthropic",
    "ANTHROPIC_AUTH_TOKEN": "sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
    "ANTHROPIC_MODEL": "deepseek-v4-pro[1m]",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1"
  }
}
```

### 阿里云 CodingPlan 配置样例

```json
{
  "env": {
    "ANTHROPIC_BASE_URL": "https://coding.dashscope.aliyuncs.com/apps/anthropic",
    "ANTHROPIC_AUTH_TOKEN": "sk-sp-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
    "ANTHROPIC_MODEL": "glm-5",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1"
  }
}
```

### 必要配置说明

| 变量 | 说明 |
|------|------|
| `ANTHROPIC_BASE_URL` | API 地址，指向兼容 Anthropic 接口的服务 |
| `ANTHROPIC_AUTH_TOKEN` | API Key |
| `ANTHROPIC_MODEL` | 主模型 |
| `ANTHROPIC_DEFAULT_OPUS_MODEL` | 替代 Opus（主力模型，复杂推理任务） |
| `ANTHROPIC_DEFAULT_SONNET_MODEL` | 替代 Sonnet（平衡任务） |
| `ANTHROPIC_DEFAULT_HAIKU_MODEL` | 替代 Haiku（快速轻量任务） |
| `CLAUDE_CODE_SUBAGENT_MODEL` | 子代理模型（简单任务、并行搜索可走此模型） |
| `CLAUDE_CODE_EFFORT_LEVEL` | 推理力度，`max` 为最高 |
| `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` | 禁用非必要网络请求（国内模型必设为 `1`） |

### 启动

#### Windows

```powershell
# PowerShell
cd C:\path\to\my-project
claude
```

#### Linux/macOS

```bash
cd /path/to/my-project
claude
```

---

## 插件

Claude Code 支持通过插件扩展能力。

### 安装 superpowers（官方思考与流程层）

```bash
claude plugin install superpowers@claude-plugins-official
```

### 安装 ai-engineering（AI 工程化实践）

```bash
# 1. 注册 marketplace
claude plugin marketplace add https://github.com/inspireso/ai-engineering.git

# 2. 安装插件
claude plugin install ai-engineering@inspireso-marketplace
```

### 更新插件

```bash
# 更新所有已安装插件
claude plugin update

# 更新指定插件
claude plugin update superpowers
claude plugin update ai-engineering
```

### 插件功能说明

**superpowers** — 思考与流程层：

| Skill | 说明 |
|-------|------|
| `brainstorming` | 创造性工作前的头脑风暴 |
| `writing-plans` | 编写实现计划 |
| `executing-plans` | 执行实现计划 |
| `TDD` | 测试驱动开发 |
| `systematic-debugging` | 系统性调试 |
| `verification` | 验证实现正确性 |
| `code-review` | 代码审查 |

**ai-engineering** — AI 工程化实践：

| Skill | 说明 |
|-------|------|
| `review` | PR 代码审查 |
| `qa` | QA 测试流程 |
| `release` | 发布流程 |
| `tdd-feature` | TDD 功能实现 |
| `refactor-analysis` | 重构影响分析 |
| `doc-gen` | 文档生成 |

调用方式：`/brainstorming`、`/review`、`/qa` 等斜杠命令，或让 Claude 自动判断何时使用。

---

## Statusline 配置

### 工作原理

状态栏通过执行一个 shell 脚本生成显示内容。Claude Code 将会话 JSON 数据通过 stdin 传递给脚本，脚本解析后输出一行文本显示在终端底部。

### 配置文件

在 `~/.claude/settings.json` 中配置 `statusLine` 字段：

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh",
    "refreshInterval": 5
  }
}
```

| 字段 | 说明 |
|------|------|
| `type` | 固定为 `"command"` |
| `command` | 脚本路径或内联命令 |
| `refreshInterval` | 刷新间隔（秒） |

### 标准输入 JSON 字段

```json
{
  "model": { "id": "...", "display_name": "Claude 4.1 Sonnet" },
  "workspace": { "current_dir": "~/my-project", "project_dir": "~/my-project" },
  "cost": { "total_cost_usd": 1.23 },
  "context_window": {
    "total_input_tokens": 45000,
    "total_output_tokens": 12000,
    "context_window_size": 200000,
    "used_percentage": 28.5,
    "remaining_percentage": 71.5,
    "current_usage": 5800
  },
  "rate_limits": {
    "five_hour": { "used_percentage": 12.3, "resets_at": 1738425600 },
    "seven_day": { "used_percentage": 45.6, "resets_at": 1738425600 }
  },
  "vim": { "mode": "INSERT" },
  "agent": { "name": "coder" }
}
```

关键字段：

| 字段 | 说明 |
|------|------|
| `model.display_name` | 模型显示名称 |
| `workspace.current_dir` | 当前目录 |
| `context_window.total_input_tokens` | 累计输入 token |
| `context_window.total_output_tokens` | 累计输出 token |
| `context_window.context_window_size` | 上下文窗口大小 |
| `context_window.used_percentage` | 上下文已用百分比 |
| `context_window.remaining_percentage` | 上下文剩余百分比 |
| `cost.total_cost_usd` | 会话总费用（美元） |
| `vim.mode` | Vim 模式 |
| `rate_limits.*` | 速率限制 |

### 当前状态栏脚本

`~/.claude/statusline.sh`：左区域显示模型、目录、分支；中间显示输入/输出 token；右区域显示上下文百分比 + 进度条 + 剩余量。

```bash
#!/bin/bash
MODEL="${ANTHROPIC_MODEL:-claude}"
CWD=$(basename "$PWD")
BRANCH=$(git branch --show-current 2>/dev/null || echo "none")

JSON_DATA=$(cat 2>/dev/null || echo "")

INPUT_TKS=$(echo "$JSON_DATA" | jq -r '.context_window.current_usage.input_tokens // 0' 2>/dev/null || echo "0")
OUTPUT_TKS=$(echo "$JSON_DATA" | jq -r '.context_window.current_usage.output_tokens // 0' 2>/dev/null || echo "0")
CTX_PERCENT=$(echo "$JSON_DATA" | jq -r '.context_window.used_percentage // 0' 2>/dev/null || echo "0")
CTX_MAX=$(echo "$JSON_DATA" | jq -r '.context_window.context_window_size // 200000' 2>/dev/null || echo "200000")

[ -z "$JSON_DATA" ] && { INPUT_TKS=0; OUTPUT_TKS=0; CTX_PERCENT=0; CTX_MAX=200000; }

format_tokens() {
    local n=$1
    [ $n -ge 1000 ] && echo "$(echo "scale=1; $n/1000" | bc)k" || echo "$n"
}

IN_DISP=$(format_tokens "$INPUT_TKS")
OUT_DISP=$(format_tokens "$OUTPUT_TKS")
CTX_REMAIN=$((CTX_MAX * (100 - CTX_PERCENT) / 100))

bar_width=8; filled=$((CTX_PERCENT * bar_width / 100))
bar=$(printf "%s%s" "$(printf '▓%.0s' $(seq 1 "$filled"))" "$(printf '░%.0s' $(seq 1 $((bar_width - filled))))")

CYAN='\033[38;5;117m'; ORANGE='\033[38;5;214m'; GREEN='\033[38;5;150m'
YELLOW='\033[38;5;180m'; PURPLE='\033[38;5;183m'
GRAY='\033[38;5;240m'; LIGHT_GRAY='\033[38;5;244m'; DARK_GRAY='\033[38;5;239m'
RESET='\033[0m'

printf "${CYAN}%s${RESET} ${GRAY}|${RESET} ${YELLOW}%s${RESET} ${GRAY}|${RESET} ${GREEN}%s${RESET}  ${GRAY}··${RESET}  ${ORANGE}↑%s${RESET} ${CYAN}↓%s${RESET}  ${GRAY}··${RESET}  ${PURPLE}ctx %d%%${RESET} ${DARK_GRAY}%s${RESET} ${LIGHT_GRAY}%s${RESET}\n" \
    "$MODEL" "$CWD" "$BRANCH" "$IN_DISP" "$OUT_DISP" "$CTX_PERCENT" "$bar" "$(format_tokens "$CTX_REMAIN")"
```

显示效果：`model | 目录 | 分支 ·· ↑输入 ↓输出 ·· ctx 百分比 ▓▓░░░░ 剩余`

### 快速自定义

使用 `/statusline` 命令通过自然语言描述你想要的布局：

```
/statusline 左边显示模型和分支，右边显示上下文百分比和费用
```

内联命令（无需脚本文件）：

```json
{
  "statusLine": {
    "type": "command",
    "command": "jq -r '\"[\(.model.display_name)] \(.context_window.used_percentage // 0)%\"'"
  }
}
```

社区项目：
- [levz0r/claude-code-statusline](https://github.com/levz0r/claude-code-statusline) — 功能完整的 statusline
- [@owloops/claude-powerline](https://www.npmjs.com/package/@owloops/claude-powerline) — powerline 风格
- [gabriel-dehan/claude_monitor_statusline](https://github.com/gabriel-dehan/claude_monitor_statusline) — 基于使用量的监控状态栏

---

## 常用命令

### 基础命令

| 命令 | 说明 |
|------|------|
| `claude` | 在当前目录启动交互模式 |
| `claude -p "prompt"` | 单次执行模式（非交互） |
| `claude --model MODEL` | 指定模型（如 `sonnet`、`opus`、`haiku`） |
| `claude --version` | 查看版本 |
| `claude --help` | 查看帮助 |

### 会话管理

| 命令 | 说明 |
|------|------|
| `claude -c` | 继续当前目录最近一次会话 |
| `claude --continue` | 同 `-c`，继续最近会话 |
| `claude -r [session-id]` | 恢复指定会话（可交互选择） |
| `claude --resume [session-id]` | 同 `-r`，恢复指定会话 |
| `claude --fork-session` | 分叉会话（配合 `-r`/`-c` 使用，创建新会话 ID） |
| `claude --from-pr [pr]` | 恢复与 PR 关联的会话 |
| `claude --session-id <uuid>` | 使用指定会话 ID |
| `claude -n "name"` | 设置会话显示名称 |

**会话恢复示例：**

```bash
# 继续上次会话
claude -c

# 恢复指定会话（交互选择）
claude -r

# 恢复后分叉为新会话（不影响原会话）
claude -c --fork-session

# 从 PR 关联恢复
claude --from-pr 123
```

### 模型与推理

| 命令 | 说明 |
|------|------|
| `claude --model sonnet` | 使用 Sonnet 模型 |
| `claude --model opus` | 使用 Opus 模型 |
| `claude --model haiku` | 使用 Haiku 模型 |
| `claude --effort max` | 最高推理力度 |
| `claude --effort high` | 高推理力度 |
| `claude --effort medium` | 中等推理力度 |
| `claude --effort low` | 低推理力度 |

### Headless 模式（非交互）

用于脚本、CI/CD 管道：

```bash
# 单次执行
claude -p "审查 src/main/java 下的安全问题"

# JSON 输出格式
claude -p "列出所有 TODO" --output-format json

# 流式 JSON 输出
claude -p "重构代码" --output-format stream-json

# 流式输入 + 输出
claude --input-format stream-json --output-format stream-json

# 限制费用
claude -p "分析代码" --max-budget-usd 1.00

# 禁用会话持久化（CI 场景）
claude -p "测试" --no-session-persistence

# JSON Schema 输出验证
claude -p "生成配置" --json-schema '{"type":"object","properties":{"name":{"type":"string"}}}'
```

### 权限与安全

| 命令 | 说明 |
|------|------|
| `claude --permission-mode default` | 默认权限模式 |
| `claude --permission-mode auto` | 自动批准编辑 |
| `claude --permission-mode acceptEdits` | 自动批准编辑操作 |
| `claude --permission-mode plan` | 规划模式 |
| `claude --permission-mode dontAsk` | 不询问 |
| `claude --permission-mode bypassPermissions` | 绕过所有权限（仅沙箱） |
| `claude --allowed-tools "Read,Edit"` | 仅允许指定工具 |
| `claude --disallowed-tools "Bash"` | 禁用指定工具 |

### Git Worktree

| 命令 | 说明 |
|------|------|
| `claude -w` | 创建新 worktree |
| `claude -w feature-branch` | 创建指定名称 worktree |
| `claude -w --tmux` | 在 tmux 中创建 worktree |

### 配置加载

| 命令 | 说明 |
|------|------|
| `claude --settings ./custom.json` | 加载指定配置文件 |
| `claude --mcp-config ./mcp.json` | 加载 MCP 配置 |
| `claude --plugin-dir ./plugins` | 加载指定插件目录 |
| `claude --add-dir ../shared` | 添加额外允许目录 |
| `claude --bare` | 最小模式（禁用 hooks、LSP、插件等） |

### 系统提示

| 命令 | 说明 |
|------|------|
| `claude --system-prompt "..."` | 替换默认系统提示 |
| `claude --append-system-prompt "..."` | 追加到默认系统提示 |

### 其他

| 命令 | 说明 |
|------|------|
| `claude --chrome` | 启用 Chrome 集成 |
| `claude --no-chrome` | 禁用 Chrome 集成 |
| `claude --ide` | 自动连接 IDE |
| `claude --verbose` | 详细输出 |
| `claude -d` | 启用调试模式 |
| `claude -d "api,hooks"` | 调试指定类别 |

### 子命令

| 命令 | 说明 |
|------|------|
| `claude auth` | 管理认证 |
| `claude mcp` | 管理 MCP 服务器 |
| `claude plugin` | 管理插件 |
| `claude update` | 检查并安装更新 |
| `claude doctor` | 检查健康状态 |
| `claude install stable` | 安装稳定版本 |
| `claude install latest` | 安装最新版本 |

### Slash 命令（交互模式）

| 命令 | 说明 |
|------|------|
| `/help` | 查看帮助 |
| `/clear` | 清屏 |
| `/compact` | 压缩上下文（节省 token） |
| `/statusline` | 自定义状态栏 |
| `/model` | 切换模型 |
| `/resume` | 恢复会话 |
| `/review` | 代码审查 |
| `/qa` | QA 测试 |

---

## 常见问题

### Permission 提示过多

使用 `/fewer-permission-prompts` 扫描常用命令并生成允许列表。

### 模型切换

通过 `~/.claude/settings.json` 的 `env` 字段切换；按需修改 `ANTHROPIC_MODEL` 等环境变量后重启会话。
