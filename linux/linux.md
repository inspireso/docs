# linux 

## 修改为阿里镜像库

```sh
mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.bak
curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
curl -o /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
```

## 网络

### 设置严格模式

```sh
echo 'net.ipv4.conf.all.rp_filter = 2' >> /etc/sysctl.conf
echo 'net.ipv4.conf.all.arp_ignore = 1' >> /etc/sysctl.conf
sysctl -p
```

### 网卡添加路由

```sh
ip ru add from ip1 table 200
ip ro add default via gw_ip dev eth0(interface) table 200

ip ru add from ip2 table 201
ip ro add default via gw_ip dev eth2(interface) table 201
```

### 查看打开的文件数

```sh
# 查看整个系统打开的文件数
cat /proc/sys/fs/file-nr
1376    0       791284
已分配文件句柄的数目 / 分配了但没有使用的句柄数目 / 文件句柄的最大数目

# 查看某个进程pid打开的文件数
ls /proc/pid/fd | wc -l

# 查看统计信息
ss -s
cat /proc/net/sockstat | grep sockets | awk '{print $3}'
cat /proc/net/sockstat

ss -axp | awk '{print $9}' |awk '{split($0,a,",");print a[2]}' | awk '{split($0,a,"=");print a[2]}'|sort|uniq -c |sort|less

#统计
lsof | wc -l 
lsof -n |awk '{print $2}'|sort|uniq -c |sort -nr|more 

#或者，需要安装yum install -y lsof
lsof -p pid | wc -l 

```

### 查看容器打开的文件数

```sh
ps auxwwf > ps.txt

#通过PID查找对应的容器ID

docker ps | grep <容器ID前缀>
```



### 查看打开的文件个数限制

```sh
cat /proc/pid/limits
```

### 修改最大连接数

```sh
vi /etc/security/limits.conf

root soft nofile 65535
root hard nofile 65535
* soft nofile 65535
* hard nofile 65535

ulimit -n 65535

#设置运行中的进程
prlimit  -p pid --nofile=65535

#systemd管理的进程
/etc/systemd/system/xxx.service.d/override.conf
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity
```

### nmcli：管理工具

#### 查看nmcli使用说明

```sh
[root@rehl7 ~]# nmcli help
Usage: nmcli [OPTIONS] OBJECT { COMMAND | help }

OPTIONS
  -t[erse]                                   简洁输出
  -p[retty]                                  美化输出
  -m[ode] tabular|multiline                  输出模式
  -f[ields] <field1,field2,...>|all|common   指定字段输出
  -e[scape] yes|no                           指定分隔符
  -n[ocheck]                                 不检测版本
  -a[sk]                                     询问缺失参数
  -w[ait] <seconds>                          设置超时等待完成操作
  -v[ersion]                                 显示版本
  -h[elp]                                    获得帮助

OBJECT
  g[eneral]       常规管理
  n[etworking]    全面的网络控制
  r[adio]         无线网络管理
  c[onnection]    网络连接管理
  d[evice]        网络设备管理
  a[gent]         网络代理管理
```

#### 常用命令

```sh
# 查看基本的网络开启状况
nmcli general status
# 启用网络设备接口
nmcli dev connect <ifname>
# 停止网络设备接口
nmcli dev disconnect <ifname>
# 查看物理网卡信息
nmcli dev
# 给网卡设备设置静态IP,根据你需要的配置更改 NAME_OF_CONNECTION,IP_ADDRESS, GW_ADDRESS 参数（如果不需要网关的话可以省略最后一部分)
nmcli con add type ethernet con-name NAME_OF_CONNECTION ifname interface-name ip4 IP_ADDRESS gw4 GW_ADDRESS
# 查看网卡连接信息
nmcli con show
# 删除有线连接
nmcli con del UUID
# 创建新的连接
nmcli con add type ethernet con-name eno2 ifname eno2 
# 使用nmcli命令操作，创建team接口team0，同时设置teaming模式为roundrobin
nmcli con add type team con-name team0 ifname team0 config '{"runner":{"name": "roundrobin"}}'
#给接口team0设置ip地址
nmcli con modify team0 ipv4.address '192.168.8.159/24' ipv4.gateway '192.168.8.254'
#设置为手动模式
nmcli con modify team0 ipv4.method manual

#设置DNS
nmcli con modify team0 ipv4.dns "114.114.114.114 8.8.8.8"

#给接口eno2添加ip地址
nmcli con mod eno2 +ipv4.address '192.168.8.159/24'
# 重新加载配置并生效
nmcli con reload && nmcli con up eno2
```

