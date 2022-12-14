# iptables

## 作为流量中转站

```sh
sysctl -w net.ipv4.ip_forward=1

PROTO=tcp|udp
DEST_IP=xxx.xxx.xxx.xxx
DEST_PORT=xxx
SOURCE_PORT=xxx

iptables -t nat -I PREROUTING -p $PROTO --dport $SOURCE_PORT -j DNAT --to-destination $DEST_IP:$DEST_PORT

iptables -I FORWARD -d $DEST_IP -p udp --dport $DEST_PORT -j ACCEPT

iptables -I FORWARD -s $DEST_IP -p udp --sport $DEST_PORT -j ACCEPT

iptables -t nat -I POSTROUTING -d $DEST_IP -p udp --dport $DEST_PORT -j MASQUERADE 


# 清理

iptables -t nat -D PREROUTING -p $PROTO --dport $SOURCE_PORT -j DNAT --to-destination $DEST_IP:$DEST_PORT

iptables -D FORWARD -d $DEST_IP -p udp --dport $DEST_PORT -j ACCEPT

iptables -D FORWARD -s $DEST_IP -p udp --sport $DEST_PORT -j ACCEPT

iptables -t nat -D POSTROUTING -d $DEST_IP -p udp --dport $DEST_PORT -j MASQUERADE 


```