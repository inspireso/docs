# kubernetes1.20集群部署



## 环境

os: Ubuntu 20.04.2 LTS
kernel: 5.8.0-53-generic #60~20.04.1-Ubuntu SMP Thu May 6 09:52:46 UTC 2021 x86_64 x86_64 x86_64 GNU/Linux

## 准备工作

```sh

cat <<"EOF" > /etc/rc.local
#!/bin/sh -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "exit 0" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing.

/etc/init.d/procps restart
swapoff -a
exit 0
EOF
chown root:root /etc/rc.local
chmod 755 /etc/rc.local

cat <<"EOF" > /lib/systemd/system/rc-local.service
#  SPDX-License-Identifier: LGPL-2.1+
#
#  This file is part of systemd.
#
#  systemd is free software; you can redistribute it and/or modify it
#  under the terms of the GNU Lesser General Public License as published by
#  the Free Software Foundation; either version 2.1 of the License, or
#  (at your option) any later version.

# This unit gets pulled automatically into multi-user.target by
# systemd-rc-local-generator if /etc/rc.local is executable.
[Unit]
Description=/etc/rc.local Compatibility
Documentation=man:systemd-rc-local-generator(8)
ConditionFileIsExecutable=/etc/rc.local
After=network.target

[Service]
Type=forking
ExecStart=/etc/rc.local start
TimeoutSec=0
RemainAfterExit=yes
GuessMainPID=no

[Install]
WantedBy=multi-user.target
Alias=rc-local.service
EOF
systemctl enable rc-local.service
systemctl daemon-reload && systemctl restart rc-local.service
systemctl status rc-local.service

#内核参数设置
setenforce 0
cat <<EOF >  /etc/security/limits.d/nofile.conf
root soft nofile 65535
root hard nofile 65535
* soft nofile 65535
* hard nofile 65535
EOF

cat <<EOF >  /etc/sysctl.d/99-net.conf
net.ipv6.conf.all.disable_ipv6=1
net.ipv6.conf.default.disable_ipv6=1
net.ipv6.conf.lo.disable_ipv6=1

vm.swappiness=0
EOF


cat <<EOF >  /etc/sysctl.d/99-k8s.conf
kernel.softlockup_all_cpu_backtrace=1
kernel.softlockup_panic=1
vm.max_map_count=262144

net.core.wmem_max=16777216
net.core.somaxconn=32768
net.core.netdev_max_backlog=16384
net.core.rmem_max=16777216

fs.inotify.max_user_watches=524288
fs.file-max=2097152
fs.inotify.max_user_instances=8192
fs.inotify.max_queued_events=16384
fs.may_detach_mounts=1

net.ipv4.tcp_slow_start_after_idle=0
net.ipv4.tcp_wmem=4096 12582912 16777216
net.ipv4.ip_forward=1
net.ipv4.tcp_max_syn_backlog=8096
net.ipv4.tcp_rmem=4096 12582912 16777216
net.bridge.bridge-nf-call-iptables=1
EOF
sudo sysctl --system

#加载相关模块
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter

#安装 containerd
sudo apt -y install apt-transport-https ca-certificates curl software-properties-common

curl -fsSL http://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | sudo apt-key add -
cat <<EOF >/etc/apt/sources.list.d/docker.list
deb [arch=amd64] http://mirrors.aliyun.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable
EOF

sudo apt -y update && sudo apt -y install containerd.io

sudo mkdir -p /etc/containerd && containerd config default | sudo tee /etc/containerd/config.toml
sed -i 's|k8s.gcr.io|registry.aliyuncs.com/google_containers|' /etc/containerd/config.toml
sed -i 's|"https://registry-1.docker.io"|"https://registry.cn-beijing.aliyuncs.com","https://registry.docker-cn.com","https://registry-1.docker.io"|' /etc/containerd/config.toml

systemctl enable containerd && systemctl restart containerd

#配置docker日志自动归档
cat <<EOF >  /etc/logrotate.d/containerd
/var/log/pods/*/*/*.log
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

cat <<EOF >  /etc/crictl.yaml
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
debug: true
EOF

#安装kubeadm kubectl kubelet
curl https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb https://mirrors.aliyun.com/kubernetes/apt/ kubernetes-xenial main
EOF

sudo apt-get update && apt-get install -y kubelet=1.21.3-00 kubeadm=1.21.3-00 kubectl=1.21.3-00

sudo swapoff -a

```



## master

