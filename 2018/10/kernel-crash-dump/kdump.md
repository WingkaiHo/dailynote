### 4.x 内核crash dump 配置

   elrepo kernel-ml 新内核不支持crashkernel=auto配制参数, 需要修改内核加载参数, 需要修改为crashkernel=256M， 保留内存大小参考[Memory requirements for kdump”.](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/kernel_administration_guide/kernel_crash_dump_guide#sect-kdump-memory-requirements)

   X86机器2G以上内存， 以1TB内存为例子， 最小需要配置224MB内存. 256MB以后足够了。

配置方法如下:
```
vim /etc/default/grub
GRUB_TIMEOUT=5
GRUB_DISTRIBUTOR="$(sed 's, release .*$,,g' /etc/system-release)"
GRUB_DEFAULT=0
GRUB_DISABLE_SUBMENU=true
GRUB_TERMINAL_OUTPUT="console"
GRUB_CMDLINE_LINUX="crashkernel=256M rhgb quiet"
GRUB_DISABLE_RECOVERY="true"

grub2-mkconfig -o /boot/grub2/grub.cfg
```

配置以后需要重新启动机器才可以生效。


### 检查和安装kdump
 
   需要安装kdump以后才可以在内核crash时候生成文件。

**检查kdump是否安装kdump**
```
$ rpm -qa | grep kexec-tools
```

如果没有安装需要安装, 并且启动对应服务
```
$ yum install kexec-tools
$ systemctl enable kdump.service
$ systemctl restart kdump.service
```

启动成功以后就可以在内核崩溃以后在`/var/crash/`目录里面生成core文件