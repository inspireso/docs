# docker

## install

```sh
# step 1: 安装必要的一些系统工具
sudo yum install -y yum-utils device-mapper-persistent-data lvm2
# Step 2: 添加软件源信息
sudo yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
# Step 3: 更新并安装 Docker-CE
sudo yum makecache fast
sudo yum -y install docker-ce
# Step 4: 开启Docker服务
sudo systemctl start docker
```

## [配置](https://docs.gitlab.com/omnibus/)

```sh
cat <<EOF > /etc/docker/daemon.json
{
  "bip": "10.16.0.1/24",
  "fixed-cidr": "10.16.0.0/24",
  "selinux-enabled": false,
  "registry-mirrors": ["https://w6gp6d0a.mirror.aliyuncs.com"]
}
EOF
```

## 重启

```sh
sudo systemctl restart docker
```

## docker-compose

```sh
curl -L "https://github.com/docker/compose/releases/download/1.22.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

