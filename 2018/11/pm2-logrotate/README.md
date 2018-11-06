### PM2日志回滚配置

PM2日志回滚需要安装pm2-logrotate插件， 通过插件配置日志进行日志回滚防止日志占满目录。安装步骤如下:

**安装pm2-logrotate**
```
$ pm2 install pm2-logrotate 
```
pm2-logrotete安装以后默认自动启动。


**配置pm2日志回滚**

  通过环境变量配置日志回滚参数，配置以后`pm2-logrotate`重新启动， 立刻生效。
```
# 保留最近7份日志(7个日志不包换当前日志)
pm2 set pm2-logrotate:retain 7
# 默认每天进行日志切分
pm2 set pm2-logrotate:rotateInterval '0 0 * * *'
# 每个日志最大10M， 如果日志大于10M立刻切分 
pm2 set pm2-logrotate:max_size 10M  
pm2 set pm2-logrotate:rotateModule true
# 每60s检查日志
pm2 set pm2-logrotate:workerInterval 60 
# 配置日志日期格式
pm2 set pm2-logrotate:dateFormat YYYY-MM-DD_HH-mm-ss 
```

  pm2日志存放路径: `/root/.pm2/logs/`

### Docker使用pm2-logrotate

Docker使用pm2时候日志也是存放在目录`/root/.pm2/logs/` 同样也需要安装pm2-logrotate, 并且通过docker-pm2启动，安装完pm2-logrotate通过docker-pm2启动自己app.js同时也会启动pm2-logrotate。对应dockerfile如下:

```
FROM node:8.12

LABEL maintainer="yongjiahe<yongjiahe@tuputech.com>"
    
# install pm2 and pm2-logrotate and setting pm2-logrotate param  
RUN npm set regsitry http://nexus.tupu.ai/repository/npm-public/ && \
    npm install pm2  -g && \
    pm2 install pm2-logrotate && \
    pm2 set pm2-logrotate:retain 7  && \
    pm2 set pm2-logrotate:rotateInterval '0 0 * * *' && \
    pm2 set pm2-logrotate:rotateModule true && \
    pm2 set pm2-logrotate:workerInterval 60 && \
    pm2 set pm2-logrotate:dateFormat YYYY-MM-DD_HH-mm-ss && \
    pm2 set pm2-logrotate:max_size 10M  

WORKDIR /app

COPY ./ /app/
RUN npm install
VOLUME /root/.pm2/logs

# pm2-docker start your app; 启动应用同时自动启动pm2-logrotate
CMD ["pm2-docker", "start", "pm2/read-gw.json"]
```

容器启动以后通过在容器终端查看如下:
```
root@dd20d14c0ee3:/app# ps -ef
UID        PID  PPID  C STIME TTY          TIME CMD
root         1     0  7 08:42 ?        00:00:01 node /usr/local/bin/pm2-docker start pm2/read-gw.json
root        16     1  4 08:42 ?        00:00:00 node /root/.pm2/modules/pm2-logrotate/node_modules/pm2-logrotate
root        26     1  6 08:42 ?        00:00:00 node /app/read-gw.js                                                                              
root        46     0  2 08:42 ?        00:00:00 bash
```
