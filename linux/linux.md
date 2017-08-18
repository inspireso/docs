## tar

```sh
#打包并压缩gzip
tar -czvf 文件名.tar.gz 目录1 [目录1 目录2 文件1 文件2]
#解压到根目录
tar -xzf tengine-2.2.0-centos7.tar.gz -C /

#大宝并压缩成bzip2
tar -cjf 文件名.tar.bz2 *.jpg 
#解压
tar -xjf 文件名.tar.bz2 
```



## 网卡添加路由

```sh
ip ru add from ip1 table 200
ip ro add default via gw_ip dev eth0(interface) table 200

ip ru add from ip2 table 201
ip ro add default via gw_ip dev eth2(interface) table 201
```

## 查看打开的文件数

```sh
# 查看整个系统打开的文件数
cat /proc/sys/fs/file-nr
# 查看某个进程pid打开的文件数
ls /proc/pid/fd | wc -l
#或者，需要安装yum install -y lsof
lsof -p pid | wc -l 
```

## 查看打开的文件个数限制

```sh
cat /proc/pid/limits
```

## 修改最大连接数

```sh
vi /etc/security/limits.conf

root soft nofile 65535
root hard nofile 65535
* soft nofile 65535
* hard nofile 65535
```

## ssh

```sh
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
restorecon -r -vv ~/.ssh/authorized_keys
```

##  selinux

```sh
永久方法 – 需要重启服务器
修改/etc/selinux/config文件中设置SELINUX=disabled ，然后重启服务器。
#临时方法 – 设置系统参数
setenforce 0
#setenforce 1 设置SELinux 成为enforcing模式
#setenforce 0 设置SELinux 成为permissive模式
```

## dnsmasq

### 安装

```sh
yum install -y dnsmasq
systemctl enable dnsmasq && systemctl start dnsmasq
```



### 配置（/etc/dnsmasq.conf ） 

```properties
resolv-file=/etc/dnsmasq.resolv.conf 
addn-hosts=/etc/dnsmasq.hosts 
```

### 注意

- dns主机的hosts最好都清空只保留127.0.0.1
- 做好dns的备机
- 机器hosts优先级是最高的（相对内部dns）
- redhat的dns主机启动/usr/local/sbin/dnsmasq -h 则不会加载本地hosts。