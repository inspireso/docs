# Ubuntu



## networking

```sh

sudo apt install libteam-utils

modinfo bonding | head -n 3
modprobe bonding
echo bonding > /etc/modules

lsmod | grep bond
sudo apt install ifenslave

sudo ip link add bond0 type bond mode round-robin
sudo ip link set eno1 master bond0
sudo ip link set eno2 master bond0



sudo apt update

sudo apt install libteam-utils -y

sudo nmcli con show
sudo nmcli con add type team con-name team0 ifname team0 config '{"runner":{"name": "roundrobin"}}'
sudo nmcli con mod team0 ipv4.address '172.16.0.36/22' ipv4.gateway '172.16.0.1'
sudo nmcli con modify team0 ipv4.dns "223.5.5.5 223.6.6.6"
sudo nmcli con mod team0 ipv4.method manual
sudo nmcli con add type team-slave con-name team0-port1 ifname eno1 master team0
sudo nmcli con add type team-slave con-name team0-port2 ifname eno2 master team0
sudo nmcli con show
```

