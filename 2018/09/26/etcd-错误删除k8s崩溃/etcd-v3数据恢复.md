### 集群数据丢失

   etcd集群数据由于错误操作丢失以后，只能通过备份恢复k8s操作，需要通过手工把etcd集群节点关闭，手工去恢复数据，再次启动集群。


### etcd备份命令

  etcd 备份可用通过定时任务执行项目脚本:
```

#! /bin/sh

export ETCDCTL_API=3
# etcd 节点信息
ETCD_ENDPOINTS="https://10.5.7.11:2379,https://10.5.7.12:2379,https://10.5.7.13:2379"
# ca根证书位置
CA_CERT="/etc/ssl/etcd/ssl/ca.pem"
# node节点证书位置
NODE_CERT="/etc/ssl/etcd/ssl/node-node1.pem"
# node节点证书key
NODE_KEY="/etc/ssl/etcd/ssl/node-node1-key.pem"
# 按照时间生成文件名称
TIME_CODE=`date '+%Y%m%d-%H%M%S'`
SNAPSHOT_FILE="etcd-snap-${TIME_CODE}.db"

etcdctl --endpoints=${ETCD_ENDPOINTS} --cacert=${CA_CERT} --cert=${NODE_CERT} --key=${NODE_KEY} snapshot save $SNAPSHOT_FILE 
```

### etcd 集群恢复数据步骤

  例如k8s环境etcd数据库有node1, node2, node3节点, 首先需要关闭etcd服务，备份/删除原来数据文件夹`/var/lib/etcd`

```
$ systemctl stop etcd
$ mv /var/lib/etcd/ /var/lib/etcd_bakup/
# etcd-snap-20180927-025254.db 是定时备份文件，需要拷贝各台机器上
$ etcd-restore.sh etcd-snap-20180927-025254.db 
```

etcd-restore.sh 脚本如下:
```
#! /bin/sh

BACKUP_FILE="$1"
echo "${BACKUP_FILE}"
# etcd.evn 是kubespray生成的的
source /etc/etcd.env 
ETCDCTL_API=3 etcdctl snapshot restore $BACKUP_FILE \
	--name $ETCD_NAME --initial-cluster "$ETCD_INITIAL_CLUSTER" \
	--initial-cluster-token "$ETCD_INITIAL_CLUSTER_TOKEN" \
	--initial-advertise-peer-urls $ETCD_INITIAL_ADVERTISE_PEER_URLS \
	--data-dir $ETCD_DATA_DIR 
```
  各个机器都执行以后，重新启动etcd服务，需要在各个节点执行下面命令启动服务

```
$systemctl restart etcd
```
