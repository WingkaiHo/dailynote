## dnsmasq 
DNSmasq是一个小巧且方便地用于配置DNS和DHCP的工具，适用于小型网络，它提供了DNS功能和可选择的DHCP功能。自己搭建公共DNS更加灵活，如果是在本地搭建，还可以大幅提高解析速度。 相比较BIND那复杂的配置来说，dnsmasq绝对轻量多了。

### dnsmasq安装和配置
```
$ yum install -y dnsmasq
```

配置dns服务
```
no-poll
strict-order
#不读取系统hosts，读取你设定的
no-hosts
#dnsmasq日志设置
log-queries
log-facility=/var/log/dnsmasq.log
#dnsmasq缓存设置
cache-size=1024
#加入本机IP为内部全网使用, 注意不能写0.0.0.0
listen-address=192.168.0.1,127.0.0.1
#dns host-file读取路径，在线监听此目录更新
hostsdir=/etc/dnsmasq.d/
# 配置上游dns服务服务
resolv-file=/etc/resolv.dnsmasq.conf
```

### 添加域名
编辑`/etc/dnsmasq.d/dnsmasq.hosts` 文件添加域名支持

例如添加本地服务例如, 可以在线添加
```
192.168.10.12 user.authentication.local
192.168.10.13 service.mysql.local
```

### 添加上游dns
编辑`/etc/resolv.dnsmasq.conf` 文件添加上游dns
```
nameserver 114.114.114.114
```


### 启动/重新启动服务
配置开机启动服务
```
$systemctl enable dnsmasq.service
```
启动服务
```
$systemctl restart dnsmasq.service
```
