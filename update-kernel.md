### 检查kernel版本
```
$ uname -sr
  Linux 3.10.0-514.21.1.el7.x86_64
```

### Upgrading Kernel in CentOS 7

安装ELRepo repository on CentOS 7
```
$ rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
$ rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm 
```

列举kernel版本
```
$ yum --disablerepo="*" --enablerepo="elrepo-kernel" list available
```

Next, install the latest mainline stable kernel:
```
yum --enablerepo=elrepo-kernel install kernel-ml 
```

更新grub

```
vim /etc/default/grub
GRUB_TIMEOUT=5
GRUB_DISTRIBUTOR="$(sed 's, release .*$,,g' /etc/system-release)"
GRUB_DEFAULT=0
GRUB_DISABLE_SUBMENU=true
GRUB_TERMINAL_OUTPUT="console"
GRUB_CMDLINE_LINUX="crashkernel=auto rhgb quiet"
GRUB_DISABLE_RECOVERY="true"

grub2-mkconfig -o /boot/grub2/grub.cfg
```

Reboot your machine to apply the latest kernel
```
$ reboot
```
