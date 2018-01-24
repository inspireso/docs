#!/bin/bash

VIP=192.168.3.66

case "$1" in
  start)
    ip addr add $VIP/32 broadcast $VIP dev lo label lo:0
    ip route add $VIP scope link src $VIP dev lo:0
    echo "1" >/proc/sys/net/ipv4/conf/lo/arp_ignore
    echo "2" >/proc/sys/net/ipv4/conf/lo/arp_announce
    echo "1" >/proc/sys/net/ipv4/conf/all/arp_ignore
    echo "2" >/proc/sys/net/ipv4/conf/all/arp_announce
    sysctl -p >/dev/null 2>&1
    echo "RealServer Start OK"
    ;;
  stop)
    ip addr del $VIP/32 dev lo:0
    #ip route del $VIP dev lo:0
    echo "0" >/proc/sys/net/ipv4/conf/lo/arp_ignore
    echo "0" >/proc/sys/net/ipv4/conf/lo/arp_announce
    echo "0" >/proc/sys/net/ipv4/conf/all/arp_ignore
    echo "0" >/proc/sys/net/ipv4/conf/all/arp_announce
    echo "RealServer Stoped"
    ;;
  *)
    echo "Usage: $0 {start|stop}"
    exit 1
esac

exit 0