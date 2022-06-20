# geth

## init

```sh
echo “磁盘基准测试”
sudo yum -y install libaio libaio-devel fio

echo "初始化数据盘"
cp /etc/fstab /etc/fstab.bak

mkfs.ext4 /dev/vdb
echo `blkid /dev/vdb | awk '{print $2}' | sed 's/\"//g'` /data ext4 defaults,noatime 0 0 >> /etc/fstab
echo `blkid /dev/nvme1n1 | awk '{print $2}' | sed 's/\"//g'` /data ext4 defaults,noatime 0 0 >> /etc/fstab

or 

mkfs.xfs /dev/vdb
echo `blkid /dev/vdb | awk '{print $2}' | sed 's/\"//g'` /data xfs defaults,noatime 0 0 >> /etc/fstab
echo `blkid /dev/nvme1n1 | awk '{print $2}' | sed 's/\"//g'` /data xfs defaults,noatime 0 0 >> /etc/fstab


mkdir /data
mount -a
df -hl
```

## install

```sh

curl -sSL https://raw.githubusercontent.com/inspireso/docs/master/etherchain/geth.sh | bash -s install

or

curl -sSL https://raw.githubusercontent.com/inspireso/docs/master/etherchain/mev-geth.sh | bash -s install
```





## FAQ

## 添加太极网节点

```sh
cat <<"EOF" > /data/eth/gethdata/geth/static-nodes.json
[
  "enode://069d83ea0bc00343e85c10ae338d8d62f2238f2c0ab8b3366652b8d187107dcde501b2ad27b519e39e5f18557d7f73eab94a261a57a2e37905cced057eb693db@47.108.178.127:30303",
  "enode://fa13c5d273c687dc2494364e1ca9c41f2c11ea299fa912b82fb36684a6f0735a9cf2222578c5b0175704963f38abe1548821b927b457297e2a2ca5f15bd83a71@47.108.245.123:30303"
]
EOF

cat <<"EOF" > /data/eth/gethdata/geth/trusted-nodes.json
[
  "enode://069d83ea0bc00343e85c10ae338d8d62f2238f2c0ab8b3366652b8d187107dcde501b2ad27b519e39e5f18557d7f73eab94a261a57a2e37905cced057eb693db@47.108.178.127:30303",
  "enode://fa13c5d273c687dc2494364e1ca9c41f2c11ea299fa912b82fb36684a6f0735a9cf2222578c5b0175704963f38abe1548821b927b457297e2a2ca5f15bd83a71@47.108.245.123:30303"
]
EOF
systemctl daemon-reload && systemctl restart geth

```

### 导出 peers

```sh
/data/eth/geth/geth attach /data/eth/gethdata/geth.ipc --exec "admin.peers" > admin.peers
```

## 添加 peer

```sh
/data/eth/geth/geth attach /data/eth/gethdata/geth.ipc --exec "admin.addPeer('enode')"
/data/eth/geth/geth attach /data/eth/gethdata/geth.ipc --exec "admin.addTrustedPeer('enode')"

```


### 升级版本

```sh
curl -sSL https://raw.githubusercontent.com/inspireso/docs/master/etherchain/geth.sh | sudo bash -s upgrade

or

curl -sSL https://raw.githubusercontent.com/inspireso/docs/master/etherchain/mev-geth.sh | bash -s upgrade


/data/eth/geth/geth attach /data/eth/gethdata/geth.ipc --exec  "admin.nodeInfo"
/data/eth/geth/geth attach /data/eth/gethdata/geth.ipc --exec "eth.syncing"


```









