### 1.1 基础环境

control-1:
public:  192.168.0.4
manager: 172.16.0.4

nova-1
public: 192.168.0.5
manager: 172.16.0.5

nova-2
public:  192.168.0.6
manager: 172.16.0.6

## 1.2 网络设置

关闭防火墙
```
$ systemctl stop firewalld
$ systemctl disable firewalld
```

关闭selinux
```
$ setenforce 0
$ vim /etc/selinux/config

LINUX=disabled
SELINUXTYPE=targeted
```

### 2 主节点

### 2.1 基础组件

### 2.1.1 SQL数据库

**安装和配置**

安装软件包：
```
$ yum install mariadb mariadb-server python2-PyMySQL
```

初始化配置
```
创建并编辑 /etc/my.cnf.d/openstack.cnf，然后完成如下动作：
在 [mysqld] 部分，设置 ``bind-address``值为控制节点的管理网络IP地址以使得其它节点可以通过管理网络访问数据库：
 [mysqld]
...
bind-address = 172.16.0.4
在``[mysqld]`` 部分，设置如下键值来启用一起有用的选项和 UTF-8 字符集：
 [mysqld]
...
default-storage-engine = innodb
innodb_file_per_table
max_connections = 4096
collation-server = utf8_general_ci
character-set-server = utf8
```

初始化数据库
```
$ mysql_secure_installation
```

### 2.1.2 NoSQL 数据库(MogoDB)

**注解**
  只有按照文档 :ref:`install_ceilometer`安装Telemetry服务时，才需要安装NoSQL数据库服务。

**安装并配置**
安装MongoDB包：
 # yum install mongodb-server mongodb

编辑文件`/etc/mongod.conf` 并完成如下动作：

配置`bind_ip`使用控制节点管理网卡的IP地址
 bind_ip = 172.16.0.4
默认情况下，MongoDB会在`/var/lib/mongodb/journal`目录下创建几个 1 GB 大小的日志文件。如果你想将每个日志文件大小减小到128MB并且限制日志文件占用的总空间为512MB，配置 smallfiles 的值：
 smallfiles = true
你也可以禁用日志。更多信息，可以参考 `MongoDB 手册<http://docs.mongodb.org/manual/>`

### 2.1.3 消息队列(rabbitmq)
  OpenStack 使用 message queue 协调操作和各服务的状态信息。消息队列服务一般运行在控制节点上。OpenStack支持好几种消息队列服务包括 RabbitMQ, Qpid, 和 ZeroMQ。不过，大多数发行版本的OpenStack包支持特定的消息队列服务。本指南安装 RabbitMQ 消息队列服务，因为大部分发行版本都支持它。如果你想安装不同的消息队列服务，查询与之相关的文档。

**安全并配置组件**

包安装并且自动启动
```
$ yum install rabbitmq-server
$ systemctl enable rabbitmq-server.service
$ systemctl start rabbitmq-server.service
```

添加 openstack 用户:
```
rabbitmqctl add_user openstack RABBIT_PASS
Creating user "openstack" ...
...done.
```
用合适的密码替换 RABBIT_DBPASS。

给`openstack`用户配置写和读权限：
```
$ rabbitmqctl set_permissions openstack ".*" ".*" ".*"
Setting permissions for user "openstack" in vhost "/" ...
...done.
```

### 2.1.4 Memcached
**安全并配置组件**

安装软件包：
```
$ yum install memcached python-memcached
```
完成安装
启动Memcached服务，并且配置它随机启动。
```
$ systemctl enable memcached.service
$ systemctl start memcached.service
```

### 2.1.5 安装openstack rpm包

启用OpenStack库
  在CentOS中， `extras`仓库提供用于启用 OpenStack 仓库的RPM包。 CentOS 默认启用``extras``仓库，因此你可以直接安装用于启用OpenStack仓库的包。
```
$ yum install centos-release-openstack-mitaka
```

