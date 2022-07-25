# ETH2


## run ropsten


### run execution client
```shell
mkdir -p /data/eth2/

GETH_VERSION=${GETH_VERSION:-geth-linux-amd64-1.10.19-23bee162}

# "下载"
curl -sSL "https://gethstore.blob.core.windows.net/builds/${GETH_VERSION}.tar.gz" | tar -xz
rm -vf /data/eth2/geth && ln -s /data/eth2/${GETH_VERSION} /data/eth2/geth
ls -la

# "安装服务 geth.service"
cat <<"EOF" > /etc/systemd/system/geth.service
[Unit]
Description=Geth
After=network.target

[Service]
LimitNOFILE=65535
Environment="GETH_API_OPTS=--http --http.addr 0.0.0.0 --http.port 8545 --http.vhosts *"
Environment="GETH_ETHASH_OPTS=--ethash.dagdir /data/eth2/el/dag"
Environment="GETH_METRICS_OPTS=--metrics --metrics.addr 0.0.0.0 --metrics.port 6060"
Environment="GETH_EXTRA_OPTS=--datadir /data/eth2/el --syncmode full"
Environment="GETH_MERGE_OPTS=--override.terminaltotaldifficulty 50000000000000000 --authrpc.addr 0.0.0.0 --authrpc.port 8551 --authrpc.vhosts "*" "

Type=simple
User=root
Restart=always
RestartSec=12
ExecStart=/data/eth2/geth/geth --ropsten $GETH_MERGE_OPTS $GETH_API_OPTS $GETH_NETWORK_OPTS $GETH_MINE_OPTS $GETH_ETHASH_OPTS $GETH_METRICS_OPTS $GETH_EXTRA_OPTS
ExecStop=/bin/kill -s SIGTERM $MAINPID
TimeoutStopSec= 180

[Install]
WantedBy=default.target
EOF

# 设置自动启动
systemctl enable geth
systemctl daemon-reload && systemctl restart geth
```
### run **beacon node**
```shell
PRYSM_VERSION=${PRYSM_VERSION:-v2.1.3}

# "下载"
mkdir -p "/data/eth2/prysm-${PRYSM_VERSION}"
curl -sSL -o "/data/eth2/prysm-${PRYSM_VERSION}/beacon-chain"  "https://github.com/prysmaticlabs/prysm/releases/download/${PRYSM_VERSION}/beacon-chain-${PRYSM_VERSION}-linux-amd64"
chmod +x "/data/eth2/prysm-${PRYSM_VERSION}/beacon-chain"
rm -vf /data/eth2/prysm && ln -s /data/eth2/prysm-${PRYSM_VERSION} /data/eth2/prysm

curl -sSL -o "/data/eth2/genesis.ssz" "https://github.com/eth-clients/merge-testnets/raw/main/ropsten-beacon-chain/genesis.ssz"

ls -la

# "安装服务 beacon.service"
cat <<"EOF" > /etc/systemd/system/beacon.service
[Unit]
Description=beacon-node
After=network.target

[Service]
LimitNOFILE=65535
Environment="EL_OPTS=--http-web3provider=http://127.0.0.1:8551 --jwt-secret=/data/eth2/el/geth/jwtsecret"
Environment="CL_OPTS=--rpc-host=0.0.0.0 --monitoring-host=0.0.0.0 --genesis-state=/data/eth2/genesis.ssz --datadir=/data/eth2/cl"
Environment="FEE_OPTS=--suggested-fee-recipient=YOUR_ETH_ADDRESS"
Type=simple
User=root
Restart=always
RestartSec=12
ExecStart=/data/eth2/prysm/beacon-chain --ropsten $FEE_OPTS $CL_OPTS $EL_OPTS
ExecStop=/bin/kill -s SIGTERM $MAINPID
TimeoutStopSec= 180

[Install]
WantedBy=default.target
EOF

# 设置自动启动
systemctl enable beacon
systemctl daemon-reload && systemctl restart beacon
```


### run validator

```shell
PRYSM_VERSION=${PRYSM_VERSION:-v2.1.3}

# "下载"
mkdir -p "/data/eth2/prysm-${PRYSM_VERSION}"
curl -sSL -o "/data/eth2/prysm-${PRYSM_VERSION}/validator"  "https://github.com/prysmaticlabs/prysm/releases/download/${PRYSM_VERSION}/validator-${PRYSM_VERSION}-linux-amd64"
chmod +x "/data/eth2/prysm-${PRYSM_VERSION}/validator"
rm -vf /data/eth2/prysm && ln -s /data/eth2/prysm-${PRYSM_VERSION} /data/eth2/prysm
ls -la

# "安装服务 validator.service"
cat <<"EOF" > /etc/systemd/system/validator.service
[Unit]
Description=validator
After=network.target

[Service]
LimitNOFILE=65535
Environment="WALLET_OPTS=--wallet-dir=/data/eth2/validator/wallet --wallet-password-file=/data/eth2/validator/wallet/pass"
Environment="FEE_OPTS=--suggested-fee-recipient=YOUR_ETH_ADDRESS"
Type=simple
User=root
Restart=always
RestartSec=12
ExecStart=/data/eth2/prysm/validator --ropsten  $WALLET_OPTS $FEE_OPTS
ExecStop=/bin/kill -s SIGTERM $MAINPID
TimeoutStopSec= 180

[Install]
WantedBy=default.target
EOF

# 设置自动启动
systemctl enable validator
systemctl daemon-reload && systemctl restart validator
```
