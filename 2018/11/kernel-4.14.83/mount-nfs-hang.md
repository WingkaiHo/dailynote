#### mount.nfs 进程挂死问题
   
由于kernel-ml-elrepo-4.18.15 gpu机器k8s训练的时候，内核崩溃问题(进程调度队列被破坏), 由于cilium网络需要使用4.8以上内核，使用kernel离开4.18最近的
4.14.83 LTS版本内核。

**mount进程挂死**

pod 总是处于创建状态
```
$ kubectl get pod 
NAME                      READY     STATUS              RESTARTS   AGE
test-nfs   0/1       ContainerCreating   0          5m
```

pod对应node节点
```
$ ps -ef | grep mount
root     18155 33543  0 14:46 ?        00:00:00 /usr/bin/mount -t nfs 192.168.0.12:/exports_data /var/lib/kubelet/pods/91055960-f3a2-11e8-ae69-44a84246e955/volumes/kubernete
s.io~nfs/data-c12
root     18156 33543  0 14:46 ?        00:00:00 /usr/bin/mount -t nfs 192.168.1.90:/exports_data /var/lib/kubelet/pods/91055960-f3a2-11e8-ae69-44a84246e955/volumes/kubernetes
.io~nfs/data-c90
root     18157 33543  0 14:46 ?        00:00:00 /usr/bin/mount -t nfs 192.168.1.94:/exports_data /var/lib/kubelet/pods/91055960-f3a2-11e8-ae69-44a84246e955/volumes/kubernetes
.io~nfs/data-c94
root     18175 18157  0 14:46 ?        00:00:00 /sbin/mount.nfs 192.168.1.94:/exports_data /var/lib/kubelet/pods/91055960-f3a2-11e8-ae69-44a84246e955/volumes/kubernetes.io~nf
s/data-c94 -o rw
root     18178 18156  0 14:46 ?        00:00:00 /sbin/mount.nfs 192.168.1.90:/exports_data /var/lib/kubelet/pods/91055960-f3a2-11e8-ae69-44a84246e955/volumes/kubernetes.io~nf
s/data-c90 -o rw
root     18181 18155  0 14:46 ?        00:00:00 /sbin/mount.nfs 192.168.0.12:/exports_data /var/lib/kubelet/pods/91055960-f3a2-11e8-ae69-44a84246e955/volumes/kubernetes.io~n
fs/data-c12 -o rw
```

由于训练pod需要同时挂比较多盘，kubelet go使用异步挂载nfs的，同时发起所有挂载命令。


#### 解决方法

k8s不提供-o nfs 配置选项，所有只能通过`/etc/nfsmount.conf` 默认配置:

**尝试nolock**

```
# Enable File Locking
Lock=False
```

多次测试发现，解决一部分， 例如同时挂载5个，有两个挂成功， 但是有3个hang住了, 不能玩全解决问题。暂时去掉这个选项.

**尝试修改nfs默认版本**


**使用v3版本**
```
# Protocol Version [2,3,4]
# This defines the default protocol version which will
# be used to start the negotiation with the server.
Defaultvers=3
```

多次测试发现在同一台机器创建pod, 都不会出现mount.nfs进程hang住问题。由于v3版本比较旧， 做为是一个备用方案。

**使用v4.0版本**

通过`mount.nfs`打印挂载过程，可以看到下面日志
```
mount.nfs: timeout set for Thu Nov 29 16:13:32 2018
mount.nfs: trying text-based options vers=4.1,addr=192.168.0.17,clientaddr=192.168.1.70
```

尝试是否能够支持4.0
```
# Protocol Version [2,3,4]
# This defines the default protocol version which will
# be used to start the negotiation with the server.
Defaultvers=4.0
```

通过测试发现， 可以解决这个问题.


**总结**

配置`/etc/nfsmount.conf`
```
# Protocol Version [2,3,4]
# This defines the default protocol version which will
# be used to start the negotiation with the server.
Defaultvers=4.0
```
