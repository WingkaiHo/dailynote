1. 配置graphie数据库节定时清理无用metrics

例如每个小时执行一次， 查找grapihe 目录下清理2天以上没有任何写入记录wsp文件
```
graphie_web$ vim /etc/graphie-cleanup-crontab

* */1 * * * /usr/bin/grapphie-auto-cleanup.sh /var/lib/docker/graphite/storage/whisper 2 
``` 

2. 拷贝脚本到grapphie-auto-cleanup.sh到`/usr/bin`目录
```
graphie_web$ cp grapphie-auto-cleanup.sh /usr/bin
```

3. 创建定时任务
```
graphie_web$ crontab /etc/graphie-cleanup-crontab
```
