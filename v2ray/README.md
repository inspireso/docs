# [v2ray](https://www.v2fly.org/)

## install

### server

```sh
mkdir -p /usr/local/v2ray && cd /usr/local/v2ray
wget https://github.com/v2fly/v2ray-core/releases/download/v5.7.0/v2ray-linux-64.zip
unzip v2ray-linux-64.zip


# 生成配置
UUID=$(/usr/local/v2ray/v2ray uuid)

cat <<EOF >  /usr/local/v2ray/config.json
{
    "log": {
      "loglevel": "info"
    },
    "inbounds": [
      {
        "port": 443,
        "protocol": "vmess",
        "settings": {
          "clients": [
            {
              "id": "${UUID}",
              "level": 0,
              "alterId": 0
            }
          ]
        }
      }
    ],
    "outbounds": [
      {
        "protocol": "freedom",
        "settings": {}
      },
      {
        "protocol": "blackhole",
        "settings": {},
        "tag": "blocked"
      }
    ],
    "routing": {
      "rules": [
        {
          "type": "field",
          "ip": [
            "geoip:private"
          ],
          "outboundTag": "blocked"
        }
      ]
    }
  }
EOF

# 注册服务
cat <<EOF >  /etc/systemd/system/v2ray.service
[Unit]
Description=V2Ray Service
Documentation=https://www.v2fly.org/
After=network.target nss-lookup.target

[Service]
User=nobody
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/v2ray/v2ray run -config /usr/local/v2ray/config.json
Restart=on-failure
RestartPreventExitStatus=23

[Install]
WantedBy=multi-user.target
EOF

systemctl enable v2ray.service && systemctl restart v2ray
systemctl status v2ray.service

```

### client

#### macos

```sh
brew install v2ray

```
