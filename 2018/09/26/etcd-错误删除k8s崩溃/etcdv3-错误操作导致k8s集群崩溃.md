## 背景

  部署一个公司内网coredns提供内部域名服务， coredns通过etcd k-v数据库保存域名，多个coredns共用同一套etcd集群提供高可用dns服务。当时设计coredns部署在k8s-master节点上，使用和k8s共用一套etcd环境.
  当时考虑：
  - k8s使用etcd目录值是: /registry
  - coredns使用etcd目录值：/coredns
  两者没有冲突， 不会产生什么影响。两者都是使用etcdv3api， 统一备份。手工部署etcd集群需要生成证书，维护比较麻烦。


### coredns 内部域名配置

  coredns没有提供面添加/删除域名， 需要通过手工命令操作etcd数据库，添加/删除域名

例如添加gcr.io 记录
```
添加host记录1：
$ sudo ETCDCTL_API=3 /usr/local/bin/etcdctl --endpoints=https://172.25.52.237:2379 \
  --cacert=/etc/ssl/etcd/ssl/ca.pem \
  --cert=/etc/ssl/etcd/ssl/member-gz-52-237.pem \
  --key=/etc/ssl/etcd/ssl/member-gz-52-237-key.pem \
  put /coredns/io/gcr/x1 '{"host":"172.25.52.217","ttl":60}'

# 添加host记录2
$ sudo ETCDCTL_API=3 /usr/local/bin/etcdctl --endpoints=https://172.25.52.237:2379 \
  --cacert=/etc/ssl/etcd/ssl/ca.pem \
  --cert=/etc/ssl/etcd/ssl/member-gz-52-237.pem \
  --key=/etc/ssl/etcd/ssl/member-gz-52-237-key.pem \
  put /coredns/io/gcr/x2 '{"host":"172.25.52.241","ttl":60}'
```

删除gcr.io记录
```
$ sudo ETCDCTL_API=3 /usr/local/bin/etcdctl --endpoints=https://172.25.52.237:2379 \
  --cacert=/etc/ssl/etcd/ssl/ca.pem \
  --cert=/etc/ssl/etcd/ssl/member-gz-52-237.pem \
  --key=/etc/ssl/etcd/ssl/member-gz-52-237-key.pem \
  del /coredns/io/gcr/x1
```

### k8s 节点销毁过程

   当时在调式cordns使用，修改dns配置，想实现多个ip负载均衡，需要修改和清理之前配置选项。etcd安全使用https证书，证书都是root权限才可以打开，命令操作很不方便。都使用复制粘贴执行命令, 下面命令多空格，本来想清理/coredns， 结果执行下面命令
```
sudo ETCDCTL_API=3 /usr/local/bin/etcdctl --endpoints=https://172.25.52.237:2379 \
  --cacert=/etc/ssl/etcd/ssl/ca.pem \
  --cert=/etc/ssl/etcd/ssl/member-gz-52-237.pem \
  --key=/etc/ssl/etcd/ssl/member-gz-52-237-key.pem \
  del / coredns
[368]
```

  执行命令以后，数据库瞬间就清空，如果没有备份。k8s整个集群信息都丢失，其它子节点可能根据数据库进行应用删除，pv删除操作，整个集群，以及上面部署应用，网络都有可能删除。发现集群有问题以后执行
```
$ kubectl get node

返回空
```

  对比etcd API v3,  API v2 版本命令行删除操作更加严格， 如果如果`/coredns`存在子项目，删除时候需要加`--recursive`, 否则返回错误。

```
ETCDCTL_API=2 etcdctl rm / --recursive
```


### 总结

  k8s主节点和etcd是整个集群核心, 里面包含集群信息，虚拟网络信息，应用部署信息能。这次事故由于我人工操作导致错误的，以后集群etcd数据需要避免下面情况:

- k8s etcd避免任何人工配置操作
- k8s etcd避免和其它应用共同使用, 防止应用bug导致数据库错删除操作。

在维护过程:
- 实现etcd节点高可用，机器需要分布不同机架。
- ETCD节点出现故障以后需要及时处理故障，如果机器故障无法修改替换节点。当半数以上节点失效以后需要人工恢复。
- 定时备份数据库。 

