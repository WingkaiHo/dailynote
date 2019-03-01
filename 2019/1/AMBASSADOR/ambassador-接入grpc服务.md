#### 把grpc服务接入api网关

k8s的'Service'负责app负载均衡的配置/其它服务访问pod内部域名配置，'ambassador'通过在'Service'annotations扩展自定义信息, 获取服务是否需要把服务注册到apigate上进行转发

#### 部署在grpc-server

下面是hello-world grpc server部署到default命名空间上, 编辑`deployment-server.yaml`
```
apiVersion: v1
kind: Service
metadata:
  name: grpc-server
  labels:
    svc: grpc-server
  annotations:
    getambassador.io/config: |
      ---
      apiVersion: ambassador/v0
      kind: Mapping
      name: hello-world-grpc-server-mapping
      grpc: True
      prefix: /helloworld.Greeter/
      rewrite: /helloworld.Greeter/
      service: grpc-server.default.svc.cluster.local:50051
spec:
  clusterIP: None
  ports:
  - name: grpc
    port: 50051
    targetPort: 50051
    protocol: TCP
  selector:
    app: grpc-server
    version: v1
---
apiVersion: apps/v1beta1
kind: Deployment
metadata:
  name: grpc-server-app
  namspace: default
  labels:
    app: grpc-server
spec:
  replicas: 3
  template:
    metadata:
      labels:
        app: grpc-server
        version: v1
    spec:
      nodeSelector:
        classify: cpu
      containers:
      - name: grpc-server
        image: grpc-server-test:1.0
        ports:
        - containerPort: 50051
```

和其它yaml不同是在

1) 在`Service`配置自定义中`getambassador.io/config`
```
...
  annotations:
    getambassador.io/config: |
      ---
      apiVersion: ambassador/v0
      kind: Mapping
      # 名称必须是唯一，否则覆盖
      name: hello-world-grpc-server-mapping
      # 告诉系统是grpc服务
      grpc: True
      # grpc服务prefix，rewrite必须一致
      # 具体名称在protobuf文件中定义
      prefix: /helloworld.Greeter/
      rewrite: /helloworld.Greeter/
      # 服务内部地址，当前服务地址，由于ambassador和服务不在同一命名空间需要写详细地址,以及端口号 
      service: grpc-server.default.svc.cluster.local:50051
...
```
Mappings基于URL`prefix`, 对于gRPC，URL前缀是完整的服务名称，包括包路径（package.service）。这些在.proto定义文件中定义。在示例proto定义文件中, 我们看到：

```
package helloworld;

// The greeting service definition.
service Greeter { ... }
```
所以URL prefix是helloworld.Greeter，映射将是: `/helloworld.Greeter/`.

2) `Service`加入配置`clusterIP: None`, 告诉k8s不用为服务配置cluster ip。 envoy直接和后端pod ip通信。grpc长连接，导致同一连接请求发送到一个pod上。


#### 客户端访问grpc服务

hello-world客户端部署可以参考`https://c.tuputech.com/topic/1279/istio-grpc-%E6%80%A7%E8%83%BD%E6%B5%8B%E8%AF%95-1`

执行下面命令连接gprc server：
```
./grpc-client hello ambassador.basic.svc.cluster.local:80
```

生产环境`ambassador`部署在命名空间basic， 不同的服务客户端都是通过ambassador api 网关进行转发。
