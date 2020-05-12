## 更换证书

整体步骤如下：

- 生成证书(参见下面)

- 删除所有空间下的serviceaccount/default

  ```sh
  kubectl get ns
  kubectt delete sa/default -n xxx
  ```

- 删除kube-system空间下的以下kube-apiserver-xxx、kube-controller-manager-xxx、kube-proxy-xxx、weave-net-xxx

  ```sh
  kubectl -n kube-system get po
  kubectl -n kube-system delete po/<pod名称>
  ```
- 验证

  ```sh
  #测试serviceaccount是否生效
  kubectl run --rm -i -t centos --image=centos -- bash
  KUBE_TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
  curl -sSk -H "Authorization: Bearer $KUBE_TOKEN" \    https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_PORT_443_TCP_PORT/api/v1/namespaces/default/pods/$HOSTNAME
  ```
  

### apiserver证书

```sh
#指定 MASTER 的IP
export MASTER_IP=<MASTER_IPV4>
tee openssl.cnf << EOF
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names
[alt_names]
DNS.1 = kubernetes
DNS.2 = kubernetes.default
DNS.3 = kubernetes.default.svc
DNS.4 = kubernetes.default.svc.cluster.local
IP.1 = ${MASTER_IP}
IP.2 = 10.96.0.1
EOF

#生成密钥
openssl genrsa -out apiserver-key.pem 2048

#生成证书
openssl req -new \
	-key apiserver-key.pem \
	-out apiserver.csr \
	-subj "/CN=kube-apiserver" \
	-config openssl.cnf

#使用CA签发证书
openssl x509 -req \
	-in apiserver.csr \
	-CA ca.pem \
	-CAkey ca-key.pem \
	-CAcreateserial \
	-out apiserver.pem \
	-days 3650 \
	-extensions v3_req \
	-extfile openssl.cnf

#覆盖原来的的apiserver证书
cp -f apiserver.* /etc/kubernetes/pki/
```

### admin证书

```sh
#生成密钥
openssl genrsa -out admin-key.pem 2048  
#生成证书
openssl req -new -key admin-key.pem -out admin.csr -subj "/CN=kube-admin"  
#使用CA签发证书
openssl x509 -req \
	-in admin.csr \
	-CA ca.pem \
	-CAkey ca-key.pem -CAcreateserial \
	-out admin.pem \
	-days 3650
```

### 节点证书

```sh
tee worker-openssl.cnf << EOF
req_extensions = v3_req  
distinguished_name = req_distinguished_name  
[req_distinguished_name]  
[ v3_req ]  
basicConstraints = CA:FALSE  
keyUsage = nonRepudiation, digitalSignature, keyEncipherment  
subjectAltName = @alt_names  
[alt_names]  
IP.1 = \$ENV::WORKER_IP
EOF

export WORKER_IP=<WORKER_IPV4>
export WORKER_HOSTNAME=<WORKER_HOSTNAME>
openssl genrsa -out "kubelet-${WORKER_HOSTNAME}-key.pem" 2048
openssl req -new \
	-key "kubelet-${WORKER_HOSTNAME}-key.pem" \
	-out "kubelet-${WORKER_HOSTNAME}.csr" \
	-subj "/O=system:nodes/CN=system:node:${WORKER_HOSTNAME}" \
	-config worker-openssl.cnf
openssl x509 -req \
	-in "kubelet-${WORKER_HOSTNAME}.csr" \
	-CA ca.pem \
	-CAkey ca-key.pem -CAcreateserial \
	-out "kubelet-${WORKER_HOSTNAME}.pem" \
	-days 3650 \
	-extensions v3_req \
	-extfile worker-openssl.cnf

openssl x509  -noout -text -in "kubelet-${WORKER_HOSTNAME}.pem"
```

## GC

