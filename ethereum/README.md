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

### 导出 peers

```sh
/data/eth/geth/geth attach /data/eth/gethdata/geth.ipc --exec "admin.peers" > admin.peers
```

### 添加 peer

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









