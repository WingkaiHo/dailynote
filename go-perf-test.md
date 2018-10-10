### 1. http 性能测试例子

### 1.1 http性能调优例子
    
下载和编译测试例子
```
$ git github.com/domac/playflame

进入源代码目录
$ cd $GOPATH/src/github.com/domac/playflame 
编译代码
$ go build
```

启动实例, 通过浏览器访问
```
$ playflame

浏览器访问 http://localhost:9090/simple 和 http://localhost:9090/advance

正常都会输出:
Hello VIP!
```

### 1.2 PrintStat打印状态
 
  虽然输出的内容是一样的，但 /advance 接口附加了一些统计功能，我们可以在终端上启动web服务时，多增加printStats参数：
```
$ go run main.go -printStats
```


### 1.2.1 下载go http并发工具

   go-wrk http压力测试工具压测的工具，除此之外，vegeta等http压测工具。

下载并安装go-wrk
```
$ go get github.com/adjust/go-wrk
$ go install github.com/adjust/go-wrk
```

go-wrk并发测试参数
```
-H="User-Agent: go-wrk 0.1 bechmark\nContent-Type: text/html;": the http headers sent separated by '\n'
-c=100: the max numbers of connections used
-k=true: if keep-alives are disabled
-i=false: if TLS security checks are disabled
-m="GET": the http request method
-n=1000: the total number of calls processed
-t=1: the numbers of threads used
-b="" the http request body
```

go-wrk并发测试命令
```
$ go-wrk -c=400 -t=8 -n=100000 http://localhost:9090/advance

==========================BENCHMARK==========================
URL:				http://localhost:9090/advance

Used Connections:		400
Used Threads:			8
Total number of calls:		100000

===========================TIMINGS===========================
Total time passed:		10.14s
Avg time per request:		34.36ms
Requests per second:		9859.38
Median time per request:	16.57ms
99th percentile time:		1015.63ms
Slowest time for request:	3055.00ms

=============================DATA=============================
Total response body sizes:		1100000
Avg response body per request:		11.00ms
Transfer rate per second:		108453.19 Byte/s (0.11 MByte/s)
==========================RESPONSES==========================
20X Responses:		100000	(100.00%)
30X Responses:		0	(0.00%)
40X Responses:		0	(0.00%)
50X Responses:		0	(0.00%)
Errors:			0	(0.00%)
```

当我们刷新接口地址的时候，终端都会把访问信息打印出来，如下:
```
IncCounter: handler.received.host-hyj.advance.no-os.no-browser = 1
RecordTimer: handler.latency.host-hyj.advance.no-os.no-browser = 301.54µs
RecordTimer: handler.latency.host-hyj.advance.no-os.no-browser = 1.380782ms
RecordTimer: handler.latency.host-hyj.advance.no-os.no-browser = 60.365µs
RecordTimer: handler.latency.host-hyj.advance.no-os.no-browser = 855.718µs
IncCounter: handler.received.host-hyj.advance.no-os.no-browser = 1
IncCounter: handler.received.host-hyj.advance.no-os.no-browser = 1
RecordTimer: handler.latency.host-hyj.advance.no-os.no-browser = 1.202379ms
IncCounter: handler.received.host-hyj.advance.no-os.no-browser = 1
RecordTimer: handler.latency.host-hyj.advance.no-os.no-browser = 37.744µs
RecordTimer: handler.latency.host-hyj.advance.no-os.no-browser = 1.240866ms
IncCounter: handler.received.host-hyj.advance.no-os.no-browser = 1
RecordTimer: handler.latency.host-hyj.advance.no-os.no-browser = 714.513µs
.....

```
