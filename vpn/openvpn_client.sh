#!/usr/bin/env bash
set -e

# Usage: ovpn.sh create|build <username>

if [ -z "$1" ]; then
  echo "Usage: ovpn.sh create|build <username>"
  exit 1
fi

if [ -z "$2" ]; then
  echo "Usage: ovpn.sh create|build <username>"
  exit 1
fi

OVPN_USER=$2

EASY_RSA_DIR=/etc/openvpn/easy-rsa/3
OVPN_CLIENT_DIR=/etc/openvpn/client
OVPN_TPL="$OVPN_CLIENT_DIR/client.ovpn.tpl"
OVPN_CONF="$OVPN_CLIENT_DIR/$OVPN_USER.ovpn"


cd $EASY_RSA_DIR

if  [ "$1" == "create" ];  then
  ## 生成客户端证书
  ./easyrsa build-client-full $OVPN_USER nopass
fi

cp "$OVPN_TPL" "$OVPN_CONF"
echo '<cert>' >> "$OVPN_CONF"
sed -n '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/p' "./pki/issued/$OVPN_USER.crt" >> "$OVPN_CONF"
echo '</cert>' >> "$OVPN_CONF"

echo '<key>' >> "$OVPN_CONF"
cat "./pki/private/$OVPN_USER.key" >> "$OVPN_CONF"
echo '</key>' >> "$OVPN_CONF"

echo "OpenVPN client config: "
echo $OVPN_CONF