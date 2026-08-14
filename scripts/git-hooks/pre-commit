#!/usr/bin/env python3
"""提交前敏感信息检查脚本（pre-commit 钩子）。

检查暂存文件中是否包含敏感信息，命中则拒绝提交。
使用方式（Mac/Linux）：
    ln -sf ../../scripts/check-secrets.py .git/hooks/pre-commit
"""
import re
import subprocess
import sys
from pathlib import Path

# 命中即拒绝的敏感模式
PATTERNS = [
    # 私钥块
    r"-----BEGIN [A-Z ]*PRIVATE KEY",
    # 常见 API key（排除全 x/* 的占位符）
    r"sk-(?![xX*]{20,})[A-Za-z0-9]{20,}",
    r"AIza[0-9A-Za-z_-]{20,}",
    r"AKIA[0-9A-Z]{16}",
    r"gh[pousr]_[A-Za-z0-9]{30,}",
    r"glpat-[A-Za-z0-9_-]{20,}",
    r"xox[baprs]-[A-Za-z0-9-]{10,}",
    # 带密码的连接串
    r"(?:mysql|redis|mongodb|postgres|amqp|jdbc)://[^:\s/]+:[^@\s]+@",
]

# 跳过检查的二进制/构建产物
SKIP_EXT = {
    ".png", ".jpg", ".jpeg", ".gif", ".pdf", ".zip", ".tar", ".gz",
    ".onnx", ".lock", ".woff", ".ttf", ".ico", ".pyc", ".class", ".so",
}


def staged_files() -> list[str]:
    out = subprocess.run(
        ["git", "diff", "--cached", "--name-only", "--diff-filter=ACM"],
        capture_output=True, text=True, check=True,
    )
    return [f for f in out.stdout.splitlines() if f]


def main() -> int:
    files = staged_files()
    if not files:
        return 0

    fail = False
    # 1. 禁止提交 .env（保留 .env.example）
    env_files = [f for f in files if f.endswith(".env") and not f.endswith(".env.example")]
    if env_files:
        print("错误: 以下 .env 文件被暂存，禁止提交敏感环境变量:", file=sys.stderr)
        for f in env_files:
            print(f"  - {f}", file=sys.stderr)
        fail = True

    # 2. 内容模式检查
    for name in files:
        path = Path(name)
        if path.suffix in SKIP_EXT or not path.is_file():
            continue
        try:
            text = path.read_text(errors="ignore")
        except OSError:
            continue
        for pat in PATTERNS:
            m = re.search(pat, text)
            if m:
                # 脱敏显示，避免在终端泄露完整值
                val = m.group(0)
                masked = val[:4] + "***" if len(val) > 4 else val
                print(f"错误: {name} 命中敏感模式: {pat}（匹配值 {masked}）", file=sys.stderr)
                fail = True

    if fail:
        print("提交已阻止。请移除敏感信息后重试（参考 docs 中 check-secrets 说明）。", file=sys.stderr)
        return 1
    print("✅ 敏感信息检查通过")
    return 0


if __name__ == "__main__":
    sys.exit(main())
