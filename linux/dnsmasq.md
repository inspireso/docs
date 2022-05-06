# DNS

## dnsmasq

### install
```sh
yum install -y dnsmasq

systemctl enable dnsmasq.service
systemctl restart dnsmasq.service && systemctl status dnsmasq.service
```

### 配置 DNS 代理

```sh
/sbin/iptables -t nat -A PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 53
/sbin/iptables -t nat -A PREROUTING -p tcp --dport 53 -j REDIRECT --to-ports 53
```

### SIGHUP

```sh
# clear the cache you trigger a reload..
pkill -HUP dnsmasq

#check the contents (dumps stats to the log) of the cache with
pkill -USR1 dnsmasq
````

systemctl enable dnsmasq.service
systemctl restart dnsmasq.service && systemctl status dnsmasq.service

```

