### Kubelet 对device plugin设备列表管理

    Kubelet是kubernetes集体群docker容器生产者，按照调度分配容器cpu， 内存资源（标准资源）， 还用device plugin注册资源（用户自定义资源）. 用户自定义资源管理相关代码放在k8s项目目录下`pkg/kubelet/cm/devicemanager/`

```
pod_devices.go: 存储各种device plugin注册设备表， device pod 分配表数据结构， 增删差改逻辑

endpoint.go: device plugin 注册信息map， 负责和device plugin进行rpc通信， 获取设备状态， 提供发送Allocte rpc调用到device plugin接口。

manager.go 当POD创建前都是如果使用nvidia.com/gpu 自定义资源都回在manager里面分配函数获取device资源接入pod， 有mangager负责分配，记录资源， 当pod是否有manager负责登记资源释放，回收资源。
```

### 设备分配流程分析

下面是POD首次创建，没有init container 为例子主线主要函数调用图:


```
manager.go
ManagerImpl.Allocate
|
|_ alllocateContainerResource
|      |_ deviceAllocate
|      |_ podDevice.insert  (插入pod以及pod申请资源， pod_device.go定义)
|
|_ podDevice.removeContainerAllocateResource (在没有init container devicesInUse 为空，此函数删除不起作用, pod_device.go定义)
|
|_ santizeNodeAllocate
      
```   


**allocateContainerResources **

  此函数处理pod yaml 可能存在limit 存在除cpu，内存外自定义类型， 这里变量limit里面所有自定义类型通过deviceAllocate给pod申请这些自定义资源。

```
apiVersion: v1
kind: Pod
metadata:
  name: cuda-vector-add
spec:
  restartPolicy: OnFailure
  containers:
    - name: cuda-vector-add
      # https://github.com/kubernetes/kubernetes/blob/v1.7.11/test/images/nvidia-cuda/Dockerfile
      image: "k8s.gcr.io/cuda-vector-add:v0.1"
      resources:
        limits:
          nvidia.com/gpu: 1 # requesting 1 GPU
          memory: 1Gi
          cpu: 1000
``` 
  
```
// for 循环用户遍历 container limit 各种资源， 判断如果是自定义才进行处理(cpu, 内存Limit 不在此处理范围)
for k, v := range container.Resources.Limits {
		resource := string(k)
		needed := int(v.Value())
		glog.V(3).Infof("needs %d %s", needed, resource)
		if !m.isDevicePluginResource(resource) {
			continue
		}
		// Updates allocatedDevices to garbage collect any stranded resources
		// before doing the device plugin allocation.
		if !allocatedDevicesUpdated {
			m.updateAllocatedDevices(m.activePods())
			allocatedDevicesUpdated = true
		}

        // 实现在pod device 列表查找空闲device (例如gpu)
		allocDevices, err := m.devicesToAllocate(podUID, contName, resource, needed, devicesToReuse[resource])
		if err != nil {
			return err
		}
		if allocDevices == nil || len(allocDevices) <= 0 {
			continue
		}

        ....

        // 获取对应资源device plugin rpc接口
		m.mutex.Lock()
		e, ok := m.endpoints[resource]
		m.mutex.Unlock()
		if !ok {
			m.mutex.Lock()
			m.allocatedDevices = m.podDevices.devices()
			m.mutex.Unlock()
			return fmt.Errorf("Unknown Device Plugin %s", resource)
		}

        // 需要分配设备列表(这里以及决定要分配哪几个gpu， 这些设备类在devicesToAllocate 返回)
		devs := allocDevices.UnsortedList()
		// TODO: refactor this part of code to just append a ContainerAllocationRequest
		// in a passed in AllocateRequest pointer, and issues a single Allocate call per pod.
		glog.V(3).Infof("Making allocation request for devices %v for device plugin %s", devs, resource)
        // 向device plugin server(k8s-device-pligin 发送allocate请求)
		resp, err := e.allocate(devs)
		metrics.DevicePluginAllocationLatency.WithLabelValues(resource).Observe(metrics.SinceInMicroseconds(startRPCTime))
		if err != nil {
            // 处理k8s-device-pligin 回应设备不合法错误
			// In case of allocation failure, we want to restore m.allocatedDevices
			// to the actual allocated state from m.podDevices.
			m.mutex.Lock()
			m.allocatedDevices = m.podDevices.devices()
			m.mutex.Unlock()
			return err
		}

		// Update internal cached podDevices state.
		m.mutex.Lock()
        // pod 以及它分配设备插入映射表中
		m.podDevices.insert(podUID, contName, resource, allocDevices, resp.ContainerResponses[0])
		m.mutex.Unlock()
	}
```

