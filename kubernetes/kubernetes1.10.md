# kubernetes1.7集群部署



## 环境

os: CentOS Linux release 7.4.1708 (Core)
kernel: 3.10.0-693.el7.x86_64 #1 SMP Tue Aug 22 21:09:27 UTC 2017 x86_64 x86_64 x86_64 GNU/Linux

## 准备工作

```sh
#卸载防火墙
systemctl stop firewalld && sudo systemctl disable firewalld && yum remove -y firewalld

#内核参数设置
setenforce 0
sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
echo "net.bridge.bridge-nf-call-ip6tables = 1" >> /etc/sysctl.conf
echo "net.bridge.bridge-nf-call-iptables = 1" >> /etc/sysctl.conf
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
sysctl -p

#加载overlay模块
modprobe overlay
lsmod | grep overlay
echo "overlay" > /etc/modules-load.d/overlay.conf

#更改镜像为阿里镜像
mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.bak
curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo

#添加kubernetes镜像
$ cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
[docker]
name=Docker
baseurl=https://mirrors.aliyun.com/docker-engine/yum/repo/main/centos/7/
enabled=1
gpgcheck=0
repo_gpgcheck=0
EOF

#安装指定版本的docker-1.12.6
yum install -y yum-versionlock docker-engine-selinux-1.12.6-1.el7.centos.noarch docker-engine-1.12.6-1.el7.centos.x86_64 
yum versionlock add docker-engine-selinux docker-engine

#安装kubernetes组件
yum install -y  kubelet kubectl kubeadm
#yum versionlock add kubelet kubectl

sed -i "s/cgroup-driver=systemd/cgroup-driver=cgroupfs/g" /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

# 配置镜像加速
mkdir /etc/docker
tee /etc/docker/daemon.json <<-'EOF'
{
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ],
  "selinux-enabled": false,
  "registry-mirrors": ["https://w6gp6d0a.mirror.aliyuncs.com"]
}
EOF
systemctl enable docker && systemctl restart docker
#systemctl enable kubelet && systemctl restart kubelet
docker info

#配置docker日志自动归档
tee /etc/logrotate.d/docker <<-'EOF'
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
cat <<EOF > config.yaml 
apiVersion: kubeadm.k8s.io/v1alpha1
kind: MasterConfiguration
etcd:
  image: "registry.cn-hangzhou.aliyuncs.com/kube_containers/etcd-amd64:3.1.10"
networking:
  podSubnet: 10.1.0.0/16
kubernetesVersion: 1.10.2
imageRepository: "registry.cn-hangzhou.aliyuncs.com/kube_containers"
tokenTTL: "0"
featureGates:
  CoreDNS: true
EOF

kubeadm init --config config.yaml

#生产环境: 使用calico
kubectl apply -f https://raw.githubusercontent.com/inspireso/docker/kubernetes/kubernetes/addon/calico/calico1.7.yaml

```

### dashboard

```sh
#准备证书（最后一个需要输入master的主机名称）
mkdir dashboard-certs
openssl req -newkey rsa:4096 -nodes -sha256 -keyout dashboard.key -x509 -days 365 -out dashboard.crt
kubectl  -n kube-system create secret generic kubernetes-dashboard-certs --from-file=./dashboard-certs

#安装dashboard
kubectl apply -f https://raw.githubusercontent.com/inspireso/docker/kubernetes/kubernetes/google_containers/kubernetes-dashboard1.8.yaml

#添加管理员
$ kubectl apply -f https://raw.githubusercontent.com/inspireso/docker/kubernetes/kubernetes/google_containers/kubernetes-dashboard-admin.rbac.yaml

#查找token
$ kubectl -n kube-system get secret | grep kubernetes-dashboard-admin
$ kubectl describe -n kube-system secret/kubernetes-dashboard-admin-token-XXX
```



## node

```sh
yum install -y nfs-utils

kubeadm join --token=xxxxxxxxxxxxx xxx.xxx.xxx.xxx
```

## 监控

### heapster

```sh
# influxdb
$ kubectl apply -f https://raw.githubusercontent.com/inspireso/docker/kubernetes/kubernetes/heapster/influxdb-deployment.yaml
# heapster
$ kubectl apply -f https://raw.githubusercontent.com/inspireso/docker/kubernetes/kubernetes/heapster/heapster-deployment.yaml.yaml
```

### prometheus

```sh
#setup
kubectl apply -f https://raw.githubusercontent.com/inspireso/docker/kubernetes/kubernetes/prometheus/setup.yaml

#prometheus
kubectl apply -f https://raw.githubusercontent.com/inspireso/docker/kubernetes/kubernetes/prometheus/prometheus.yaml

#kube-state-metrics
kubectl apply -f https://raw.githubusercontent.com/inspireso/docker/kubernetes/kubernetes/prometheus/kube-state-metrics.yaml

```

## ingress

```sh
#初始化配置
kubectl apply -f https://raw.githubusercontent.com/inspireso/docker/kubernetes/kubernetes/google_containers/ingress-nginx-config-map.yaml
#部署nginx-ingress
kubectl apply -f https://raw.githubusercontent.com/inspireso/docker/kubernetes/kubernetes/google_containers/ingress-nginx.yaml

```

## helm

```sh
$ curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get > get_helm.sh
$ chmod 700 get_helm.sh
$ ./get_helm.sh

helm init --tiller-image=registry.cn-hangzhou.aliyuncs.com/kube_containers/tiller:latest --stable-repo-url https://kubernetes.oss-cn-hangzhou.aliyuncs.com/charts

kubectl create serviceaccount --namespace kube-system tiller
kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
kubectl patch deploy --namespace kube-system tiller-deploy -p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}'
```



## FAQ

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
$ kubectl taint nodes kuben0 dedicated=master:NoSchedule
```



### reset
```sh
$ kubeadm reset
$ rm /var/etcd/ -rf
$ docker rm -f $(docker ps -a -q)
```

### 升级linux内核

```sh
$ rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org \
&& rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-2.el7.elrepo.noarch.rpm \
&& yum clean all \
&& yum --enablerepo=elrepo-kernel install kernel-ml \
&& grub2-set-default 0

# 查看
$ grub2-editenv list

#查看启动项
$ awk -F\' '$1=="menuentry " {print i++ " : " $2}' /etc/grub2.cfg

#查看已经安装的内核
$ rpm -qa | grep kernel
```

### OverlayFS

```sh
modprobe overlay
lsmod | grep overlay
echo "overlay" > /etc/modules-load.d/overlay.conf

$ sed -i -e '/^ExecStart=/ s/$/ --storage-driver=overlay/' /usr/lib/systemd/system/docker.service \
rm /var/lib/docker -rf
```

### 维护

```sh
kubectl cordon kuben6
kubectl drain --ignore-daemonsets kuben6
kubectl uncordon kuben6
```