```sh
cat <<EOF > kubeadm.yaml 
apiVersion: kubeadm.k8s.io/v1beta2
kind: InitConfiguration
bootstrapTokens:
- groups:
  ttl: "0"
---
apiVersion: kubeadm.k8s.io/v1beta2
kind: ClusterConfiguration
kubernetesVersion: 1.21.3
imageRepository: "registry.aliyuncs.com/google_containers"
clusterName: kubernetes
controllerManager: {}
dns:
  type: CoreDNS
etcd:
  local:
    dataDir: /var/lib/etcd
networking:
  dnsDomain: cluster.local
  podSubnet: 10.244.0.0/16
  serviceSubnet: 10.1.0.0/16

EOF

ctr -n k8s.io image pull registry.aliyuncs.com/google_containers/coredns:1.8.0
ctr -n k8s.io image tag registry.aliyuncs.com/google_containers/coredns:1.8.0 registry.aliyuncs.com/google_containers/coredns:v1.8.0
ctr -n k8s.io image ls

kubeadm init --config kubeadm.yaml --ignore-preflight-errors=ImagePull

echo 'export KUBECONFIG=/etc/kubernetes/admin.conf' >> ~/.profile
source ~/.profile

#生产环境: 使用flannel
curl -o kube-flannel.yml https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

#启用flannel的gw模式;编辑下载的kube-flannel.yml 文件，找到net-conf.json:配置，修改如下：
  net-conf.json: |
    {
      "Network": "10.244.0.0/16",
      "Backend": {
        "Type": "vxlan"
      }
    }
修改为：
  net-conf.json: |
    {
      "Network": "10.244.0.0/16",
      "Backend": {
        "Type": "vxlan",
        "Directrouting": true
      }
    }

kubectl apply -f kube-flannel.yml


```



## node

```
#master
kubeadm token create --config kubeadm.yaml --print-join-command

#node
ctr -n k8s.io image pull registry.cn-hangzhou.aliyuncs.com/kube_containers/flannel:v0.14.0
ctr -n k8s.io image tag registry.cn-hangzhou.aliyuncs.com/kube_containers/flannel:v0.14.0 quay.io/coreos/flannel:v0.14.0

ctr -n k8s.io image pull quay.io/coreos/flannel:v0.14.0

kubeadm join --token=xxxxxxxxxxxxx xxx.xxx.xxx.xxx

echo 'export KUBECONFIG=/etc/kubernetes/kubelet.conf' >> ~/.profile
source ~/.profile
```



## gpu-node

```
#安装驱动
ubuntu-drivers devices
ubuntu-drivers autoinstall

#containerd.io
vi /etc/containerd/config.toml
在[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]后面插入一下内容

            SystemdCgroup = true
          [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.nvidia]
            privileged_without_host_devices = false
            runtime_engine = ""
            runtime_root = ""
            runtime_type = "io.containerd.runc.v1"
            [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.nvidia.options]
              BinaryName = "/usr/bin/nvidia-container-runtime"
              SystemdCgroup = true


distribution=$(. /etc/os-release;echo $ID$VERSION_ID) \
    && curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add - \
    && curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list

sudo apt-get update \
    && sudo apt-get install -y nvidia-container-runtime

sudo systemctl restart containerd
    
sudo ctr image pull docker.io/nvidia/cuda:11.0-base
sudo ctr run --rm -t --gpus 0 docker.io/nvidia/cuda:11.0-base cuda-11.0-base nvidia-smi

# docker-ce
apt remove -y containerd.io
apt install -y docker-ce

distribution=$(. /etc/os-release;echo $ID$VERSION_ID) \
   && curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add - \
   && curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list

apt update && apt install -y nvidia-docker2

cat <<"EOF" > /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-opts": {
    "max-size": "100m",
    "max-file": "5"
  },
  "registry-mirrors": ["https://2e854usg.mirror.aliyuncs.com"],
  "bip": "10.16.0.1/16",
  "default-runtime": "nvidia",
  "runtimes": {
     "nvidia": {
        "path": "nvidia-container-runtime",
        "runtimeArgs": []
      }
    }
}
EOF

sudo systemctl restart docker

sudo docker run --rm -it --gpus all nvidia/cuda:11.0-base nvidia-smi
```



## FAQ

### 获取kubeadm join 命令

```sh
#master
kubeadm token create --config kubeadm.yaml --print-join-command

```

### master node->work load

```sh
$ kubectl taint nodes --all dedicated-
$ kubectl taint nodes kuben1 kube
```

### node ->  unschedulable

```sh
$ kubectl taint nodes kuben-master dedicated=master:NoSchedule
```

### reset
```sh
kubeadm reset
source ~/.profile && ctr task rm -f $(ctr task ls -q ) && ctr c delete $(ctr c ls -q )
rm /var/etcd/ -rf
rm /var/lib/docker -rf
rm /var/lib/dockershim/ -rf
rm /var/lib/containerd -rf
```


### 维护

```sh
kubectl cordon kube-worker1
kubectl drain --ignore-daemonsets --delete-local-data  kube-worker1
kubectl uncordon kube-worker1
```



### 更新证书

```sh

kubeadm certs check-expiration
kubeadm certs renew all
kubeadm init phase kubeconfig all
```

