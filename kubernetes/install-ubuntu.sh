#!/bin/bash

# 具体安装问题请参考官网
# https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/

## 使用方法
## export KUBE_VERSION=1.21.3
## master:sh install-ubuntu.sh master
## worker: sh install-ubuntu.sh
## nvidia: sh install-ubuntu.sh nvidia


# 指定kubernetes版本
KUBENETES_VERSION=$(KUBE_VERSION:-1.21.3)
MASTER=$(echo $@ | grep "master")
NVIDIA=$(echo $@ | grep "nvidia")

# 在 master 节点和 worker 节点都要执行


# 关闭 swap
swapoff -a
yes | cp /etc/fstab /etc/fstab_bak
cat /etc/fstab_bak |grep -v swap > /etc/fstab

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
sysctl --system

##加载相关模块
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

apt -y update && apt -y install containerd.io

mkdir -p /etc/containerd && containerd config default | tee /etc/containerd/config.toml
sed -i 's|k8s.gcr.io|registry.aliyuncs.com/google_containers|' /etc/containerd/config.toml
sed -i 's|"https://registry-1.docker.io"|"https://registry.cn-beijing.aliyuncs.com","https://registry.docker-cn.com","https://registry-1.docker.io"|' /etc/containerd/config.toml

systemctl enable containerd && systemctl restart containerd

cat <<EOF >  /etc/crictl.yaml
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
debug: true
EOF



#安装kubernetes组件
curl https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb https://mirrors.aliyun.com/kubernetes/apt/ kubernetes-xenial main
EOF

apt update && apt install -y kubelet=${KUBENETES_VERSION}-00 kubeadm=${KUBENETES_VERSION}-00 kubectl=${KUBENETES_VERSION}-00


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

# 打印版本
kubectl version
kubeadm version

cat <<EOF > ./kubeadm.yaml 
aapiVersion: kubeadm.k8s.io/v1beta2
kind: InitConfiguration
bootstrapTokens:
- groups:
  ttl: "0"
---
apiVersion: kubeadm.k8s.io/v1beta2
kind: ClusterConfiguration
kubernetesVersion: ${KUBENETES_VERSION}
imageRepository: "registry.aliyuncs.com/google_containers"
clusterName: kubernetes
controllerManager: {}
dns:
  type: CoreDNS
etcd:
  local:
    dataDir: /var/lib/etcd
networking:
  dnsDomain: ${DNS_DOMAIN:-cluster.local}
  podSubnet: ${PAD_SUBNET:-10.244.0.0/16}
  serviceSubnet: ${SERVICE_SUBNET:-10.1.0.0/16}
EOF

ctr -n k8s.io image pull registry.aliyuncs.com/google_containers/coredns:1.8.0
ctr -n k8s.io image tag registry.aliyuncs.com/google_containers/coredns:1.8.0 registry.aliyuncs.com/google_containers/coredns:v1.8.0

if  test "$MASTER"; then
  
  kubeadm init --config kubeadm.yaml --ignore-preflight-errors=ImagePull

  echo 'export KUBECONFIG=/etc/kubernetes/admin.conf' >> ~/.profile
  source ~/.profile

  curl -o kube-flannel.yml https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
  sed -i 's|"Type": "vxlan"|"Type": "vxlan","Directrouting": true|g' kube-flannel.yml
  kubectl apply -f kube-flannel.yml

  #生成 join 脚本
  cat <<"EOF" > ./k8s-join.sh
#!/bin/bash

EOF
  kubeadm token create --config kubeadm.yaml --print-join-command >> ./k8s-join.sh

  cat <<"EOF" >> ./k8s-join.sh
echo 'export KUBECONFIG=/etc/kubernetes/kubelet.conf' >> ~/.profile
source ~/.profile

EOF


fi

if  test "$NVIDIA"; then
  #安装驱动
  ubuntu-drivers devices
  ubuntu-drivers autoinstall

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
  systemctl restart docker
  docker pull registry.cn-hangzhou.aliyuncs.com/kube_containers/flannel:v0.14.0
  docker tag registry.cn-hangzhou.aliyuncs.com/kube_containers/flannel:v0.14.0 quay.io/coreos/flannel:v0.14.0
  
  echo 'docker run --rm -it --gpus all nvidia/cuda:11.0-base nvidia-smi'
fi
