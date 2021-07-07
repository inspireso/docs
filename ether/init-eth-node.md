## init-get-node



```sh
#!/bin/sh

echo “磁盘基准测试”
sudo yum install libaio -y
sudo yum install libaio-devel -y
sudo yum install fio -y

echo "初始化数据盘"
mkfs.ext4 /dev/vdb

mkdir /data
cp /etc/fstab /etc/fstab.bak
echo `blkid /dev/vdb | awk '{print $2}' | sed 's/\"//g'` /data ext4 defaults 0 0 >> /etc/fstab
cat /etc/fstab
mount -a
df -hl

mkdir -p /data/eth
cd /data/eth


echo "下载安装 geth"
wget https://gethstore.blob.core.windows.net/builds/geth-linux-amd64-1.10.3-991384a7.tar.gz
tar -xzvf geth-linux-amd64-1.10.3-991384a7.tar.gz
ln -s /data/eth/geth-linux-amd64-1.10.3-991384a7 /data/eth/geth
ls -la

echo "安装服务 geth.service"
cat <<"EOF" > /etc/systemd/system/geth.service
[Unit]
Description=Geth
After=network.target

[Service]
LimitNOFILE=65535
Environment="DATA_DIR=/data/eth/gethdata"
Environment="DAG_DIR=/data/eth/gethdata/dag"
Environment="GETH_API_OPTS=--http --http.addr 0.0.0.0"
#Environment="GETH_MINE_OPTS=--mine --miner.etherbase 0x65A07d3081a9A6eE9BE122742c84ffea6964aCd2"
Environment="GETH_ETHASH_OPTS=--ethash.dagdir /data/eth/gethdata/dag"
Environment="GETH_EXTRA_OPTS=--datadir /data/eth/gethdata --maxpeers 1000 --cache 4096 --syncmode fast"
Environment="GETH_METRICS_OPTS=--metrics --metrics.addr 0.0.0.0 --metrics.port 6060"

Type=simple
User=root
Restart=always
RestartSec=12
ExecStart=/data/eth/geth/geth $GETH_API_OPTS $GETH_NETWORK_OPTS $GETH_MINE_OPTS $GETH_ETHASH_OPTS $GETH_METRICS_OPTS $GETH_EXTRA_OPTS

[Install]
WantedBy=default.target
EOF

mkdir -p /etc/systemd/system/geth.service.d
cat <<"EOF" > /etc/systemd/system/geth.service.d/limit.conf
[Service]
LimitNOFILE=65535
EOF

echo "启动 geth"
systemctl enable geth
systemctl daemon-reload && systemctl restart geth
systemctl status geth

echo "添加太极网节点"
cat <<"EOF" > /data/eth/gethdata/geth/static-nodes.json
[
 "enode://6ff737ef129ea4147a889a0f4fa1b80c981645eafd5e8dd4e569e0c74902e128591017c4530d5c99cc3c48d90abcfc7eb56b7b7a368508f636aa915dc7ef8a96@118.31.110.141:30303",
 "enode://2223cd460107a7e6d3647adf6dccfc70213f4061f81dc72b716c7806e89804f9f814e39365203beb6c268fb75a42b72c7ee631f372f46973c4aa75076b4ba247@161.117.250.168:30303",
 "enode://e5010b213ba9434e4f227008d5d719f13336b09373067882f8dba67e9181cf31a4561fac107d56c6d18cdac1dee74c742395d03fce3d99b7809eeff626c10570@47.251.33.122:30303",
 "enode://0b4851695f80115745d2fe341abb60803ea5e39edac4d74679f085f8f879f75ede8a3b37b5c687f0122f940c0b0c8755de1b6237fa85f732d81283363ba2e053@47.254.151.210:30303"
]
EOF
systemctl daemon-reload && systemctl restart geth

echo "生成控制台脚本"
cat <<"EOF" > /data/eth/console.sh
#!/bin/sh

/data/eth/geth/geth attach /data/eth/gethdata/geth.ipc
EOF
chmod +x /data/eth/console.sh
```



## restore nodekey

```sh
scp root@172.17.64.14:/data/eth/gethdata/geth/nodekey /data/eth/gethdata/geth/nodekey
scp root@172.17.64.14:/data/eth/gethdata/geth/static-nodes.json /data/eth/gethdata/geth/static-nodes.json
```



## FAQ



### 导出 peers

```sh
/data/eth/geth/geth attach /data/eth/gethdata/geth.ipc --exec "admin.peers" > admin.peers
```

## 添加 peer

```sh
/data/eth/geth/geth attach /data/eth/gethdata/geth.ipc --exec "admin.peers"
```



### 升级版本

```sh
mkdir -p /etc/systemd/system/geth.service.d
cat <<"EOF" > /etc/systemd/system/geth.service.d/limit.conf
[Service]
LimitNOFILE=65535
EOF

cd /data/eth && wget https://gethstore.blob.core.windows.net/builds/geth-linux-amd64-1.10.3-991384a7.tar.gz
tar -xzvf geth-linux-amd64-1.10.4-aa637fd3.tar.gz
rm -f /data/eth/geth && ln -s /data/eth/geth-linux-amd64-1.10.4-aa637fd3 /data/eth/geth

systemctl daemon-reload && systemctl restart geth && systemctl status geth
/data/eth/geth/geth attach /data/eth/gethdata/geth.ipc --exec  "admin.nodeInfo"
/data/eth/geth/geth attach /data/eth/gethdata/geth.ipc --exec "eth.syncing"


echo "添加太极网节点"
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









