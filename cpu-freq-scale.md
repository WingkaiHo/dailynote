### centos7 配置开机默认开启cpu性能模式

  使用ib网卡，启动连接默认以后，cpu在高性能模式下可以得到更高响应速度，更快传说效果，建议服务器默认工作状态都开启模式。

**系统启动cpu性能模式**
  启动性能模式可以通过下面命令启动, 需要确认主板已经开启性能默认
```
$sudo cpupower frequency-set --governor performance
```
  
**获取cpu频率**
  执行命令以后可以通过下面命令看效果, 在执行之前cpu和保持在1.2GHz， 执行后上2.0～2.5，看cpu实际情况
```
$ cpupower frequency-info
```

上面命令如果机器重新启动以后会失效果, 如果启动的时候默认打开通过cpupower服务

首先看下面变量配置
```
cat /etc/sysconfig/cpupower 
# See 'cpupower help' and cpupower(1) for more info
CPUPOWER_START_OPTS="frequency-set -g performance"
CPUPOWER_STOP_OPTS="frequency-set -g ondemand"
```

再看cpupower systemd配置
```
cat /usr/lib/systemd/system/cpupower.service

[Unit]
Description=Configure CPU power related settings
After=syslog.target

[Service]
Type=oneshot
RemainAfterExit=yes
EnvironmentFile=/etc/sysconfig/cpupower
ExecStart=/usr/bin/cpupower $CPUPOWER_START_OPTS
ExecStop=/usr/bin/cpupower $CPUPOWER_STOP_OPTS

[Install]
WantedBy=multi-user.target
```

所有当服务
1） 启动时候启动cpu性能模式
2） 关闭时候启动cpu省电模式


执行下面命令默认启动cpu性能模式
```
sudo systemctl enable cpupower.service
sudo systemctl start cpupower.service
```
