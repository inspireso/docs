# Microk8s 集群部署



## 环境

os: ubuntu20.4
kernel: Linux chia-master 5.8.0-53-generic #60~20.04.1-Ubuntu SMP Thu May 6 09:52:46 UTC 2021 x86_64 x86_64 x86_64 GNU/Linux

## 准备工作

```sh
#内核参数设置
cat <<EOF >>  /etc/security/limits.conf
root soft nofile 65535
root hard nofile 65535
* soft nofile 65535
* hard nofile 65535
EOF

cat <<EOF >>  /etc/sysctl.conf
net.ipv6.conf.all.disable_ipv6=1
net.ipv6.conf.default.disable_ipv6=1
net.ipv6.conf.lo.disable_ipv6=1

vm.swappiness=0
net.ipv4.neigh.default.gc_stale_time=120

# see details in https://help.aliyun.com/knowledge_detail/39428.html
#net.ipv4.conf.all.rp_filter=0
#net.ipv4.conf.default.rp_filter=0
#net.ipv4.conf.default.arp_announce=2
#net.ipv4.conf.lo.arp_announce=2
#net.ipv4.conf.all.arp_announce=2

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

#安装kubernetes组件
snap install microk8s --classic

cp /var/snap/microk8s/current/args/containerd-template.toml /var/snap/microk8s/current/args/containerd-template.toml.bak
sed -i 's|k8s.gcr.io|registry.aliyuncs.com/google_containers|' /var/snap/microk8s/current/args/containerd-template.toml

microk8s.stop
snap alias microk8s.kubectl kubectl
microk8s join 172.16.0.10:25000/147bd47cd7332f03a5586e65b5f8aeee

```



## master

```sh
microk8s enable dns
```

## node

```sh
# master
microk8s add-node

# node
microk8s join 172.16.0.10:25000/2c4032e7e23b3c8d93836cdaaca695e8
```







## FAQ

### ubuntu snap cannot communicate with server

```sh
sudo apt autoremove --purge snapd
sudo apt install snapd
sudo systemctl enable snapd

```



