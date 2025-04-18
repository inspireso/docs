



# OpenVPN

## install

```sh
yum install -y epel-release
yum install -y openssl openssl-devel lzo lzo-devel pam pam-devel automake pkgconfig makecache
yum install -y openvpn
yum install -y easy-rsa

#groupadd openvpn
#useradd -g openvpn -M -s /sbin/nologin openvpn

mkdir -p /etc/openvpn/
cp -R /usr/share/easy-rsa/ /etc/openvpn/
cp /usr/share/doc/openvpn/sample/sample-config-files/server.conf /etc/openvpn/
cp -r /usr/share/doc/easy-rsa/vars.example /etc/openvpn/easy-rsa/3/vars

```

## 服务器端配置

### /etc/openvpn/server/server.conf

```sh
cat <<EOF > /etc/openvpn/server/jumper.conf
port 8443
proto udp
dev tun
ca /etc/openvpn/easy-rsa/3/pki/ca.crt
cert /etc/openvpn/easy-rsa/3/pki/issued/server.crt
key /etc/openvpn/easy-rsa/3/pki/private/server.key
dh /etc/openvpn/easy-rsa/3/pki/dh.pem
tls-auth /etc/openvpn/easy-rsa/3/ta.key 0

server 10.8.0.0 255.255.255.0
ifconfig-pool-persist ipp.txt
push "route 172.16.0.0 255.255.255.0"

keepalive 10 120
cipher AES-256-CBC
#duplicate-cn
max-clients 100
user openvpn
group openvpn
persist-key
persist-tun
# txqueuelen 1000
# tun-mtu 1500
# txqueuelen 1000
# mssfix 1431
#mssfix 0
#tun-mtu 9000

status openvpn-status.log
log-append  openvpn.log
verb 3
explicit-exit-notify 1
script-security 2
up /etc/openvpn/server/up.sh
down /etc/openvpn/server/down.sh
EOF
```

```sh
cat <<EOF > /etc/openvpn/server/up.sh
#!/bin/sh

/usr/sbin/iptables -I FORWARD -o tun+ -j ACCEPT
/usr/sbin/iptables -t nat -A POSTROUTING -s 10.8.0.0/24  -j MASQUERADE
EOF
```
chmod +x /etc/openvpn/server/up.sh


```sh
cat <<EOF > /etc/openvpn/server/down.sh
#!/bin/sh

/usr/sbin/iptables -D FORWARD -o tun0 -j ACCEPT
/usr/sbin/iptables -t nat -D POSTROUTING -s 10.8.0.0/24  -j MASQUERADE
EOF
```

chmod +x /etc/openvpn/server/down.sh

### 日志归档

```sh
cat <<EOF >  /etc/logrotate.d/openvpn
/etc/openvpn/server/*.log
{
    size    50M
    rotate  0
    missingok
    nocreate
    #compress
    copytruncate
    nodelaycompress
    notifempty
}
EOF
```



### vi /etc/openvpn/easy-rsa/3.0/vars

修改第45、65、76、84-89、97、105、113、117、134、139、171、180、192行：

```sh
set_var EASYRSA                 "$PWD"
set_var EASYRSA_PKI             "$EASYRSA/pki"
set_var EASYRSA_DN     			"cn_only"
set_var EASYRSA_REQ_COUNTRY     "CN"
set_var EASYRSA_REQ_PROVINCE    "HONGKONG"
set_var EASYRSA_REQ_CITY        "HONGKONG"
set_var EASYRSA_REQ_ORG         "OpenVPN CERTIFICATE AUTHORITY"
set_var EASYRSA_REQ_EMAIL       "110@qq.com"
set_var EASYRSA_REQ_OU          "OpenVPN EASY CA"
set_var EASYRSA_KEY_SIZE        2048
set_var EASYRSA_ALGO            rsa
set_var EASYRSA_CA_EXPIRE       7000
set_var EASYRSA_CERT_EXPIRE     3650
set_var EASYRSA_NS_SUPPORT      "no"
set_var EASYRSA_NS_COMMENT      "OpenVPN CERTIFICATE AUTHORITY"
set_var EASYRSA_EXT_DIR 		"$EASYRSA/x509-types"
set_var EASYRSA_SSL_CONF        "$EASYRSA/openssl-1.0.cnf"
set_var EASYRSA_DIGEST          "sha256"
```

