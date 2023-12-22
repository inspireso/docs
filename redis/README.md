# redis

## install

### docker compose cluster

部署集群至少需要 6 个节点，三个主节点，三个从节点。

#### 所有节点运行 redis-server

```sh
mkdir -p /opt/redis/conf

cat <<EOF >  /opt/redis/conf/redis.conf
port 6379
cluster-enabled yes
cluster-config-file nodes.conf
cluster-node-timeout 5000
appendonly yes
bind 0.0.0.0
EOF

cat <<EOF >  /opt/redis/docker-compose.yaml
version: '3'
services:
  server:
    restart: always
    network_mode: "host"
    image: redis:7.2
    command: ["redis-server", "/usr/local/etc/redis/redis.conf"]
    ports:
      - '6379:6379'
    volumes:
      - /opt/redis/conf/redis.conf:/usr/local/etc/redis/redis.conf
      - /opt/redis/data:/data
EOF

cd /opt/redis/
docker compose up -d 

```

#### 创建集群

假设所有节点列表ip 如下：

- node1: 192.168.0.11
- node2: 192.168.0.12
- node3: 192.168.0.13
- node4: 192.168.0.14
- node5: 192.168.0.15
- node6: 192.168.0.16


```sh
# 创建集群, --cluster-replicas 1 表示每个主节点有一个从节点
docker exec -it redis_server_1 redis-cli --cluster create \
    192.168.0.11:6379 \
    192.168.0.12:6379 \
    192.168.0.13:6379 \
    192.168.0.14:6379 \
    192.168.0.15:6379 \
    192.168.0.16:6379 \
    --cluster-replicas 1
```
