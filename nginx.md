## 环境

- OS: centos7

## 编译/安装tengine/打包

 ```sh
# 安装编译工具
$ yum install -y epel-release
$ yum install -y gcc make libc-devel  openssl-devel pcre-devel zlib-devel jemalloc-devel bzip2

#下载源代码
$ cd /usr/src/
$ curl --insecure -o jemalloc-5.0.1.tar.bz2  https://github.com/jemalloc/jemalloc/releases/download/5.0.1/jemalloc-5.0.1.tar.bz2
$ tar xjf jemalloc-5.0.1.tar.bz2

$ cd /usr/src/
$ curl --insecure -o openssl-1.0.2l.tar.gz  https://www.openssl.org/source/openssl-1.0.2l.tar.gz
$ tar xzf openssl-1.0.2l.tar.gz

$ curl -o tengine-2.2.0.tar.gz http://tengine.taobao.org/download/tengine-2.2.0.tar.gz
$ tar xzf tengine-2.2.0.tar.gz
$ cd tengine-2.2.0
$ ./configure  \
	--user=nginx \
  	--group=nginx \
  	--pid-path=/var/run/nginx.pid \
  	--lock-path=/var/run/nginx.lock \
  	--http-client-body-temp-path=/var/cache/nginx/client_temp \
  	--http-proxy-temp-path=/var/cache/nginx/proxy_temp \
    --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
    --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
    --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
    --with-http_v2_module \
    --with-openssl=/usr/src/openssl-1.0.2l \
    --with-jemalloc=/usr/src/jemalloc-5.0.1
    
    
$ make & make install
$ ln -s /usr/local/nginx/sbin/nginx /usr/local/sbin/nginx
$ cat <<EOF > /usr/lib/systemd/system/nginx.service
[Unit]
Description=nginx - high performance web server
Documentation=http://nginx.org/en/docs/
After=network-online.target remote-fs.target nss-lookup.target
Wants=network-online.target

[Service]
Type=forking
PIDFile=/run/nginx.pid
ExecStartPre=/usr/local/nginx/sbin/nginx -t -c /usr/local/nginx/conf/nginx.conf
ExecStart=/usr/local/nginx/sbin/nginx -c /usr/local/nginx/conf/nginx.conf
ExecReload=/bin/kill -s HUP $MAINPID
ExecStop=/bin/kill -s QUIT $MAINPID

[Install]
WantedBy=multi-user.target

EOF

# 打包
$ tar -czvf tengine-2.2.0-centos7.tar.gz /usr/local/nginx /usr/local/sbin/nginx /usr/lib/systemd/system/nginx.service
 ```

## 直接安装

```sh
$ curl -v -o --insecure tengine-2.2.0-centos7.tar.gz  "https://github.com/inspireso/docs/blob/master/resources/tengine-2.2.0-centos7.tar.gz" 
$ tar xzf tengine-2.2.0-centos7.tar.gz -C /
#添加nginx用户和用户组
$ useradd -d /var/cache/nginx -s /sbin/nologin -U nginx
# 系统自动启动
$ systemctl enable nginx && systemctl start nginx.service
```

## 优化配置

### 修改最大连接数

- /etc/security/limits.conf

```sh
#修改最大连接数
$ echo root soft nofile 65535 >> /etc/security/limits.conf
$ echo root hard nofile 65535 >> /etc/security/limits.conf
$ echo * soft nofile 65535 >> /etc/security/limits.conf
$ echo * hard nofile 65535 >> /etc/security/limits.conf
```

- /usr/local/nginx/conf/nginx.conf

```sh
worker_processes  auto;
worker_cpu_affinity auto;
worker_rlimit_nofile 65535;
events {
    worker_connections  65535;
}
```

- 查看是否生效

