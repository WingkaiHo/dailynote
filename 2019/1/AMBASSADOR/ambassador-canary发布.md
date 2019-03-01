#### 灰度发布(canary)目前在k8s上的实现

Kubernetes使用其核心对象(pod)支持基本的金丝雀发布工作流程。在此工作流程中，app服务所有者可以创建Kubernetes sevice(负载负载均衡器)。然后，可以将此服务指向多个deployment控制器。app每个deployment可以是不同的版本。多个版本都同一个Service(负载均衡器)流量分配，通过指定replicas给定部署中的数量，可以控制不同版本之间的流量。例如，您可以设置replicas: 3for v1和replicas: 1for v2，以确保25％的流量进入v2。这种方法有效，但除非你有很多副本，否则它会相当粗糙。此外，自动缩放不适用于此策略。


### 

	Ambassador支持细粒度灰度发布。使用加权循环方案在多个服务之间路由流量。收集所有服务的完整指标，便于比较新版本和生产的相对表现。Ambassador灰度配置比较简单。


#### Ambassador 配置灰色度发布

hello-grpc-service有两个版本，1.0， 1.1灰度版本， 80%流量1.0， 20%流量1.1, 关键在service上配置Ambassador映射

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
apiVersion: v1
kind: Service
metadata:
  name: grpc-server-canary
  labels:
    svc: grpc-server
  annotations:
    getambassador.io/config: |
      ---
      apiVersion: ambassador/v0
      kind: Mapping
      name: grpc-server-canary-mapping
      grpc: True
      prefix: /helloworld.Greeter/
      rewrite: /helloworld.Greeter/
      service: grpc-server-canary.default.svc.cluster.local:50051
      weight: 20
spec:
  clusterIP: None
  ports:
  - name: grpc
    port: 50051
    targetPort: 50051
    protocol: TCP
  selector:
    app: grpc-server
    version: v1-1
```

只需在把`grpc-server-canary`上配置权重，剩下的流量转发正式版本上，这个ambassador方便处。如果`grpc-server-canary`有问题，只需删除grpc-server-canary服务就可以了。


下面是整个灰度发布例子。
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
apiVersion: v1
kind: Service
metadata:
  name: grpc-server-canary
  labels:
    svc: grpc-server
  annotations:
    getambassador.io/config: |
      ---
      apiVersion: ambassador/v0
      kind: Mapping
      name: grpc-server-canary-mapping
      grpc: True
      prefix: /helloworld.Greeter/
      rewrite: /helloworld.Greeter/
      service: grpc-server-canary.default.svc.cluster.local:50051
      weight: 20
spec:
  clusterIP: None
  ports:
  - name: grpc
    port: 50051
    targetPort: 50051
    protocol: TCP
  selector:
    app: grpc-server
    version: v1-1
---
apiVersion: apps/v1beta1
kind: Deployment
metadata:
  name: grpc-server-app-v1
  labels:
    app: grpc-server
spec:
  replicas: 2
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
        image: docker.tupu.ai/tupu/grpc-server-test:1.0
        ports:
        - containerPort: 50051
---
apiVersion: apps/v1beta1
kind: Deployment
metadata:
  name: grpc-server-app-v1-1
  labels:
    app: grpc-server
spec:
  replicas: 2
  template:
    metadata:
      labels:
        app: grpc-server
        version: v1-1
    spec:
      nodeSelector:
        classify: cpu
      containers:
      - name: grpc-server
        image: docker.tupu.ai/tupu/grpc-server-test:1.1
        ports:
        - containerPort: 50051
```  