#### 配置teamd

```sh
sudo apt install libteam-utils

# 使用nmcli命令操作，创建team接口team0，同时设置teaming模式为roundrobin
nmcli connection add type team con-name CNAME ifname INAME [config JSON]
#CNAME 指代连接的名称，INAME 是接口名称，JSON (JavaScript Object Notation) 指定所使用的处理器(runner)。JSON 语法格式：'{"runner":{"name":"METHOD"}}'
#METHOD 是以下的其中一个：broadcast、activebackup、roundrobin、loadbalance 或者 lacp。
#broadcast 传输来自所有端口的包。
#roundrobin 以轮循的方式传输所有端口的包。
#activebakup 这是一个故障迁移程序，监控链接更改并选择活动的端口进行传输。
#loadbalance 监控流量并使用哈希函数以尝试在选择传输端口的时候达到完美均衡。
#lacp 实施802.3ad 链路聚合协议，可以使用与 loadbalance 运行程序相同的传输端口选择的可能性。

#例子
nmcli con add type team con-name team0 ifname team0 config '{"runner":{"name": "roundrobin"}}'
#给接口team0设置ip地址
nmcli con mod team0 ipv4.address '192.168.8.159/24' ipv4.gateway '192.168.8.254'
#设置为手动模式
nmcli con mod team0 ipv4.method manual
#将两张物理网卡加入到team中
nmcli con add type team-slave ifname eno1 master team0
nmcli con add type team-slave con-name team0-port2 ifname eno2 master team0
nmcli con add type team-slave con-name team0-port3 ifname eno3 master team0
nmcli con show
nmcli con reload && sudo nmcli con up team0
# nmcli con up team0
# 查看team0的状态就出现了
teamdctl team0 st 
```

- 配置bond

```sh
modinfo bonding | head -n 3
modprobe bonding
  echo bonding > /etc/modules

lsmod | grep bond
sudo apt install ifenslave

# 使用nmcli命令操作，创建team接口team0，同时设置teaming模式为roundrobin
nmcli connection add type team con-name CNAME ifname INAME [config JSON]
#CNAME 指代连接的名称，INAME 是接口名称，JSON (JavaScript Object Notation) 指定所使用的处理器(runner)。JSON 语法格式：'{"runner":{"name":"METHOD"}}'
#METHOD 是以下的其中一个：broadcast、activebackup、roundrobin、loadbalance 或者 lacp。
#Mode=0(balance-rr) 表示负载分担round-robin，和交换机的聚合强制不协商的方式配合。
#Mode=1(active-backup) 表示主备模式，只有一块网卡是active,另外一块是备的standby，这时如果交换机配的是捆绑，将不能正常工作，因为交换机往两块网卡发包，有一半包是丢弃的。
#Mode=2(balance-xor) 表示XOR Hash负载分担，和交换机的聚合强制不协商方式配合。（需要xmit_hash_policy）
#Mode=3(broadcast) 表示所有包从所有interface发出，这个不均衡，只有冗余机制...和交换机的聚合强制不协商方式配合。
#Mode=4(802.3ad) 表示支持802.3ad协议，和交换机的聚合LACP方式配合（需要xmit_hash_policy）
#Mode=5(balance-tlb) 是根据每个slave的负载情况选择slave进行发送，接收时使用当前轮到的slave
#Mode=6(balance-alb) 在5的tlb基础上增加了rlb。）

#例子
nmcli con add type bond con-name bond0 ifname bond0 mode balance-rr
#给接口 bond0 设置ip地址
nmcli con mod bond0 ipv4.address '192.168.8.159/24' ipv4.gateway '192.168.8.254'
#设置为手动模式
nmcli con mod bond0 ipv4.method manual
#将两张物理网卡加入到 bond0 中
nmcli con add type bond-slave con-name bond0-port1 ifname eno1 master bond0
nmcli con add type bond-slave con-name bond0-port2 ifname eno2 master bond0
nmcli con add type bond-slave con-name bond0-port3 ifname eno3 master bond0
nmcli con reload && nmcli con up bond0
```

  

### ip

