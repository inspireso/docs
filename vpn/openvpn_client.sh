#!/usr/bin/env bash
set -e

# Usage: ovpn.sh create|build [-p <password>] <username>
# 密码规则：默认 用户名@随机8位密码，可通过 -p 指定

if [ -z "$1" ]; then
  echo "Usage: ovpn.sh create|build [-p <password>] <username>"
  echo ""
  echo "Commands:"
  echo "  create  - 生成客户端证书（带密码）并创建配置文件"
  echo "  build   - 仅创建配置文件（证书已存在）"
  echo ""
  echo "Options:"
  echo "  -p <password>  - 指定密码（默认自动生成）"
  echo ""
  echo "密码规则：默认 用户名@随机8位密码"
  exit 1
fi

# 解析参数
ACTION=""
OVPN_USER=""
CUSTOM_PASSWORD=""
CA_PASSWORD_INPUT=""

while [ $# -gt 0 ]; do
  case "$1" in
    create|build)
      ACTION="$1"
      shift
      ;;
    -p)
      if [ -z "$2" ]; then
        echo "Error: Missing password after -p"
        exit 1
      fi
      CUSTOM_PASSWORD="$2"
      shift 2
      ;;
    -c)
      if [ -z "$2" ]; then
        echo "Error: Missing CA password after -c"
        exit 1
      fi
      CA_PASSWORD_INPUT="$2"
      shift 2
      ;;
    *)
      if [ -z "$OVPN_USER" ]; then
        OVPN_USER="$1"
      else
        echo "Error: Unknown parameter: $1"
        exit 1
      fi
      shift
      ;;
  esac
done

if [ -z "$ACTION" ] || [ -z "$OVPN_USER" ]; then
  echo "Error: Missing action or username"
  echo "Usage: ovpn.sh create|build [-p <password>] <username>"
  exit 1
fi

EASY_RSA_DIR=/etc/openvpn/easy-rsa/3
OVPN_CLIENT_DIR=/etc/openvpn/client
OVPN_TPL="$OVPN_CLIENT_DIR/client.ovpn.tpl"
OVPN_CONF="$OVPN_CLIENT_DIR/$OVPN_USER.ovpn"
PASSWORD_FILE="$OVPN_CLIENT_DIR/passwd.txt"

if [ ! -f "$OVPN_TPL" ]; then
  echo "Error: Template file not found: $OVPN_TPL"
  exit 1
fi

cd $EASY_RSA_DIR

if [ "$ACTION" == "create" ]; then
  # 检查证书是否已存在
  if [ -f "./pki/issued/$OVPN_USER.crt" ]; then
    echo "Warning: Certificate already exists for $OVPN_USER"
    exit 1
  fi

  # 输入 CA 密码
  if [ -z "$CA_PASSWORD_INPUT" ]; then
    echo "请输入 CA 密码（用于签发证书）"
    read -s -p "CA Password: " CA_PASSWORD
    echo ""
  else
    CA_PASSWORD="$CA_PASSWORD_INPUT"
  fi

  if [ -z "$CA_PASSWORD" ]; then
    echo "Error: CA password is required"
    exit 1
  fi

  # 设置密码：自定义或随机生成
  if [ -n "$CUSTOM_PASSWORD" ]; then
    USER_PASSWORD="$CUSTOM_PASSWORD"
    echo "使用指定密码: $USER_PASSWORD"
  else
    RANDOM_PASS=$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | head -c 8)
    USER_PASSWORD="$OVPN_USER@$RANDOM_PASS"
    echo "生成随机密码: $USER_PASSWORD"
  fi

  echo "生成客户端证书..."
  export EASYRSA_BATCH=yes
  export EASYRSA_PASSIN="pass:$CA_PASSWORD"
  export EASYRSA_PASSOUT="pass:$USER_PASSWORD"

  if ! ./easyrsa build-client-full "$OVPN_USER" 2>&1; then
    echo "Error: Failed to generate certificate"
    unset EASYRSA_BATCH EASYRSA_PASSIN EASYRSA_PASSOUT
    exit 1
  fi

  unset EASYRSA_BATCH EASYRSA_PASSIN EASYRSA_PASSOUT

  # 验证证书生成成功
  if [ ! -f "./pki/issued/$OVPN_USER.crt" ]; then
    echo "Error: Certificate not created"
    exit 1
  fi

  # 记录密码
  echo "$OVPN_USER  $USER_PASSWORD" >> "$PASSWORD_FILE"
  echo ""
  echo "Password: $USER_PASSWORD"
  echo "Password saved to: $PASSWORD_FILE"
fi

if [ "$ACTION" == "build" ]; then
  # 检查证书是否存在
  if [ ! -f "./pki/issued/$OVPN_USER.crt" ]; then
    echo "Error: Certificate not found for $OVPN_USER (use 'create' to generate)"
    exit 1
  fi
fi

# 创建配置文件
cp "$OVPN_TPL" "$OVPN_CONF"

echo '<cert>' >> "$OVPN_CONF"
sed -n '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/p' "./pki/issued/$OVPN_USER.crt" >> "$OVPN_CONF"
echo '</cert>' >> "$OVPN_CONF"

echo '<key>' >> "$OVPN_CONF"
cat "./pki/private/$OVPN_USER.key" >> "$OVPN_CONF"
echo '</key>' >> "$OVPN_CONF"

echo ""
echo "OpenVPN client config: $OVPN_CONF"