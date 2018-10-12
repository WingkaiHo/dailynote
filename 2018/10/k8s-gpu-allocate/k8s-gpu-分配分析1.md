## Kubernetes GPU卡调度-Device plugin 接口

   机器GPU设备获取，在POD里面显示GPU卡通过 NVIDIA device plugin实现的(https://github.com/NVIDIA/k8s-device-plugin)。
   插件在k8s通过DaemonSet启动，默认在所有机器启动，最终只有在有GPU机器生效。
   在使用GPU Pod上面通过环境变量配置这个pod里面NVIDIA驱动可以看到哪个GPU， 例如POD里面可以见序号1,2,3的GPU, 可以通过`NVIDIA_VISIBLE_DEVICES=1,2,3`, 当然k8s里面这里`1,2,3`被GPU显卡对应uuid代替。

下面是kubelet device插件接口Go代码:

定义在, 接口都是由kubelet主动调用

k8s.io/kubernetes/pkg/kubelet/apis/deviceplugin/v1beta1/api.pb.go
```

kubelet 发送向device发送请求时候执行接口
type DevicePluginClient interface {
    // GetDevicePluginOptions returns options to be communicated with Device
    // Manager
    GetDevicePluginOptions(ctx context.Context, in *Empty, opts ...grpc.CallOption) (*DevicePluginOptions, error)
    // ListAndWatch returns a stream of List of Devices
    // Whenever a Device state change or a Device disapears, ListAndWatch
    // returns the new list
    ListAndWatch(ctx context.Context, in *Empty, opts ...grpc.CallOption) (DevicePlugin_ListAndWatchClient, error)
    // Allocate is called during container creation so that the Device
    // Plugin can run device specific operations and instruct Kubelet
    // of the steps to make the Device available in the container
    Allocate(ctx context.Context, in *AllocateRequest, opts ...grpc.CallOption) (*AllocateResponse, error)
    // PreStartContainer is called, if indicated by Device Plugin during registeration phase,
    // before each container start. Device plugin can run device specific operations
    // such as reseting the device before making devices available to the container
    PreStartContainer(ctx context.Context, in *PreStartContainerRequest, opts ...grpc.CallOption) (*PreStartContainerResponse, error)
}

device plugin需要实现接口函数
type DevicePluginServer interface {
    // GetDevicePluginOptions returns options to be communicated with Device
    // Manager
    // NVIDIA device plugin 没有接口做处理
    GetDevicePluginOptions(context.Context, *Empty) (*DevicePluginOptions, error)
    // ListAndWatch returns a stream of List of Devices
    // Whenever a Device state change or a Device disapears, ListAndWatch
    // returns the new list
    ListAndWatch(*Empty, DevicePlugin_ListAndWatchServer) error
    // Allocate is called during container creation so that the Device
    // Plugin can run device specific operations and instruct Kubelet
    // of the steps to make the Device available in the container
    // 需要申请GPU POD 创建前通过 DevicePluginClient 接口调用此接口
    // kubelet 调用时候在AllocateRequest里面指定gpu卡 uuid， device plugin负责加入到pod里面，nvidia插件通过配置pod环境变量
    Allocate(context.Context, *AllocateRequest) (*AllocateResponse, error)
    // PreStartContainer is called, if indicated by Device Plugin during registeration phase,
    // before each container start. Device plugin can run device specific operations
    // such as reseting the device before making devices available to the container
    // NVIDIA device plugin 没有接口做处理 
    PreStartContainer(context.Context, *PreStartContainerRequest) (*PreStartContainerResponse, error)
}
```

### Kubelet获取本机器显卡(ListAndWatch)

    Nvidia device plugin 启动服务以后执行注册通知kubelet, 这里不特别展示代码， 主要device plugin 的`ListAndWatch`接口， 代码是在`k8s-device-plugin`项目目录下server.go文件下

```
// ListAndWatch lists devices and update that list according to the health status
func (m *NvidiaDevicePlugin) ListAndWatch(e *pluginapi.Empty, s pluginapi.DevicePlugin_ListAndWatchServer) error {
	s.Send(&pluginapi.ListAndWatchResponse{Devices: m.devs})

	for {
		select {
		case <-m.stop:
			return nil
		case d := <-m.health:
			// FIXME: there is no way to recover from the Unhealthy state.
			d.Health = pluginapi.Unhealthy
			s.Send(&pluginapi.ListAndWatchResponse{Devices: m.devs})
		}
	}
}
```

   函数执行以后首先向client(kubelet)发送当前当前机器所有GPU 设备列表`m.devs`。 下面`m.devs`初始化代码
```
server.go
// NewNvidiaDevicePlugin returns an initialized NvidiaDevicePlugin
func NewNvidiaDevicePlugin() *NvidiaDevicePlugin {
	return &NvidiaDevicePlugin{
		devs:   getDevices(),
		socket: serverSock,

		stop:   make(chan interface{}),
		health: make(chan *pluginapi.Device),
	}
}

nvidia.go
func getDevices() []*pluginapi.Device {
	n, err := nvml.GetDeviceCount()
	check(err)

	var devs []*pluginapi.Device
	for i := uint(0); i < n; i++ {
		d, err := nvml.NewDeviceLite(i)
		check(err)
        # 获取列表，配置设备状态
		devs = append(devs, &pluginapi.Device{
			ID:     d.UUID,
			Health: pluginapi.Healthy,
		})
	}

	return devs
}
```

  由代码看出`m.devs`数组里面每个项目包含设备id， 设备状态。

  这个函数watch功能体现在下面代码
```
for {
		select {
        # 提供chan stop 给程序main函数发送退出信号，退出函数 
		case <-m.stop:
			return nil
        # 提供chan health 接收设备状态给把信号
		case d := <-m.health:
			// FIXME: there is no way to recover from the Unhealthy state.
			d.Health = pluginapi.Unhealthy
			s.Send(&pluginapi.ListAndWatchResponse{Devices: m.devs})
		}
	}
```

  Golang select 类似linux c select()函数， 这里侦测chan对端是否有数据发送，如果没有数据就阻塞. 如果有数据接收。 外面for循环防止接收信号后函数退出。


```
health 定义:
type NvidiaDevicePlugin struct {
	devs   []*pluginapi.Device
	socket string

	stop   chan interface{}
    # devs数组项目指针
	health chan *pluginapi.Device
	server *grpc.Server
}

直接修改对应设备健康状态
d.Health = pluginapi.Unhealthy

发送所有设备状态列表， 通知kubelet GPU卡状态改变
s.Send(&pluginapi.ListAndWatchResponse{Devices: m.devs})
```

### Device plugin 接收显卡申请

   下面NVIDIA 实现Allocate接口代码
```
// Allocate which return list of devices.
func (m *NvidiaDevicePlugin) Allocate(ctx context.Context, reqs *pluginapi.AllocateRequest) (*pluginapi.AllocateResponse, error) {
	devs := m.devs
	responses := pluginapi.AllocateResponse{}
	for _, req := range reqs.ContainerRequests {
        # kubelet 在reqs.ContainerRequests 里面指定了GPU 需要申请GPU id
		response := pluginapi.ContainerAllocateResponse{
			Envs: map[string]string{
				"NVIDIA_VISIBLE_DEVICES": strings.Join(req.DevicesIDs, ","),
			},
		}

		for _, id := range req.DevicesIDs {
			if !deviceExists(devs, id) {
				return nil, fmt.Errorf("invalid allocation request: unknown device: %s", id)
			}
		}

		responses.ContainerResponses = append(responses.ContainerResponses, &response)
	}

	return &responses, nil
}
```

  kubelet 在reqs.ContainerRequests 里面指定了GPU需要申请GPU id. device plugin 工作是把这些id 加入到容器环境变量中， 

```
response := pluginapi.ContainerAllocateResponse{
    Envs: map[string]string{
        "NVIDIA_VISIBLE_DEVICES": strings.Join(req.DevicesIDs, ","),
    },

```

  在返回之前， 检查这些设备id是否有效，如果存在无效id返回错误

```
 for _, id := range req.DevicesIDs {
            if !deviceExists(devs, id) {
                return nil, fmt.Errorf("invalid allocation request: unknown device: %s", id)
            }
        }

```

  此接口能否修改kubelet发送过来GPU id为其它我们想要的(解决多分配时候考略GPU之间的连接方式问题)， 需要看kubelet上层代码， 但是这里面还是缺乏GPU分配信息，使用情况。不能确定，需要分析Kubelet源代码。

### 总结

  NVIDIA k8s device 插件用户注册GPU设备， 返回设备变更， 还有容器创建前根据kubelet需要申请显卡id加入环境变量。显卡回收等都不是这个插件管理，插件里面也不知道，没有保存申记录。整个GPU资源管理在kubelet上实现。

