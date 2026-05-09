#!/usr/bin/env bash

# 检查 OpenVPN 客户端配置文件是否有密码保护

if [ -z "$1" ]; then
  echo "Usage: check_ovpn_key.sh <ovpn_file> [password]"
  echo ""
  echo "检查 .ovpn 文件中的私钥是否加密"
  echo ""
  echo "参数:"
  echo "  ovpn_file  - OpenVPN 配置文件路径"
  echo "  password   - 可选，测试密码是否正确"
  exit 1
fi

OVPN_FILE="$1"
PASSWORD="$2"

if [ ! -f "$OVPN_FILE" ]; then
  echo "Error: File not found: $OVPN_FILE"
  exit 1
fi

# 检查是否包含私钥
if ! grep -q '<key>' "$OVPN_FILE"; then
  echo "Error: No private key found in $OVPN_FILE"
  exit 1
fi

# 提取私钥
TEMP_KEY=$(mktemp)
sed -n '/<key>/,/<\/key>/p' "$OVPN_FILE" | sed '1d;$d' > "$TEMP_KEY"

# 检查是否有 ENCRYPTED 标记
echo "=========================================="
echo "检查: $OVPN_FILE"
echo "=========================================="

if grep -q "ENCRYPTED" "$TEMP_KEY"; then
  echo "[状态] 私钥已加密 ✓"

  # 显示加密信息
  if grep -q "Proc-Type:" "$TEMP_KEY"; then
    PROC_TYPE=$(grep "Proc-Type:" "$TEMP_KEY" | head -1)
    echo "[信息] $PROC_TYPE"
  fi

  if grep -q "DEK-Info:" "$TEMP_KEY"; then
    DEK_INFO=$(grep "DEK-Info:" "$TEMP_KEY" | head -1)
    echo "[信息] $DEK_INFO"
  fi

  # 如果提供了密码，验证密码是否正确
  if [ -n "$PASSWORD" ]; then
    echo ""
    echo "验证密码..."
    if openssl rsa -in "$TEMP_KEY" -passin "pass:$PASSWORD" -check -noout 2>/dev/null; then
      echo "[结果] 密码正确 ✓"
    else
      echo "[结果] 密码错误 ✗"
    fi
  fi

else
  echo "[状态] 私钥未加密 ✗"
  echo "[警告] 建议为私钥添加密码保护"
fi

# 检查证书格式
echo ""
echo "[格式检查]"
if grep -q "BEGIN ENCRYPTED PRIVATE KEY" "$TEMP_KEY"; then
  echo "格式: ENCRYPTED PRIVATE KEY (PKCS#8)"
elif grep -q "BEGIN PRIVATE KEY" "$TEMP_KEY"; then
  echo "格式: PRIVATE KEY (PKCS#8, 无密码)"
elif grep -q "BEGIN RSA PRIVATE KEY" "$TEMP_KEY"; then
  echo "格式: RSA PRIVATE KEY (传统格式)"
else
  echo "格式: 未知"
fi

rm "$TEMP_KEY"

echo ""
echo "=========================================="