# ETH2


## run mainnet

### run execution client
```shell
mkdir -p /data/ethereum/execution

GETH_VERSION=${GETH_VERSION:-geth-linux-amd64-1.10.24-972007a5}

# "下载"
curl -sSL "https://gethstore.blob.core.windows.net/builds/${GETH_VERSION}.tar.gz" | tar -xz
rm -vf /data/ethereum/execution/geth && ln -s /data/ethereum/execution/${GETH_VERSION}/geth /data/ethereum/execution/geth
cd /data/ethereum/execution && ls -la

# "安装服务 geth.service"
cat <<"EOF" > /etc/systemd/system/geth.service
[Unit]
Description=Geth
After=network.target

[Service]
LimitNOFILE=65535
Environment="GETH_API_OPTS=--http --http.api eth,net,engine,admin --http.addr 0.0.0.0 --http.port 8545 --http.vhosts *"
Environment="GETH_NETWORK_OPTS=--port 30303"
Environment="GETH_ETHASH_OPTS=--ethash.dagdir /data/ethereum/execution/gethdata/geth/dag"
Environment="GETH_METRICS_OPTS=--metrics --metrics.addr 0.0.0.0 --metrics.port 6060"
Environment="GETH_EXTRA_OPTS=--datadir /data/ethereum/execution/gethdata --syncmode snap"
Environment="GETH_MERGE_OPTS=--authrpc.addr 0.0.0.0 --authrpc.port 8551 --authrpc.vhosts "*" "

Type=simple
User=root
Restart=always
RestartSec=12
ExecStart=/data/ethereum/execution/geth $GETH_MERGE_OPTS $GETH_API_OPTS $GETH_NETWORK_OPTS $GETH_ETHASH_OPTS $GETH_METRICS_OPTS $GETH_EXTRA_OPTS
ExecStop=/bin/kill -s SIGTERM $MAINPID
TimeoutStopSec= 180

[Install]
WantedBy=default.target
EOF

# 设置自动启动
systemctl enable geth
systemctl daemon-reload && systemctl restart geth
```
#### 开放防火墙
- udp/30303 
- tcp/30303

### run **beacon node**
```shell
PRYSM_VERSION=${PRYSM_VERSION:-v3.1.1}
file=beacon-chain-${PRYSM_VERSION}-linux-amd64

# "下载"
mkdir -p "/data/ethereum/consensus/prysm"
curl --silent -L "https://prysmaticlabs.com/releases/${file}" -o "/data/ethereum/consensus/prysm/${file}"
chmod +x "/data/ethereum/consensus/prysm/${file}"
rm -vf /data/ethereum/consensus/beacon-chain && ln -s "/data/ethereum/consensus/prysm/${file}" /data/ethereum/consensus/beacon-chain
cd /data/ethereum/consensus && ls -la

# "安装服务 beacon.service"
cat <<"EOF" > /etc/systemd/system/beacon.service
[Unit]
Description=beacon-node
After=network.target

[Service]
LimitNOFILE=65535
Environment="EL_OPTS=--execution-endpoint=http://localhost:8551 --jwt-secret=/data/ethereum/execution/gethdata/geth/jwtsecret"
Environment="CL_OPTS=--rpc-host=0.0.0.0 --rpc-port 4000 --p2p-tcp-port 13000 --p2p-udp-port 12000 --monitoring-host=0.0.0.0 --monitoring-port 8081  --datadir=/data/ethereum/consensus"
Environment="CMD_OPTS=--accept-terms-of-use"
Environment="FEE_OPTS=--suggested-fee-recipient=YOUR_ETH_ADDRESS"
Type=simple
User=root
Restart=always
RestartSec=12
ExecStart=/data/ethereum/consensus/beacon-chain $CMD_OPTS $CL_OPTS $EL_OPTS $FEE_OPTS
ExecStop=/bin/kill -s SIGTERM $MAINPID
TimeoutStopSec= 180

[Install]
WantedBy=default.target
EOF

# 设置自动启动
systemctl enable beacon
systemctl daemon-reload && systemctl restart beacon

```

#### 开放防火墙
- udp/12000 
- tcp/13000

### run validator

```shell
PRYSM_VERSION=${PRYSM_VERSION:-v3.1.1}
file=validator-${PRYSM_VERSION}-linux-amd64

# "下载"
mkdir -p "/data/ethereum/validator/prysm"
curl --silent -L "https://prysmaticlabs.com/releases/${file}" -o "/data/ethereum/validator/prysm/${file}"
chmod +x "/data/ethereum/validator/prysm/${file}"
rm -vf /data/ethereum/validator/validator && ln -s "/data/ethereum/validator/prysm/${file}" /data/ethereum/validator/validator
cd /data/ethereum/validator && ls -la

# "安装服务 validator.service"
cat <<"EOF" > /etc/systemd/system/validator.service
[Unit]
Description=validator
After=network.target

[Service]
LimitNOFILE=65535
Environment="WALLET_OPTS=--wallet-dir=/data/ethereum/validator/wallet --wallet-password-file=/data/ethereum/validator/wallet/pass"
Environment="FEE_OPTS=--suggested-fee-recipient=YOUR_ETH_ADDRESS"
Type=simple
User=root
Restart=always
RestartSec=12
ExecStart=/data/ethereum/prysm/validator $WALLET_OPTS $FEE_OPTS
ExecStop=/bin/kill -s SIGTERM $MAINPID
TimeoutStopSec= 180

[Install]
WantedBy=default.target
EOF

# 设置自动启动
systemctl enable validator
systemctl daemon-reload && systemctl restart validator
```
