# SSH 隧道作为 OpenVPN TCP 通道

在某些网络环境下，UDP 协议可能被限制或 QoS 优先级较低。通过 SSH 隧道封装 OpenVPN 流量，可以实现：

1. 绕过 UDP 协议限制
2. 利用 SSH 的加密层提供额外安全
3. 伪装流量为正常 SSH 连接

## 架构说明

```
┌─────────────┐      SSH Tunnel (TCP)      ┌─────────────┐
│   Client    │ ◄─────────────────────────► │   Server    │
│             │                             │             │
│  OpenVPN    │ ──► SSH:localhost:1194 ──►  │ OpenVPN     │
│  (tun0)     │      (tunnel)               │ (tun0)      │
└─────────────┘                             └─────────────┘
```

## 服务端配置

### OpenVPN TCP 模式

修改 OpenVPN 服务端配置为 TCP 模式：

```sh
cat <<EOF > /etc/openvpn/server/tcp.conf
port 1194
proto tcp-server
dev tun
ca /etc/openvpn/easy-rsa/3/pki/ca.crt
cert /etc/openvpn/easy-rsa/3/pki/issued/server.crt
key /etc/openvpn/easy-rsa/3/pki/private/server.key
dh /etc/openvpn/easy-rsa/3/pki/dh.pem
tls-auth /etc/openvpn/easy-rsa/3/ta.key 0

server 10.9.0.0 255.255.255.0
ifconfig-pool-persist ipp-tcp.txt
push "route 172.16.0.0 255.255.255.0"

keepalive 10 120
cipher AES-256-CBC
max-clients 100
user openvpn
group openvpn
persist-key
persist-tun

status openvpn-tcp-status.log
log-append openvpn-tcp.log
verb 3
script-security 2
up /etc/openvpn/server/up-tcp.sh
down /etc/openvpn/server/down-tcp.sh
EOF
```

### iptables 规则

```sh
cat <<EOF > /etc/openvpn/server/up-tcp.sh
#!/bin/sh
/usr/sbin/iptables -I FORWARD -o tun+ -j ACCEPT
/usr/sbin/iptables -t nat -A POSTROUTING -s 10.9.0.0/24 -j MASQUERADE
EOF
chmod +x /etc/openvpn/server/up-tcp.sh

cat <<EOF > /etc/openvpn/server/down-tcp.sh
#!/bin/sh
/usr/sbin/iptables -D FORWARD -o tun+ -j ACCEPT
/usr/sbin/iptables -t nat -D POSTROUTING -s 10.9.0.0/24 -j MASQUERADE
EOF
chmod +x /etc/openvpn/server/down-tcp.sh
```

### 启动服务

```sh
systemctl enable openvpn-server@tcp
systemctl start openvpn-server@tcp
```

## 客户端配置

### 方式一：SSH 本地端口转发 + OpenVPN

#### 1. 建立 SSH 隧道

```sh
# 手动建立 SSH 隧道
ssh -L 1194:127.0.0.1:1194 -N -f user@server-ip

# 或者使用 systemd 服务
cat <<EOF > /etc/systemd/system/openvpn-ssh-tunnel.service
[Unit]
Description=SSH Tunnel for OpenVPN
After=network.target network-online.target ssh.service
Wants=network-online.target

[Service]
User=root
Type=simple
ExecStart=/usr/bin/ssh -NL 1194:127.0.0.1:1194 user@server-ip \
    -o ServerAliveInterval=30 \
    -o ServerAliveCountMax=3 \
    -o BatchMode=yes \
    -o StrictHostKeyChecking=no \
    -o ExitOnForwardFailure=yes \
    -i /root/.ssh/id_rsa
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable openvpn-ssh-tunnel
systemctl start openvpn-ssh-tunnel
```

#### 2. OpenVPN 客户端配置

```sh
cat <<EOF > /etc/openvpn/client/ssh-tunnel.conf
client
dev tun
proto tcp-client
remote 127.0.0.1 1194
resolv-retry infinite
nobind
persist-key
persist-tun
verb 3
tls-auth /etc/openvpn/client/ta.key 1
keepalive 10 120

ca /etc/openvpn/client/ca.crt
cert /etc/openvpn/client/user1.crt
key /etc/openvpn/client/user1.key
EOF
```

#### 3. 启动 OpenVPN 客户端

```sh
systemctl enable openvpn-client@ssh-tunnel
systemctl start openvpn-client@ssh-tunnel
```

### 方式二：使用 ProxyCommand（推荐）

OpenVPN 支持 `sock-proxy` 指令，可以配合 `socat` 或 `nc` 通过 SOCKS 代理连接。

#### 1. 建立 SSH SOCKS 代理

```sh
ssh -D 1080 -N -f user@server-ip

# 或 systemd 服务
cat <<EOF > /etc/systemd/system/socks-proxy.service
[Unit]
Description=SSH SOCKS Proxy
After=network.target network-online.target
Wants=network-online.target

[Service]
User=root
Type=simple
ExecStart=/usr/bin/ssh -ND 1080 user@server-ip \
    -o ServerAliveInterval=30 \
    -o ServerAliveCountMax=3 \
    -o BatchMode=yes \
    -o StrictHostKeyChecking=no \
    -i /root/.ssh/id_rsa
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
```

#### 2. 安装 socat

```sh
# CentOS/RHEL
yum install -y socat

# Ubuntu/Debian
apt install -y socat
```

#### 3. OpenVPN 客户端配置（SOCKS 代理）

