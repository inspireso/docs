#!/bin/bash
# Claude Code 进阶单行状态栏

# 获取基本信息
MODEL="${ANTHROPIC_MODEL:-claude}"
CWD=$(basename "$PWD")
BRANCH=$(git branch --show-current 2>/dev/null || echo "none")

# 从 stdin 读取上下文数据（JSON格式）
JSON_DATA=$(cat 2>/dev/null || echo "")

# 调试：保存原始数据到文件
echo "$JSON_DATA" > /tmp/statusline-debug.json

# 解析 JSON，使用正确的嵌套字段路径
INPUT_TKS=$(echo "$JSON_DATA" | jq -r '.context_window.current_usage.input_tokens // 0' 2>/dev/null || echo "0")
OUTPUT_TKS=$(echo "$JSON_DATA" | jq -r '.context_window.current_usage.output_tokens // 0' 2>/dev/null || echo "0")
CTX_PERCENT=$(echo "$JSON_DATA" | jq -r '.context_window.used_percentage // 0' 2>/dev/null || echo "0")
CTX_MAX=$(echo "$JSON_DATA" | jq -r '.context_window.context_window_size // 200000' 2>/dev/null || echo "200000")

# 如果 JSON 为空，使用默认值
if [ -z "$JSON_DATA" ] || [ "$JSON_DATA" = "" ]; then
    INPUT_TKS="0"
    OUTPUT_TKS="0"
    CTX_PERCENT="0"
    CTX_MAX="200000"
fi

# 格式化 token 数字
format_tokens() {
    local n=$1
    if [ $n -ge 1000 ]; then
        echo "$(echo "scale=1; $n/1000" | bc)k"
    else
        echo "$n"
    fi
}

IN_DISP=$(format_tokens $INPUT_TKS)
OUT_DISP=$(format_tokens $OUTPUT_TKS)

# 计算剩余上下文（基于百分比）
CTX_REMAIN=$((CTX_MAX * (100 - CTX_PERCENT) / 100))
CTX_REMAIN_DISP=$(format_tokens $CTX_REMAIN)

# 生成进度条 (使用 Unicode 方块字符)
bar_width=8
filled=$((CTX_PERCENT * bar_width / 100))
bar=""
for i in $(seq 1 $bar_width); do
    if [ $i -le $filled ]; then
        bar+="▓"
    else
        bar+="░"
    fi
done

# ANSI 颜色定义 (256色模式)
CYAN='\033[38;5;117m'
ORANGE='\033[38;5;214m'
GREEN='\033[38;5;150m'
YELLOW='\033[38;5;180m'
PURPLE='\033[38;5;183m'
GRAY='\033[38;5;240m'
LIGHT_GRAY='\033[38;5;244m'
DARK_GRAY='\033[38;5;239m'
RESET='\033[0m'

# 输出状态栏 (紧凑单行)
printf "${CYAN}%s${RESET} ${GRAY}|${RESET} ${YELLOW}%s${RESET} ${GRAY}|${RESET} ${GREEN}%s${RESET}  ${GRAY}··${RESET}  ${ORANGE}↑%s${RESET} ${CYAN}↓%s${RESET}  ${GRAY}··${RESET}  ${PURPLE}ctx %d%%${RESET} ${DARK_GRAY}%s${RESET} ${LIGHT_GRAY}%s${RESET}\n" \
    "$MODEL" "$CWD" "$BRANCH" "$IN_DISP" "$OUT_DISP" "$CTX_PERCENT" "$bar" "$CTX_REMAIN_DISP"