如果更新了一个新内核，重启主机来使用新内核。
安装 OpenStack 客户端：
```
$ yum install python-openstackclient
```

RHEL 和 CentOS 默认启用了 SELinux . 安装 openstack-selinux 软件包以便自动管理 OpenStack 服务的安全策略:
```
yum install openstack-selinux
```

### 2.2 认证服务

### 2.2.1 认证服务概述
- OpenStack:term:`Identity service`为认证管理，授权管理和服务目录服务管理提供单点整合。其它OpenStack服务将身份认证服务当做通用统一API来使用。此外，提供用户信息但是不在OpenStack项目中的服务（如LDAP服务）可被整合进先前存在的基础设施中。

- 为了从identity服务中获益，其他的OpenStack服务需要与它合作。当某个OpenStack服务收到来自用户的请求时，该服务询问Identity服务，验证该用户是否有权限进行此次请求

- 身份服务包含这些组件：
  服务器一个中心化的服务器使用RESTful 接口来提供认证和授权服务。 驱动驱动或服务后端被整合进集中式服务器中。它们被用来访问OpenStack外部仓库的身份信息, 并且它们可能已经存在于OpenStack被部署在的基础设施（例如，SQL数据库或LDAP服务器）中。 模块中间件模块运行于使用身份认证服务的OpenStack组件的地址空间中。这些模块拦截服务请求，取出用户凭据，并将它们送入中央是服务器寻求授权。中间件模块和OpenStack组件间的整合使用Python Web服务器网关接口。
  当安装OpenStack身份服务，用户必须将之注册到其OpenStack安装环境的每个服务。身份服务才可以追踪那些OpenStack服务已经安装，以及在网络中定位它们

### 2.2.2 创建认证服务对应数据库和表

**创建数据库和表**
```
$ mysql -u root -p

创建数据库
mysql> CREATE DATABASE keystone;

创建表
mysql> GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' \
 IDENTIFIED BY 'KEYSTONE_DBPASS';
mysql> GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' \
 IDENTIFIED BY 'KEYSTONE_DBPASS';
用合适的密码替换 KEYSTONE_DBPASS. 
```

### 2.2.3 Keystone和Httpd服务器安装配置

**注解**
教程使用带有``mod_wsgi``的Apache HTTP服务器来服务认证服务请求，端口为5000和35357。缺省情况下，Keystone服务仍然监听这些端口。然而，本教程手动禁用keystone服务。

**安装和配置**

keystone和http包安装
```
$ yum install openstack-keystone httpd mod_wsg
```

Keystone配置

生成ADMIN_TOKEN
```
$ openssl rand -hex 10
```

编辑文件`/etc/keystone/keystone.conf`并完成如下动作:
```
在[DEFAULT]部分，定义初始管理令牌的值：
 [DEFAULT]
...
admin_token = ADMIN_TOKEN
使用前面步骤生成的随机数替换``ADMIN_TOKEN`` 值。

在 [database] 部分，配置数据库访问：
 [database]
...
connection = mysql+pymysql://keystone:KEYSTONE_DBPASS@controller/keystone
将``KEYSTONE_DBPASS``替换为你为数据库选择的密码。
在``[token]``部分，配置Fernet UUID令牌的提供者。
 [token]
...
provider = uuid
driver = memcache

[memcache]
servers = localhost:11211

[revoke]


# Entrypoint for an implementation of the backend for persisting revocation
# events in the keystone.revoke namespace. Supplied drivers are kvs and sql.
# (string value)
driver = sql

```

**配置 Apache HTTP 服务器**

- 编辑`/etc/httpd/conf/httpd.conf`文件，配置`ServerName`选项为控制节点：
```
vim /etc/httpd/conf/httpd.conf

修改:
  ServerName controller
```

