#! /bin/sh -x

BACKUP_FILE="$1"
echo "${BACKUP_FILE}"
source /etc/etcd.env 
ETCDCTL_API=3 etcdctl snapshot restore $BACKUP_FILE \
	--name $ETCD_NAME --initial-cluster "$ETCD_INITIAL_CLUSTER" \
	--initial-cluster-token "$ETCD_INITIAL_CLUSTER_TOKEN" \
	--initial-advertise-peer-urls $ETCD_INITIAL_ADVERTISE_PEER_URLS \
	--data-dir $ETCD_DATA_DIR 