### 创建证书
```sh
cd /etc/openvpn/easy-rsa/3
./easyrsa init-pki

##创建CA证书
./easyrsa build-ca
pass phrase：openvpn
Common Name: OpenVPN CERTIFICATE AUTHORITY

## dh,ta
./easyrsa gen-dh
openvpn --genkey --secret ta.key

#server
./easyrsa gen-req server nopass
Common Name: openvpn

##签发证书,签约服务端证书
./easyrsa sign-req server server

```

### 开启转发功能

```sh
cat <<EOF >  /etc/security/limits.d/nofile.conf
*   soft    nproc         2067554
*   hard    nproc         2067554
EOF

cat <<EOF >  /etc/sysctl.conf
net.ipv6.conf.all.disable_ipv6=1
net.ipv6.conf.default.disable_ipv6=1
net.ipv6.conf.lo.disable_ipv6=1
net.ipv4.ip_forward=1

net.ipv4.tcp_window_scaling = 1
net.ipv4.ip_local_port_range = 1024 65535
net.core.netdev_max_backlog = 3240000
net.core.somaxconn = 65535

net.core.rmem_default=16777216
net.core.wmem_default=16777216
net.core.optmem_max=16777216
net.core.rmem_max=16777216
net.core.wmem_max=16777216
net.ipv4.tcp_mem=16777216 16777216 16777216
net.ipv4.tcp_wmem=4096 87380 16777216
net.ipv4.tcp_rmem=4096 87380 16777216

net.ipv4.tcp_syncookies = 0
net.ipv4.tcp_max_syn_backlog = 3240000
net.ipv4.tcp_max_tw_buckets = 1440000

# We would decrease the default values for tcp_keepalive_* params as follow:
net.ipv4.tcp_keepalive_time = 600  # default 7200
net.ipv4.tcp_keepalive_intvl = 10  # default 75
net.ipv4.tcp_keepalive_probes = 9  # default 9
net.ipv4.tcp_fin_timeout = 7

net.ipv4.tcp_syn_retries=3
net.ipv4.tcp_synack_retries=3
net.ipv4.tcp_orphan_retries=3
net.ipv4.tcp_retries2 = 8

# Avoid falling back to slow start after a connection goes idle.
net.ipv4.tcp_slow_start_after_idle = 0

# Disable caching of TCP congestion state
net.ipv4.tcp_no_metrics_save = 1
EOF

sysctl -p

sysctl -a | grep net.ipv4.conf.eth0.forwarding 
sysctl -a | grep net.ipv4.conf.eno1.forwarding
```

### 分配用户

```sh
cd /etc/openvpn/easy-rsa/3

## 生成客户端证书
./easyrsa build-client-full user1 nopass

## 复制客户端说需要的文件
mkdir -p /etc/openvpn/client
cp /etc/openvpn/easy-rsa/3/pki/ca.crt /etc/openvpn/client/
cp /etc/openvpn/easy-rsa/3/ta.key /etc/openvpn/client/
cp /etc/openvpn/easy-rsa/3/pki/issued/user1.crt /etc/openvpn/client/
cp /etc/openvpn/easy-rsa/3/pki/private/user1.key /etc/openvpn/client/

```

### 启动

```sh
systemctl enable openvpn-server@jumper && systemctl restart openvpn-server@jumper
```



## 客户端配置