- 用下面的内容创建文件 /etc/httpd/conf.d/wsgi-keystone.conf
```
Listen 5000
Listen 35357

<VirtualHost *:5000>
    WSGIDaemonProcess keystone-public processes=5 threads=1 user=keystone group=keystone display-name=%{GROUP}
    WSGIProcessGroup keystone-public
    WSGIScriptAlias / /usr/bin/keystone-wsgi-public
    WSGIApplicationGroup %{GLOBAL}
    WSGIPassAuthorization On
    ErrorLogFormat "%{cu}t %M"
    ErrorLog /var/log/httpd/keystone-error.log
    CustomLog /var/log/httpd/keystone-access.log combined

    <Directory /usr/bin>
        Require all granted
    </Directory>
</VirtualHost>

<VirtualHost *:35357>
    WSGIDaemonProcess keystone-admin processes=5 threads=1 user=keystone group=keystone display-name=%{GROUP}
    WSGIProcessGroup keystone-admin
    WSGIScriptAlias / /usr/bin/keystone-wsgi-admin
    WSGIApplicationGroup %{GLOBAL}
    WSGIPassAuthorization On
    ErrorLogFormat "%{cu}t %M"
    ErrorLog /var/log/httpd/keystone-error.log
    CustomLog /var/log/httpd/keystone-access.log combined

    <Directory /usr/bin>
        Require all granted
    </Directory>
</VirtualHost>
```

**启动httpd**

```
$ systemctl enable httpd.service
$ systemctl start httpd.service
```

### 2.2.4 创建服务实体和API端点

**先决条件**
  默认情况下，身份认证服务数据库不包含支持传统认证和目录服务的信息。你必须使用:doc:keystone-install 章节中为身份认证服务创建的临时身份验证令牌用来初始化的服务实体和API端点。
你必须使用``–os-token``参数将认证令牌的值传递给:command:openstack 命令。类似的，你必须使用``–os-url`` 参数将身份认证服务的 URL传递给 openstack 命令或者设置OS_URL环境变量。本指南使用环境变量以缩短命令行的长度。

**警告:**
  因为安全的原因，，除非做必须的认证服务初始化，不要长时间使用临时认证令牌。
```
配置认证令牌：
$ export OS_TOKEN=ADMIN_TOKEN
将``ADMIN_TOKEN``替换为你在 :doc:`keystone-install`章节中生成的认证令牌。例如：
$ export OS_TOKEN=879cc308ae5740280160

配置端点URL：
$ export OS_URL=http://controller:35357/v3

配置认证 API 版本：
$ export OS_IDENTITY_API_VERSION=3
```

**创建服务实体和API端点**

在你的Openstack环境中，认证服务管理服务目录。服务使用这个目录来决定您的环境中可用的服务。
创建服务实体和身份认证服务：
```
$openstack service create \
  --name keystone --description "OpenStack Identity" identity
```
+-------------+----------------------------------+
+-------------+----------------------------------+
| Field       | Value                            |
+-------------+----------------------------------+
| description | OpenStack Identity               |
| enabled     | True                             |
| id          | 8a87a72504d44ef49979ac64f078db5d |
| name        | keystone                         |
| type        | identity                         |
+-------------+----------------------------------+

注解
OpenStack 是动态生成 ID 的，因此您看到的输出会与示例中的命令行输出不相同。

### 2.2.5 创建认证服务的API端点
  身份认证服务管理了一个与您环境相关的 API 端点的目录。服务使用这个目录来决定如何与您环境中的其他服务进行通信。
OpenStack使用三个API端点变种代表每种服务：admin，internal和public。默认情况下，管理API端点允许修改用户和租户而公共和内部APIs不允许这些操作。在生产环境中，处于安全原因，变种为了服务不同类型的用户可能驻留在单独的网络上。对实例而言，公共API网络为了让顾客管理他们自己的云在互联网上是可见的。管理API网络在管理云基础设施的组织中操作也是有所限制的。内部API网络可能会被限制在包含OpenStack服务的主机上。此外，OpenStack支持可伸缩性的多区域。为了简单起见，本指南为所有端点变种和默认``RegionOne``区域都使用管理网络。

