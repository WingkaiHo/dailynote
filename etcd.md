### 修改etcd对应键值

下面修改根目录下的创建heyongjia, 为`hello word`
curl http://100.64.16.110:2379/v2/keys/heyongjia -XPUT -d value="Hello world"
{"action":"set","node":{"key":"/heyongjia","value":"Hello world","modifiedIndex":12,"createdIndex":12}} 

### 获取对应键值
curl http://100.64.16.110:2379/v2/keys/heyongjia -XGET
{"action":"get","node":{"key":"/heyongjia","value":"Hello world","modifiedIndex":12,"createdIndex":12}}

### 创建目录(123/123)
curl -s http://100.64.16.110:2379/v2/keys/123/123 -XPUT -d dir=true

### 列出目录所有信息
curl http://100.64.16.110:2379/v2/keys/
{"action":"get","node":{"dir":true,"nodes":[{"key":"/diu","value":"666","modifiedIndex":8,"createdIndex":8},{"key":"/tony","dir":true,"modifiedIndex":5,"createdIndex":5},{"key":"/heyongjia","value":"Hello world","modifiedIndex":12,"createdIndex":12},{"key":"/123","dir":true,"modifiedIndex":13,"createdIndex":13}]}}

curl http://100.64.16.110:2379/v2/keys/123/123
{"action":"get","node":{"key":"/123/123","dir":true,"modifiedIndex":13,"createdIndex":13}}

按顺序列出所有创建的有序键。

列举根目录所有键
curl -s 'http://100.64.16.110:2379/v2/keys/?recursive=true&sorted=true'
{"action":"get","node":{"dir":true,"nodes":[{"key":"/123","dir":true,"nodes":[{"key":"/123/123","dir":true,"modifiedIndex":13,"createdIndex":13}],"modifiedIndex":13,"createdIndex":13},{"key":"/diu","value":"666","modifiedIndex":8,"createdIndex":8},{"key":"/heyongjia","value":"Hello world","modifiedIndex":12,"createdIndex":12},{"key":"/tony","dir":true,"nodes":[{"key":"/tony/hong","value":"a","modifiedIndex":6,"createdIndex":6}],"modifiedIndex":5,"createdIndex":5}]}}

列举heyongjia目录所有键
curl -s 'http://100.64.16.110:2379/v2/keys/heyongjia?recursive=true&sorted=true'
{"action":"get","node":{"key":"/heyongjia","value":"Hello world","modifiedIndex":12,"createdIndex":12}}


删除目录：默认情况下只允许删除空目录，如果要删除有内容的目录需要加上recursive=true参数。
1
curl 'http://127.0.0.1:2379/v2/keys/foo_dir?dir=true' -XDELETE
　　

创建一个隐藏节点：命名时名字以下划线_开头默认就是隐藏键。
1
curl http://127.0.0.1:2379/v2/keys/_message -XPUT -d value="Hello hidden world"


对键值修改进行监控：etcd提供的这个API让用户可以监控一个值或者递归式的监控一个目录及其子目录的值，当目录或值发生变化时，etcd会主动通知。
curl http://100.64.16.110:2379/v2/keys/heyongjia?wait=true
对键值监控，直到此值改变以后，获取并且退出


curl http://100.64.16.110:2379/v2/keys/heyongjia -XPUT -d value="hi"
{"action":"set","node":{"key":"/heyongjia","value":"hi","modifiedIndex":17,"createdIndex":17},"prevNode":{"key":"/heyongjia","value":"Hello world","modifiedIndex":16,"createdIndex":16}}

export ETCDCTL_API=3
etcdctl --endpoints=${ETCD_ENDPOINTS} --cacert=/etc/ssl/etcd/ssl/ca.pem --cert=/etc/ssl/etcd/ssl/node-k8s-1.pem --key=/etc/ssl/etcd/ssl/node-k8s-1-key.pem  get /registry --keys-only  --prefix


The allocation CIDR is different from the previous cilium instance. This error is most likely caused by a temporary network disruption to the kube-apiserver that prevent Cilium from retrieve the node's IPv4/IPv6 allocation range. If you believe the allocation range is supposed to be different you need to clean up all Cilium state with the `cilium cleanup` command on this node. Be aware this will cause network disruption for all existing containers managed by Cilium running on this node and you will have to restart them." error="Unable to allocate internal IPv4 node IP 10.234.2.1: provided IP is not in the valid range. The range of valid IPs is 10.234.0.0/24." subsys=daemon

