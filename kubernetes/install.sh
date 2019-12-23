#!/bin/bash

# 具体安装问题请参考官网
# https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/

## 使用方法
## export KUBE_VERSION=1.14.8
## master: sh install.sh master
## worker: sh install.sh


# 指定kubernetes版本
KUBENETES_VERSION=$(KUBE_VERSION:-1.14.8)
MASTER=$(echo $@ | grep "master")

# 在 master 节点和 worker 节点都要执行

#更改镜像为阿里镜像
mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.bak
curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo

#卸载防火墙
systemctl stop firewalld && systemctl disable firewalld && yum remove -y firewalld

# 关闭 swap
swapoff -a
yes | cp /etc/fstab /etc/fstab_bak
cat /etc/fstab_bak |grep -v swap > /etc/fstab

#内核参数设置
setenforce 0
sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
cat <<EOF >>  /etc/security/limits.conf
root soft nofile 1024000
root hard nofile 1024000
* soft nofile 1024000
* hard nofile 1024000
EOF

cat <<EOF >>  /etc/sysctl.conf
net.ipv6.conf.all.disable_ipv6=1
net.ipv6.conf.default.disable_ipv6=1
net.ipv6.conf.lo.disable_ipv6=1

vm.swappiness=0
net.ipv4.neigh.default.gc_stale_time=120

# see details in https://help.aliyun.com/knowledge_detail/39428.html
net.ipv4.conf.all.rp_filter=0
net.ipv4.conf.default.rp_filter=0
net.ipv4.conf.default.arp_announce=2
net.ipv4.conf.lo.arp_announce=2
net.ipv4.conf.all.arp_announce=2

# see details in https://help.aliyun.com/knowledge_detail/41334.html
net.ipv4.tcp_max_tw_buckets=5000
net.ipv4.tcp_syncookies=1
net.ipv4.tcp_max_syn_backlog=1024
net.ipv4.tcp_synack_retries=2
kernel.sysrq=1

kernel.pid_max=65535
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
net.bridge.bridge-nf-call-ip6tables = 1
EOF
sysctl -p

#加载ipvs相关模块
cat <<EOF > /etc/sysconfig/modules/ipvs.modules
#!/bin/sh
modprobe -- ip_vs
modprobe -- ip_vs_rr
modprobe -- ip_vs_wrr
modprobe -- ip_vs_sh
modprobe -- nf_conntrack_ipv4
EOF
chmod +x /etc/sysconfig/modules/ipvs.modules && sh /etc/sysconfig/modules/ipvs.modules && lsmod | grep -e ip_vs -e nf_conntrack_ipv4

#安装ipvs管理工具
yum install -y ipset ipvsadm

#安装指定版本的docker
# 卸载旧版本
yum remove -y docker \
    docker-client \
    docker-client-latest \
    docker-common \
    docker-latest \
    docker-latest-logrotate \
    docker-logrotate \
    docker-selinux \
    docker-engine-selinux \
    docker-engine

# 设置 yum repository
yum install -y yum-utils
yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
yum makecache fast

# 安装并启动 docker
yum install -y docker-ce-18.09.7 docker-ce-cli-18.09.7 containerd.io
mkdir -p /etc/docker
cat <<EOF >  /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
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
systemctl enable docker && systemctl start docker

#安装kubernetes组件
# 卸载旧版本
yum remove -y kubelet kubeadm kubectl

cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=http://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=http://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg
       http://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
yum install -y kubelet-${KUBENETES_VERSION}-0 kubeadm-${KUBENETES_VERSION}-0 kubectl-${KUBENETES_VERSION}-0
systemctl enable kubelet && systemctl start kubelet

# 安装 nfs-utils
# 必须先安装 nfs-utils 才能挂载 nfs 网络存储
yum install -y nfs-utils

#配置docker日志自动归档
cat <<EOF >  /etc/logrotate.d/docker
/var/lib/docker/containers/*/*.log
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
docker version
kubectl version
kubeadm version

cat <<EOF > ./kubeadm.yaml 
apiVersion: kubeadm.k8s.io/v1beta1
kind: InitConfiguration
bootstrapTokens:
- groups:
ttl: "0"
---
apiVersion: kubeproxy.config.k8s.io/v1alpha1
kind: KubeProxyConfiguration
mode: "ipvs"
---
apiVersion: kubeadm.k8s.io/v1beta1
imageRepository: "registry.aliyuncs.com/google_containers"
kind: ClusterConfiguration
kubernetesVersion: v${KUBENETES_VERSION}
networking:
dnsDomain: ${DNS_DOMAIN:-cluster.local}
podSubnet: ${PAD_SUBNET:-10.244.0.0/16}
serviceSubnet: ${SERVICE_SUBNET:-10.1.0.0/16}
EOF

if  test "$MASTER"; then
    kubeadm init --config kubeadm.yaml

    # 配置 kubectl
    rm -rf /root/.kube/
    mkdir /root/.kube/
    cp -i /etc/kubernetes/admin.conf /root/.kube/config

    curl -o kube-flannel.yml https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
    sed -i 's|"Type": "vxlan"|"Type": "vxlan","Directrouting": true|g' kube-flannel.yml
    kubectl apply -f kube-flannel.yml
fi
