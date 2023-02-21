# NAT

## sysctl.conf

```sh

cat <<EOF >  /etc/sysctl.d/90-nat.conf
net.ipv6.conf.all.disable_ipv6=1
net.ipv6.conf.default.disable_ipv6=1
net.ipv6.conf.lo.disable_ipv6=1

net.ipv4.ip_forward=1
#是否支持巨型帧转发（使用LVS做负载均衡器时建议此值为1）
net.ipv4.ip_forward_use_pmtu = 1 
net.ipv4.ip_no_pmtu_disc = 1
net.ipv4.ip_local_port_range=1024 65535
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0

net.nf_conntrack_max = 4194304
net.netfilter.nf_conntrack_max=4194304
net.netfilter.nf_conntrack_buckets=65536
net.netfilter.nf_conntrack_icmp_timeout=10
# net.netfilter.nf_conntrack_tcp_timeout_syn_recv=5
# net.netfilter.nf_conntrack_tcp_timeout_syn_sent=5
# net.netfilter.nf_conntrack_tcp_timeout_established=600
# net.netfilter.nf_conntrack_tcp_timeout_fin_wait=15
# net.netfilter.nf_conntrack_tcp_timeout_time_wait=15
# net.netfilter.nf_conntrack_tcp_timeout_close_wait=15
# net.netfilter.nf_conntrack_tcp_timeout_last_ack=15
# net.netfilter.nf_conntrack_udp_timeout_stream = 120

net.netfilter.nf_conntrack_icmpv6_timeout = 30
net.netfilter.nf_conntrack_log_invalid = 0
net.netfilter.nf_conntrack_frag6_low_thresh = 3145728
net.netfilter.nf_conntrack_frag6_timeout = 60
net.netfilter.nf_conntrack_generic_timeout = 600
net.netfilter.nf_conntrack_gre_timeout = 30
net.netfilter.nf_conntrack_gre_timeout_stream = 180

net.core.netdev_max_backlog = 3240000
net.core.somaxconn = 65535
net.core.rmem_default=16777216
net.core.wmem_default=16777216
net.core.optmem_max=33554432
net.core.rmem_max=33554432
net.core.wmem_max=33554432

net.ipv4.tcp_mem=16777216 16777216 16777216
net.ipv4.tcp_rmem=4096 87380 33554432
net.ipv4.tcp_wmem=4096 87380 33554432

net.ipv4.udp_mem=16777216 16777216 16777216
net.ipv4.udp_rmem_min=4096
net.ipv4.udp_wmem_min=4096

net.ipv4.tcp_syn_retries=3
net.ipv4.tcp_synack_retries=3
net.ipv4.tcp_orphan_retries=3
net.ipv4.tcp_retries2 = 8

net.ipv4.tcp_syncookies = 0
net.ipv4.tcp_max_syn_backlog=3240000
net.ipv4.tcp_abort_on_overflow = 1
net.ipv4.tcp_synack_retries=3
net.ipv4.tcp_max_tw_buckets=1048576
net.ipv4.tcp_slow_start_after_idle=0

# TIME_WAIT
# net.ipv4.tcp_tw_recycle=0
# net.ipv4.tcp_tw_reuse=1
net.ipv4.tcp_timestamps=0
#表示当keepalive起用的时候，TCP发送keepalive消息的频度。默认 7200
net.ipv4.tcp_keepalive_time = 60
#keepalive探测包的发送间隔,默认 75
net.ipv4.tcp_keepalive_intvl = 20
#如果对方不予应答，探测包的发送次数,默认 9
net.ipv4.tcp_keepalive_probes = 3
#表示如果套接字由本端要求关闭，这个参数决定了它保持在FIN-WAIT-2状态的时间,默认 60
net.ipv4.tcp_fin_timeout = 30

EOF

sysctl -p /etc/sysctl.d/90-nat.conf

```

CONNTRACK_MAX 默认计算公式

CONNTRACK_MAX = 内存个数*1024*1024*1024/16384/(ARCH/32)
其中 ARCH 为 CPU 架构，值为 32 或 64。
比如：64 位 8G 内存的机器：(8*1024^3)/16384/(64/32) = 262144


## FAQ

### conntrack

```
$ dmesg | tail
[104235.156774] nf_conntrack: nf_conntrack: table full, dropping packet
[104243.800401] net_ratelimit: 3939 callbacks suppressed
[104243.800401] nf_conntrack: nf_conntrack: table full, dropping packet
[104262.962157] nf_conntrack: nf_conntrack: table full, dropping packet
```

```sh
$ sysctl -a | grep conntrack

net.netfilter.nf_conntrack_count = 53191
net.netfilter.nf_conntrack_max = 4194304
net.netfilter.nf_conntrack_buckets = 65536
net.netfilter.nf_conntrack_tcp_timeout_syn_recv = 60
net.netfilter.nf_conntrack_tcp_timeout_syn_sent = 120
net.netfilter.nf_conntrack_tcp_timeout_time_wait = 120
...

```

- net.netfilter.nf_conntrack_count，表示当前连接跟踪数；
- net.netfilter.nf_conntrack_max，表示最大连接跟踪数；
- net.netfilter.nf_conntrack_buckets，表示连接跟踪表的大小。

