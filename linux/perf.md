# linux 性能优化



## tools

![linux 性能工具](assets/linux-performance-tools.png)

## cpu

### stress

```sh
# CPU 密集型进程
$ stress --cpu 1 --timeout 600

# I/O 密集型进程
$ stress -i 1 --timeout 600

# 大量进程的场景
$ stress -c 8 --timeout 600

```

**说明**

```sh
# 参数：
-? 显示帮助信息
-v 显示版本号
-q 不显示运行信息
-n，--dry-run 显示已经完成的指令执行情况
-t --timeout N 指定运行N秒后停止
   --backoff N 等待N微妙后开始运行
-c --cpu 产生n个进程 每个进程都反复不停的计算随机数的平方根
-i --io  产生n个进程 每个进程反复调用sync()，sync()用于将内存上的内容写到硬盘上
-m --vm n 产生n个进程,每个进程不断调用内存分配malloc和内存释放free函数
   --vm-bytes B 指定malloc时内存的字节数 (默认256MB)
   --vm-hang N 指示每个消耗内存的进程在分配到内存后转入休眠状态，与正常的无限分配和释放内存的处理相反，这有利于模拟只有少量内存的机器
-d --hadd n 产生n个执行write和unlink函数的进程
   --hadd-bytes B 指定写的字节数，默认是1GB
   --hadd-noclean 不要将写入随机ASCII数据的文件Unlink
   
时间单位可以为秒s，分m，小时h，天d，年y，文件大小单位可以为K，M，G
```



### mpstat

```sh
# -P ALL 表示监控所有CPU，后面数字5表示间隔5秒后输出一组数据
$ mpstat -P ALL 5
```

### pidstat

```sh
# 间隔5秒后输出一组数据
$ pidstat -u 5 1

```

**说明**

```sh
pidstat [ 选项 ] [ <时间间隔> ] [ <次数> ]

# install latest version from source
git clone --depth=50 --branch=master https://github.com/sysstat/sysstat.git sysstat/sysstat
cd sysstat/sysstat
git checkout -qf 6886152fb3af82376318c35eda416c3ce611121d
export TRAVIS_COMPILER=gcc
export CC=gcc
export CC_FOR_BUILD=gcc
./configure --disable-nls --prefix=/usr/local/
make &&make install

# 常用的参数：
-u：默认的参数，显示各个进程的cpu使用统计
-r：显示各个进程的内存使用统计
-d：显示各个进程的IO使用情况
-p：指定进程号
-w：显示每个进程的上下文切换情况
-t：显示选择任务的线程的统计信息外的额外信息
-T { TASK | CHILD | ALL }
这个选项指定了pidstat监控的。TASK表示报告独立的task，CHILD关键字表示报告进程下所有线程统计信息。ALL表示报告独立的task和task下面的所有线程。
注意：task和子线程的全局的统计信息和pidstat选项无关。这些统计信息不会对应到当前的统计间隔，这些统计信息只有在子线程kill或者完成的时候才会被收集。
-V：版本号
-h：在一行上显示了所有活动，这样其他程序可以容易解析。
-I：在SMP环境，表示任务的CPU使用率/内核数量
-l：显示命令名和所有参数

# 输出说明：
PID：进程ID
%usr：进程在用户空间占用cpu的百分比
%system：进程在内核空间占用cpu的百分比
%guest：进程在虚拟机占用cpu的百分比
%CPU：进程占用cpu的百分比
CPU：处理进程的cpu编号
Command：当前进程对应的命令
Minflt/s:任务每秒发生的次要错误，不需要从磁盘中加载页
Majflt/s:任务每秒发生的主要错误，需要从磁盘中加载页
VSZ：虚拟地址大小，虚拟内存的使用KB
RSS：常驻集合大小，非交换区五里内存使用KB
kB_rd/s：每秒从磁盘读取的KB
kB_wr/s：每秒写入磁盘KB
kB_ccwr/s：任务取消的写入磁盘的KB。当任务截断脏的pagecache的时候会发生。
Cswch/s:每秒主动任务上下文切换数量
Nvcswch/s:每秒被动任务上下文切换数量
Usr-ms:任务和子线程在用户级别使用的毫秒数。
System-ms:任务和子线程在系统级别使用的毫秒数。
Guest-ms:任务和子线程在虚拟机(running a virtual processor)使用的毫秒数。
```

## 网络基准测试

### TCP/UDP 性能

```sh

# Ubuntu
apt-get install iperf3
# CentOS
yum install iperf3



# -s表示启动服务端，-i表示汇报间隔，-p表示监听端口
iperf3 -s -i 1 -p 8443


# -c表示启动客户端，192.168.0.30为目标服务器的IP
# -b表示目标带宽(单位是bits/s)
# -t表示测试时间
# -P表示并发数，-p表示目标服务器监听端口
iperf3 -c 172.16.10.131 -b 1G -t 15 -P 2 -p 8443

```



