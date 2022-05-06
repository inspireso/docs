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
cat > /usr/lib/systemd/system/dnsmasq.service <<EOF
[Unit]
Description=DNS caching server.
After=network.target

[Service]
ExecStart=/usr/sbin/dnsmasq -k
ExecStartPost=/sbin/iptables -t nat -A PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 53
ExecStartPost=/sbin/iptables -t nat -A PREROUTING -p tcp --dport 53 -j REDIRECT --to-ports 53

ExecStopPost=/sbin/iptables -t nat -D PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 53
ExecStopPost=/sbin/iptables -t nat -D PREROUTING -p tcp --dport 53 -j REDIRECT --to-ports 53

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload && systemctl restart dnsmasq.service
iptables -nvL -t nat

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