```
$ openstack endpoint create --region RegionOne \
  identity public http://controller:5000/v3
+--------------+----------------------------------+
| Field        | Value                            |
+--------------+----------------------------------+
| enabled      | True                             |
| id           | 92a155dc38634b21a129982ac21d05a1 |
| interface    | public                           |
| region       | RegionOne                        |
| region_id    | RegionOne                        |
| service_id   | 8a87a72504d44ef49979ac64f078db5d |
| service_name | keystone                         |
| service_type | identity                         |
| url          | http://controller:5000/v3        |
+--------------+----------------------------------+

$openstack endpoint create --region RegionOne \
 identity internal http://controller:5000/v3
+--------------+----------------------------------+
| Field        | Value                            |
+--------------+----------------------------------+
| enabled      | True                             |
| id           | 159aeac4baad487ea815f3f60372f9b7 |
| interface    | internal                         |
| region       | RegionOne                        |
| region_id    | RegionOne                        |
| service_id   | 8a87a72504d44ef49979ac64f078db5d |
| service_name | keystone                         |
| service_type | identity                         |
| url          | http://controller:5000/v3        |
+--------------+----------------------------------+

$ openstack endpoint create --region RegionOne \
   identity admin http://controller:35357/v3
+--------------+----------------------------------+
| Field        | Value                            |
+--------------+----------------------------------+
| enabled      | True                             |
| id           | f09d2a32265f4bd3a2960b2c974bf85e |
| interface    | admin                            |
| region       | RegionOne                        |
| region_id    | RegionOne                        |
| service_id   | 8a87a72504d44ef49979ac64f078db5d |
| service_name | keystone                         |
| service_type | identity                         |
| url          | http://controller:35357/v3       |
+--------------+----------------------------------+
```

注解
每个添加到OpenStack环境中的服务要求一个或多个服务实体和三个认证服务中的API 端点变种

### 2.2.5 创建项目和角色

**创建域default**
```
$ openstack domain create --description "Default Domain" default
+-------------+----------------------------------+
| Field       | Value                            |
+-------------+----------------------------------+
| description | Default Domain                   |
| enabled     | True                             |
| id          | f12b5c873d6a4074b2424cd7c504037c |
| name        | default                          |
+-------------+----------------------------------+
```

**创建 admin 项目**
  在你的环境中，为进行管理操作，创建管理的项目、用户和角色
```
$ openstack project create --domain default \
  --description "Admin Project" admin

+-------------+----------------------------------+
| Field       | Value                            |
+-------------+----------------------------------+
| description | Admin Project                    |
| domain_id   | f12b5c873d6a4074b2424cd7c504037c |
| enabled     | True                             |
| id          | 9d7b3dae9f4b4826a92ea0efb80b613a |
| is_domain   | False                            |
| name        | admin                            |
| parent_id   | f12b5c873d6a4074b2424cd7c504037c |
+-------------+----------------------------------+
```

**创建 admin 用户**
```
$ openstack user create --domain default \
  --password-prompt admin
User Password:
Repeat User Password:

+-----------+----------------------------------+
| Field     | Value                            |
+-----------+----------------------------------+
| domain_id | f12b5c873d6a4074b2424cd7c504037c |
| enabled   | True                             |
| id        | 5f9727d46b9e4f89a55036843c751953 |
| name      | admin                            |
+-----------+----------------------------------+
```

**创建 admin 角色**
```
$ openstack role create admin
+-----------+----------------------------------+
| Field     | Value                            |
+-----------+----------------------------------+
| domain_id | None                             |
| id        | 08740edf7e1845e7b9485b33b059a2f6 |
| name      | admin                            |
+-----------+----------------------------------+
```

**添加admin角色到admin项目和用户上**
```
$ openstack role add --project admin --user admin admin

这个命令执行后没有输出。
```
 
