# kubernetes1.14集群部署



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
cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
net.ipv4.ip_forward = 1"
EOF
sysctl -p

#更改镜像为阿里镜像
mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.bak
curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo

#安装指定版本的docker-ce
yum install -y yum-utils device-mapper-persistent-data lvm2
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
yum install -y kubelet-1.14.3-0 kubeadm-1.14.3-0 kubectl-1.14.3-0
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
  "registry-mirrors": ["https://k4azpinc.mirror.aliyuncs.com"]
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
apiVersion: kubeadm.k8s.io/v1beta1
imageRepository: "registry.aliyuncs.com/google_containers"
kind: ClusterConfiguration
kubernetesVersion: v1.14.2
mode: ipvs
networking:
  dnsDomain: cluster.local
  podSubnet: 10.244.0.0/16
  serviceSubnet: 10.1.0.0/16
EOF

kubeadm init --config kubeadm.yaml

#生产环境: 使用flannel
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/62e44c867a2846fefb68bd5f178daf4da3095ccb/Documentation/kube-flannel.yml

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
kubectl drain --ignore-daemonsets kube-worker1
kubectl uncordon kube-worker1
```

