## 网卡添加路由

```sh
ip ru add from ip1 table 200
ip ro add default via gw_ip dev eth0(interface) table 200

ip ru add from ip2 table 201
ip ro add default via gw_ip dev eth2(interface) table 201
```