```sh
ip [ OPTIONS ] OBJECT { COMMAND | help }  
OBJECT 和 COMMAND可以简写到一个字母
ip help    　　　　　可以查到OBJECT列表和OPTIONS，简写 ip h
ip <OBJECT> help　　　查看针对该OBJECT的帮助，比如 ip addr help，简写 ip a h
ip addr    　　　　　查看网络接口地址，简写 ip a

#查看网络接口地址，替代ifconfig： 
ip addr
# 网络接口统计信息
ip -s link

## ip route显示和设定路由
#显示路由表
ip route
#添加静态路由
ip route add 10.15.150.0/24 via 192.168.150.253 dev enp0s3
#删除静态路由只需要把 add 替换成 del，或者更简单的只写目标网络
ip route del 10.15.150.0/24

##用 ip neighbor 代替 arp -n
ip nei

## 用ss 代替 netstat
#对应netstat -ant
ss -ant
#对应netstat -antp
ss -antp
ss -antp|column -t
```



### iperf: 带宽测试

```sh
# 安装
curl -o /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
yum install -y iperf

## 应用实例
#使用 iperf -s 命令将 Iperf 启动为 server 模式:
iperf -s
————————————————————
Server listening on TCP port 5001
TCP window size: 8.00 KByte (default)
————————————————————
#启动客户端，向IP为10.230.48.65的主机发出TCP测试，并每2秒返回一次测试结果：
iperf -c 10.230.48.65 -i 2

#以Mbytes/sec为单位显示测试结果：
iperf -c 10.230.48.65  

#设置TCP传输窗口大小为300K
iperf -s -w 300K
————————————————————
Server listening on TCP port 5001
TCP window size: 300 KByte
———————————————————

#测试传输约1MB数据
iperf -c 59.125.103.56 -f K -i 2 -w 300K –n 1000000

#测试持续36秒
iperf -c 59.125.103.56 -f K -i 2 -w 300K –t 36

#测试双向传输
iperf -c 220.112.45.87 -f K -i 2 -w 300k -n 1000000 -d

#UDP测试
iperf -c 59.125.103.56 -f K -i 2 -w 300K –u

#测试丢包
iperf -s -u -i 2
iperf -c 172.16.2.159 -u -b 200M -i2 -t 60

```

> -s 以server模式启动，eg：iperf –s 。Server端为数据的接收端。 
>
> -D 以服务方式运行ipserf，eg：iperf -s -D 
>
> -R 停止iperf服务，针对-D，eg：iperf -s -R 
>
> -o <filename> 重定向输出到指定文件。 
>
> -c,--client <hostname/IP> 如果Iperf运行为服务器模式，则可利用-c参数指定一个客户端，本机将接受指定客户端的连接，但不支持UDP协议。 
>
> -P,--parallel #  设置Iperf服务模式下的最大连接数，默认值为0，表示不限制连接数量。 
>
> Iperf客户端选项 
>
> -b,--bandwidth 指定客户端通过UDP协议发送信息的带宽，默认值为1Mbit/s 
>
> -c,--client <hostname/IP> 指定Iperf服务器的主机名和IP地址　　
>
> -d,--dualtest 同时进行双向传输测试 
>
> -n,--num 指定传输的字节数，eg：iperf -c 222.35.11.23 -n 100000 
>
> -r,--tradeoff 单独进行双向传输测试 
>
> -t,--time 指定Iperf测试时间，默认10秒,eg：iperf -c 222.35.11.23 -t 5 
>
> -L,--listenport 指定一个端口，服务器将利用这个端口与客户机连接 
>
> -P, --parallel 设置Iperf客户端至Iperf服务器的连接数，默认值为1 
>
> -S, --tos  设置发出包的类型，具体类型请参阅man文档 
>
> -F 指定需要传输的文件 
>
> -T 指定ttl值 
>
> 通用参数：
>
> -f [kmKM] 分别表示以Kbits, Mbits, KBytes, MBytes显示报告，默认以Mbits为单位,eg：iperf -c 222.35.11.23 -f K 
>
> -i sec 以秒为单位显示报告间隔，eg：iperf -c 222.35.11.23 -i 2 
>
> -l 缓冲区大小，默认是8KB,eg：iperf -c 222.35.11.23 -l 16 
>
> -m 显示tcp最大mtu 
>
> -o 将报告和错误信息输出到文件eg：iperf -c 222.35.11.23 -o ciperflog.txt 
>
> -p 指定服务器端使用的端口或客户端所连接的端口eg：iperf -s -p 9999;iperf -c 222.35.11.23 -p 9999 
>
> -u 使用udp协议 
>
> -w 指定TCP窗口大小，默认是8KB 
>
> -B 绑定一个主机地址或接口(当主机有多个地址或接口时使用该参数) 
>
> -C 兼容旧版本(当server端和client端版本不一样时使用) 
>
> -M 设定TCP数据包的最大mtu值 
>
> -N 设定TCP不延时 
>
> -V 传输ipv6数据包 