**注解**
  你创建的任何角色必须映射到每个OpenStack服务配置文件目录下的`policy.json` 文件中。默认策略是给予**admin**角色大部分服务的管理访问权限。更多信息，参考 `Operations Guide - Managing Projects and Users http://docs.openstack.org/ops-guide/ops-projects-users.html`


环境中每个服务包含独有用户的`service`项目。创建`service`项目：

```
$ openstack project create --domain default \ 
  --description "Service Project" service

+-------------+---------------------------------
| field       | value                            |
+-------------+----------------------------------+
| description | Service Project                  |
| domain_id   | f12b5c873d6a4074b2424cd7c504037c |
| enabled     | True                             |
| id          | 9e4aed74b3734cd6961f6261e73f8b04 |
| is_domain   | False                            |
| name        | service                          |
| parent_id   | f12b5c873d6a4074b2424cd7c504037c |
+-------------+----------------------------------+
```

常规（非管理）任务应该使用无特权的项目和用户。作为例子，本指南创建 demo 项目和用户。


**创建demo project**
```
$ openstack project create --domain default \
  --description "Demo Project" demo

+-------------+----------------------------------+
| Field       | Value                            |
+-------------+----------------------------------+
| description | Demo Project                     |
| domain_id   | f12b5c873d6a4074b2424cd7c504037c |
| enabled     | True                             |
| id          | d79aae88d95f4bbaa0474e7186948084 |
| is_domain   | False                            |
| name        | demo                             |
| parent_id   | f12b5c873d6a4074b2424cd7c504037c |
+-------------+----------------------------------+
```

**创建demo用户**
```
$ openstack user create --domain default  \
  --password-prompt demo
User Password:
Repeat User Password:
+-----------+----------------------------------+
| Field     | Value                            |
+-----------+----------------------------------+
| domain_id | f12b5c873d6a4074b2424cd7c504037c |
| enabled   | True                             |
| id        | 77df6b9a807d41efb643ccdd785b7ff0 |
| name      | demo                             |
+-----------+----------------------------------+
```

**创建 user 角色**
```
$ openstack role create user
+-----------+----------------------------------+
| Field     | Value                            |
+-----------+----------------------------------+
| domain_id | None                             |
| id        | 5111d79465de40e181691a1f419c2297 |
| name      | user                             |
+-----------+----------------------------------+
```

添加`user`角色到`demo`项目和用户
```
$ openstack role add --project demo --user demo user
```

### 2.2.6 keystone验证

**验证前准备**

- 因为安全性的原因，关闭临时认证令牌机制：
  编辑 /etc/keystone/keystone-paste.ini 文件，从`[pipeline:public_api]` `[pipeline:admin_api]` 和`[pipeline:api_v3]`部分删除`admin_token_auth`。

- 重置`OS_TOKEN`和`OS_URL`环境变量:
```
$ unset OS_TOKEN OS_URL
```

**用户验证**

- 作为`admin`用户，请求认证令牌：
```
$ openstack --os-auth-url http://controller:35357/v3  --os-project-domain-name default --os-user-domain-name default --os-project-name admin --os-username admin token issue
Password: 
+------------+----------------------------------+
| Field      | Value                            |
+------------+----------------------------------+
| expires    | 2017-11-03T08:32:44.511027Z      |
| id         | 0a626ac6e26e4f9cbdc1d88bebcc71ed |
| project_id | 9d7b3dae9f4b4826a92ea0efb80b613a |
| user_id    | 5f9727d46b9e4f89a55036843c751953 |
+------------+----------------------------------+
```


- 作为`demo`用户，请求认证令牌：
```
$ openstack --os-auth-url http://controller:5000/v3 --os-project-domain-name default --os-user-domain-name default  --os-project-name demo --os-username demo token issue
Password: 
+------------+----------------------------------+
| Field      | Value                            |
+------------+----------------------------------+
| expires    | 2017-11-03T08:44:53.872553Z      |
| id         | 89f3c81a2ae84295bf4bd9392aa800e6 |
| project_id | d79aae88d95f4bbaa0474e7186948084 |
| user_id    | 77df6b9a807d41efb643ccdd785b7ff0 |
+------------+----------------------------------+
```

