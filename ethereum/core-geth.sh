#!/usr/bin/env bash

set -e

# Usage: geth.sh install|upgrade

if [ -z "$1" ]; then
  exit 1
fi

# 指定 geth 版本
GETH_VERSION=${GETH_VERSION:-v1.12.8}


mkdir -p /data/etc
cd /data/etc

echo "下载 geth"
wget "https://github.com/etclabscore/core-geth/releases/download/${GETH_VERSION}/core-geth-linux-${GETH_VERSION}.zip" 
unzip -d "core-geth-linux-${GETH_VERSION}" core-geth-linux-${GETH_VERSION}.zip
rm -vf /data/etc/geth && ln -s /data/etc/core-geth-linux-${GETH_VERSION} /data/etc/geth
ls -la


if  [ "$1" == "install" ];  then
  echo "安装服务 getc.service"
  cat <<"EOF" > /etc/systemd/system/getc.service
[Unit]
Description=Getc
After=network.target

[Service]
LimitNOFILE=65535
Environment="DATA_DIR=/data/etc/gethdata"
Environment="DAG_DIR=/data/etc/gethdata/dag"
Environment="GETH_API_OPTS=--http --http.addr 0.0.0.0 --http.port 8545 --http.vhosts *"
#Environment="GETH_MINE_OPTS=--mine --miner.etherbase 0x65A07d3081a9A6eE9BE122742c84ffea6964aCd2"
Environment="GETH_ETHASH_OPTS=--ethash.dagdir /data/etc/gethdata/dag"
Environment="GETH_EXTRA_OPTS=--datadir /data/etc/gethdata --maxpeers 1000 --cache 4096 --syncmode snap"
Environment="GETH_METRICS_OPTS=--metrics --metrics.addr 0.0.0.0 --metrics.port 6060"

Type=simple
User=root
Restart=always
RestartSec=12
ExecStart=/data/etc/geth/geth --classic $GETH_API_OPTS $GETH_NETWORK_OPTS $GETH_MINE_OPTS $GETH_ETHASH_OPTS $GETH_METRICS_OPTS $GETH_EXTRA_OPTS
ExecStop=/bin/kill -s SIGTERM $MAINPID
TimeoutStopSec= 180

[Install]
WantedBy=default.target
EOF

  mkdir -p /etc/systemd/system/getc.service.d
  cat <<"EOF" > /etc/systemd/system/getc.service.d/limit.conf
[Service]
LimitNOFILE=65535
EOF

  echo "生成控制台脚本"
  cat <<"EOF" > /data/etc/console.sh
#!/bin/sh

/data/etc/geth/geth attach /data/etc/gethdata/geth.ipc
EOF
  chmod +x /data/etc/console.sh

  cat <<"EOF" >> ~/.bashrc
alias geth.syncing='/data/etc/geth/geth attach /data/etc/gethdata/geth.ipc --exec "eth.syncing"'
alias geth.nodeInfo='/data/etc/geth/geth attach /data/etc/gethdata/geth.ipc --exec "admin.nodeInfo"'
alias geth.peers='/data/etc/geth/geth attach /data/etc/gethdata/geth.ipc --exec "admin.peers"'
alias geth.peerCount='/data/etc/geth/geth attach /data/etc/gethdata/geth.ipc --exec "net.peerCount"'

EOF
  source ~/.bashrc
    
fi

echo "重启动 getc"
systemctl enable getc
systemctl daemon-reload && systemctl restart getc
systemctl status getc


## docker

docker run -d \
    --name core-geth \
    -v /data/mordor:/root \
    -p 30303:30303 \
    -p 8545:8545 \
    etclabscore/core-geth:version-1.12.8 \
    --mordor \
    --http --http.addr 0.0.0.0 --http.port 8545 \
    --mine --miner.etherbase 0x65A07d3081a9A6eE9BE122742c84ffea6964aCd2
