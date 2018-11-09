### 域名后缀为.local无法解析问题

   发现以`.local`后缀域名通过dig/nslookup都正常返回，但是通过ping显示无效域名。 通过strace跟踪ping发现
```
connect(4, {sa_family=AF_LOCAL, sun_path="/var/run/avahi-daemon/socket"}, 110) = 0
fcntl(4, F_GETFL)                       = 0x2 (flags O_RDWR)
fstat(4, {st_mode=S_IFSOCK|0777, st_size=0, ...}) = 0
mmap(NULL, 4096, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0) = 0x7fa10eed7000
write(4, "RESOLVE-HOSTNAME-IPV4 kibana.log"..., 44) = 44
read(4, "-15 Timeout reached\n", 4096)  = 20
close(4)                                = 0
munmap(0x7fa10eed7000, 4096)            = 0
open("/usr/share/locale/locale.alias", O_RDONLY|O_CLOEXEC) = 4
fstat(4, {st_mode=S_IFREG|0644, st_size=2502, ...}) = 0
mmap(NULL, 4096, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0) = 0x7fa10eed7000
read(4, "# Locale name alias data base.\n#"..., 4096) = 2502
read(4, "", 4096)                       = 0
close(4)                                = 0
munmap(0x7fa10eed7000, 4096)            = 0
open("/usr/share/locale/zh_CN.utf8/LC_MESSAGES/libc.mo", O_RDONLY) = -1 ENOENT (No such file or directory)
open("/usr/share/locale/zh_CN/LC_MESSAGES/libc.mo", O_RDONLY) = 4
fstat(4, {st_mode=S_IFREG|0644, st_size=81139, ...}) = 0
mmap(NULL, 81139, PROT_READ, MAP_PRIVATE, 4, 0) = 0x7fa10eec4000
close(4)                                = 0
open("/usr/lib64/gconv/gconv-modules.cache", O_RDONLY) = 4
fstat(4, {st_mode=S_IFREG|0644, st_size=26254, ...}) = 0
mmap(NULL, 26254, PROT_READ, MAP_SHARED, 4, 0) = 0x7fa10eebd000
```

最后没有发送到dns上，而是发送本地avahi-daemon去解析这个域名。 所有解释失败。可以通过修改下面配置`/etc/avahi/avahi-daemon.conf`
```
[server]
#host-name=foo
domain-name=alocal
```

把`local`修改为`alocal`， 遇到`local`后缀域名就发送dns服务器去解析。


### avahi-daemon 配置

`avahi-daemon`是linux上`mDNS`(多播 DNS)一个开源实现, 是`mDNS`也是(Bonjour 的一部分，可在 Mac OS 上找到). `mDNS`允许系统在局域网中广播查询其他资源的名称, mDNS 允许你按名称与多个系统通信 —— 多数情况下不用路由器。你也不必在所有本地系统上同步类似 /etc/hosts 之类的文件。本文介绍如何设置它.



可以通过配置avahi-daemon.conf主机名称，以及域名
```
vim /etc/avahi/avahi-daemon.conf

[SERVER]
# 默认情况mDNS使用hostname-set主机名称，这个项目不用配置
# host-name=

# 主机域名(后缀)，默认`.local`. 设置默认域名avahi-daemon尝试在LAN中注册其主机名和服务。例如主机名叫abc， 在mDNS注册abc.local. 如果遇到.local后缀通过mDNS搜索。 
# 由于我们k8s内部域名是`.local`结尾默认通过mDNS搜索. 为了避免冲突可以使用其它域名例如alocal
domain-name=alocal
```   

hostname解析顺序可以通过下面的文件进行配置
```
vim /etc/nsswitch.conf
hosts:      files mdns4_minimal [NOTFOUND=return] dns myhostname 
```

我这台机器就是上面配置
- 优先使用文件dns(/etc/hosts).
- mdns4_minimal(mDNS), 如果mDNS返回NOTFOUND, ping就会结束域名解析，返回无效域名错误。当然可以配置为[NOTFOUND=continue], 但是消耗首次ping时间.
- 发送到远端dns服务器.
- 最后查看我的主机名称.

如果不需要mDNS可以把`mdns4_minimal`去掉。
