## 如何进入容器和网络的netns命名空间

### 背景
docker使用namespace实现网络，计算等资源的隔离，当需要排查网络问题时，使用`ip netns`命令却无法在主机上看到任何network namespace，这是因为默认docker把创建的网络命名空间链接文件隐藏起来了，导致`ip netns`命令无法读取，给分析网络原理和排查问题带来了麻烦


### 恢复容器的netns

执行下面的命令来获取容器进程号

docker inspect 容器|grep Pid

获取容器的进程号

执行如下命令，将进程网络命名空间恢复到主机目录，

ln -s /proc/容器进程号/ns/net /var/run/netns/容器