**deviceAllocate**
  
  自定义资源(device plguin 注册资源) 分配策略代码就定义在这个地方. 这个函数比较长，我们这里主线是首次创建，没有initcontainer分配自定义设备(nvidia gpu), 掉其它不相关代码

```
    // Needs to allocate additional devices.
	if m.allocatedDevices[resource] == nil {
		m.allocatedDevices[resource] = sets.NewString()
	}

	// Gets Devices in use. gpu情况(nvidia.com/gpu), 获取所有已经分配出去gpu列表
	devicesInUse := m.allocatedDevices[resource]
	// Gets a list of available devices. 可分配gpu列表=健康gpu列表-已经分配出去gpu
	available := m.healthyDevices[resource].Difference(devicesInUse)
	if int(available.Len()) < needed {
		return nil, fmt.Errorf("requested number of devices unavailable for %s. Requested: %d, Available: %d", resource, needed, available.Len())
	}
	allocated := available.UnsortedList()[:needed]
	// Updates m.allocatedDevices with allocated devices to prevent them
	// from being allocated to other pods/containers, given that we are
	// not holding lock during the rpc call.
	for _, device := range allocated {
        // 记录到分配列表中
		m.allocatedDevices[resource].Insert(device)
		devices.Insert(device)
	}
	return devices, nil
```

   这里代码对应所有自定设备，目前接口没有考虑那几个设备之间有更加优化分配， 这里分配基本按照healthyDevices顺序分配，有前面设备没有释放，分后面的。这里都实现gpu设备分配，记录，更新，修改只能在这里添加接口影响这个逻辑，同样有可能影响其它自定义使用，有一定风险。



### 能否通过Device plugin Allocate接口返回修改GPU分配

   下面device plugin Allocate 返回数据结构:
```
type ContainerAllocateResponse struct {
	// List of environment variable to be set in the container to access one of more devices.
	Envs map[string]string `protobuf:"bytes,1,rep,name=envs" json:"envs,omitempty" protobuf_key:"bytes,1,opt,name=key,proto3" protobuf_val:"bytes,2,opt,name=value,proto3"`
	// Mounts for the container.
	Mounts []*Mount `protobuf:"bytes,2,rep,name=mounts" json:"mounts,omitempty"`
	// Devices for the container.
	Devices []*DeviceSpec `protobuf:"bytes,3,rep,name=devices" json:"devices,omitempty"`
	// Container annotations to pass to the container runtime
	Annotations map[string]string `protobuf:"bytes,4,rep,name=annotations" json:"annotations,omitempty" protobuf_key:"bytes,1,opt,name=key,proto3" protobuf_val:"bytes,2,opt,name=value,proto3"`
}
```

上面是device plugin server(例如 Nvidia k8s-device-plugin) 返回给kubelet client数据结构：
     nvidia gpu 为例子， 这里面Envs 配置可以显示gpu uuid， 这些uuid都是kubelet决定， 在pod_device里面保存环境变量， 通过这些环境变量pod nvidia驱动可以见到这些设备。


```
pod_devvice.go

// Returns all of devices allocated to the pods being tracked, keyed by resourceName.
// manager.go ManagerImpl 接口经常用这个函数更新/恢复 m.allocatedDevices = m.podDevices.devices()
func (pdev podDevices) devices() map[string]sets.String {
	ret := make(map[string]sets.String)
	for _, containerDevices := range pdev {
		for _, resources := range containerDevices {
			for resource, devices := range resources {
				if _, exists := ret[resource]; !exists {
					ret[resource] = sets.NewString()
				}
                # allocResp 不能影响/修改设备已经使用列表 
				if devices.allocResp != nil {
					ret[resource] = ret[resource].Union(devices.deviceIds)
				}
			}
		}
	}
	return ret
}
```

  设备分配记录并不是在这个数据结构去获取， 通过device plugin 在多gpu分配时候侦测系统， 放回p2p gpu给pod方式目前1.11版本是不可行的。


### 总结 
    
     在deveice plugin Allocate去修改gpu分配，在1.11版本不支持，目前gpu分配，选择算法定义在kubelet上，确实可以通过修改deviceAllocate修改。 需要加入device plugin interface加入设备选择接口发送列表，让nvidia device plugin实现设备选择，返回最优化分配。不过影响其它device plugin 使用。 需要在研究微软KubeGPU, 怎么在kube scheduler上实现调度。


