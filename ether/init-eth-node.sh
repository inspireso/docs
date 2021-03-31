
#!/bin/sh

mkfs.ext4 /dev/vdb

mkdir /data
cp /etc/fstab /etc/fstab.bak
echo `blkid /dev/vdb | awk '{print $2}' | sed 's/\"//g'` /data ext4 defaults 0 0 >> /etc/fstab
cat /etc/fstab
mount -a
df -hl

mkdir -p /data/eth
cd /data/eth


wget https://gethstore.blob.core.windows.net/builds/geth-linux-amd64-1.10.1-c2d2f4ed.tar.gz

tar -xzvf geth-linux-amd64-1.10.1-c2d2f4ed.tar.gz
ln -s /data/eth/geth-linux-amd64-1.10.1-c2d2f4ed /data/eth/geth
ls -la


cat <<"EOF" > /etc/systemd/system/geth.service
[Unit]
Description=Geth
After=network.target

[Service]
Environment="DATA_DIR=/data/eth/gethdata"
Environment="DAG_DIR=/data/eth/gethdata/dag"
Environment="GETH_API_OPTS=--http --http.addr 0.0.0.0 --http.port 18899"
Environment="GETH_NETWORK_OPTS=--bootnodes enode://d9835e6d1ed9ccf514d83602042647d9e95d29f0c6c977edeb384e2866b2942e4a0459a4076050f23503eb2ce40dc096f2442c72efce0015dbd1ee759d889244@192.168.9.1:30303"
Environment="GETH_MINE_OPTS=--mine --miner.etherbase 0x6ebaf477f83e055589c1188bcc6ddccd8c9b131a"
Environment="GETH_ETHASH_OPTS=--ethash.dagdir /data/eth/gethdata/dag"
Environment="GETH_EXTRA_OPTS=--datadir /data/eth/gethdata --maxpeers 100 --cache 4096 --syncmode fast"
Environment="GETH_METRICS_OPTS=--metrics --metrics.addr 0.0.0.0 --metrics.port 6060"

Type=simple
User=root
Restart=always
RestartSec=12
ExecStart=/data/eth/geth/geth $GETH_API_OPTS $GETH_NETWORK_OPTS $GETH_MINE_OPTS $GETH_ETHASH_OPTS $GETH_METRICS_OPTS $GETH_EXTRA_OPTS

[Install]
WantedBy=default.target
EOF


systemctl enable geth
systemctl daemon-reload && systemctl restart geth
systemctl status geth

cat <<"EOF" > /data/eth/console.sh
#!/bin/sh

/data/eth/geth/geth attach /data/eth/gethdata/geth.ipc
EOF
chmod +x /data/eth/console.sh






