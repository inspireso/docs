## install
```sh
yum install -y gmp-devel xl2tpd module-init-tools gcc openssl-devel

wget https://download.strongswan.org/strongswan-5.8.4.tar.gz

tar xvf strongswan-5.8.4.tar.gz

cd strongswan-5.8.4

./configure --prefix=/usr/local/strongswan --sysconfdir=/etc \
--enable-eap-radius \
--enable-eap-mschapv2 \
--enable-eap-identity \
--enable-eap-md5 \
--enable-eap-mschapv2 \
--enable-eap-tls \
--enable-eap-ttls \
--enable-eap-peap \
--enable-eap-tnc \
--enable-eap-dynamic \
--enable-xauth-eap \
--enable-openssl


make && make install

```

## config

### ipsec.conf

```sh

cat <<"EOF" > /etc/strongswan/ipsec.conf
# ipsec.conf - strongSwan IPsec configuration file

# basic configuration

config setup
    uniqueids=no

conn %default
    ike=aes128-sha256-modp2048
    esp=aes128-sha256-modp2048
    compress=no
    type=tunnel

conn ike2
    keyexchange=ikev2
    fragmentation=yes
    forceencaps=yes
    dpddelay=300s
    dpdtimeout=30s
    dpdaction=restart
    forceencaps=yes
    ikelifetime=4h
    lifetime=2h
    eap_identity=%identity
    auto=add
    rekey=no
    dpdaction=clear
    left=%any
    leftid=@aliyun
    leftauth=psk
    leftsubnet=0.0.0.0/0
    right=%any
    rightid=%any
    rightauth=psk
    rightsourceip=10.255.255.1/24
    rightdns=223.5.5.5,223.6.6.6

EOF

cat <<"EOF" > /etc/strongswan/ipsec.secrets
# ipsec.secrets - strongSwan IPsec secrets file

@aliyun @mac : PSK "MjVFQ0I1N0UtNkM3Ri00MUM4LTlFMkMtRTZDMEM4NTlDNzYxCg"

EOF

```

### iptables 模式

```sh
cat <<"EOF" > /etc/strongswan/swanctl/conf.d/moon.swanctl.conf

connections {
   rw {
      local_addrs = 172.16.17.18

      local {
         auth = psk
         id = @aliyun-cd
      }
      remote {
         auth = psk
      }
      children {
         net {
            local_ts  = 172.16.17.0/24
            remote_ts = 10.31.0.0/16

            updown = /usr/libexec/strongswan/_updown iptables
            esp_proposals = aes128-sha256-modp2048
         }
      }
      version = 2
      proposals = aes128-sha256-modp2048
   }
}

secrets {
  ike-1 {
    id = @mac
    secret = MjVFQ0I1N0UtNkM3Ri00MUM4LTlFMkMtRTZDMEM4NTlDNzYxCg
  }
  ike-2 {
      id-1a = @aliyun-cd
      id-1b = @usg-002
      secret = MjVFQ0I1N0UtNkM3Ri00MUM4LTlFMkMtRTZDMEM4NTlDNzYxCg
  }
}
EOF



/sbin/iptables -t nat -I POSTROUTING -s 10.31.0.0/16 -j MASQUERADE
/sbin/iptables -t nat -I POSTROUTING -s 172.16.6.0/23  -j MASQUERADE
/sbin/iptables -t nat -I POSTROUTING -s 192.168.8.0/24  -j MASQUERADE

ip route add 172.16.6.0/23 dev ipsec0
ip route del 172.16.6.0/23 dev ipsec0

/sbin/iptables -t nat -I POSTROUTING -s 10.31.0.0/16 -o eth0  -j MASQUERADE

/sbin/iptables -t nat -I POSTROUTING -o eth0  -j MASQUERADE

swanctl --load-all



```

### xfrm 模式

