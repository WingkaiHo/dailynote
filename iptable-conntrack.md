在All-In-One机器/Test Server/Test Client上，均需要打开以下限制:    

#### 最大文件句柄数
```# vim /etc/security/limits.conf
* soft nofile 104857
* hard nofile 104857
```

#### 最大文件数限制
```
# vim /etc/sysctl.conffs.file-max=1048576
# sudo sysctl -p /etc/sysctl.conf
```

#### conntrack最大连接数
```
# vim /etc/sysctl.conf
   net.netfilter.nf_conntrack_max = 6553500
# sysctl -p /etc/sysctl.conf
```
