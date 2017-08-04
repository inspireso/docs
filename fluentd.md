

## nginx

**nginx.conf**

```sh
log_format  main '$remote_addr $host [$time_local] $status "$request" $request_time $request_length $body_bytes_sent  "$http_referer" "$http_user_agent"
```

## fluentd

### tail

td-agent.conf**

```sh
<source>
  type tail
  path /usr/local/nginx/logs/*access.log
  pos_file /var/log/td-agent/nginx.access.log.pos
  tag nginx.access
  format /^(?<remote>[^ ]*) (?<host>[^ ]*) \[(?<time>[^\]]*)\] (?<code>[^ ]*) "(?<method>\S+)(?: +(?<path>[^\"]*) +\S*)?" (?<request_time>[^ ]*)(?<request_length>[^ ]*)(?<body_bytes_sent>[^ ]*)(?: "(?<referer>[^\"]*)" "(?<user_agent>[^\"]*)")?$/
  types remote:string,host:string,time:time,code:string,method:string,path:string,request_time：float,request_length:integer,body_bytes_sent:integer,referer:string,user_agent:string
  time_format %d/%b/%Y:%H:%M:%S %z
</source>
```

### influxdb

**安装**

```sh
td-agent-gem install fluent-plugin-influxdb
```

**使用**

```sh
<match nginx.access>
  @type influxdb
  host xxx.xxx.xxx.xxx
  port 8086
  dbname nginx
  measurement access
  user root
  password xxxxxx
  use_ssl false
  time_precision ms
  tag_keys ["host","agent","code","method"]
  time_key time
</match>
```

### elasticsearch

**安装**

```sh
td-agent-gem install fluent-plugin-elasticsearch
```

**使用**

```sh
<match nginx.access>
  type elasticsearch
  log_level info
  include_tag_key true
  host xxx.xxx.xxx.xxx
  port xxxx
  logstash_format true
  logstash_prefix nginx
  buffer_chunk_limit 2M
  flush_interval 5s
  max_retry_wait 30
  disable_retry_limit
  num_threads 8
</match>
```



