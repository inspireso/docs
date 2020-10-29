# 准备工作
不同的机器、操作系统、web服务器以及相关参数等的不同，也会影响性能测试的结果。有必要在测试前对参数进行一下配置。
比如做一次性能测试并对高负载系统，网络参数进行调优。这里列一下操作系统的几个重要参数。

```sh
fs.file-max = 999999 
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_max_tw_buckets = 5000
net.ipv4.ip_local_port_range = 1024 61000
net.ipv4.tcp_rmem = 4096 32768 262142
net.ipv4.tcp_wmem = 4096 32768 262142
net.core.netdev_max_backlog = 8096
net.core.rmem_default = 262144
net.core.wmem_default = 262144
net.core.rmem_max = 2097152
net.core.wmem_max = 2097152
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn.backlog=1024
```

- file-max：这个参数表示进程（比如一个worker进程）可以同时打开的最大句柄数，这个参数直接限制最大并发连接数，需根据实际情况配置。
- tcp_tw_reuse：这个参数设置为1，表示允许将TIME-WAIT状态的socket重新用于新的TCP连接，这对于服务器来说很有意义，因为服务器上总会有大量TIME-WAIT状态的连接。 - tcp_keepalive_time：这个参数表示当keepalive启用时，TCP发送keepalive消息的频度。默认是2小时，若将其设置得小一些，可以更快地清理无效的连接。
- tcp_fin_timeout：这个参数表示当服务器主动关闭连接时，socket保持在FIN-WAIT-2状态的最大时间。
- tcp_max_tw_buckets：这个参数表示操作系统允许TIME_WAIT套接字数量的最大值，如果超过这个数字，TIME_WAIT套接字将立刻被清除并打印警告信息。该参数默认为180000，过多的TIME_WAIT套接字会使Web服务器变慢。
- tcp_max_syn_backlog：这个参数表示TCP三次握手建立阶段接收SYN请求队列的最大长度，默认为1024，将其设置得大一些可以使出现Nginx繁忙来不及accept新连接的情况时，Linux不至于丢失客户端发起的连接请求。
- ip_local_port_range：这个参数定义了在UDP和TCP连接中本地（不包括连接的远端）端口的取值范围。
- net.ipv4.tcp_rmem：这个参数定义了TCP接收缓存（用于TCP接收滑动窗口）的最小值、默认值、最大值。
- net.ipv4.tcp_wmem：这个参数定义了TCP发送缓存（用于TCP发送滑动窗口）的最小值、默认值、最大值。
- netdev_max_backlog：当网卡接收数据包的速度大于内核处理的速度时，会有一个队列保存这些数据包。这个参数表示该队列的最大值。
- rmem_default：这个参数表示内核套接字接收缓存区默认的大小。
- wmem_default：这个参数表示内核套接字发送缓存区默认的大小。
- rmem_max：这个参数表示内核套接字接收缓存区的最大大小。
- wmem_max：这个参数表示内核套接字发送缓存区的最大大小。
- tcp_syncookies：该参数与性能无关，用于解决TCP的SYN攻击。

# ab

ab 测试工具是 Apache 提供的一款测试工具，具有简单易上手的特点，在测试 Web 服务时非常实用。

## 安装

```sh
#centos
yum install -y httpd-tools
#ubuntu
apt-get install -y apache2-utils
```

## 使用

```sh
#扩大并发连接数
ulimit -n  65535

##POST
ab -n 100  -c 10 -p 'post.txt' -T 'application/x-www-form-urlencoded' 'http://test.api.com/test/register'
#post.txt 为存放 post 参数的文档，存储格式如下
usernanme=test&password=test&sex=1

##GET
ab -c 10 -n 100 http://www.test.api.com/test/login?userName=test&password=test

```

**参数说明**

- -n：表示请求总数(与-t参数可任选其一)
- -t：标识请求时间
- -c：表示并发数（最小默认为 1 且不能大于总请求次数，例如：10 个请求，10 个并发，实际就是 1 人请求 1 次）；
- -p：模拟post请求，文件格式为gid=2&status=1（-p 和 -T 参数要配合使用）
- -T：post数据所使用的Content-Type头信息，如 -T 'application/x-www-form-urlencoded'

**输出说明**

- Requests per second：吞吐率，指某个并发用户数下单位时间内处理的请求数；
- Time per request：上面的是用户平均请求等待时间，指处理完成所有请求数所花费的时间 /（总请求数 / 并发用户数）；
- Time per request：下面的是服务器平均请求处理时间，指处理完成所有请求数所花费的时间 / 总请求数；
- Percentage of the requests served within a certain time：每秒请求时间分布情况，指在整个请求中，每个请求的时间长度的分布情况，例如有 50% 的请求响应在 8ms 内，66% 的请求响应在 10ms 内，说明有 16% 的请求在 8ms~10ms 之间。

# [wrk](https://github.com/wg/wrk)

## 安装

```sh
yum install -y https://extras.getpagespeed.com/release-el7-latest.rpm
yum install -y wrk

//OR

yum groupinstall 'Development Tools'
yum install -y openssl-devel git 
git clone --depth=1 https://github.com/wg/wrk.git wrk
cd wrk
make
# move the executable to somewhere in your PATH
cp wrk /usr/local/bin
chmod +x /usr/local/bin/wrk

```

## 使用

