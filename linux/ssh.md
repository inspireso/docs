
# ssh

## usage

```sh
ssh [-V] [-f] [SSH_OPTIONS]

参数	含义说明
-D	本地机器动态的应用程序端口转发
-R	将远程主机(服务器)的某个端口转发到本地端指定机器的指定端口
-L	将本地机(客户机)的某个端口转发到远端指定机器的指定端口
-f	后台运行
-T	不占用 shell
-n	配合 -f 参数使用
-N	不执行远程命令
-q	安静模式运行；忽略提示和错误
```

## examples

### 动态端口转发
任何发往这个端口的请求都会被转发到远端服务器。我们可以利用动态端口转发访问另一子网的网络资源。

```sh
ssh -D 1080 usernamme@example.com

```

### 本地端口转发
在你的本机打开一个端口 A，这个端口和远端设备的端口 B 绑定，任何发往端口 A 的请求都会被转发到端口 B 上。实际的实现效果就像远端端口 B 上运行的服务被运行在了本机的端口 A 一样。

```sh
ssh -L localIp:localPort:remoteIp:remotePort usernamme@example.com

#ssh-tunnel.service
cat > /etc/systemd/system/ssh-tunnel.service <<EOF
[Unit]
Description=SSH tunnel service
Wants=network-online.target
After=network.target network-online.target ssh.service

[Service]
User=root
Type=simple
ExecStart=/usr/bin/ssh -NL localIp:localPort:remoteIp:remotePort usernamme@example.com -o ServerAliveInterval=30 -o ServerAliveCountMax=3 -o BatchMode=yes -o StrictHostKeyChecking=no -i SSH_KEY_FILE_PATH
Restart=always

[Install]
WantedBy=multi-user.target
EOF

```

### 远端端口转发到本地(内网穿透)
远端端口转发和本地端口转发相反，在远端打开一个端口 A，这个端口 A 和本地的端口 B 绑定，在远端服务器访问端口 A 的时候，所有请求都会被发往本地的端口 B。实际运行的效果就像是本地端口 B 上运行的服务被运行在了远端端口 A 一样。

```sh

ssh -R remoteIp:remotePort:localIp:localPort usernamme@example.com

#ssh-tunnel.service
cat > /etc/systemd/system/ssh-tunnel.service <<EOF
[Unit]
Description=SSH tunnel service
Wants=network-online.target
After=network.target network-online.target ssh.service

[Service]
User=root
Type=simple
ExecStart=/usr/bin/ssh -NR remoteIp:remotePort:localIp:localPort usernamme@example.com -o ServerAliveInterval=30 -o ServerAliveCountMax=3 -o BatchMode=yes -o StrictHostKeyChecking=no -i SSH_KEY_FILE_PATH
Restart=always

[Install]
WantedBy=multi-user.target
EOF

```
