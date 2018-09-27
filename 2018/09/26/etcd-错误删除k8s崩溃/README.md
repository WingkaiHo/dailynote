### etcd v3 删除命令比较危险

下面脚本就可以瞬间把k8s集群销毁

```
#! /bin/sh

export ETCDCTL_API=3
ETCD_ENDPOINTS="https://10.5.7.11:2379,https://10.5.7.12:2379,https://10.5.7.13:2379"
CA_CERT="/etc/ssl/etcd/ssl/ca.pem"
NODE_CERT="/etc/ssl/etcd/ssl/node-node1.pem"
NODE_KEY="/etc/ssl/etcd/ssl/node-node1-key.pem"

etcdctl --endpoints=${ETCD_ENDPOINTS} --cacert=${CA_CERT} --cert=${NODE_CERT} --key=${NODE_KEY} del / coredns
```

本来想删除/coredns目录，

中间加空格

把根目录所有记录都删除了
