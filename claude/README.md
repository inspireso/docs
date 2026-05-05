# Claude Code 使用指南

Claude Code 是 Anthropic 官方推出的终端 AI 编程助手，支持代码编辑、文件操作、git 工作流、浏览器自动化等能力。

---

## 安装

### 前置要求

- [Node.js](https://nodejs.org/zh-cn/download/) 18+
- Windows 需安装 [Git for Windows](https://git-scm.com/download/win)
- 全局依赖（用于 statusline 等）：`jq`、`bc`

### 安装 Claude Code

```bash
npm install -g @anthropic-ai/claude-code
claude --version  # 验证安装
```

### 更新

```bash
npm update -g @anthropic-ai/claude-code
```

---

## 配置国内模型

Claude Code 本身使用 Anthropic API，但可以通过环境变量接入兼容 Anthropic API 的国内模型服务，如 DeepSeek。

### 方式一：环境变量（推荐）

```bash
export ANTHROPIC_BASE_URL=https://api.deepseek.com/anthropic
export ANTHROPIC_AUTH_TOKEN=<你的 DeepSeek API Key>
export ANTHROPIC_MODEL=deepseek-v4-pro[1m]
export ANTHROPIC_DEFAULT_OPUS_MODEL=deepseek-v4-pro[1m]
export ANTHROPIC_DEFAULT_SONNET_MODEL=deepseek-v4-pro[1m]
export ANTHROPIC_DEFAULT_HAIKU_MODEL=deepseek-v4-flash
export CLAUDE_CODE_SUBAGENT_MODEL=deepseek-v4-flash
export CLAUDE_CODE_EFFORT_LEVEL=max
```

可将上述内容加入 `~/.zshrc` 或 `~/.bashrc`。

### 方式二：settings.json（全局配置）

在 `~/.claude/settings.json` 中配置 `env` 字段：

```json
{
  "env": {
    "ANTHROPIC_BASE_URL": "https://api.deepseek.com/anthropic",
    "ANTHROPIC_AUTH_TOKEN": "sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
    "ANTHROPIC_MODEL": "deepseek-v4-pro[1m]",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "deepseek-v4-pro[1m]",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "deepseek-v4-pro[1m]",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "deepseek-v4-flash",
    "CLAUDE_CODE_SUBAGENT_MODEL": "deepseek-v4-flash",
    "CLAUDE_CODE_EFFORT_LEVEL": "max"
  }
}
```

> **重要：** 使用国内模型时，还需在 `~/.claude.json` 中设置 `"hasCompletedOnboarding": true` 以跳过 Anthropic 官认证流程的引导页面。否则 Claude Code 会尝试引导用户完成 Anthropic 登录，无法直接使用第三方模型。
>
> ```json
> {
>   "hasCompletedOnboarding": true
> }
> ```

### 环境变量说明

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

> 若使用其他兼容 Anthropic API 的模型服务，仅需修改 `ANTHROPIC_BASE_URL` 和 `ANTHROPIC_AUTH_TOKEN` 即可。

### 启动

```bash
cd /path/to/my-project
claude
```

> 参考：[DeepSeek API Docs](https://api-docs.deepseek.com/zh-cn/guides/coding_agents)

---

## 插件

Claude Code 支持通过插件扩展能力。插件在 `~/.claude/plugins/` 目录下。

### 安装插件

```bash
# 安装 superpowers 插件（官方思考与流程层）
claude plugin install superpowers@claude-plugins-official

# 安装 context7 插件（文档查询）
claude plugin install context7@claude-plugins-official

# 查看已安装插件
claude plugin list

# 更新插件
claude plugin update superpowers@claude-plugins-official
```

### 启用/禁用插件

```bash
# 启用插件
claude plugin enable superpowers@claude-plugins-official

# 禁用插件（不卸载）
claude plugin disable superpowers@claude-plugins-official

# 卸载插件
claude plugin uninstall superpowers@claude-plugins-official
```

### 配置文件

在 `~/.claude/settings.json` 中配置已启用的插件：

```json
{
  "enabledPlugins": {
    "context7@claude-plugins-official": true,
    "superpowers@claude-plugins-official": true
  }
}
```

### superpowers 插件功能

superpowers 提供思考与流程层的能力：

| Skill | 说明 |
|-------|------|
| `brainstorming` | 创造性工作前的头脑风暴 |
| `writing-plans` | 编写实现计划 |
| `executing-plans` | 执行实现计划 |
| `TDD` | 测试驱动开发 |
| `systematic-debugging` | 系统性调试 |
| `verification` | 验证实现正确性 |
| `code-review` | 代码审查 |

调用方式：`/brainstorming`、`/plan`、`/TDD` 等斜杠命令，或让 Claude 自动判断何时使用。

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
