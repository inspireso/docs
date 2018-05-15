#!/usr/bin/bash

#######################################
ss_server=47.52.42.104
listen_port=1080
#######################################

# 清空
iptables -t nat -F && iptables -t nat -X shadowsocks && ipset -X cidr_cn
rm /etc/shadowsocks/ipset.sh

# 获取大陆ip地址段
#curl http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest | grep 'apnic|CN|ipv4' | awk -F\| '{ printf("%s/%d\n", $4, 32-log($5)/log(2)) }' > /etc/shadowsocks/chnroutes.txt

# ipset
ipset -N cidr_cn hash:net

for i in `cat /etc/shadowsocks/chnroutes.txt`; do
    echo ipset -A cidr_cn $i >> /etc/shadowsocks/ipset.sh
done

bash /etc/shadowsocks/ipset.sh
ipset -S > /etc/sysconfig/ipset.cidr_cn

# 新建一条链 shadowsocks
iptables -t nat -N shadowsocks

# 保留地址、私有地址、回环地址 不走代理
iptables -t nat -A shadowsocks -d 0/8 -j RETURN
iptables -t nat -A shadowsocks -d 127/8 -j RETURN
iptables -t nat -A shadowsocks -d 10/8 -j RETURN
iptables -t nat -A shadowsocks -d 169.254/16 -j RETURN
iptables -t nat -A shadowsocks -d 172.16/12 -j RETURN
iptables -t nat -A shadowsocks -d 192.168/16 -j RETURN
iptables -t nat -A shadowsocks -d 224/4 -j RETURN
iptables -t nat -A shadowsocks -d 240/4 -j RETURN

# 发往shadowsocks服务器的数据不走代理，否则陷入死循环
iptables -t nat -A shadowsocks -d ${ss_server} -j RETURN

# 大陆地址不走代理，因为这毫无意义，绕一大圈很费劲的
iptables -t nat -A shadowsocks -m set --match-set cidr_cn dst -j RETURN

# 其余的全部重定向至ss-redir监听端口1080(端口号随意,统一就行)
iptables -t nat -A shadowsocks -p tcp -j REDIRECT --to-ports ${listen_port}
iptables -t nat -A shadowsocks -p icmp -j REDIRECT --to-ports ${listen_port}

# OUTPUT链添加一条规则，重定向至shadowsocks链
#iptables -t nat -A OUTPUT -p tcp -j shadowsocks

# 在 PREROUTING 链前插入 SHADOWSOCKS 链,使其生效
iptables -t nat -I PREROUTING -p tcp -j shadowsocks
iptables -t nat -I PREROUTING -p icmp -j shadowsocks

# 持久化iptables规则到文件
iptables-save > /etc/sysconfig/iptables.shadowsocks