```sh
#!/bin/bash

# Remove all the dangling images
docker rmi $(docker images -qf "dangling=true")

# Get all the images currently in use
USED_IMAGES=($( \
    docker ps -a --format '{{.Image}}' | \
    sort -u | \
    uniq | \
    awk -F ':' '$2{print $1":"$2}!$2{print $1":latest"}' \
))

# Get all the images currently available
ALL_IMAGES=($( \
    docker images --format '{{.Repository}}:{{.Tag}}' | \
    sort -u \
))

# Remove the unused images
for i in "${ALL_IMAGES[@]}"; do
    UNUSED=true
    for j in "${USED_IMAGES[@]}"; do
        if [[ "$i" == "$j" ]]; then
            UNUSED=false
        fi
    done
    if [[ "$UNUSED" == true ]]; then
        docker rmi "$i"
    fi
done
```

## Evicted 

```sh
kubectl get pods | grep Evicted | awk '{print $1}' | xargs kubectl delete pod
```



## Terminating

删除namespace后，出现namespace一直处于Terminating状态

```sh
#导出名称空间对象描述
kubectl get namespace <ns> -o json > tmp.json
#修改状态
vi tmp.json
#删除spec中的内容

#开启另一个窗口
kubectl proxy --port=8081

#调用api更新namespace对象
curl -k -H "Content-Type: application/json" -X PUT --data-binary @tmp.json http://127.0.0.1:8081/api/v1/namespaces/<ns>/finalize
```

## 获取kubeadm join 命令

```sh
#master
kubeadm token create --config kubeadm.yaml --print-join-command

```

## networks have same bridge namer

```sh
 ip link del docker0 && rm -rf /var/docker/network/* && mkdir -p /var/docker/network/files
 systemctl start docker
 # delete all containers
 docker rm -f $(docker ps -a -q)
```

## master node->work load

```sh
$ kubectl taint nodes --all dedicated-
$ kubectl taint nodes kuben1 kube
```

## node ->  unschedulable

```sh
$ kubectl taint nodes kuben-master dedicated=master:NoSchedule
```

## reset

```sh
$ kubeadm reset
$ rm /var/etcd/ -rf
$ docker rm -f $(docker ps -a -q)
```

## 维护

```sh
kubectl cordon kube-worker1
kubectl drain --ignore-daemonsets kube-worker1
kubectl uncordon kube-worker1
```



## [参考](https://github.com/kelseyhightower/kubernetes-the-hard-way/issues/248)

### kubectl -> apiserver interaction

```sh
e.g. kubectl get pods

In this case, we have a Client CA signing certificates for the human users and a Server CA signing the API server certificate.


          +------------+                           +------------+
          | Server CA  |                           | Client CA  |
          +-+----------+                           +-+----------+
            ^                                        ^
            |                                        |
            | Can I trust server.pem?                | Can I trust client.pem?
            |                                        |
            |                        tcp port :6443  |
        +---+-----------+   client.pem           +---+-----------+
        |               | +--------------------> |               |
        |    kubectl    |                        |   API Server  |
        |               | <--------------------+ |               |
        +---------------+      server-cert.pem   +---------------+

kubeconfig                                      kube-apiserver
 certificate-authority: ca.pem                   --client-ca-file=client-ca.pem
 client-certificate: client.pem                  --tls-cert-file=server.pem
 client-key: client-key.pem                      --tls-private-key-file=server-key.pem
                                                 --tls-ca-file= #NOT USED
                                                 --kubelet-certificate-authority= #NOT USED
                                                 --kubelet-client-certificate= #NOT USED
                                                 --kubelet-client-key= #NOT USED

					        kube-controller-manager
                                                 --root-ca-file=ca.pem
                                                 --cluster-signing-cert-file= #NOT USED
                                                 --cluster-signing-key-file=  #NOT USED	
openssl x509 -in server.pem -noout -issuer -subject
issuer= /C=IT/ST=Italy/L=Milan/CN=Server CA
subject= /CN=apiserver

openssl x509 -in client.pem -noout -issuer -subject
issuer= /CN=Client CA
subject= /O=system:masters/CN=admin
```

### kubelet -> apiserver interaction (no TLS bootstraapping)

