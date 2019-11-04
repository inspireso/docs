# kubernetes1.14集群部署



## 环境

os: CentOS Linux release 7.4.1708 (Core)
kernel: 3.10.0-693.el7.x86_64 #1 SMP Tue Aug 22 21:09:27 UTC 2017 x86_64 x86_64 x86_64 GNU/Linux

## 准备工作

```sh
#更改镜像为阿里镜像
mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.bak
curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo

#卸载防火墙
systemctl stop firewalld && sudo systemctl disable firewalld && yum remove -y firewalld

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
EOF
sysctl -p

# 加载ipvs相关模块
modprobe -- ip_vs
modprobe -- ip_vs_rr
modprobe -- ip_vs_wrr
modprobe -- ip_vs_sh
modprobe -- nf_conntrack_ipv4
#检查是否加载成功
lsmod | grep -e ip_vs -e nf_conntrack_ipv4
## 配置启动加载ipvs依赖的模块
cat <<EOF > /etc/sysconfig/modules/ipvs.modules
#!/bin/sh
modprobe -- ip_vs
modprobe -- ip_vs_rr
modprobe -- ip_vs_wrr
modprobe -- ip_vs_sh
modprobe -- nf_conntrack_ipv4
EOF
echo "/etc/sysconfig/modules/ipvs.modules" >> /etc/rc.local
chmod +x /etc/rc.local && systemctl enable rc-local.service

chmod +x /etc/sysconfig/modules/ipvs.modules && bash /etc/sysconfig/modules/ipvs.modules && lsmod | grep -e ip_vs -e nf_conntrack_ipv4

#安装ipvs管理工具
yum install -y ipset ipvsadm

#安装指定版本的docker-ce
yum install -y yum-utils
yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
yum makecache fast
yum -y install docker-ce-18.09.6-3.el7
systemctl enable docker && systemctl start docker

#安装kubernetes组件
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
yum makecache fast
yum install -y kubelet-1.14.8-0 kubeadm-1.14.8-0 kubectl-1.14.8-0
systemctl enable kubelet && systemctl start kubelet

# 配置docker
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
systemctl enable docker && systemctl restart docker
#systemctl enable kubelet && systemctl restart kubelet
docker info

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
```



## master

```sh
cat <<EOF > kubeadm.yaml 
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
kubernetesVersion: v1.14.8
networking:
  dnsDomain: cluster.local
  podSubnet: 10.244.0.0/16
  serviceSubnet: 10.1.0.0/16
EOF

kubeadm init --config kubeadm.yaml

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

### dashboard

```sh
#准备证书（最后一个需要输入master的主机名称）
mkdir dashboard-certs
openssl req -newkey rsa:4096 -nodes -sha256 -keyout dashboard.key -x509 -days 365 -out dashboard.crt
kubectl  -n kube-system create secret generic kubernetes-dashboard-certs --from-file=./dashboard-certs

#安装dashboard
kubectl apply -f https://raw.githubusercontent.com/inspireso/docker/kubernetes-1.14/kubernetes/google_containers/kubernetes-dashboard1.10.yaml

#添加管理员
kubectl apply -f https://raw.githubusercontent.com/inspireso/docker/kubernetes/kubernetes/google_containers/kubernetes-dashboard-admin.rbac.yaml

#查找token
kubectl describe secrets -n kube-system $(kubectl -n kube-system get secret | awk '/dashboard-admin/{print $1}')

kubectl -n kube-system get secret | grep kubernetes-dashboard-admin
kubectl describe -n kube-system secret/kubernetes-dashboard-admin-token-XXX
```



## node

```sh
#master
kubeadm token create --config kubeadm.yaml --print-join-command

#node
docker pull registry.cn-hangzhou.aliyuncs.com/ates-k8s/flannel:v0.11.0-amd64
yum install -y nfs-utils

kubeadm join --token=xxxxxxxxxxxxx xxx.xxx.xxx.xxx
```

## ingress

```sh
#部署nginx-ingress
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.24.1/deploy/mandatory.yaml
#部署nginx-ingress-service
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.24.1/deploy/provider/baremetal/service-nodeport.yaml

```



## FAQ

### 获取kubeadm join 命令

```sh
#master
kubeadm token create --config kubeadm.yaml --print-join-command

```

### networks have same bridge namer

 ```sh
 ip link del docker0 && rm -rf /var/docker/network/* && mkdir -p /var/docker/network/files
 systemctl start docker
 # delete all containers
 docker rm -f $(docker ps -a -q)
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
$ kubeadm reset
$ rm /var/etcd/ -rf
$ docker rm -f $(docker ps -a -q)
```


### 维护

```sh
kubectl cordon kube-worker1
kubectl drain --ignore-daemonsets --delete-local-data  kube-worker1
kubectl uncordon kube-worker1
```

