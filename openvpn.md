# OpenVPN

## install

```sh
yum install -y epel-release
yum install -y openssl openssl-devel lzo lzo-devel pam pam-devel automake pkgconfig makecache
yum install -y openvpn
yum install -y easy-rsa

groupadd openvpn
useradd -g openvpn -M -s /sbin/nologin openvpn

mkdir /etc/openvpn/
cp -R /usr/share/easy-rsa/ /etc/openvpn/
cp /usr/share/doc/openvpn-2.4.9/sample/sample-config-files/server.conf /etc/openvpn/
cp -r /usr/share/doc/easy-rsa-3.0.3/vars.example /etc/openvpn/easy-rsa/3.0/vars

```

## 服务器端配置

### vi /etc/openvpn/server.conf

```sh
cat <<EOF > /etc/openvpn/server.conf
port 8443
proto udp
dev tun
ca /etc/openvpn/easy-rsa/3.0/pki/ca.crt
cert /etc/openvpn/easy-rsa/3.0/pki/issued/server.crt
key /etc/openvpn/easy-rsa/3.0/pki/private/server.key
dh /etc/openvpn/easy-rsa/3.0/pki/dh.pem
tls-auth /etc/openvpn/ta.key 0
server 10.8.0.0 255.255.255.0
ifconfig-pool-persist ipp.txt
push "route 172.16.2.0 255.255.255.0"
keepalive 10 120
cipher AES-256-CBC
comp-lzo
max-clients 50
user openvpn
group openvpn
persist-key
persist-tun
status openvpn-status.log
log-append  openvpn.log
verb 3
mute 20
explicit-exit-notify 1
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
cd /etc/openvpn/easy-rsa/3.0
./easyrsa init-pki

##创建CA证书
./easyrsa build-ca
pass phrase：openvpn
Common Name: OpenVPN CERTIFICATE AUTHORITY

## dh,ta
./easyrsa gen-dh
openvpn --genkey --secret ta.key
cp -r ta.key /etc/openvpn/

#server
./easyrsa gen-req server nopass
Common Name: openvpn

##签发证书,签约服务端证书
./easyrsa sign-req server server

```

### 配置防火墙

vi /etc/sysconfig/iptables, 添加如下规则

```sh
cat <<EOF >> /etc/rc.d/rc.local
iptables -A INPUT -p udp -m state --state NEW -m udp --dport 8443 -j ACCEPT
iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -j MASQUERADE
EOF
chmod +x /etc/rc.d/rc.local
systemctl enable rc-local.service && systemctl start rc-local.service
```

### 开启转发功能

```sh
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
sysctl -p
```

### 分配用户

```sh
cd /etc/openvpn/easy-rsa/3.0

## 生成客户端证书
./easyrsa build-client-full user1 nopass

## 复制客户端说需要的文件
mkdir -p /etc/openvpn/client
cp /etc/openvpn/easy-rsa/3.0/pki/ca.crt /etc/openvpn/client/
cp /etc/openvpn/ta.key /etc/openvpn/client/
cp /etc/openvpn/easy-rsa/3.0/pki/issued/user1.crt /etc/openvpn/client/
cp /etc/openvpn/easy-rsa/3.0/pki/private/user1.key /etc/openvpn/client/

```

### 启动

```sh
systemctl enable openvpn@server && systemctl restart openvpn@server
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
comp-lzo
verb 3
mute 20
tls-auth ta.key 1
keepalive 10 120
```

> 注意:  dev, proto,verb,mute配置项和服务器端相同



## FAQ

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

