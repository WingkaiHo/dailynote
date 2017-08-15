---
解决tomcat 在docker容器里面限制最大内存被系统oom
---


##1.1 docker限制最大内存
```
$docker run -d --name mycontainer -p 8080:8080 -m 1024M myapp-tomcat
```

  但是tomcat最大内存分配是宿主机器的1/4内存，如果1024M小于宿主机器1/4内存，程序可能被超配内存，而被系统oom


##1.2 通过java opt解决内存超配问题
```
$docker run -d --name mycontainer -p 8080:8080 -m 1024M -e JAVA_OPTIONS=' -XX:+PrintFlagsFinal -XX:+PrintGCDetails -Xmx512m' myapp-tomcat
```

  为了保证不被系统oom -Xmx512m <= 容器最大限制内存值, 建议是最大限制的内存50%.

  如果tomcat 使用java 9可以不用这样配置
