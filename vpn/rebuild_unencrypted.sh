#!/usr/bin/env bash
set -e

# 重建未加密的 OpenVPN 用户证书
# Usage: rebuild_unencrypted.sh [--force] <username1> <username2> ...
#    or: rebuild_unencrypted.sh [--force] -f <userlist_file>

if [ -z "$1" ]; then
  echo "Usage: rebuild_unencrypted.sh [--force] <username1> <username2> ..."
  echo "   or: rebuild_unencrypted.sh [--force] -f <userlist_file>"
  echo ""
  echo "Options:"
  echo "  --force  - 跳过确认步骤，直接重建"
  echo "  -f       - 从文件读取用户名列表"
  echo ""
  echo "密码规则：用户名@随机8位密码"
  exit 1
fi

# 解析参数
FORCE=false
USERS_ARGS=""

while [ $# -gt 0 ]; do
  case "$1" in
    --force)
      FORCE=true
      shift
      ;;
    -f)
      if [ -z "$2" ]; then
        echo "Error: Missing filename after -f"
        exit 1
      fi
      USER_FILE=$2
      if [ ! -f "$USER_FILE" ]; then
        echo "Error: File not found: $USER_FILE"
        exit 1
      fi
      USERS_ARGS=$(grep -v '^#' "$USER_FILE" | grep -v '^$')
      shift 2
      ;;
    *)
      USERS_ARGS="$USERS_ARGS $1"
      shift
      ;;
  esac
done

# 去除多余空格
USERS=$(echo "$USERS_ARGS" | tr ' ' '\n' | grep -v '^$' | tr '\n' ' ')

if [ -z "$USERS" ]; then
  echo "Error: No usernames provided"
  exit 1
fi

EASY_RSA_DIR=/etc/openvpn/easy-rsa/3
OVPN_CLIENT_DIR=/etc/openvpn/client
OVPN_TPL="$OVPN_CLIENT_DIR/client.ovpn.tpl"
PASSWORD_FILE="$OVPN_CLIENT_DIR/passwords.txt"

if [ ! -f "$OVPN_TPL" ]; then
  echo "Error: Template file not found: $OVPN_TPL"
  exit 1
fi

cd $EASY_RSA_DIR

# 显示待重建用户
echo "=========================================="
echo "待重建用户:"
echo "$USERS"
echo "=========================================="

# 确认操作（除非指定 --force）
if [ "$FORCE" = false ]; then
  read -p "确认重建这些用户的证书？(y/n): " CONFIRM
  if [ "$CONFIRM" != "y" ]; then
    echo "已取消"
    exit 0
  fi
fi

# 输入 CA 密码（一次性）
echo ""
echo "请输入 CA 密码（用于撤销旧证书和签发新证书）"
read -s -p "CA Password: " CA_PASSWORD
echo ""

if [ -z "$CA_PASSWORD" ]; then
  echo "Error: CA password is required"
  exit 1
fi

# 初始化密码记录
echo "# Rebuilt at $(date)" >> "$PASSWORD_FILE"

SUCCESS_COUNT=0
FAIL_COUNT=0
FAILED_USERS=""
REBUILD_LIST=""

for OVPN_USER in $USERS; do
  echo ""
  echo "Processing: $OVPN_USER"

  OVPN_CONF="$OVPN_CLIENT_DIR/$OVPN_USER.ovpn"

  # 1. 撤销旧证书
  if [ -f "./pki/issued/$OVPN_USER.crt" ]; then
    echo "  撤销旧证书..."
    export EASYRSA_BATCH=yes
    export EASYRSA_PASSIN="pass:$CA_PASSWORD"
    ./easyrsa revoke "$OVPN_USER" >/dev/null 2>&1 || true
    unset EASYRSA_BATCH EASYRSA_PASSIN
  fi

  # 2. 删除旧证书文件
  rm -f "./pki/issued/$OVPN_USER.crt"
  rm -f "./pki/private/$OVPN_USER.key"
  rm -f "./pki/reqs/$OVPN_USER.req"
  rm -f "$OVPN_CONF"

  # 3. 生成新密码：用户名@随机8位
  RANDOM_PASS=$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | head -c 8)
  USER_PASSWORD="$OVPN_USER@$RANDOM_PASS"

  # 4. 生成新证书（带密码）
  echo "  生成新证书..."
  export EASYRSA_BATCH=yes
  export EASYRSA_PASSIN="pass:$CA_PASSWORD"
  export EASYRSA_PASSOUT="pass:$USER_PASSWORD"

  if ! ./easyrsa build-client-full "$OVPN_USER" 2>&1; then
    echo "Error: Failed to generate certificate for $OVPN_USER"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    FAILED_USERS="$FAILED_USERS $OVPN_USER"
    unset EASYRSA_BATCH EASYRSA_PASSIN EASYRSA_PASSOUT
    continue
  fi

  unset EASYRSA_BATCH EASYRSA_PASSIN EASYRSA_PASSOUT

  # 验证证书生成成功
  if [ ! -f "./pki/issued/$OVPN_USER.crt" ]; then
    echo "Error: Certificate not created for $OVPN_USER"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    FAILED_USERS="$FAILED_USERS $OVPN_USER"
    continue
  fi

  # 5. 生成配置文件
  echo "  创建配置文件..."
  cp "$OVPN_TPL" "$OVPN_CONF"

  echo '<cert>' >> "$OVPN_CONF"
  sed -n '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/p' "./pki/issued/$OVPN_USER.crt" >> "$OVPN_CONF"
  echo '</cert>' >> "$OVPN_CONF"

  echo '<key>' >> "$OVPN_CONF"
  cat "./pki/private/$OVPN_USER.key" >> "$OVPN_CONF"
  echo '</key>' >> "$OVPN_CONF"

  # 6. 记录密码
  echo "$OVPN_USER  $USER_PASSWORD" >> "$PASSWORD_FILE"

  REBUILD_LIST="$REBUILD_LIST $OVPN_USER"
  SUCCESS_COUNT=$((SUCCESS_COUNT + 1))

  echo "  Success: $OVPN_CONF"
  echo "  Password: $USER_PASSWORD"
done

# 生成 CRL
echo ""
echo "=========================================="
echo "生成 CRL..."
export EASYRSA_BATCH=yes
export EASYRSA_PASSIN="pass:$CA_PASSWORD"
./easyrsa gen-crl >/dev/null
unset EASYRSA_BATCH EASYRSA_PASSIN

echo ""
echo "=========================================="
echo "重建完成"
echo "成功: $SUCCESS_COUNT"
echo "失败: $FAIL_COUNT"

if [ -n "$FAILED_USERS" ]; then
  echo "失败用户:$FAILED_USERS"
fi

if [ $SUCCESS_COUNT -gt 0 ]; then
  echo ""
  echo "已重建用户:$REBUILD_LIST"
  echo "密码记录: $PASSWORD_FILE"
fi