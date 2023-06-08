# docker

## install

### centos

```sh
# step 1: 安装必要的一些系统工具
sudo yum install -y yum-utils device-mapper-persistent-data lvm2
# Step 2: 添加软件源信息
sudo yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
sudo sed -i 's/$releasever/7/' /etc/yum.repos.d/docker-ce.repo
# Step 3: 更新并安装 Docker-CE
sudo yum makecache fast
sudo yum -y install docker-ce
# Step 4: 开启Docker服务
sudo systemctl enable docker && sudo systemctl start docker
```

```sh
#安装 containerd
sudo apt -y install apt-transport-https ca-certificates curl software-properties-common

curl -fsSL http://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | sudo apt-key add -

cat <<EOF >/etc/apt/sources.list.d/docker.list
deb [arch=amd64] http://mirrors.aliyun.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable
EOF

# aliyun ecs
curl -fsSL http://mirrors.cloud.aliyuncs.com/docker-ce/linux/ubuntu/gpg | sudo apt-key add -

cat <<EOF >/etc/apt/sources.list.d/docker.list
deb [arch=amd64] http://mirrors.cloud.aliyuncs.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable
EOF

apt -y update && sudo apt -y install docker-ce
sudo systemctl enable docker && sudo systemctl start docker
```

### ubuntu

```sh
sudo apt -y install apt-transport-https ca-certificates curl software-properties-common

curl -fsSL http://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | sudo apt-key add -
cat <<EOF >/etc/apt/sources.list.d/docker.list
deb [arch=amd64] http://mirrors.aliyun.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable
EOF

apt -y update && sudo apt -y install docker-ce

sudo systemctl enable docker && sudo systemctl start docker

```

## [配置](https://docs.gitlab.com/omnibus/)

```sh
mkdir -p /etc/docker
cat <<EOF >  /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "5"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ],
  "selinux-enabled": false,
  "registry-mirrors": ["https://k4azpinc.mirror.aliyuncs.com"],
  "bip": "10.16.0.1/16"
}
EOF

cat <<EOF >>  /etc/sysctl.conf
net.ipv6.conf.all.disable_ipv6=1
net.ipv6.conf.default.disable_ipv6=1
net.ipv6.conf.lo.disable_ipv6=1
EOF
sysctl -p
```

## 重启

```sh
sudo systemctl restart docker
```

## docker-compose

```sh
sudo yum update

sudo yum install -y docker-compose-plugin

docker compose version
```

## LazyDocker

```sh
docker run --rm -it -v /var/run/docker.sock:/var/run/docker.sock \
-v ~/.config/lazydocker:/.config/jesseduffield/lazydocker \
lazyteam/lazydocker
```

## FAQ

```sh
&0: stdin
&1: stdout
&2: stderr
# 输出日志到指定文件,包括错误信息
docker logs xxx &> build.log

# 输出日志到指定文件,包括错误信息, 同时直接查看
docker logs xxx 2>&1 | tee xxx.log
```