```sh
client
dev tun
proto udp
remote <ip> 8443  
resolv-retry infinite
nobind
persist-key
persist-tun
verb 3
tls-auth ta.key 1
keepalive 10 120
```

> 注意:  dev, proto,verb,mute配置项和服务器端相同


### 日志归档

```sh
cat <<EOF >  /etc/logrotate.d/openvpn
/etc/openvpn/*.log
{
    size    50M
    rotate  0
    missingok
    nocreate
    #compress
    copytruncate
    nodelaycompress
    notifempty
}
EOF
```

## FAQ

### 加密私钥

```sh
openssl rsa -des -in xxx-nopass.key -out xxx.key

```



### 转发失败

```sh
iptables -nL -t filter
iptables -nL -t mangle
iptables -nL -t nat

# 检查所有网卡的forwarding=1
sysctl -a | grep net.ipv4.conf.eth0.forwarding 

# 跟踪 iptables
#centos6
modprobe ipt_LOG
sysctl net.netfilter.nf_log.2=ipt_LOG
#centos7
modprobe nf_log_ipv4
sysctl net.netfilter.nf_log.2=nf_log_ipv4

iptables -t raw -F
iptables -t raw -A PREROUTING -p icmp -j TRACE

#centos8
modprobe nf_log_ipv4
sysctl net.netfilter.nf_log.2=nf_log_ipv4

iptables -t raw -F
iptables -t raw -A PREROUTING -p tcp -j LOG --log-prefix "iptables:"


dmesg -C
dmesg -Lew
```

### sysctl

```sh
cat <<EOF >  /etc/security/limits.d/nofile.conf
*   soft    nproc         2067554
*   hard    nproc         2067554
EOF

cat <<EOF >>  /etc/sysctl.conf
net.ipv6.conf.all.disable_ipv6=1
net.ipv6.conf.default.disable_ipv6=1
net.ipv6.conf.lo.disable_ipv6=1
net.ipv4.ip_forward=1

net.ipv4.tcp_window_scaling = 1
net.ipv4.ip_local_port_range = 1024 65535
net.core.netdev_max_backlog = 3240000
net.core.somaxconn = 65535

net.core.rmem_default=16777216
net.core.wmem_default=16777216
net.core.optmem_max=16777216
net.core.rmem_max=16777216
net.core.wmem_max=16777216
net.ipv4.tcp_mem=16777216 16777216 16777216
net.ipv4.tcp_wmem=4096 87380 16777216
net.ipv4.tcp_rmem=4096 87380 16777216

net.ipv4.tcp_syncookies = 0
net.ipv4.tcp_max_syn_backlog = 3240000
net.ipv4.tcp_max_tw_buckets = 1440000

# We would decrease the default values for tcp_keepalive_* params as follow:
net.ipv4.tcp_keepalive_time = 600  # default 7200
net.ipv4.tcp_keepalive_intvl = 10  # default 75
net.ipv4.tcp_keepalive_probes = 9  # default 9
net.ipv4.tcp_fin_timeout = 7

net.ipv4.tcp_syn_retries=3
net.ipv4.tcp_synack_retries=3
net.ipv4.tcp_orphan_retries=3
net.ipv4.tcp_retries2 = 8

# Avoid falling back to slow start after a connection goes idle.
net.ipv4.tcp_slow_start_after_idle = 0

# Disable caching of TCP congestion state
net.ipv4.tcp_no_metrics_save = 1
EOF

sysctl -p


### 生成客户端证书错误

```sh
rm -rf /etc/openvpn/easy-rsa/3.0/pki/reqs/<client>.req
rm -rf /etc/openvpn/easy-rsa/3.0/pki/private/<client>.key
```

### 撤销证书

```sh
cd /etc/openvpn/easy-rsa/3.0

## 撤销命令revoke
./easyrsa revoke <client>

## 生成CRL文件(撤销证书的列表)
./easyrsa gen-crl

systemctl restart openvpn@server

```

