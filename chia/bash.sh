#kubectl 批量更改node 节点标签
kubectl get nodes | awk '{print $1}' | xargs -I {} kubectl label node {} hpool-
kubectl get nodes |  awk '{print $1}' | xargs -I {} kubectl label node {} hpool-miner=true