```sh
e.g. worker node registration
In this case, in addition to the CAs above, we create another CA signing certificates for the worker nodes. Since we have now two CAs on the API server, we bundle them in a single file cat client-ca.pem > bundle-ca.pem && and cat worker-ca.pem >> bundle-ca.pem and set --client-ca-file=bundle-ca.pem on the API server

          +------------+                           +------------+
          | Server CA  |                           | Worker CA  |
          +-+----------+                           +-+----------+
            ^                                        ^
            |                                        |
            | Can I trust server.pem?                | Can I trust kubelet.pem?
            |                                        |
            |                         tcp port :6443 |
        +---+-----------+   kubelet.pem          +---+-----------+
        |               | +--------------------> |               |
        |    kubelet    |                        |   API Server  |
        |               | <--------------------+ |               |
        +---------------+      server.pem        +---------------+

kubelet
 --kubeconfig=/var/lib/kubelet/kubeconfig
 
kubeconfig                                      kube-apiserver
 certificate-authority: ca.pem                   --client-ca-file=bundle-ca.pem #bundle-ca.pem contains both client-ca.pem and worker-ca.pem
 client-certificate: kubelet.pem                 --tls-cert-file=server.pem
 client-key: kubelet-key.pem                     --tls-private-key-file=server-key.pem
                                                 --tls-ca-file= #NOT USED
                                                 --kubelet-certificate-authority= #NOT USED
                                                 --kubelet-client-certificate= #NOT USED
                                                 --kubelet-client-key= #NOT USED

					        kube-controller-manager
                                                 --root-ca-file=ca.pem
                                                 --cluster-signing-cert-file= #NOT USED
                                                 --cluster-signing-key-file=  #NOT USED	

openssl x509 -in server.pem -noout -issuer -subject
issuer= /C=IT/ST=Italy/L=Milan/CN=Server CA
subject= /CN=apiserver

openssl x509 -in kubelet.pem -noout -issuer -subject
issuer= /CN=Worker CA
subject= /O=system:nodes/CN=system:kubelet
```

### apiserver -> kubelet interaction

```sh
e.g. kubectl exec -it pod /bin/bash

In this case, we still use the Server CA to sign certificates in requests from the API server to the kubelet HTTPS services on TCP port 10255, eg. when users issue kubectl exec -it pod /bin/bash commands. My question here: is still this interaction a two-way TLS authentication handshake? i.e. the kubelet and the API server authenticate each other? Or only the API (server) client certificate kubelet-client.pem is authenticated by the kubelet server?

          +------------+                             +------------+
          | Server CA  |                             | Worker CA  |
          +-+----------+                             +-+----------+
            ^                                          ^
            |                                          |
            | Can I trust kubelet-client.pem?          | Can I trust kubelet.pem?
            |                                          |
            |         tcp port:10255                   |
        +---+-----------+       kubelet-client.pem +---+-----------+
        |               | <----------------------+ |               |
        |    kubelet    |                          |   API Server  |
        |               | +----------------------> |               |
        +---------------+  kubelet.pem             +---------------+
                           ^
                           | is it a two-way authentication?

kubelet
 --kubeconfig=/var/lib/kubelet/kubeconfig
 --anonymous-auth=false
 --client-ca-file=ca.pem
 
kubeconfig                                      kube-apiserver
 certificate-authority: ca.pem                   --client-ca-file=bundle-ca.pem # bundle-ca.pem contains both the client-ca.pem and the worker-ca.pem
 client-certificate: kubelet.pem                 --tls-cert-file=server.pem
 client-key: kubelet-key.pem                     --tls-private-key-file=server-key.pem
                                                 --tls-ca-file= #NOT USED
                                                 --kubelet-certificate-authority= #NOT USED
                                                 --kubelet-client-certificate=kubelet-client.pem
                                                 --kubelet-client-key=kubelet-client-key.pem

					        kube-controller-manager
                                                 --root-ca-file=ca.pem
                                                 --cluster-signing-cert-file= #NOT USED
                                                 --cluster-signing-key-file=  #NOT USED	

openssl x509 -in kubelet-client.pem -noout -issuer -subject
issuer= /C=IT/ST=Italy/L=Milan/CN=Server CA
subject= /O=system:masters/CN=kubelet-client

openssl x509 -in kubelet.pem -noout -issuer -subject
issuer= /CN=Worker CA
subject= /O=system:nodes/CN=system:kubelet

```

