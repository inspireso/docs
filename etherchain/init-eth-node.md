# geth

## init

```sh
echo “磁盘基准测试”
sudo yum -y install libaio libaio-devel fio

echo "初始化数据盘"
mkfs.ext4 /dev/vdb

mkdir /data
cp /etc/fstab /etc/fstab.bak
echo `blkid /dev/vdb | awk '{print $2}' | sed 's/\"//g'` /data ext4 defaults 0 0 >> /etc/fstab
cat /etc/fstab
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
 "enode://6ff737ef129ea4147a889a0f4fa1b80c981645eafd5e8dd4e569e0c74902e128591017c4530d5c99cc3c48d90abcfc7eb56b7b7a368508f636aa915dc7ef8a96@118.31.110.141:30303",
 "enode://2223cd460107a7e6d3647adf6dccfc70213f4061f81dc72b716c7806e89804f9f814e39365203beb6c268fb75a42b72c7ee631f372f46973c4aa75076b4ba247@161.117.250.168:30303",
 "enode://e5010b213ba9434e4f227008d5d719f13336b09373067882f8dba67e9181cf31a4561fac107d56c6d18cdac1dee74c742395d03fce3d99b7809eeff626c10570@47.251.33.122:30303",
 "enode://0b4851695f80115745d2fe341abb60803ea5e39edac4d74679f085f8f879f75ede8a3b37b5c687f0122f940c0b0c8755de1b6237fa85f732d81283363ba2e053@47.254.151.210:30303"
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


/data/eth/geth/geth attach /data/eth/gethdata/geth.ipc --exec  "admin.nodeInfo"
/data/eth/geth/geth attach /data/eth/gethdata/geth.ipc --exec "eth.syncing"


```









