# RabbitMQ

## install

**docker compose**


### node1
```sh
mkdir -p /opt/rabbit

cat <<EOF >  /opt/rabbit/docker-compose.yaml
version: '3'
services:
  mq1:
    image: rabbitmq:3-management
    container_name: rabbitmq1
    hostname: rabbit_mq1
    ports:
    - "4369:4369"
    - "5671:5671"
    - "5672:5672"
    - "15671:15671"
    - "15672:15672"
    - "25672:25672"
    extra_hosts:
    - "rabbit_mq1:172.16.2.116"
    - "rabbit_mq2:172.16.2.117"
    - "rabbit_mq3:172.16.2.118"
    volumes:
    - /opt/rabbit/lib:/var/lib/rabbitmq
    - /opt/rabbit/log:/var/log/rabbitmq
    - /opt/rabbit/rabbitmq-ram.sh:/opt/rabbitmq/rabbitmq-ram.sh
    restart: always
    environment:
    - RABBITMQ_DEFAULT_USER=admin
    - RABBITMQ_DEFAULT_PASS=1234
    - RABBITMQ_ERLANG_COOKIE=CURIOAPPLICATION
    - RABBITMQ_NODENAME:rabbitmq1
EOF

cat <<EOF >  /opt/rabbit/rabbitmq-ram.sh
rabbitmqctl stop_app
rabbitmqctl reset
rabbitmqctl start_app
EOF

cd /opt/rabbitmq
docker compose up -d
docker exec -it rabbitmq1  sh /opt/rabbitmq/rabbitmq-ram.sh

```

### node2

```sh
cat <<EOF >  /opt/rabbit/docker-compose.yaml
version: '3'
services:
  mq1:
    image: rabbitmq:3-management
    container_name: rabbitmq2
    hostname: rabbit_mq2
    ports:
    - "4369:4369"
    - "5671:5671"
    - "5672:5672"
    - "15671:15671"
    - "15672:15672"
    - "25672:25672"
    extra_hosts:
    - "rabbit_mq1:172.16.2.116"
    - "rabbit_mq2:172.16.2.117"
    - "rabbit_mq3:172.16.2.118"
    volumes:
    - /opt/rabbit/lib:/var/lib/rabbitmq
    - /opt/rabbit/log:/var/log/rabbitmq
    - /opt/rabbit/rabbitmq-ram.sh:/opt/rabbitmq/rabbitmq-ram.sh
    restart: always
    environment:
    - RABBITMQ_DEFAULT_USER=admin
    - RABBITMQ_DEFAULT_PASS=1234
    - RABBITMQ_ERLANG_COOKIE=CURIOAPPLICATION
    - RABBITMQ_NODENAME:rabbit_mq2
EOF

cat <<EOF >  /opt/rabbit/rabbitmq-ram.sh
rabbitmqctl stop_app
rabbitmqctl join_cluster --ram rabbit@rabbit_mq1
rabbitmqctl start_app
EOF

# 启动并加入集群
cd /opt/rabbitmq
docker compose up -d
docker exec -it rabbitmq2  sh /opt/rabbitmq/rabbitmq-ram.sh
```

### node3

```sh

cat <<EOF >  /opt/rabbit/docker-compose.yaml
version: '3'
services:
  mq1:
    image: rabbitmq:3-management
    container_name: rabbitmq3
    hostname: rabbit_mq3
    ports:
    - "4369:4369"
    - "5671:5671"
    - "5672:5672"
    - "15671:15671"
    - "15672:15672"
    - "25672:25672"
    extra_hosts:
    - "rabbit_mq1:172.16.2.116"
    - "rabbit_mq2:172.16.2.117"
    - "rabbit_mq3:172.16.2.118"
    volumes:
    - /opt/rabbit/lib:/var/lib/rabbitmq
    - /opt/rabbit/log:/var/log/rabbitmq
    - /opt/rabbit/rabbitmq-ram.sh:/opt/rabbitmq/rabbitmq-ram.sh
    restart: always
    environment:
    - RABBITMQ_DEFAULT_USER=admin
    - RABBITMQ_DEFAULT_PASS=1234
    - RABBITMQ_ERLANG_COOKIE=CURIOAPPLICATION
    - RABBITMQ_NODENAME:rabbit_mq3
EOF

cat <<EOF >  /opt/rabbit/rabbitmq-ram.sh
rabbitmqctl stop_app
rabbitmqctl join_cluster --ram rabbit@rabbit_mq1
rabbitmqctl start_app
EOF

# 启动并加入集群
cd /opt/rabbitmq
docker compose up -d
docker exec -it rabbitmq3 sh /opt/rabbitmq/rabbitmq-ram.sh
```