注解
这个命令使用`demo` 用户的密码和API端口5000，这样只会允许对身份认证服务API的常规（非管理）访问。

### 2.2.7 创建 OpenStack 客户端环境脚本

**创建admin用户脚本**

创建并且编辑admin-openrc
```
export OS_PROJECT_DOMAIN_NAME=default
export OS_USER_DOMAIN_NAME=default
export OS_PROJECT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=ADMIN_PASS
export OS_AUTH_URL=http://controller:35357/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
```


**创建demo用户脚本**

创建并且编辑demo-openrc
```
export OS_PROJECT_DOMAIN_NAME=default
export OS_USER_DOMAIN_NAME=default
export OS_PROJECT_NAME=demo
export OS_USERNAME=demo
export OS_PASSWORD=DEMO_PASS
export OS_AUTH_URL=http://controller:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
```

**注意:**
将 `DEMO_PASS` 和 `ADMIN_PASS` 替换为你在认证服务中为用户选择的密码。

**使用admin-openrc脚本**
```
$ source admin-openrc
请求认证令牌:
$ openstack token issue
+------------+----------------------------------+
| Field      | Value                            |
+------------+----------------------------------+
| expires    | 2017-11-03T08:52:05.882295Z      |
| id         | d39f4cfa724a43cb97c1d72b676fe7b6 |
| project_id | 9d7b3dae9f4b4826a92ea0efb80b613a |
| user_id    | 5f9727d46b9e4f89a55036843c751953 |
+------------+----------------------------------+
```

**使用demo-openrc脚本**
```
$ source demo-openrc
请求认证令牌:
$ openstack token issue
+------------+----------------------------------+
| Field      | Value                            |
+------------+----------------------------------+
| expires    | 2017-11-03T08:52:05.882295Z      |
| id         | d39f4cfa724a43cb97c1d72b676fe7b6 |
| project_id | 9d7b3dae9f4b4826a92ea0efb80b613a |
| user_id    | 5f9727d46b9e4f89a55036843c751953 |
+------------+----------------------------------+
```

### 2.3 安装镜像服务(glance)
   镜像服务 (glance) 允许用户发现、注册和获取虚拟机镜像。它提供了一个 REST API，允许您查询虚拟机镜像的 metadata 并获取一个现存的镜像。您可以将虚拟机镜像存储到各种位置，从简单的文件系统到对象存储系统—-例如 OpenStack 对象存储, 并通过镜像服务使用。

## 2.3.1 挂载数据盘给glance
 简单来说，本指南描述了使用`file`作为后端配置镜像服务，能够上传并存储在一个托管镜像服务的控制节点目录中。默认情况下，这个目录是 /var/lib/glance/images/。
继续进行之前，确认控制节点的该目录有至少几千兆字节的可用空间。

**格式化数据盘**
```
vdc可以修改其他名字数据盘
$ mkfs.xfs /dev/vdc

把数据盘挂载目录/var/lib/glance/images
$ mkdir -p /var/lib/glance/images
$ mount /dev/vdc /var/lib/glance/images

配置开机自动挂载
$ vim /etc/fstab
/dev/vdc /var/lib/glance/images/                       xfs    defaults        1 1 

$ df 
dev/vda1       41147376 2189144  37159608    6% /
evtmpfs         1931416       0   1931416    0% /dev
mpfs            1940964       0   1940964    0% /dev/shm
mpfs            1940964   16764   1924200    1% /run
mpfs            1940964       0   1940964    0% /sys/fs/cgroup
mpfs             388196       0    388196    0% /run/user/0
dev/vdc       209612800   32944 209579856    1% /var/lib/glance/images 

$chown glance:glance /var/lib/glance/images
```

### 2.3.2 创建glance对应数据库

