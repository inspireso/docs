#!/usr/bin/env bash
set -e

# Usage: ovpn_batch.sh create|build [-f <userlist_file>] [-p <password_file>] [-c <ca_password>] <username1> ...
#
# 密码规则：默认 用户名@随机8位密码，可通过 -p 从文件读取
# CA密码：脚本开始时一次性输入，或通过 -c 参数指定

if [ -z "$1" ]; then
  echo "Usage: ovpn_batch.sh create|build [-f <userlist_file>] [-p <password_file>] [-c <ca_password>] <username1> ..."
  echo ""
  echo "Commands:"
  echo "  create  - 生成客户端证书（带密码）并创建配置文件"
  echo "  build   - 仅创建配置文件（证书已存在）"
  echo ""
  echo "Options:"
  echo "  -f <file>      - 从文件读取用户名列表（每行一个用户名）"
  echo "  -p <file>      - 从文件读取密码（格式：username  password）"
  echo "  -c <password>  - 指定 CA 密码（避免交互式输入）"
  echo ""
  echo "密码规则：默认 用户名@随机8位密码"
  exit 1
fi

# 解析参数
ACTION=""
USERS_ARGS=""
USER_FILE=""
PASSWORD_MAP_FILE=""
CA_PASSWORD_INPUT=""

while [ $# -gt 0 ]; do
  case "$1" in
    create|build)
      ACTION="$1"
      shift
      ;;
    -f)
      if [ -z "$2" ]; then
        echo "Error: Missing filename after -f"
        exit 1
      fi
      USER_FILE="$2"
      shift 2
      ;;
    -p)
      if [ -z "$2" ]; then
        echo "Error: Missing filename after -p"
        exit 1
      fi
      PASSWORD_MAP_FILE="$2"
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
    -*)
      echo "Error: Unknown option: $1"
      exit 1
      ;;
    *)
      USERS_ARGS="$USERS_ARGS $1"
      shift
      ;;
  esac
done

if [ -z "$ACTION" ]; then
  echo "Error: Action must be 'create' or 'build'"
  exit 1
fi

# 从文件读取用户名列表
if [ -n "$USER_FILE" ]; then
  if [ ! -f "$USER_FILE" ]; then
    echo "Error: File not found: $USER_FILE"
    exit 1
  fi
  USERS=$(grep -v '^#' "$USER_FILE" | grep -v '^$')
else
  USERS=$(echo "$USERS_ARGS" | tr ' ' '\n' | grep -v '^$')
fi

if [ -z "$USERS" ]; then
  echo "Error: No usernames provided"
  exit 1
fi