```sh
## GET
wrk -t 8 -c 200 -d 30s http://172.16.2.162:8081/0k.txt

## POST
wrk -t 8 -c 200 -d 30s -s post.lua --latency http://192.168.31.107/user/login
#post.lua
wrk.method = "POST"
wrk.headers["Content-Type"] = "application/x-www-form-urlencoded"
wrk.body = "youbody&youset"
```

参数说明**

-c：总的连接数（每个线程处理的连接数=总连接数/线程数）
-d：测试的持续时间，如2s(2second)，2m(2minute)，2h(hour)，默认为s
-t：需要执行的线程总数，默认为2，一般线程数不宜过多. 核数的2到4倍足够了. 多了反而因为线程切换过多造成效率降低
-s：执行Lua脚本，这里写lua脚本的路径和名称，后面会给出案例
-H：需要添加的头信息，注意header的语法，举例，-H “token: abcdef”
--timeout：超时的时间
--latency：显示延迟统计信息

**输出说明**

Latency：响应时间
Req/Sec：每个线程每秒钟的执行的连接数
Avg：平均
Max：最大
Stdev：标准差
+/- Stdev： 正负一个标准差占比
Requests/sec：每秒请求数（也就是QPS），等于总请求数/测试总耗时
Latency Distribution，如果命名中添加了—latency就会出现相关信息

## lua脚本说明

wrk 压测脚本有3个生命周期, 分别是 启动阶段,运行阶段和结束阶段,每个线程都有自己的lua运行环境



### 启动阶段

```sh
function setup(thread)
在脚本文件中实现setup方法，wrk就会在测试线程已经初始化但还没有启动的时候调用该方法。wrk会为每一个测试线程调用一次setup方法，并传入代表测试线程的对象thread作为参数。setup方法中可操作该thread对象，获取信息、存储信息、甚至关闭该线程。
-- thread提供了1个属性，3个方法
-- thread.addr 设置请求需要打到的ip
-- thread:get(name) 获取线程全局变量
-- thread:set(name, value) 设置线程全局变量
-- thread:stop() 终止线程

```

### 运行阶段

```sh
function init(args)
-- 每个线程仅调用1次，args 用于获取命令行中传入的参数, 例如 --env=pre

function delay()
-- 每次请求调用1次，发送下一个请求之前的延迟, 单位为ms

function request()
-- 每次请求调用1次，返回http请求

function response(status, headers, body)
-- 每次请求调用1次，返回http响应

init由测试线程调用，只会在进入运行阶段时，调用一次。支持从启动wrk的命令中，获取命令行参数； delay在每次发送request之前调用，如果需要delay，那么delay相应时间； request用来生成请求；每一次请求都会调用该方法，所以注意不要在该方法中做耗时的操作； reponse在每次收到一个响应时调用；为提升性能，如果没有定义该方法，那么wrk不会解析headers和body；
结束阶段

```

### 结束阶段

```sh
function done(summary, latency, requests)


latency.min              -- minimum value seen
latency.max              -- maximum value seen
latency.mean             -- average value seen
latency.stdev            -- standard deviation
latency:percentile(99.0) -- 99th percentile value
latency(i)               -- raw value and count

summary = {
  duration = N,  -- run duration in microseconds
  requests = N,  -- total completed requests
  bytes    = N,  -- total bytes received
  errors   = {
    connect = N, -- total socket connection errors
    read    = N, -- total socket read errors
    write   = N, -- total socket write errors
    status  = N, -- total HTTP status codes > 399
    timeout = N  -- total request timeouts
  }
}

该方法在整个测试过程中只会调用一次，可从参数给定的对象中，获取压测结果，生成定制化的测试报告。
```

### 线程变量

```sh
wrk = {
    scheme  = "http",
    host    = "localhost",
    port    = nil,
    method  = "GET",
    path    = "/",
    headers = {},
    body    = nil,
    thread  = <userdata>,
}

-- 生成整个request的string，例如：返回
-- GET / HTTP/1.1
-- Host: tool.lu
function wrk.format(method, path, headers, body)
-- method: http方法, 如GET/POST/DELETE 等
-- path:   url的路径, 如 /index, /index?a=b&c=d
-- headers: 一个header的table
-- body:    一个http body, 字符串类型

-- 获取域名的IP和端口，返回table，例如：返回 `{127.0.0.1:80}`
function wrk.lookup(host, service)
-- host:一个主机名或者地址串(IPv4的点分十进制串或者IPv6的16进制串)
-- service：服务名可以是十进制的端口号，也可以是已定义的服务名称，如ftp、http等


-- 判断addr是否能连接，例如：`127.0.0.1:80`，返回 true 或 false
function wrk.connect(addr)
```

每个request的参数都不一样
```lua
request = function()
   uid = math.random(1, 10000000)
   path = "/test?uid=" .. uid
   return wrk.format(nil, path)
end

解释一下wrk.format这个函数
wrk.format这个函数的作用,根据参数和全局变量wrk生成一个http请求
函数签名: 
function wrk.format(method, path, headers, body)
method:http方法,比如GET/POST等
path: url上的路径(含函数)
headers: http header
body: http body

```

发送JSON

```lua
request = function()
    local headers = { }
    headers['Content-Type'] = "application/json"
    body = {
        mobile={"1533899828"},
        params={code=math.random(1000,9999)}
    }

    local cjson = require("cjson")
    body_str = cjson.encode(body)
    return wrk.format('POST', nil, headers, body_str)
end
```