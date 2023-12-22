# centos

## 配置静态 ip

```sh
# 查看网卡
ip a

# 修改网卡ens192配置
sed -i 's/BOOTPROTO/#BOOTPROTO/' /etc/sysconfig/network-scripts/ifcfg-ens192

cat <<EOF >>  /etc/sysconfig/network-scripts/ifcfg-ens192
BOOTPROTO=static
IPADDR=xxx.xxx.xxx.xxx
NETMASK=255.255.255.0
GATEWAY=xxx.xxx.xxx.x
DNS1=223.5.5.5
DNS2=223.6.6.6
EOF

cat <<EOF >>  /etc/sysctl.conf
net.ipv6.conf.all.disable_ipv6=1
net.ipv6.conf.default.disable_ipv6=1
net.ipv6.conf.lo.disable_ipv6=1
EOF
sysctl -p
systemctl restart network
```

## 配置阿里云镜像

```sh
mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.bak
curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
yum makecache fast
```

## 安装 docker

```sh
sudo yum install -y yum-utils device-mapper-persistent-data lvm2
sudo yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
sudo yum makecache fast
sudo yum -y install docker-ce
sudo systemctl enable docker && sudo systemctl start docker

mkdir -p /etc/docker
cat <<EOF >  /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "5"
  },
  "registry-mirrors": ["https://k4azpinc.mirror.aliyuncs.com"],
  "bip": "10.16.0.1/16"
}
EOF
sudo systemctl restart docker
```