## blkid

```
echo `blkid /dev/vdb | awk '{print $2}' | sed 's/\"//g'` /data ext4 defaults 0 0 >> /etc/fstab
```



## ifstat

```sh
[root@sz-idc-02-k8s002 ~]# ifstat
#kernel
Interface        RX Pkts/Rate    TX Pkts/Rate    RX Data/Rate    TX Data/Rate
                 RX Errs/Drop    TX Errs/Drop    RX Over/Rate    TX Coll/Rate
lo                     0 0             0 0             0 0             0 0
                       0 0             0 0             0 0             0 0
eno1                 901 0         94097 0        903682 0         7469K 0
                       0 0             0 0             0 0             0 0
eno2                   0 0             0 0             0 0             0 0
                       0 0             0 0             0 0             0 0
eno3              276831 0         94106 0       286558K 0         7483K 0
                       0 0             0 0             0 0             0 0
eno4                   0 0             0 0             0 0             0 0
                       0 0             0 0             0 0             0 0
enp0s20f0u1u6          4 0             0 0           200 0             0 0
                       0 0             0 0             0 0             0 0
docker0                0 0             0 0             0 0             0 0
                       0 0             0 0             0 0             0 0
team0             169071 0        188158 0       277902K 0        14949K 0
                       0 0             0 0             0 0             0 0
```



## glances（实时监控）

```sh
#安装
yum install -y glances
#docker
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock:ro --pid host --network host -it nicolargo/glances
# 运行
glances

#docker
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock:ro --pid host --network host -it docker.io/nicolargo/glances

#配置alias
cat <<EOF >>  ~/.bashrc
alias glances='docker run --rm -v /var/run/docker.sock:/var/run/docker.sock:ro --pid host --network host -it docker.io/nicolargo/glances'
EOF

```



## iftop

```sh
# install
yum install epel-release -y
yum install iftop -y

# used
iftop -N -n -i ens32
```

### iftop 界面含义如下

```sh
第一行：带宽显示

中间部分：外部连接列表，即记录了哪些ip正在和本机的网络连接

中间部分右边：实时参数分别是该访问ip连接到本机2秒，10秒和40秒的平均流量

=>代表发送数据，<= 代表接收数据

底部三行：表示发送，接收和全部的流量

底部三行第二列：为你运行iftop到目前流量

底部三行第三列：为高峰值

底部三行第四列：为平均值
```

### 进入 iftop 的命令

```sh
按h切换是否显示帮助;

按n切换显示本机的IP或主机名;

按s切换是否显示本机的host信息;

按d切换是否显示远端目标主机的host信息;

按t切换显示格式为2行/1行/只显示发送流量/只显示接收流量;

按N切换显示端口号或端口服务名称;

按S切换是否显示本机的端口信息;

按D切换是否显示远端目标主机的端口信息;

按p切换是否显示端口信息;

按P切换暂停/继续显示;

按b切换是否显示平均流量图形条;

按B切换计算2秒或10秒或40秒内的平均流量;

按T切换是否显示每个连接的总流量;

按l打开屏幕过滤功能，输入要过滤的字符，比如ip,按回车后，屏幕就只显示这个IP相关的流量信息;

按L切换显示画面上边的刻度;刻度不同，流量图形条会有变化;

按j或按k可以向上或向下滚动屏幕显示的连接记录;

按1或2或3可以根据右侧显示的三列流量数据进行排序;

按<根据左边的本机名或IP排序;

按>根据远端目标主机的主机名或IP排序;

按o切换是否固定只显示当前的连接;

按f可以编辑过滤代码，这是翻译过来的说法，我还没用过这个！

按!可以使用shell命令，这个没用过！没搞明白啥命令在这好用呢！

按q退出监控。
```

## bash-completion

```
yum install bash-completion
echo "export TIME_STYLE='+%Y/%m/%d %H:%M:%S'" >> ~/.bash_profile
```



## ssh

