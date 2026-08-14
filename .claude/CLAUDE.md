# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

这是一个技术文档仓库，记录各领域的技术实践和解决方案。内容以 Markdown 文档为主，`python/src/` 下有少量示例代码。

## 范围纪律

- 收到直接的实现或修复请求时，立即开始执行，不要过度探索代码库。
- 只读取与变更直接相关的文件。
- 当用户给出直接请求时，直接执行 — 不要擅自启动头脑风暴或设计流程。

## 文档编写约定

- **文件命名**：小写英文，多词用连字符（如 `disk-expansion.md`），技术文档归类到对应子目录。
- **交叉引用**：相关文档之间用相对路径链接（如 `[LVM.md](LVM.md)`），避免知识孤岛。
- **代码块**：shell 代码块标注 `bash`，配置标注语言类型，输出示例不标注语言。
- **Python 代码例外**：`python/src/` 下有可运行代码，修改时需先跑测试（`cd python && source .venv/bin/activate`），遵循 TDD。

## 目录结构

**子目录（按技术领域）：**

- `aix/` — AI 相关（Agent/MCP/Skill 架构、Claude Code）
- `claude/` — Claude Code 使用指南
- `linux/` — Linux 系统管理（磁盘、网络、LVM、性能）
- `nginx/`, `kubernetes/` — 负载均衡和容器编排
- `vpn/` — VPN 和网络隧道（OpenVPN、IPsec）
- `golang/`, `rust/`, `python/`, `java/` — 各语言开发笔记
- `mysql/`, `redis/`, `clickhouse/`, `rabbitmq/` — 数据库和消息队列
- `macos/`, `windows/` — 桌面操作系统

**根目录独立文档：** `docker.md`, `gitlab.md`, `ffmpeg.md`, `fluentd.md`, `tcpdump.md`, `ros.md`

其他目录（`chia/`, `ether/`, `ethereum/`, `k6/`, `nextcloud/`, `rancher/`, `shadowsocks/`, `v2ray/` 等）按需探索。

## Python 示例代码

`python/src/` 包含示例代码：

- `selenium/` - Selenium 自动化和 OCR 示例
- `ocr/` - OCR 文字识别测试（PaddleOCR、EasyOCR）
- `pdf/` - PDF 处理示例
- `spider/` - 爬虫示例
- `bluefin/` - Bluefin API 客户端

运行 Python 示例时使用 `.venv` 虚拟环境：
```bash
cd python && source .venv/bin/activate
```

## 知识库产物(starmap)

- 根目录 `starmap.html` 与 `.meta/` 是 starmap 知识库自动生成的产物(台账/索引/星图),**不要手编**
- 新增/删除文件后运行 `.claude/skills/starmap/scripts/starmap.py build .` 增量刷新
- 产物细节与维护方式见 `.claude/skills/starmap/SKILL.md`

## 文档风格

- 所有文档使用中文
- Markdown 文件按主题分类存放
- 每个子目录有 README.md 作为入口

## AI 目录架构图

`aix/ai.md` 包含 Agent/MCP/Skill 架构的 Mermaid 图，可用 Mermaid 渲染器查看。