# Claude Code VSCode 扩展使用指南

Claude Code 提供官方 VSCode 扩展，可在编辑器内直接使用 Claude 辅助编程。

---

## 安装 VSCode

### Windows

#### 方法一：官网下载

1. 访问 [VSCode 官网](https://code.visualstudio.com/)
2. 点击 "Download for Windows" 下载安装包
3. 运行 `VSCodeSetup.exe`，按提示完成安装
4. 安装时可勾选以下选项：
   - 添加到 PATH（推荐）
   - 创建桌面快捷方式
   - 注册为代码文件默认编辑器

#### 方法二：包管理器安装

**winget（Windows 10/11 自带）：**
```powershell
winget install Microsoft.VisualStudioCode
```

**Chocolatey：**
```powershell
choco install vscode
```

**Scoop：**
```powershell
scoop install vscode
```

#### 方法三：Microsoft Store

在 Microsoft Store 搜索 "Visual Studio Code" 安装。

### macOS

#### 方法一：官网下载

1. 访问 [VSCode 官网](https://code.visualstudio.com/)
2. 点击 "Download for Mac" 下载 `.zip` 或 `.dmg` 文件
3. 解压/安装后，将 Visual Studio Code 拖入 Applications文件夹

#### 方法二：Homebrew 安装

```bash
# Homebrew Cask
brew install --cask visual-studio-code
```

#### 方法三：App Store

在 Mac App Store 搜索 "Visual Studio Code" 安装。

### 验证安装

**Windows：**
```powershell
code --version
```

**macOS：**
```bash
code --version
```

显示版本号即安装成功。

> **macOS PATH 配置：** 若 `code` 命令未识别，在 VSCode 中按 `Cmd+Shift+P`，输入 `Shell Command: Install 'code' command in PATH`。

---

## 安装 Claude Code 扩展

### 方法一：扩展市场搜索

**Windows：**
1. 打开 VSCode
2. 按 `Ctrl+Shift+X` 打开扩展面板
3. 搜索 `Claude Code`
4. 点击 Install 安装

**macOS：**
1. 打开 VSCode
2. 按 `Cmd+Shift+X` 打开扩展面板
3. 搜索 `Claude Code`
4. 点击 Install 安装

### 方法二：命令行安装

**Windows PowerShell：**
```powershell
code --install-extension anthropic.claude-code
```

**macOS Terminal：**
```bash
code --install-extension anthropic.claude-code
```

### 方法三：快捷命令安装

**Windows：**
1. 按 `Ctrl+Shift+P` 打开命令面板
2. 输入 `Extensions: Install Extensions`
3. 搜索 `Claude Code` 并安装

**macOS：**
1. 按 `Cmd+Shift+P` 打开命令面板
2. 输入 `Extensions: Install Extensions`
3. 搜索 `Claude Code` 并安装

---

## 启动使用

### 启动 Claude Code

**Windows：**

| 方式 | 操作 |
|------|------|
| 命令面板 | `Ctrl+Shift+P` → 输入 `Claude Code: Open` |
| 侧边栏 | 点击左侧活动栏的 Claude 图标 |

**macOS：**

| 方式 | 操作 |
|------|------|
| 命令面板 | `Cmd+Shift+P` → 输入 `Claude Code: Open` |
| 侧边栏 | 点击左侧活动栏的 Claude 图标 |

### 基本交互

- 在输入框中输入问题或指令
- Claude 会读取当前打开的文件内容作为上下文
- 可选中代码片段后提问，Claude 会聚焦于选中内容

---

## 配置国内模型

VSCode 扩展使用独立的配置文件，与 CLI 版本略有不同。

### 配置文件位置

| 操作系统 | 配置路径 |
|---------|----------|
| Windows | `%APPDATA%\Code\User\globalStorage\anthropic.claude-code\settings.json` |
| macOS | `~/Library/Application Support/Code/User/globalStorage/anthropic.claude-code/settings.json` |

### 阿里云 CodingPlan 配置样例

```json
{
  "env": {
    "ANTHROPIC_BASE_URL": "https://coding.dashscope.aliyuncs.com/apps/anthropic",
    "ANTHROPIC_AUTH_TOKEN": "sk-sp-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
    "ANTHROPIC_MODEL": "qwen3.5-plus",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1"
  }
}
```

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

> **注意：** 配置国内模型后，需重启 VSCode 或重新打开 Claude Code 面板生效。

---

## 功能说明

### 核心能力

| 功能 | 说明 |
|------|------|
| 代码编辑 | 直接在编辑器中修改代码 |
| 文件操作 | 读取、创建、修改项目文件 |
| 代码解释 | 解释选中代码的功能和逻辑 |
| 问题修复 | 分析并修复代码问题 |
| 重构建议 | 提供代码重构建议 |
| 测试生成 | 为代码生成单元测试 |

### 上下文感知

- 自动读取当前打开的文件
- 支持手动添加文件到上下文（`Add File` 按钮）
- 选中代码片段会自动成为提问焦点

---

## 快捷键配置

可在 VSCode 键盘快捷键设置中自定义 Claude Code 命令：

**Windows：**
1. 按 `Ctrl+K Ctrl+S` 打开键盘快捷键设置
2. 搜索 `Claude Code`
3. 双击命令设置快捷键

**macOS：**
1. 按 `Cmd+K Cmd+S` 打开键盘快捷键设置
2. 搜索 `Claude Code`
3. 双击命令设置快捷键

常用命令：

| 命令 ID | 说明 |
|---------|------|
| `anthropic.claude-code.openChat` | 打开 Claude 面板 |
| `anthropic.claude-code.addToContext` | 添加当前文件到上下文 |
| `anthropic.claude-code.sendToClaude` | 发送选中内容到 Claude |

---

## 与 CLI 版本对比

| 功能 | CLI 版本 | VSCode 扩展 |
|------|----------|-------------|
| 代码编辑 | 支持 | 支持（更直观） |
| 文件浏览 | 支持 | 支持（集成文件树） |
| Git 操作 | 支持 | 支持 |
| 浏览器自动化 | 支持 | 支持 |
| 斜杠命令 | 支持 | 支持 |
| 插件系统 | 支持 | 支持 |
| 内嵌编辑 | 无 | 支持（类似 Copilot） |

---

## 常见问题

### 扩展无法启动

检查配置文件路径是否正确，确保 JSON 格式无误。

### 模型响应异常

1. 检查 `ANTHROPIC_BASE_URL` 和 `ANTHROPIC_AUTH_TOKEN` 配置
2. 确保 `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` 设为 `1`
3. 查看 VSCode 输出面板的错误日志

**Windows：** `Ctrl+Shift+U` 打开输出面板，选择 `Claude Code`

**macOS：** `Cmd+Shift+U` 打开输出面板，选择 `Claude Code`

### 上下文过大

VSCode 扩展有上下文限制，避免添加过多文件。可使用 `/compact` 压缩上下文。

### 权限提示频繁

在配置文件中添加 `allowedTools` 减少提示：

```json
{
  "allowedTools": ["Read", "Edit", "Write"]
}
```

---

## 相关链接

- [Claude Code CLI 使用指南](README.md)
- [Anthropic 官方文档](https://docs.anthropic.com/claude-code)
- [VSCode 扩展市场](https://marketplace.visualstudio.com/items?itemName=anthropic.claude-code)