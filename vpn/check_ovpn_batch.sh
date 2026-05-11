#!/usr/bin/env bash

# 批量检查目录下的 .ovpn 文件是否有密码保护
# 统计并列出未设置密码的账号

# 默认扫描当前目录
OVPN_DIR="${1:-.}"

if [ ! -d "$OVPN_DIR" ]; then
  echo "Error: Directory not found: $OVPN_DIR"
  exit 1
fi

OVPN_FILES=$(find "$OVPN_DIR" -maxdepth 1 -name "*.ovpn" -type f)

if [ -z "$OVPN_FILES" ]; then
  echo "No .ovpn files found in $OVPN_DIR"
  exit 0
fi

TOTAL=0
ENCRYPTED=0
UNENCRYPTED=0
UNENCRYPTED_USERS=""

for OVPN_FILE in $OVPN_FILES; do
  TOTAL=$((TOTAL + 1))
  FILENAME=$(basename "$OVPN_FILE")
  USERNAME="${FILENAME%.ovpn}"

  # 检查是否包含私钥
  if ! grep -q '<key>' "$OVPN_FILE"; then
    continue
  fi

  # 提取私钥并检查是否有 ENCRYPTED 标记
  TEMP_KEY=$(mktemp)
  sed -n '/<key>/,/<\/key>/p' "$OVPN_FILE" | grep -v '<key>' | grep -v '</key>' > "$TEMP_KEY"

  if grep -q "ENCRYPTED" "$TEMP_KEY"; then
    ENCRYPTED=$((ENCRYPTED + 1))
  else
    UNENCRYPTED=$((UNENCRYPTED + 1))
    UNENCRYPTED_USERS="$UNENCRYPTED_USERS $USERNAME"
  fi

  rm "$TEMP_KEY"
done

# 输出统计结果
echo "总用户数: $TOTAL"
echo "已加密: $ENCRYPTED"
echo "未加密: $UNENCRYPTED"

# 输出未加密用户列表（空格分隔）
if [ $UNENCRYPTED -gt 0 ]; then
  echo ""
  # 排序并去除首尾空格
  SORTED_USERS=$(echo "$UNENCRYPTED_USERS" | tr ' ' '\n' | sort | tr '\n' ' ' | sed 's/^ //;s/ $//')
  echo "未加密用户: $SORTED_USERS"
  exit 1
else
  exit 0
fi