**创建数据库和表**
```
$ mysql -u root -p

创建数据库
mysql> CREATE DATABASE glance;

创建表
mysql> GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' \
       IDENTIFIED BY 'GLANCE_DBPASS';

mysql> GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' 
       IDENTIFIED BY 'GLANCE_DBPASS';

用合适的密码替换 GLANCE_DBPASS 
```

**要创建服务证书**

- 打开admin权限
```
$source admin-openrc
```

- 创建 glance 用户:
```
$ openstack user create --domain default --password-prompt glance
User Password:
Repeat User Password:
+-----------+----------------------------------+
| Field     | Value                            |
+-----------+----------------------------------+
| domain_id | f12b5c873d6a4074b2424cd7c504037c |
| enabled   | True                             |
| id        | f120c0b95484464ab64153ca30dce541 |
| name      | glance                           |
+-----------+----------------------------------+
```

- 添加 admin 角色到 glance 用户和 service 项目上
```
$ openstack role add --project service --user glance admin
```

- 创建glance服务实体：
```
$ openstack service create --name glance --description "OpenStack Image" image
+-------------+----------------------------------+
| Field       | Value                            |
+-------------+----------------------------------+
| description | OpenStack Image                  |
| enabled     | True                             |
| id          | 1ae552c4de3e40d0a1a499a56f076a0f |
| name        | glance                           |
| type        | image                            |
+-------------+----------------------------------+
```

**创建镜像服务的 API 端点**
```
$ openstack endpoint create --region RegionOne \
   image public http://controller:9292
+--------------+----------------------------------+
| Field        | Value                            |
+--------------+----------------------------------+
| enabled      | True                             |
| id           | 79a332ff61b54b87b53115c1a72b3d0a |
| interface    | public                           |
| region       | RegionOne                        |
| region_id    | RegionOne                        |
| service_id   | 1ae552c4de3e40d0a1a499a56f076a0f |
| service_name | glance                           |
| service_type | image                            |
| url          | http://controller:9292           |
+--------------+----------------------------------+

$ openstack endpoint create --region RegionOne \
   image internal http://controller:9292
+--------------+----------------------------------+
| Field        | Value                            |
+--------------+----------------------------------+
| enabled      | True                             |
| id           | 26352e49add547548b47a3d9053bc56c |
| interface    | internal                         |
| region       | RegionOne                        |
| region_id    | RegionOne                        |
| service_id   | 1ae552c4de3e40d0a1a499a56f076a0f |
| service_name | glance                           |
| service_type | image                            |
| url          | http://controller:9292           |
+--------------+----------------------------------+

$ openstack endpoint create --region RegionOne \
   image admin http://controller:9292
+--------------+----------------------------------+
| Field        | Value                            |
+--------------+----------------------------------+
| enabled      | True                             |
| id           | 38528f74a08c48ac87c6a20ae61e86ab |
| interface    | admin                            |
| region       | RegionOne                        |
| region_id    | RegionOne                        |
| service_id   | 1ae552c4de3e40d0a1a499a56f076a0f |
| service_name | glance                           |
| service_type | image                            |
| url          | http://controller:9292           |
+--------------+----------------------------------+
```

### 2.3.3 安装和配置glance

**注解**
默认配置文件在各发行版本中可能不同。你可能需要添加这些部分，选项而不是修改已经存在的部分和选项。另外，在配置片段中的省略号(...)表示默认的配置选项你应该保留。

**安装openstack-glance rpm**
```
$yum install openstack-glance
```

**配置glance-api**
编辑文件 /etc/glance/glance-api.conf 并完成如下动作：
```
 [database]
...
connection = mysql+pymysql://glance:GLANCE_DBPASS@controller/glance
将`GLANCE_DBPASS`替换为你为镜像服务选择的密码。


在 [keystone_authtoken] 和 [paste_deploy] 部分，配置认证服务访问：
 [keystone_authtoken]
...
auth_uri = http://controller:5000
auth_url = http://controller:35357
memcached_servers = controller:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = glance
password = GLANCE_PASS

[paste_deploy]
...
flavor = keystone
将 GLANCE_PASS 替换为你为认证服务中你为 glance 用户选择的密码。
 
注解
在 [keystone_authtoken] 中注释或者删除其他选项。
在 [glance_store] 部分，配置本地文件系统存储和镜像文件位置：
 [glance_store]
...
stores = file,http
default_store = file
filesystem_store_datadir = /var/lib/glance/images/
```

