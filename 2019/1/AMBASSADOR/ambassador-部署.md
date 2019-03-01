#### ambassador部署

ambassador比较简单, 通过github项目下k8s yaml部署就可以了。

下载地址:
```
wget https://getambassador.io/yaml/ambassador/ambassador-rbac.yaml
```

因为我们供内部应用使用，还需要添加ambassador-rbac.yaml追加ambassador service负载均衡配置
```
---
apiVersion: v1
kind: Service
metadata:
  labels:
    service: ambassador
  name: ambassador
spec:
  ports:
  - name: http
    port: 80
    targetPort: 80
  selector:
    service: ambassador
```

执行下面命令:
```
$kubectl apply -f ambassador-rbac.yaml
```
