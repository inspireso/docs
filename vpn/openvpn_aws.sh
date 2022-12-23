openvpn-up.sh
#!/bin/sh
#cmd tun_dev tun_mtu link_mtu ifconfig_local_ip ifconfig_remote_ip [ init | restart ]

echo $@

/sbin/ipset -N cidr_ikuai hash:net || /sbin/ipset flush cidr_ikuai
/sbin/ipset -N cidr_cn hash:net || /sbin/ipset flush cidr_cn
/sbin/ipset -N cidr_fw hash:net || /sbin/ipset flush cidr_fw
for ip in $(cat /etc/openvpn/cn_rules.conf); do /sbin/ipset add cidr_cn $ip; done

/sbin/iptables -t mangle -F

# 保留地址、私有地址、回环地址,不走隧道
/sbin/iptables -t mangle -N tunnel

/sbin/iptables -t mangle -A tunnel -m addrtype --dst-type LOCAL -j RETURN
/sbin/iptables -t mangle -A tunnel -m addrtype --dst-type MULTICAST -j RETURN
/sbin/iptables -t mangle -A tunnel -m addrtype --dst-type BROADCAST -j RETURN

/sbin/iptables -t mangle -A tunnel -d 127.0.0.0/8 -j RETURN
/sbin/iptables -t mangle -A tunnel -d 255.255.255.255/32 -j RETURN
/sbin/iptables -t mangle -A tunnel -d 224.0.0.0/4 -j RETURN
/sbin/iptables -t mangle -A tunnel -d 240.0.0.0/4 -j RETURN
/sbin/iptables -t mangle -A tunnel -d 169.254.0.0/16 -j RETURN

/sbin/iptables -t mangle -A tunnel -d 10.0.0.0/8 -j RETURN
/sbin/iptables -t mangle -A tunnel -d 172.16.0.0/12 -j RETURN
/sbin/iptables -t mangle -A tunnel -d 192.168.0.0/16 -j RETURN
/sbin/iptables -t mangle -A tunnel -d 100.64.0.0/10 -j RETURN

#block
/sbin/iptables -t mangle -A tunnel -m set --match-set cidr_block dst -j DROP

# 国内地址,不走隧道 
/sbin/iptables -t mangle -A tunnel -m set --match-set cidr_cn dst -j RETURN
# 标记
/sbin/iptables -t mangle -A tunnel -m mark --mark 3 -j RETURN
/sbin/iptables -t mangle -A tunnel -p udp -j MARK --set-mark 3
/sbin/iptables -t mangle -A tunnel -p tcp -j MARK --set-mark 3
/sbin/iptables -t mangle -A tunnel -p udp -j MARK --set-mark 3

# 只有指定的地址可以转发
/sbin/iptables -t mangle -A tunnel -m set --match-set cidr_fw dst -j MARK --set-mark 3
/sbin/iptables -t mangle -A tunnel -m mark --mark 3 -j RETURN
/sbin/iptables -t mangle -A tunnel -p udp -j DROP
/sbin/iptables -t mangle -A tunnel -p icmp -j DROP

# 应用规则
/sbin/iptables -t mangle -I PREROUTING -p icmp -j tunnel
/sbin/iptables -t mangle -I PREROUTING -p tcp -j tunnel
/sbin/iptables -t mangle -I PREROUTING -p udp -j tunnel
# 测试 ping
/sbin/iptables -t mangle -I FORWARD -p icmp -j tunnel
/sbin/iptables -t mangle -I OUTPUT -p icmp -j tunnel
#/sbin/iptables -t mangle -I OUTPUT -p tcp -j tunnel
#/sbin/iptables -t mangle -I OUTPUT -p udp -j tunnel

/sbin/iptables -t mangle -I FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

/sbin/iptables -t mangle -I OUTPUT -p tcp -m conntrack --ctstate NEW -j ACCEPT
/sbin/iptables -t mangle -I OUTPUT -p udp -m conntrack --ctstate NEW -j ACCEPT

# 配置路由规则
/sbin/ip rule add fwmark 3 table 100
/sbin/ip route add default dev $1 table 100
#/sbin/iptables -I FORWARD -o $1 -j ACCEPT
#/sbin/iptables -t nat -I POSTROUTING -o $1 -j MASQUERADE

# 配置 DNS 代理
#/sbin/iptables -t nat -A PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 53
#/sbin/iptables -t nat -A PREROUTING -p tcp --dport 53 -j REDIRECT --to-ports 53
#/sbin/iptables -t nat -A PREROUTING -d 47.242.250.123 -p tcp --dport 5555 -j DNAT --to-destination 172.16.10.126:5555


openvpn-down.sh
#!/bin/sh
#cmd tun_dev tun_mtu link_mtu ifconfig_local_ip ifconfig_remote_ip [ init | restart ]

/sbin/ip rule del table 100
#/sbin/iptables -D FORWARD -o $1 -j ACCEPT
#/sbin/iptables -t nat -D POSTROUTING -o $1 -j MASQUERADE