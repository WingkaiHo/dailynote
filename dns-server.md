### dnsmasq 
DNSmasq是一个小巧且方便地用于配置DNS和DHCP的工具，适用于小型网络，它提供了DNS功能和可选择的DHCP功能。自己搭建公共DNS更加灵活，如果是在本地搭建，还可以大幅提高解析速度。 相比较BIND那复杂的配置来说，dnsmasq绝对轻量多了。

### dnsmasq安装和配置
```
$ yum install -y dnsmasq
```

配置dns服务
```
#指定上游dns服务器
resolv-file=/etc/resolv.dnsmasq.conf
#表示严格按照 resolv-file 文件中的顺序从上到下进行 DNS 解析, 直到第一个成功解析成功为止
strict-order
# 开启后会寻找本地的hosts文件在去寻找缓存的域名，最后到上游dns查找
#no-resolv
listen-address=0.0.0.0 #0.0.0.0 设置为公网IP
```

### 添加域名
编辑`/etc/hosts` 文件添加域名支持

例如添加本地服务例如
```
192.168.10.12 user.authentication.local
192.168.10.13 service.mysql.local
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