```sh
#生成公钥密钥
ssh-keygen -t rsa 

chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
chmod 600 ~/.ssh/config

#设置免输入yes的known_hosts添加
echo "StrictHostKeyChecking no" >> ~/.ssh/config
echo "UserKnownHostsFile /dev/null" >> ~/.ssh/config
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

## user+group

```sh
#sudoers 文件添加可写权限
chmod -v u+w /etc/sudoers 
#取消 sudoers 文件可写权限
chmod -v u-w /etc/sudoers 
#修改密码 

passwd <UserName>
#新建用户
useradd -p <password> <UserName>
#建工作组
groupadd <GroupName>
#新建用户同时增加工作组
useradd -g <GroupName> <UserName>
#给已有的用户增加工作组
usermod -G <GroupName> <UserName> 或者：gpasswd -a <UserName> <GroupName>
#切换当前会话到新 group 或者重启 X 会话
newgrp - <GroupName>

#用户列表文件：/etc/passwd
#用户组列表文件：/etc/group
#查看系统中有哪些用户：cut -d : -f 1 /etc/passwd
#查看可以登录系统的用户：cat /etc/passwd | grep -v /sbin/nologin | cut -d : -f 1
#查看某一用户：w 用户名
#查看登录用户：who
#查看用户登录历史记录：last
```

## du

查看目录占用空间大小

```sh
du -sh /data

du -h  --max-depth=1 /data
```

## dd/fio

```sh
#随机读： 
fio -filename=/dev/sdb -direct=1 -iodepth 1 -thread -rw=randread -ioengine=psync -bs=16k -size=10G -numjobs=10 -runtime=1000 -group_reporting -name=randread

#顺序读： 
fio -filename=/dev/sdb1 -direct=1 -iodepth 1 -thread -rw=read -ioengine=psync -bs=16k -size=200G -numjobs=30 -runtime=1000 -group_reporting -name=read

#随机写： 
fio -filename=/dev/sdb1 -direct=1 -iodepth 1 -thread -rw=randwrite -ioengine=psync -bs=16k -size=200G -numjobs=30 -runtime=1000 -group_reporting -name=randwrite

#顺序写： 
fio -filename=/dev/sdb1 -direct=1 -iodepth 1 -thread -rw=write -ioengine=psync -bs=16k -size=200G -numjobs=30 -runtime=1000 -group_reporting -name=write

#混合随机读写： 
fio -filename=/dev/sdb1 -direct=1 -iodepth 1 -thread -rw=randrw -rwmixread=70 -ioengine=psync -bs=16k -size=1G -numjobs=10 -runtime=100 -group_reporting -name=randrw -ioscheduler=noop

说明： 
filename=/dev/sdb1       测试文件名称，通常选择需要测试的盘的data目录。 
direct=1                 测试过程绕过机器自带的buffer。使测试结果更真实。 
rw=randwrite             测试随机写的I/O 
rw=randrw                测试随机写和读的I/O 
bs=16k                   单次io的块文件大小为16k 
bsrange=512-2048         同上，提定数据块的大小范围 
size=5g                  本次的测试文件大小为5g，以每次4k的io进行测试。 
numjobs=30               本次的测试线程为30. 
runtime=1000             测试时间为1000秒，如果不写则一直将5g文件分4k每次写完为止。 
ioengine=psync           io引擎使用pync方式 
rwmixwrite=30            在混合读写的模式下，写占30% 
group_reporting          关于显示结果的，汇总每个进程的信息。

## dd
dd if=/dev/zero of=/tmp/test1.img bs=bm count=1 oflag=dsync

## 显示进度
sudo dd if=/dev/sda bs=2048 count=44898303 conv=sync,noerror | pv -s 21G |sudo dd of=/dev/sdb
sudo dd if=/dev/nvme0n1 bs=10M  conv=sync,noerror | pv -s 120G |sudo dd of=/dev/nvme3n1
sudo pv -tpreb /dev/nvme0n1 | dd of=/dev/zero bs=10M conv=notrunc,noerror
```



## tar

```sh
#打包并压缩gzip
tar -czvf 文件名.tar.gz 目录1 [目录1 目录2 文件1 文件2]
#解压到根目录
tar -xzf tengine-2.2.0-centos7.tar.gz -C /

#打包并压缩成bzip2
tar -cjf 文件名.tar.bz2 *.jpg 
#解压
tar -xjf 文件名.tar.bz2 

```



## 快速复制

### 本机不同磁盘之间复制

```sh
#复制目录
$ tar cvf – /home/src_dir | tar xvf – -C /data