```sh


# 连接跟踪对象大小为376，链表项大小为16
nf_conntrack_max*连接跟踪对象大小+nf_conntrack_buckets*链表项大小
= 4194304*376+65536*16 B= 1.5 GB


# -L表示列表，-o表示以扩展格式显示
$ conntrack -L -o extended | head
ipv4     2 tcp      6 83 TIME_WAIT src=10.8.10.14 dst=139.5.201.34 sport=53120 dport=80 src=139.5.201.34 dst=10.9.0.6 sport=80 dport=53120 [ASSURED] mark=0 use=1
ipv4     2 tcp      6 64 TIME_WAIT src=10.8.10.30 dst=139.5.201.34 sport=46018 dport=80 src=139.5.201.34 dst=10.9.0.6 sport=80 dport=1098 [ASSURED] mark=0 use=1
ipv4     2 tcp      6 42 TIME_WAIT src=10.8.10.30 dst=139.5.201.34 sport=50174 dport=80 src=139.5.201.34 dst=10.9.0.6 sport=80 dport=64923 [ASSURED] mark=0 use=1
ipv4     2 tcp      6 431967 ESTABLISHED src=10.8.10.42 dst=40.90.189.152 sport=56362 dport=443 src=40.90.189.152 dst=10.9.0.6 sport=443 dport=56362 [ASSURED] mark=0 use=1
ipv4     2 tcp      6 41 TIME_WAIT src=10.8.10.14 dst=139.5.201.34 sport=49482 dport=80 src=139.5.201.34 dst=10.9.0.6 sport=80 dport=49482 [ASSURED] mark=0 use=1
ipv4     2 tcp      6 101 TIME_WAIT src=10.8.10.18 dst=139.5.201.34 sport=38026 dport=80 src=139.5.201.34 dst=10.9.0.6 sport=80 dport=2270 [ASSURED] mark=0 use=1
ipv4     2 tcp      6 60 TIME_WAIT src=10.8.10.30 dst=139.5.201.34 sport=39544 dport=80 src=139.5.201.34 dst=10.9.0.6 sport=80 dport=39544 [ASSURED] mark=0 use=1
ipv4     2 tcp      6 42 TIME_WAIT src=10.8.10.30 dst=139.5.201.34 sport=39810 dport=80 src=139.5.201.34 dst=10.9.0.6 sport=80 dport=39810 [ASSURED] mark=0 use=1
ipv4     2 tcp      6 431999 ESTABLISHED src=10.8.10.30 dst=118.31.23.26 sport=59600 dport=4000 src=118.31.23.26 dst=10.9.0.6 sport=4000 dport=59600 [ASSURED] mark=0 use=1
ipv4     2 tcp      6 6 TIME_WAIT src=10.8.10.18 dst=139.5.201.34 sport=33156 dport=80 src=139.5.201.34 dst=10.9.0.6 sport=80 dport=33156 [ASSURED] mark=0 use=1

# 统计总的连接跟踪数
$ conntrack -L -o extended | wc -l
14289

# 统计TCP协议各个状态的连接跟踪数
$ conntrack -L -o extended | awk '/^.*tcp.*$/ {sum[$6]++} END {for(i in sum) print i, sum[i]}'
conntrack v1.4.4 (conntrack-tools): 50922 flow entries have been shown.
LAST_ACK 4
SYN_RECV 12
CLOSE 47
CLOSE_WAIT 2
ESTABLISHED 9173
FIN_WAIT 9
SYN_SENT 673
TIME_WAIT 25686

# 统计各个源IP的连接跟踪数
$ conntrack -L -o extended | awk '{print $7}' | cut -d "=" -f 2 | sort | uniq -c | sort -nr | head -n 10
  14116 192.168.0.2
    172 192.168.0.96

# 统计各个目标IP的连接跟踪数
$ conntrack -L -o extended | awk '{print $8}' | cut -d "=" -f 2 | sort | uniq -c | sort -nr | head -n 10
  14116 192.168.0.2
    172 192.168.0.96    


# 统计信息
$ conntrack -S

cpu=0 found=0 invalid=130 insert=0 insert_failed=0 drop=0 early_drop=0 error=0 search_restart=10

cpu=1 found=0 invalid=0 insert=0 insert_failed=0 drop=0 early_drop=0 error=0 search_restart=0

cpu=2 found=0 invalid=0 insert=0 insert_failed=0 drop=0 early_drop=0 error=0 search_restart=1

cpu=3 found=0 invalid=0 insert=0 insert_failed=0 drop=0 early_drop=0 error=0 search_restart=0

大多数计数器将为0。“Found”和“insert”将始终为0，仅出于向后兼容的目的而存在。造成的其他错误包括：

invalid：数据包与现有连接不匹配，并且未创建新连接。

insert_failed：数据包开始新的连接，但是插入状态表失败。例如，当伪装时NAT引擎恰巧选择了相同的源地址和端口时，可能会发生这种情况。

drop：数据包启动一个新的连接，但是没有可用的内存为其分配新的状态条目。

early_drop：conntrack表已满。为了接受新连接，丢弃了没有双向通信的现有连接。

error：icmp（v6）收到与已知连接不匹配的icmp错误数据包

search_restart：查找由于另一个CPU的插入或删除而中断。

clash_resolve：几个CPU尝试插入相同的conntrack条目。    

```