```bash
$ ps aux | grep nginx | grep worker
nginx    11897  0.0  1.6  79392 31412 ?        S    Aug01   0:24 nginx: worker process
$ cat /proc/11897/limits
Limit                     Soft Limit           Hard Limit           Units
Max cpu time              unlimited            unlimited            seconds
Max file size             unlimited            unlimited            bytes
Max data size             unlimited            unlimited            bytes
Max stack size            8388608              unlimited            bytes
Max core file size        0                    unlimited            bytes
Max resident set          unlimited            unlimited            bytes
Max processes             7276                 7276                 processes
Max open files            65535                65535                files
Max locked memory         65536                65536                bytes
Max address space         unlimited            unlimited            bytes
Max file locks            unlimited            unlimited            locks
Max pending signals       7276                 7276                 signals
Max msgqueue size         819200               819200               bytes
Max nice priority         0                    0
Max realtime priority     0                    0
Max realtime timeout      unlimited            unlimited            us
```

### linux内核参数

```sh
#表示进程（例如一个worker进程）可能同时打开的最大句柄数，直接限制最大并发连接数
fs.file-max = 999999

#1代表允许将状态为TIME-WAIT状态的socket连接重新用于新的连接。对于服务器来说有意义，因为有大量的TIME-WAIT状态的连接
net.ipv4.tcp_tw_reuse = 1

#当keepalive启用时，TCP发送keepalive消息的频率。默认是2个小时。将其调小一些，可以更快的清除无用的连接
net.ipv4.tcp_keepalive_time = 600

#当服务器主动关闭链接时，socket保持FN-WAIT-2状态的最大时间
net.ipv4.tcp_fin_timeout = 30

#允许TIME-WAIT套接字数量的最大值。超过些数字，TIME-WAIT套接字将立刻被清除同时打印警告信息。默认是180000，过多的TIME-WAIT套接字会使webserver变慢
net.ipv4.tcp_max_tw_buckets = 5000

#UDP和TCP连接中本地端口（不包括连接的远端）的取值范围
net.ipv4.ip_local_port_range = 1024　　61000

#TCP接收/发送缓存的最小值、默认值、最大值
net.ipv4.tcp_rmem = 4096　　32768　　262142
net.ipv4.tcp_wmem = 4096　　32768　　262142

#当网卡接收的数据包的速度大于内核处理的速度时，会有一个队列保存这些数据包。这个参数就是这个队列的最大值。
net.core.netdev_max_backlog = 8096

#内核套接字接收/发送缓存区的默认值
net.core.rmem_default = 262144
net.core.wmem_default = 262144

#内核套接字接收/发送缓存区的最大值
net.core.rmem_max = 2097152
net.core.wmem_max = 2097152

#解决TCP的SYN攻击。与性能无关
net.ipv4.tcp_syncookies = 1

#三次握手建立阶段SYN请求队列的最大长度，默认是1024。设置大一些可以在繁忙时将来不及处理的请求放入队列，而不至于丢失客户端的请求
net.ipv4.tcp_max_syn_backlog = 1024
```

## FAQ

### 打开的文件数

```sh
# 查看整个系统打开的文件数
cat /proc/sys/fs/file-nr
1376    0       791284
已分配文件句柄的数目 / 分配了但没有使用的句柄数目 / 文件句柄的最大数目

# 查看某个进程pid打开的文件数
ls /proc/pid/fd | wc -l

#或者，需要安装yum install -y lsof
lsof -p pid | wc -l 
```

### 爬虫

```sh
# http
map $http_user_agent $limit_bots {
    default 0;
    ~*(qihoobot|Baiduspider|Googlebot|YoudaoBot|Sosospider) 1;
    ~*(Adsbot-Google|Feedfetcher-Google|Googlebot-Mobile|Googlebot-Image|Mediapartners-Google) 1;
    ~*(Slurp|spider|MSNBot|ia_archiver|Bot) 1;
}

# server
if ($limit_bots = 1) {
	return 403;
}
```

## user-agent

```sh
# http
map $http_user_agent $is_mobile {
    default 0;
    ~*(Android|iPhone|IEMoble|Mobile|WAP|Smartphone) 1;
}

# server, location
if ($is_mobile = 0) {
  proxy_pass  http://ups_account;
  break;
}

```

