# RouterOS

## download

https://mikrotik.com/download

## install

### esxi

``` 
# create a new VM
# select "Other" and "Ubuntu 64-bit"

# https://mikrotik-doc-cn.readthedocs.io/zh/latest/source/Getting_started/First_Time_Configuration/content.html#id4

# 允许dhcp
/ip dhcp-client add interface=ether1 disabled=no
# 查看ip
/ip dhcp-client print

```

## web 访问

```
直接访问 http://ip 即可

ip: 使用  `/ip dhcp-client print` 查看
```