```sh
cat <<EOF > /etc/openvpn/client/socks-tunnel.conf
client
dev tun
proto tcp-client
remote 127.0.0.1 1194
socks-proxy 127.0.0.1 1080
resolv-retry infinite
nobind
persist-key
persist-tun
verb 3
tls-auth /etc/openvpn/client/ta.key 1
keepalive 10 120

ca /etc/openvpn/client/ca.crt
cert /etc/openvpn/client/user1.crt
key /etc/openvpn/client/user1.key
EOF
```

## 连接顺序

确保服务启动顺序正确：

```sh
# 1. 先启动 SSH 隧道
systemctl start openvpn-ssh-tunnel

# 2. 等待隧道建立
sleep 5

# 3. 启动 OpenVPN 客户端
systemctl start openvpn-client@ssh-tunnel
```

### 配置服务依赖

```sh
# 修改 OpenVPN 客户端服务，依赖 SSH 隧道
mkdir -p /etc/systemd/system/openvpn-client@ssh-tunnel.service.d

cat <<EOF > /etc/systemd/system/openvpn-client@ssh-tunnel.service.d/override.conf
[Unit]
Requires=openvpn-ssh-tunnel.service
After=openvpn-ssh-tunnel.service
EOF

systemctl daemon-reload
```

## 自动重连脚本

```sh
cat <<'EOF' > /usr/local/bin/openvpn-ssh-reconnect.sh
#!/bin/bash
# OpenVPN SSH 隧道自动重连脚本

SSH_TUNNEL="openvpn-ssh-tunnel.service"
OPENVPN_CLIENT="openvpn-client@ssh-tunnel.service"
MAX_RETRY=3
RETRY_INTERVAL=10

check_tunnel() {
    if nc -z 127.0.0.1 1194 2>/dev/null; then
        return 0
    fi
    return 1
}

reconnect() {
    echo "$(date): 尝试重连 SSH 隧道..."
    systemctl restart $SSH_TUNNEL

    for i in $(seq 1 $MAX_RETRY); do
        sleep $RETRY_INTERVAL
        if check_tunnel; then
            echo "$(date): SSH 隧道重连成功"
            systemctl restart $OPENVPN_CLIENT
            return 0
        fi
    done

    echo "$(date): SSH 隧道重连失败"
    return 1
}

# 主逻辑
if ! check_tunnel; then
    echo "$(date): 检测到隧道断开"
    reconnect
fi
EOF

chmod +x /usr/local/bin/openvpn-ssh-reconnect.sh
```

### 添加定时检查

```sh
cat <<EOF > /etc/cron.d/openvpn-ssh-check
*/5 * * * * root /usr/local/bin/openvpn-ssh-reconnect.sh >> /var/log/openvpn-ssh-check.log 2>&1
EOF
```

## 性能优化

### SSH 隧道优化

在 `~/.ssh/config` 或 SSH 命令中添加：

```sh
# ~/.ssh/config
Host openvpn-server
    HostName server-ip
    User user
    IdentityFile ~/.ssh/id_rsa
    Compression yes
    CompressionLevel 4
    ServerAliveInterval 30
    ServerAliveCountMax 3
    TCPKeepAlive yes
```

### SSH 配置参数说明

| 参数 | 说明 |
|------|------|
| `-C` | 启用压缩 |
| `-o CompressionLevel=4` | 压缩级别 (1-9) |
| `-o ServerAliveInterval=30` | 心跳间隔 |
| `-o ServerAliveCountMax=3` | 心跳失败次数 |
| `-o TCPKeepAlive=yes` | TCP 保活 |

### OpenVPN MTU 调整

由于 SSH 隧道增加了额外开销，建议调整 MTU：

```sh
# 服务端配置添加
tun-mtu 1400
mssfix 1360

# 客户端配置添加
tun-mtu 1400
mssfix 1360
```

## 故障排查

### 检查 SSH 隧道状态

```sh
# 检查隧道端口
ss -tlnp | grep 1194
netstat -tlnp | grep 1194

# 测试隧道连通性
nc -zv 127.0.0.1 1194
curl -v telnet://127.0.0.1:1194

# 查看 SSH 隧道进程
ps aux | grep "ssh.*1194"
```

### 查看 OpenVPN 日志

```sh
# 客户端日志
journalctl -u openvpn-client@ssh-tunnel -f

# 服务端日志
tail -f /etc/openvpn/server/openvpn-tcp.log
```

### 常见错误

#### 1. 隧道端口未监听

```sh
# 错误信息
TCP connection to [AF_INET]127.0.0.1:1194 failed: Connection refused

# 解决方案
systemctl restart openvpn-ssh-tunnel
```

#### 2. SSH 认证失败

```sh
# 检查密钥权限
chmod 600 ~/.ssh/id_rsa

# 测试 SSH 连接
ssh -v user@server-ip
```

#### 3. OpenVPN 连接超时

```sh
# 检查服务端 TCP 模式
ss -tlnp | grep 1194

# 确认 OpenVPN 监听 TCP
# proto tcp-server 确保服务端使用 TCP
```

## 安全建议

1. **使用 SSH 密钥认证**：禁用密码登录
2. **限制 SSH 用户权限**：创建专用 tunnel 用户
3. **配置 fail2ban**：防止暴力破解
4. **监控隧道状态**：及时发现异常断开

```sh
# 创建专用 tunnel 用户
useradd -m -s /bin/false tunnel

# 限制 tunnel 用户只能转发端口
# /etc/ssh/sshd_config
Match User tunnel
    AllowTcpForwarding yes
    X11Forwarding no
    PermitTunnel no
    PermitTTY no
    ForceCommand /bin/false
```

## 参考

- [OpenVPN Manual](https://openvpn.net/community-resources/reference-manual-for-openvpn-2-4/)
- [SSH Port Forwarding](https://www.ssh.com/academy/ssh/tunneling/example)