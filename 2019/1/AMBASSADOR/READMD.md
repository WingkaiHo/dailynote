#### app使用AMBASSADOR做api网关

AMBASSADOR 做为一个对象网关， 与反向代理不用之处是. 

- 方向代理： envoy里面配置多个host， 不用host有不同upstream app
- 对象网关： envoy里面只用一个default host, 不用path对应不用upstream app

#### 获取app service名称
本例子使用google.golang.org/grpc项目helloworld为部署例子.

```
go get google.golang.org/grpc
```

使用AMBASSADOR做代理前首先需要helloworld例子的protobuf service name:

```
$cat $GOPATH/src/google.golang.org/grpc/examples/helloworld/helloworld/helloworld.pb.go
...
var _Greeter_serviceDesc = grpc.ServiceDesc{
    ServiceName: "helloworld.Greeter",
    HandlerType: (*GreeterServer)(nil),
    Methods: []grpc.MethodDesc{
        {
            MethodName: "SayHello",
            Handler:    _Greeter_SayHello_Handler,
        },
    },
    Streams:  []grpc.StreamDesc{},
    Metadata: "helloworld.proto",
}
...
```

#### k8s api 控制AMBASSADOR

k8s 通过crd支持第三放api， 但是AMBASSADOR目前还早期阶段。需要通过service的metadata.annotations: 添加key进行配置注入:

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
      name: grpc-server-mapping
      # grpc 配置
      grpc: True
      # 下面两个必须需要配置为proto文件里面配置的ServiceName
      prefix: /helloworld.Greeter/
      rewrite: /helloworld.Greeter/
      # 对应服务dns名称以及端口， 必须全称
      service: grpc-server.istio-proxy1.svc.cluster.local:50051
spec:
  clusterIP: None
  ports:
  - name: grpc
    port: 50051
    targetPort: 50051
    protocol: TCP
  selector:
    app: grpc-server
```

配置clusterIP为none原因, 由于

- AMBASSADOR 配置upstream是通过dns获取ip地址，不像istio控制envoy通过k8s api enpoints配置upstream
- 不配置clusterIP为None， 就解析成service lvs地址， grpc是长连接无法进行L7负载均衡(只有一个后端处理这个客户端请求)


