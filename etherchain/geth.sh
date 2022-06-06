#!/usr/bin/env bash

set -e

# Usage: geth.sh install|upgrade

if [ -z "$1" ]; then
  exit 1
fi

# 指定 geth 版本
GETH_VERSION=${GETH_VERSION:-geth-linux-amd64-1.10.18-de23cf91}


mkdir -p /data/eth
cd /data/eth

echo "下载 geth"
curl -sSL "https://gethstore.blob.core.windows.net/builds/${GETH_VERSION}.tar.gz" | tar -xz
rm -vf /data/eth/geth && ln -s /data/eth/${GETH_VERSION} /data/eth/geth
ls -la


if  [ "$1" == "install" ];  then
  echo "安装服务 geth.service"
  cat <<"EOF" > /etc/systemd/system/geth.service
[Unit]
Description=Geth
After=network.target

[Service]
LimitNOFILE=65535
Environment="DATA_DIR=/data/eth/gethdata"
Environment="DAG_DIR=/data/eth/gethdata/dag"
Environment="GETH_API_OPTS=--http --http.addr 0.0.0.0 --http.port 8545 --http.vhosts *"
#Environment="GETH_MINE_OPTS=--mine --miner.etherbase 0x65A07d3081a9A6eE9BE122742c84ffea6964aCd2"
Environment="GETH_ETHASH_OPTS=--ethash.dagdir /data/eth/gethdata/dag"
Environment="GETH_EXTRA_OPTS=--datadir /data/eth/gethdata --maxpeers 1000 --cache 4096 --syncmode snap"
Environment="GETH_METRICS_OPTS=--metrics --metrics.addr 0.0.0.0 --metrics.port 6060"

Type=simple
User=root
Restart=always
RestartSec=12
ExecStart=/data/eth/geth/geth $GETH_API_OPTS $GETH_NETWORK_OPTS $GETH_MINE_OPTS $GETH_ETHASH_OPTS $GETH_METRICS_OPTS $GETH_EXTRA_OPTS
ExecStop=/bin/kill -s SIGTERM $MAINPID
TimeoutStopSec= 180

[Install]
WantedBy=default.target
EOF

  mkdir -p /etc/systemd/system/geth.service.d
  cat <<"EOF" > /etc/systemd/system/geth.service.d/limit.conf
[Service]
LimitNOFILE=65535
EOF

  echo "生成控制台脚本"
  cat <<"EOF" > /data/eth/console.sh
#!/bin/sh

/data/eth/geth/geth attach /data/eth/gethdata/geth.ipc
EOF
  chmod +x /data/eth/console.sh

  cat <<"EOF" >> ~/.bashrc
alias geth.syncing='/data/eth/geth/geth attach /data/eth/gethdata/geth.ipc --exec "eth.syncing"'
alias geth.nodeInfo='/data/eth/geth/geth attach /data/eth/gethdata/geth.ipc --exec "admin.nodeInfo"'
alias geth.peers='/data/eth/geth/geth attach /data/eth/gethdata/geth.ipc --exec "admin.peers"'
alias geth.peerCount='/data/eth/geth/geth attach /data/eth/gethdata/geth.ipc --exec "net.peerCount"'

EOF
  source ~/.bashrc
    
fi

echo "重启动 geth"
systemctl enable geth
systemctl daemon-reload && systemctl restart geth
systemctl status geth

