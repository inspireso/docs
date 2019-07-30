# ab

ab 测试工具是 Apache 提供的一款测试工具，具有简单易上手的特点，在测试 Web 服务时非常实用。

## 安装

```sh
yum install -y httpd-tools
```

## 使用

```sh
##POST
ab -n 100  -c 10 -p 'post.txt' -T 'application/x-www-form-urlencoded' 'http://test.api.com/test/register'
#post.txt 为存放 post 参数的文档，存储格式如下
usernanme=test&password=test&sex=1

##GET
ab -c 10 -n 100 http://www.test.api.com/test/login?userName=test&password=test

```

**参数说明：**

- -n：总请求次数（最小默认为 1）；
- -c：并发次数（最小默认为 1 且不能大于总请求次数，例如：10 个请求，10 个并发，实际就是 1 人请求 1 次）；
- -p：post 参数文档路径（-p 和 -T 参数要配合使用）；
- -T：header 头内容类型（此处切记是大写英文字母 T）。

**输出说明：**

- Requests per second：吞吐率，指某个并发用户数下单位时间内处理的请求数；
- Time per request：上面的是用户平均请求等待时间，指处理完成所有请求数所花费的时间 /（总请求数 / 并发用户数）；
- Time per request：下面的是服务器平均请求处理时间，指处理完成所有请求数所花费的时间 / 总请求数；
- Percentage of the requests served within a certain time：每秒请求时间分布情况，指在整个请求中，每个请求的时间长度的分布情况，例如有 50% 的请求响应在 8ms 内，66% 的请求响应在 10ms 内，说明有 16% 的请求在 8ms~10ms 之间。