SRC="/data"; TRG="/data1"; tar cf - "$SRC" | pv -s $(du -sb "$SRC" | cut -f1) | tar xf - -C "$TRG"

time tar -c go |pv |lz4 -B4 |ssh -p22 -c aes128-ctr 192.168.176.11 "lz4 -d |tar -xC /data/"

#复制文件
$ tar cf - access.log |tar xf - -C /opt
$ tar cf - access.log | pv |tar xf - -C /opt

bg %1
fg %1

```

 ### rsync

```sh
rsync -auvzP --remove-source-files  chia@chia-003:/data/farm/*/*.plot /data/farm/sdc/
```



## RPM

```sh
rpm [options] xxx.rpm
-ivh：安装显示安装进度 --install--verbose--hash
-Uvh：升级软件包 --Update；
-qpl：列出 RPM 软件包内的文件信息 [Query Package list]；
-qpi：列出 RPM 软件包的描述信息 [Query Package install package(s)]；
-qf：查找指定文件属于哪个 RPM 软件包 [Query File]；
-Va：校验所有的 RPM 软件包，查找丢失的文件 [View Lost]；
-e：删除包
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



## 升级linux内核

```sh
rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org \
&& rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-2.el7.elrepo.noarch.rpm \
&& yum clean all \
&& yum --enablerepo=elrepo-kernel install kernel-ml \
&& grub2-set-default 0

# 查看
grub2-editenv list

#查看启动项
awk -F\' '$1=="menuentry " {print i++ " : " $2}' /etc/grub2.cfg

#查看已经安装的内核
rpm -qa | grep kernel
```

## OverlayFS

```sh
echo "overlay" > /etc/modules-load.d/overlay.conf
modprobe overlay
lsmod | grep overlay

$ sed -i -e '/^ExecStart=/ s/$/ --storage-driver=overlay/' /usr/lib/systemd/system/docker.service \
rm /var/lib/docker -rf
```

## cifs/smb

```sh
yum -y install cifs-utils

vi /etc/cifs.conf
username=sharefs
password=SUNisco2018
domain=workgroup
mount -t cifs //192.168.8.191/data /data/shipagency -o credentials='/etc/cifs.conf',cache=none
```

## NFS

```sh
yum install -y nfs-utils
echo "options sunrpc tcp_slot_table_entries=128" >> /etc/modprobe.d/sunrpc.conf
echo "options sunrpc tcp_max_slot_table_entries=128" >>  /etc/modprobe.d/sunrpc.conf
sysctl -w sunrpc.tcp_slot_table_entries=128
```

## vi

### 常用命令

```sh
w(e)          移动光标到下一个单词
b             移动光标到上一个单词
0             移动光标到本行最开头
^             移动光标到本行最开头的字符处
$             移动光标到本行结尾处
o			 在当前行后面插入一空行

H             移动光标到屏幕的首行
M             移动光标到屏幕的中间一行
L             移动光标到屏幕的尾行
gg            移动光标到文档首行
G             移动光标到文档尾行
yy 　　		表示拷贝光标所在行
dd 　　		表示删除光标所在行
D 　　 		表示删除从当前光标到光标所在行尾的内容
```

## logrotate

```sh
#演练
logrotate -d /etc/logrotate.d/log-file

#强制轮循
logrotate -vf /etc/logrotate.d/log-file

#参数
compress 通过 gzip 压缩转储以后的日志
nocompress 不需要压缩时，用这个参数
copytruncate 用于还在打开中的日志文件，把当前日志备份并截断
nocopytruncate 备份日志文件但是不截断
create mode owner group 转储文件，使用指定的文件模式创建新的日志文件
nocreate 不建立新的日志文件
delaycompress 和 compress 一起使用时，转储的日志文件到下一次转储时才压缩
nodelaycompress 覆盖 delaycompress 选项，转储同时压缩。
errors address 专储时的错误信息发送到指定的 Email 地址
ifempty 即使是空文件也转储，这个是 logrotate 的缺省选项。
notifempty 如果是空文件的话，不转储
mail address 把转储的日志文件发送到指定的 E-mail 地址
nomail 转储时不发送日志文件
olddir directory 转储后的日志文件放入指定的目录，必须和当前日志文件在同一个文件系统
noolddir 转储后的日志文件和当前日志文件放在同一个目录下
prerotate/endscript 在转储以前需要执行的命令可以放入这个对，这两个关键字必须单独成行
postrotate/endscript 在转储以后需要执行的命令可以放入这个对，这两个关键字必须单独成行
daily 指定转储周期为每天
weekly 指定转储周期为每周
monthly 指定转储周期为每月
rotate count 指定日志文件删除之前转储的次数，0 指没有备份，5 指保留 5 个备份
tabootext [+] list 让 logrotate 不转储指定扩展名的文件，缺省的扩展名是：.rpm-orig, .rpmsave, v, 和 ~ 
size size 当日志文件到达指定的大小时才转储，Size 可以指定 bytes (缺省) 以及 KB (sizek) 或者 MB(sizem)
```

## curl

```sh
curl --insecure -v -O https://xxx
```

## openssl

```sh
#查看证书
openssl x509  -noout -text -in xxx.pem

#生成证书
penssl genrsa -out kubelet-key.pem 2048
openssl req -new -key kubelet-key.pem -out kubelet.csr -subj "/CN=kubelet-key" -config worker-openssl.cnf
openssl x509 -req -in kubelet.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out kubelet.pem -days 365 -extensions v3_req -extfile worker-openssl.cnf -rsa256
```



## cfssl

```sh
#install
wget https://pkg.cfssl.org/R1.2/cfssl_linux-amd64
chmod +x cfssl_linux-amd64
sudo mv cfssl_linux-amd64 /usr/local/bin/cfssl

wget https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
chmod +x cfssljson_linux-amd64
sudo mv cfssljson_linux-amd64 /usr/local/bin/cfssljson

wget https://pkg.cfssl.org/R1.2/cfssl-certinfo_linux-amd64
chmod +x cfssl-certinfo_linux-amd64
sudo mv cfssl-certinfo_linux-amd64 /usr/local/bin/cfssl-certinfo

cfssl print-defaults config > config.json
cfssl print-defaults csr > csr.json

tee admin-csr.json << EOF
{
  "CN": "admin",
  "hosts": [],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "Shenzhen",
      "L": "Shenzhen",
      "O": "k8s",
      "OU": "System"
    }
  ]
}
EOF

cfssl-certinfo -cert /etc/kubernetes/pki/bak/admin.pem
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes apiserver-csr.json | cfssljson -bare apiserver
```

## rm（防止误删除）

```sh
vi ~/.bashrc
#alias rm='rm -i'
alias rm=trash        
alias rl='ls ~/.Trash'  
alias ur=undelfile

if [ ! -d ~/.Trash/ ]; then
        mkdir ~/.Trash
fi

undelfile()  
{  
  mv -i ~/.Trash/$@ ./  
}  
trash()  
{  
  mv $@ ~/.Trash/  
}
cleartrash()  
{  
    read -p "Clear trash?[n]" confirm  
    [ $confirm == 'y' ] || [ $confirm == 'Y' ]  && /usr/bin/rm -rf ~/.Trash/*  
}

source ~/.bashrc

##使用
#删除一个文件夹，helloworld下面的文件均被移到回收站中
$rm helloworld

#删除一个文件
$rm abc.txt

#撤销abc.txt
$ur abc.txt

#撤销helloworld文件夹
$ur helloworld

#列出回收站
$rl

#清空回收
cleartrash
```

## chronyd

```sh
yum -y install chrony

vi /etc/chrony.conf
#在行首添加
server ntp.aliyun.com iburst

#开机自动启动，并启动服务
systemctl enable chronyd
systemctl start chronyd

```

## NTP

```sh
yum -y install ntp
 
vi /etc/ntp.conf

driftfile  /var/lib/ntp/drift
pidfile   /var/run/ntpd.pid
logfile /var/log/ntp.log
restrict    default kod nomodify notrap nopeer noquery
restrict -6 default kod nomodify notrap nopeer noquery
restrict 127.0.0.1
server 127.127.1.0
fudge  127.127.1.0 stratum 10
server ntp.aliyun.com iburst minpoll 4 maxpoll 10
restrict ntp.aliyun.com nomodify notrap nopeer noquery

#开机自动启动，并启动服务
systemctl enable ntpd
systemctl start ntpd

```



## TLS/SSL

```sh
sort -u /proc/crypto | grep module | grep aes
```



## FAQ

### No space left on device – running out of Inodes

```sh
#查看inode使用情况
df -i
#统计具体目录的文件个数
find /tmp | wc -l
#删除对应的小文件
```



