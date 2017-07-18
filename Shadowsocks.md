## 约定

以下shadowsocks默认配置如下：

server_port: 443

local_port: 1080

method: aes-256-cfb

## 服务器

### 准备

- [ ] 境外服务器（centos7）
- [ ] 开放443端口

### 安装shadowsocks

```sh
# 安装pip
yum install python-setuptools && easy_install pip

# 安装 shadowsocks
pip install shadowsocks
```

###  配置

- 添加配置文件 `/etc/shadowsocks/config.json`
  ```json
  {
      "server":"0.0.0.0",
      "server_port":443,
      "password":"自定义密码",
      "timeout":300,
      "method":"aes-256-cfb",
      "fast_open":true
  }
  ```

- 添加服务 `/etc/systemd/system/shadowsocks.service`

  ```sh
  [Unit]
  Description=Shadowsocks Server
  Documentation=https://github.com/shadowsocks/shadowsocks
  After=network.target remote-fs.target nss-lookup.target

  [Service]
  Type=forking
  ExecStart=/usr/bin/ssserver -c /etc/shadowsocks/config.json -d start
  ExecReload=/bin/kill -HUP $MAINPID
  ExecStop=/usr/bin/ssserver -d stop

  [Install]
  WantedBy=multi-user.target
  ```


- 设置自启动

  ```sh
  systemctl enable shadowsocks && systemctl start shadowsocks
  ```

### 优化网路参数

> 参考：https://github.com/shadowsocks/shadowsocks/wiki/Optimizing-Shadowsocks

- 编辑 `/etc/security/limits.conf`，在尾部添加上以下内容

  ```sh
  root soft nofile 65535
  root hard nofile 65535
  * soft nofile 65535
  * hard nofile 65535
  ```

- 编辑 `/etc/sysctl.d/ss.conf`
  ```sh
  # disable ipv6
  net.ipv6.conf.all.disable_ipv6 = 1

  # max open files
  fs.file-max = 51200
  # max read buffer
  net.core.rmem_max = 67108864
  # max write buffer
  net.core.wmem_max = 67108864
  # default read buffer
  net.core.rmem_default = 65536
  # default write buffer
  net.core.wmem_default = 65536
  # max processor input queue
  net.core.netdev_max_backlog = 4096
  # max backlog
  net.core.somaxconn = 4096

  # resist SYN flood attacks
  net.ipv4.tcp_syncookies = 1
  # reuse timewait sockets when safe
  net.ipv4.tcp_tw_reuse = 1
  # turn off fast timewait sockets recycling
  net.ipv4.tcp_tw_recycle = 0
  # short FIN timeout
  net.ipv4.tcp_fin_timeout = 30
  # short keepalive time
  net.ipv4.tcp_keepalive_time = 1200
  # outbound port range
  net.ipv4.ip_local_port_range = 10000 65000
  # max SYN backlog
  net.ipv4.tcp_max_syn_backlog = 4096
  # max timewait sockets held by system simultaneously
  net.ipv4.tcp_max_tw_buckets = 5000
  # turn on TCP Fast Open on both client and server side
  net.ipv4.tcp_fastopen = 3
  # TCP receive buffer
  net.ipv4.tcp_rmem = 4096 87380 67108864
  # TCP write buffer
  net.ipv4.tcp_wmem = 4096 65536 67108864
  # turn on path MTU discovery
  net.ipv4.tcp_mtu_probing = 1

  # for high-latency network
  net.ipv4.tcp_congestion_control = hybla

  # for low-latency network, use cubic instead
  # net.ipv4.tcp_congestion_control = cubic
  ```

- 使配置生效

  ```sh
  sysctl -p /etc/sysctl.d/ss.conf
  ```


## 客户端

### 下载对应的客户端

- [Windows](https://github.com/shadowsocks/shadowsocks-windows/releases/download/4.0.4/Shadowsocks-4.0.4.zip)
- [OS X](https://github.com/shadowsocks/ShadowsocksX-NG/releases/download/v1.5.1/ShadowsocksX-NG.1.5.1.zip)
- [Android](https://github.com/shadowsocks/shadowsocks-android/releases/download/v4.1.8/shadowsocks-nightly-4.1.8.apk)

### 使用说明

- [Windows](https://github.com/shadowsocks/shadowsocks-windows/wiki/Shadowsocks-Windows-%E4%BD%BF%E7%94%A8%E8%AF%B4%E6%98%8E)

## 服务器作为网关

使用局域网中的一台服务器作为网关的时候，只需要其他要上网的计算器设置默认网关为该服务器即可。

### 准备

- [ ] 一台安装centos7的服务器（或者虚拟机）
- [ ] 设置内网固定ip（下面192.168.3.254为例）

### 安装shadowsocks-libev

```sh
yum install -y epel-release
yum install shadowsocks-libev
```

### 配置

- 添加配置文件 `/etc/shadowsocks/config.json`

  ```json
  {
       "server":"上面服务器的外网IP",
       "server_port":443,
       "password":"上面服务器配置的自定义密码",
       "method":"aes-256-cfb",
       "local_address": "0.0.0.0",
       "local_port":1080,
       "timeout":15
  }
  ```


- 添加服务 `/usr/lib/systemd/system/shadowsocks.service`

  ```sh
  [Unit]
  Description=Shadowsocks Redir  service
  After=network.target

  [Service]
  Type=simple
  User=nobody
  ExecStart=/usr/bin/ss-redir -c /etc/shadowsocks/config.json
  ExecReload=/bin/kill -HUP $MAINPID
  ExecStop=/bin/kill -s QUIT $MAINPID
  PrivateTmp=true
  KillMode=process
  Restart=on-failure
  RestartSec=5s

  [Install]
  WantedBy=multi-user.target
  ```


- 设置自启动

  ```sh
  systemctl enable shadowsocks && systemctl start shadowsocks
  ```


### 配置服务器作为网关

- 编辑 `/etc/sysctl.d/gw.conf` ，在最后添加

  ```sh
  net.ipv4.ip_forward=1
  ```

- 配置iptables，编辑`/etc/init.d/iptables-gfwlist`

  ```sh
  ipset -N gfwlist iphash
  iptables -t nat -A PREROUTING -p tcp -m set --match-set gfwlist dst -j REDIRECT --to-port 1080
  iptables -t nat -A PREROUTING -p icmp -m set --match-set gfwlist dst -j REDIRECT --to-port 1080
  ```

- 配置自动执行上面的脚本

  ```sh
  chmod +x /etc/init.d/iptables-gfwlist
  echo "/etc/init.d/iptables-gfwlist" >> /etc/rc.local
  chmod +x /etc/rc.local
  systemctl enable rc-local.service && systemctl start rc-local.service
  ```



- 配置ipset+dnsmasq

  ```sh
  # 安装ipset
  yum install -y ipset dnsmasq
  # 下载从gfwlist转为dnsmasq配置文件的脚本
  curl https://raw.githubusercontent.com/inspireso/gfwlist2dnsmasq/master/gfwlist2dnsmasq.sh -o /usr/bin/gfwlist2dnsmasq.sh
  chmod +x gfwlist2dnsmasq.sh
  # 生成翻墙域名列表，使用阿里的DNS解析gfwlist中域名
  gfwlist2dnsmasq.sh -d 223.5.5.5 -p 53 -s gfwlist -o /etc/dnsmasq.d/gfwlist.conf
  systemctl enable dnsmasq.service && systemctl start dnsmasq.service
  ```

- 配置完毕

  客户端可以指定

  默认网关：192.168.3.254

  DNS服务器: 192.168.3.254



### 优化网路参数

- 参见上面服务器的网路参数

