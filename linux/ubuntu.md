# Ubuntu

## apt

```sh

cp -vf /etc/apt/sources.list /etc/apt/sources.list.bak
sed -i 's|http://archive.ubuntu.com/ubuntu|http://mirrors.aliyun.com/ubuntu/|' /etc/apt/sources.list
sed -i 's|http://ports.ubuntu.com/ubuntu-ports|http://mirrors.aliyun.com/ubuntu/|' /etc/apt/sources.list
sed -i 's|http://cn.archive.ubuntu.com/ubuntu|http://mirrors.aliyun.com/ubuntu/|' /etc/apt/sources.list

apt-get clean all
apt-get update
```

## networking

```sh

sudo apt install libteam-utils

modinfo bonding | head -n 3
modprobe bonding
echo bonding > /etc/modules

lsmod | grep bond
sudo apt install ifenslave

sudo ip link add bond0 type bond mode round-robin
sudo ip link set eno1 master bond0
sudo ip link set eno2 master bond0



sudo apt update

sudo apt install libteam-utils -y

sudo nmcli con show
sudo nmcli con add type team con-name team0 ifname team0 config '{"runner":{"name": "roundrobin"}}'
sudo nmcli con mod team0 ipv4.address '172.16.0.36/22' ipv4.gateway '172.16.0.1'
sudo nmcli con modify team0 ipv4.dns "223.5.5.5 223.6.6.6"
sudo nmcli con mod team0 ipv4.method manual
sudo nmcli con add type team-slave con-name team0-port1 ifname eno1 master team0
sudo nmcli con add type team-slave con-name team0-port2 ifname eno2 master team0
sudo nmcli con show
```

### 配置静态ip
sudo vi /etc/netplan/50-cloud-init.yaml

```yaml
network:
    ethernets:
        enp5s0:
            dhcp4: no
            addresses: [172.16.6.223/23]
            optional: true
            gateway4: 172.16.6.125
            nameservers:
                    addresses: [223.5.5.5,223.6.6.6]
 
    version: 2

```

```sh
sudo netplan apply

```


## DNS

dns服务
- systemd-resolved: 
- systemd-networkd:

全局配置

/etc/systemd/resolved.conf

针对单个链接(conn)的静态配置文件

/etc/systemd/network/*.network

```sh
ls -la /etc/resolv.conf
#查看 dns 状态
systemd-resolve --status

#修改全局 dns
vi /etc/systemd/resolved.conf

systemctl restart systemd-resolved.service

```

## apt

```sh
dpkg-scanpackages -m . > Packages
apt-ftparchive release . > Release

```