**配置glance-registry**
编辑文件`/etc/glance/glance-registry.conf`并完成如下动作：
```
 [database]
...
connection = mysql+pymysql://glance:GLANCE_DBPASS@controller/glance
将``GLANCE_DBPASS`` 替换为你为镜像服务选择的密码。

在 [keystone_authtoken] 和 [paste_deploy] 部分，配置认证服务访问：
 [keystone_authtoken]
...
auth_uri = http://controller:5000
auth_url = http://controller:35357
memcached_servers = controller:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = glance
password = GLANCE_PASS

[paste_deploy]
...
flavor = keystone
将 GLANCE_PASS 替换为你为认证服务中你为 glance 用户选择的密码。
 
注解
在 [keystone_authtoken] 中注释或者删除其他选项。
```

**写入镜像服务数据库**
```
$ su -s /bin/sh -c "glance-manage db_sync" glance
```

**启动服务/设置开机启动**
```
$ systemctl enable openstack-glance-api.service \
  openstack-glance-registry.service

$ systemctl start openstack-glance-api.service \
  openstack-glance-registry.service
```

**验证glance服务**
```
$ source admin-openrc

下载镜像
$ wget http://download.cirros-cloud.net/0.3.4/cirros-0.3.4-x86_64-disk.img

上传镜像
$ openstack image create "cirros"  --file cirros-0.3.4-x86_64-disk.img --disk-format qcow2 --container-format bare  --public
+------------------+------------------------------------------------------+
| Field            | Value                                                |
+------------------+------------------------------------------------------+
| checksum         | ee1eca47dc88f4879d8a229cc70a07c6                     |
| container_format | bare                                                 |
| created_at       | 2017-11-03T10:47:31Z                                 |
| disk_format      | qcow2                                                |
| file             | /v2/images/7e6cb71e-fdec-4831-bf2f-77a3196f12a2/file |
| id               | 7e6cb71e-fdec-4831-bf2f-77a3196f12a2                 |
| min_disk         | 0                                                    |
| min_ram          | 0                                                    |
| name             | cirros                                               |
| owner            | 9d7b3dae9f4b4826a92ea0efb80b613a                     |
| protected        | False                                                |
| schema           | /v2/schemas/image                                    |
| size             | 13287936                                             |
| status           | active                                               |
| tags             |                                                      |
| updated_at       | 2017-11-03T10:47:31Z                                 |
| virtual_size     | None                                                 |
| visibility       | public                                               |
+------------------+------------------------------------------------------+

$ ll /var/lib/glance/images
-rw-r----- 1 glance glance 13287936 11月  3 18:47 7e6cb71e-fdec-4831-bf2f-77a3196f12a2

查询
$ openstack image list
+--------------------------------------+--------+--------+
| ID                                   | Name   | Status |
+--------------------------------------+--------+--------+
| 7e6cb71e-fdec-4831-bf2f-77a3196f12a2 | cirros | active |
+--------------------------------------+--------+--------+
```

### 2.4 计算服务(Nova)配置

### 2.4.1 数据库配置（在）

openstack user create --domain default \
>   --password-prompt nova
User Password:
Repeat User Password:
+-----------+----------------------------------+
| Field     | Value                            |
+-----------+----------------------------------+
| domain_id | f12b5c873d6a4074b2424cd7c504037c |
| enabled   | True                             |
| id        | 6bba6bde770049b7b11f736d876d0bd3 |
| name      | nova                             |
+-----------+----------------------------------+