```sh
cat <<"EOF" > /etc/strongswan/swanctl/conf.d/moon.swanctl.conf

connections {
  gw-gw {
    local_addrs = 172.16.17.18

    local {
        auth = psk
        id = @aliyun-cd
    }
    remote {
        auth = psk
    }
    children {
      nat-nat {
          local_ts  = 0.0.0.0/0
          remote_ts = 0.0.0.0/0

          if_id_in = 42
          if_id_out = 42

          esp_proposals = aes128-sha256-modp2048
      }
    }
    version = 2
    proposals = aes128-sha256-modp2048
  }
}

secrets {
   ike-1 {
      id-1a = @aliyun-cd
      id-1b = @usg-001
      secret = MjVFQ0I1N0UtNkM3Ri00MUM4LTlFMkMtRTZDMEM4NTlDNzYxCg
   }
  ike-1 {
      id-1a = @aliyun-cd
      id-1b = @usg-002
      secret = MjVFQ0I1N0UtNkM3Ri00MUM4LTlFMkMtRTZDMEM4NTlDNzYxCg
   }
}
EOF

cat <<"EOF" > /etc/strongswan/updown

#!/bin/bash

case "${PLUTO_VERB}" in
    up-client)
        ip link add ipsec0 type xfrm dev eth0 if_id 42
        ip link set ipsec0 up
        ip route add 10.31.0.0/16 dev ipsec0
        ip route add 172.16.7.176/24 dev ipsec0
        ip route add 192.168.8.0/24 dev ipsec0

        iptables -A FORWARD -o ipsec0 -j ACCEPT
        iptables -A FORWARD -i ipsec0 -j ACCEPT
        iptables -t nat -I POSTROUTING -s 172.16.7.176/24  -j MASQUERADE
        iptables -t nat -I POSTROUTING -s 192.168.8.0/24  -j MASQUERADE
        ;;
    down-client)
        iptables -t nat -F
        iptables -t nat -D POSTROUTING -s 172.16.7.176/24  -j MASQUERADE
        iptables -t nat -D POSTROUTING -s 192.168.8.0/24  -j MASQUERADE
        iptables -D FORWARD -o ipsec0 -j ACCEPT
        iptables -D FORWARD -i ipsec0 -j ACCEPT
        
        ip route del 10.31.0.0/16 dev ipsec0
        ip route del 172.16.7.176/24 dev ipsec0
        ip route del 192.168.8.0/24 dev ipsec0

        ip link del ipsec0
        ;;
esac

EOF

chmod +x /etc/strongswan/updown

swanctl --load-all

```

## nat

```sh
/sbin/iptables -t nat -I POSTROUTING -o ipsec0  -j MASQUERADE

/sbin/iptables -t nat -D POSTROUTING -o ipsec0  -j MASQUERADE

/sbin/iptables -t nat -I POSTROUTING -s 172.16.6.0/23  -j MASQUERADE

/sbin/iptables -t nat -D POSTROUTING -s 10.31.0.0/16 -o eth0  -j MASQUERADE
/sbin/iptables -t nat -D POSTROUTING -s 172.16.6.0/23  -j MASQUERADE

ip route add 172.16.6.0/23 dev ipsec0
ip route del 172.16.6.0/23 dev ipsec0

```

```sh
iptables -nL -t filter
iptables -nL -t mangle
iptables -nL -t nat

# 检查所有网卡的forwarding=1
sysctl -a | grep net.ipv4.conf.eth0.forwarding 

# 跟踪 iptables
modprobe ipt_LOG ip6t_LOG nfnetlink_log
iptables -t raw -A PREROUTING -p icmp -j TRACE
iptables -t raw -A OUTPUT -p icmp -j TRACE
xtables-monitor --trace

iptables -t raw -A PREROUTING -p icmp -s 172.16.6.0/23 -d 114.114.114.114 -j TRACE
iptables -t raw -A OUTPUT -p icmp -s 172.16.6.0/23 -d 114.114.114.114 -j TRACE
iptables -t raw -A OUTPUT -p icmp -s 114.114.114.114 -d 172.16.6.0/23 -j TRACE

iptables -t raw -A OUTPUT -p icmp -s 172.16.6.0/23 -j TRACE

dmesg -C
dmesg -ew


iptables -t raw -D PREROUTING -p icmp -s 172.16.6.0/23 -j TRACE

```
