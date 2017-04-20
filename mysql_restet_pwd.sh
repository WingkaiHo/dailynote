kill -TERM mysqld
/usr/bin/mysqld_safe --skip-grant-tables &

mysql -u root -p
use mysql
update user set password=password('engine') where user='root';
flush privileges;
exit;

//关闭
#mysqladmin -u root -p shutdown

//启动
#/usr/bin/mysql_safe --user=mysql &
