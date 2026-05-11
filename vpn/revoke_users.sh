#!/usr/bin/env bash
set -e

# 批量注销 OpenVPN 用户证书
# Usage: revoke_users.sh [--force] [--delete] <username1> <username2> ...
#    or: revoke_users.sh [--force] [--delete] -f <userlist_file>

if [ -z "$1" ]; then
  echo "Usage: revoke_users.sh [--force] [--delete] <username1> <username2> ..."
  echo "   or: revoke_users.sh [--force] [--delete] -f <userlist_file>"
  echo ""
  echo "Options:"
  echo "  --force  - 跳过确认步骤"
  echo "  --delete - 删除证书文件（默认仅撤销）"
  echo "  -f       - 从文件读取用户名列表"
  echo ""
  echo "注意：撤销后需重启 OpenVPN 服务使 CRL 生效"
  exit 1
fi

# 解析参数
FORCE=false
DELETE=false
USERS_ARGS=""

while [ $# -gt 0 ]; do
  case "$1" in
    --force)
      FORCE=true
      shift
      ;;
    --delete)
      DELETE=true
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

cd $EASY_RSA_DIR

# 显示待注销用户
echo "=========================================="
echo "待注销用户:"
echo "$USERS"
echo "=========================================="

if [ "$DELETE" = true ]; then
  echo "模式: 撤销证书 + 删除文件"
else
  echo "模式: 仅撤销证书（保留文件）"
fi

echo ""

# 确认操作（除非指定 --force）
if [ "$FORCE" = false ]; then
  read -p "确认注销这些用户？(y/n): " CONFIRM
  if [ "$CONFIRM" != "y" ]; then
    echo "已取消"
    exit 0
  fi
fi

# 输入 CA 密码（一次性）
echo ""
echo "请输入 CA 密码（用于撤销证书和生成 CRL）"
read -s -p "CA Password: " CA_PASSWORD
echo ""

if [ -z "$CA_PASSWORD" ]; then
  echo "Error: CA password is required"
  exit 1
fi

SUCCESS_COUNT=0
FAIL_COUNT=0
FAILED_USERS=""
NOT_FOUND_USERS=""

for OVPN_USER in $USERS; do
  echo ""
  echo "Processing: $OVPN_USER"

  # 检查证书是否存在
  if [ ! -f "./pki/issued/$OVPN_USER.crt" ]; then
    echo "  Warning: Certificate not found for $OVPN_USER"
    NOT_FOUND_USERS="$NOT_FOUND_USERS $OVPN_USER"
    continue
  fi

  # 1. 撤销证书
  echo "  撤销证书..."
  export EASYRSA_BATCH=yes
  export EASYRSA_PASSIN="pass:$CA_PASSWORD"

  if ! ./easyrsa revoke "$OVPN_USER" >/dev/null 2>&1; then
    echo "  Error: Failed to revoke certificate for $OVPN_USER"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    FAILED_USERS="$FAILED_USERS $OVPN_USER"
    unset EASYRSA_BATCH EASYRSA_PASSIN
    continue
  fi

  unset EASYRSA_BATCH EASYRSA_PASSIN

  # 2. 删除证书文件（如果指定 --delete）
  if [ "$DELETE" = true ]; then
    echo "  删除证书文件..."
    rm -f "./pki/issued/$OVPN_USER.crt"
    rm -f "./pki/private/$OVPN_USER.key"
    rm -f "./pki/reqs/$OVPN_USER.req"
    rm -f "$OVPN_CLIENT_DIR/$OVPN_USER.ovpn"
  fi

  SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
  echo "  Success: $OVPN_USER 已注销"
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
echo "注销完成"
echo "成功: $SUCCESS_COUNT"
echo "失败: $FAIL_COUNT"

if [ -n "$NOT_FOUND_USERS" ]; then
  echo "证书不存在:$NOT_FOUND_USERS"
fi

if [ -n "$FAILED_USERS" ]; then
  echo "注销失败:$FAILED_USERS"
fi

echo ""
echo "CRL 已更新，需重启 OpenVPN 服务使注销生效："
echo "  systemctl restart openvpn-server@jumper"