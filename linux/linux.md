

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
# 查看某个进程pid打开的文件数
ls /proc/pid/fd | wc -l
#或者，需要安装yum install -y lsof
lsof -p pid | wc -l 
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
```

### nmcli：管理工具

- 查看nmcli使用说明

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

- 常用命令

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

#给接口eno2添加ip地址
nmcli con mod eno2 +ipv4.address '192.168.8.159/24'
# 重新加载配置并生效
nmcli con reload && nmcli con up eno2
```

- 配置teamd

```sh
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
nmcli con add type team-slave con-name team0-port1 ifname eno1 master team0
nmcli con add type team-slave con-name team0-port2 ifname eno2 master team0
nmcli con add type team-slave con-name team0-port3 ifname eno3 master team0
# nmcli con up team0
# 查看team0的状态就出现了
teamdctl team0 st 
```



### iperf: 带宽测试

```sh
# 安装
curl -o /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
yum install -y iperf

# 启动服务端
iperf -s -i 1 -w 448k

# 启动客户端
iperf -c 192.168.8.155 -i 1 -w 448k -t 60
```

> -s 以server模式启动。#iperf -s
>
> -c host以client模式启动。host是server端地址。#iperf -c serverip
>
> 通用参数：
>
> -b表示使用带宽数量
>
> -f [kmKM] 分别表示以Kbits, Mbits, KBytes, MBytes显示报告，默认以Mbits为单位,#iperf -c 192.168.0.241 -f K
>
> -i sec 以秒为单位显示报告间隔，#iperf -c 192.168.0.241 -i 2
>
> -l 缓冲区大小，默认是8KB,#iperf -c 192.168.0.241 -l 16
>
> -m 显示tcp最大mtu值
>
> -o 将报告和错误信息输出到文件#iperf -c 192.168.0.241 -ociperflog.txt
>
> -p 指定服务器端使用的端口或客户端所连接的端口#iperf -s -p 9999;iperf -c 192.168.0.241-p 9999
>
> -u 使用udp协议
>
> -w 指定TCP窗口大小，默认是8KB
>
> -B 绑定一个主机地址或接口（当主机有多个地址或接口时使用该参数）
>
> -C 兼容旧版本（当server端和client端版本不一样时使用）
>
> -M 设定TCP数据包的最大mtu值
>
> -N 设定TCP不延时
>
> -V 传输ipv6数据包
>
> server专用参数：
>
> -D 以服务方式运行。#iperf -s -D
>
> -R 停止iperf服务。针对-D，#iperf -s -R
>
> client端专用参数：
>
> -d 同时进行双向传输测试
>
> -n 指定传输的字节数，#iperf -c 192.168.0.241 -n 100000
>
> -r 单独进行双向传输测试
>
> -t 测试时间，默认20秒,#iperf -c 192.168.0.241-t 5
>
> -F 指定需要传输的文件
>
> -T 指定ttl值



### ss

```sh
ss -lntp
```

## ifstat



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

## du

查看目录占用空间大小

```sh
du /data -BM -d1
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



## 修改为阿里镜像库

```sh
mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.bak
curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
curl -o /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
```

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
$ echo "overlay" > /etc/modules-load.d/overlay.conf
$ lsmod | grep overlay

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