# 加载密码映射文件
declare -A PASSWORD_MAP
if [ -n "$PASSWORD_MAP_FILE" ]; then
  if [ ! -f "$PASSWORD_MAP_FILE" ]; then
    echo "Error: Password file not found: $PASSWORD_MAP_FILE"
    exit 1
  fi
  echo "Loading passwords from: $PASSWORD_MAP_FILE"
  while IFS=' ' read -r user pass; do
    # 跳过注释和空行
    if [[ "$user" =~ ^# ]] || [ -z "$user" ]; then
      continue
    fi
    PASSWORD_MAP["$user"]="$pass"
  done < "$PASSWORD_MAP_FILE"
fi

EASY_RSA_DIR=/etc/openvpn/easy-rsa/3
OVPN_CLIENT_DIR=/etc/openvpn/client
OVPN_TPL="$OVPN_CLIENT_DIR/client.ovpn.tpl"
PASSWORD_FILE="$OVPN_CLIENT_DIR/passwd.txt"

if [ ! -f "$OVPN_TPL" ]; then
  echo "Error: Template file not found: $OVPN_TPL"
  exit 1
fi

cd $EASY_RSA_DIR

# create 模式：输入 CA 密码（一次性）
if [ "$ACTION" == "create" ]; then
  if [ -n "$CA_PASSWORD_INPUT" ]; then
    CA_PASSWORD="$CA_PASSWORD_INPUT"
  else
    echo "=========================================="
    echo "请输入 CA 密码（用于签发所有客户端证书）"
    echo "=========================================="
    read -s -p "CA Password: " CA_PASSWORD
    echo ""
  fi

  if [ -z "$CA_PASSWORD" ]; then
    echo "Error: CA password is required"
    exit 1
  fi
fi

# 初始化密码记录文件（追加模式，不覆盖）
echo "# OpenVPN Client Passwords - Generated at $(date)" >> "$PASSWORD_FILE"
echo "# Format: username  password" >> "$PASSWORD_FILE"

SUCCESS_COUNT=0
FAIL_COUNT=0
FAILED_USERS=""

for OVPN_USER in $USERS; do
  echo "=========================================="
  echo "Processing: $OVPN_USER"

  OVPN_CONF="$OVPN_CLIENT_DIR/$OVPN_USER.ovpn"

  if [ "$ACTION" == "create" ]; then
    # 检查证书是否已存在
    if [ -f "./pki/issued/$OVPN_USER.crt" ]; then
      echo "Warning: Certificate already exists for $OVPN_USER, skipping certificate generation"
    else
      # 设置密码：从映射文件读取或随机生成
      if [ -n "${PASSWORD_MAP[$OVPN_USER]}" ]; then
        USER_PASSWORD="${PASSWORD_MAP[$OVPN_USER]}"
        echo "Using specified password: $USER_PASSWORD"
      else
        RANDOM_PASS=$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | head -c 8)
        USER_PASSWORD="$OVPN_USER@$RANDOM_PASS"
        echo "Generated random password: $USER_PASSWORD"
      fi

      echo "Generating certificate for $OVPN_USER..."

      # 使用 expect 自动化密码输入
      if command -v expect &> /dev/null; then
        expect <<EOF
set timeout 30
spawn ./easyrsa build-client-full $OVPN_USER
expect "Enter PEM pass phrase:"
send "$USER_PASSWORD\r"
expect "Verifying - Enter PEM pass phrase:"
send "$USER_PASSWORD\r"
expect "Enter pass phrase for*CA key:"
send "$CA_PASSWORD\r"
expect eof
EOF
      else
        # 没有 expect，使用 easy-rsa 的批量模式
        export EASYRSA_BATCH=yes
        export EASYRSA_PASSIN="pass:$CA_PASSWORD"
        export EASYRSA_PASSOUT="pass:$USER_PASSWORD"

        ./easyrsa build-client-full "$OVPN_USER"

        unset EASYRSA_BATCH EASYRSA_PASSIN EASYRSA_PASSOUT
      fi

      # 验证证书生成成功
      if [ ! -f "./pki/issued/$OVPN_USER.crt" ]; then
        echo "Error: Failed to generate certificate for $OVPN_USER"
        FAIL_COUNT=$((FAIL_COUNT + 1))
        FAILED_USERS="$FAILED_USERS $OVPN_USER"
        continue
      fi

      # 记录密码
      echo "$OVPN_USER  $USER_PASSWORD" >> "$PASSWORD_FILE"
      echo "Password saved to: $PASSWORD_FILE"
    fi
  else
    # build 模式，检查证书是否存在
    if [ ! -f "./pki/issued/$OVPN_USER.crt" ]; then
      echo "Error: Certificate not found for $OVPN_USER (use 'create' to generate)"
      FAIL_COUNT=$((FAIL_COUNT + 1))
      FAILED_USERS="$FAILED_USERS $OVPN_USER"
      continue
    fi
  fi

  # 生成配置文件
  echo "Creating config file..."
  cp "$OVPN_TPL" "$OVPN_CONF"

  echo '<cert>' >> "$OVPN_CONF"
  sed -n '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/p' "./pki/issued/$OVPN_USER.crt" >> "$OVPN_CONF"
  echo '</cert>' >> "$OVPN_CONF"

  echo '<key>' >> "$OVPN_CONF"
  cat "./pki/private/$OVPN_USER.key" >> "$OVPN_CONF"
  echo '</key>' >> "$OVPN_CONF"

  echo "Success: $OVPN_CONF"
  SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
done

echo ""
echo "=========================================="
echo "Batch operation completed"
echo "Success: $SUCCESS_COUNT"
echo "Failed: $FAIL_COUNT"

if [ -n "$FAILED_USERS" ]; then
  echo "Failed users:$FAILED_USERS"
fi

if [ "$ACTION" == "create" ] && [ $SUCCESS_COUNT -gt 0 ]; then
  echo ""
  echo "Password file: $PASSWORD_FILE"
  echo "Please keep this file secure!"
fi