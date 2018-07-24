# [Gitlib](https://docs.gitlab.com/omnibus/)

## 启动

```sh
docker run -d \
    -p 5000:5000 -p 80:8081 -p 22:22 \
    --name gitlab \
    --restart always \
    -v $GITLAB_HOME/config:/etc/gitlab \
    -v $GITLAB_HOME/logs:/var/log/gitlab \
    -v $GITLAB_HOME/data:/var/opt/gitlab \
    gitlab/gitlab-ce:latest
```

## [配置](https://docs.gitlab.com/omnibus/)

```sh
docker exec -t -i gitlab vim /etc/gitlab/gitlab.rb
```

## 重启

```sh
docker restart gitlab
```

## 作为服务

### 编辑 `/usr/lib/systemd/system/gitlab.service`

```json
[Unit]
Description=Gitlab Service
After=docker.service
Requires=docker.service

[Service]
Environment="PORT=-p 80:80 -p 8443:443 -p 2222:22"
Environment="VOLUME=-v /gitlab/config:/etc/gitlab -v /gitlab/logs:/var/log/gitlab -v /gitlab/data:/var/opt/gitlab"
Environment="ENV="
Environment="ARGS="
Environment="IMAGE=gitlab/gitlab-ce"
ExecStartPre=-/usr/bin/docker stop %n
ExecStartPre=-/usr/bin/docker rm %n
ExecStart=/usr/bin/docker run --name %n $PORT $VOLUME $ENV $IMAGE $ARGS
TimeoutStartSec=0
Restart=always

[Install]
WantedBy=multi-user.target
```

## gitlab-runner

```sh
# 启动一个runner
docker run --restart=always -d --name gitlab-runner -v /gitlab/runner:/etc/gitlab-runner  -v /var/run/docker.sock:/var/run/docker.sock gitlab/gitlab-runner:latest

#注册,按照要求填写
docker exec -it gitlab-runner  gitlab-ci-multi-runner register  --locked=false 
```

## svn迁移到git

```sh
#签出代码为git库
git svn clone http://xxx.xxx.xxx.xxx/svn/project -s --authors-file=users.txt
cd dc
#再次更新到最新代码
git svn fetch
#添加git远程地址
git remote add origin https://your.gitlabdomain.com/your-group/your-project.git
#同步本地库到远程
git push --set-upstream origin master
```

## docker-gc

```sh
#!/bin/bash

EXCLUDE_FROM_GC=('registry.uutaka.com/docker/ci-tools:latest' 'registry.uutaka.com/docker/docker-maven/maven:3.5-jdk-8')

# Remove all the dangling images
docker rmi $(docker images -qf "dangling=true")

# Get all the images currently in use
USED_IMAGES=($( \
    docker ps -a --format '{{.Image}}' | \
    sort -u | \
    uniq | \
    awk -F ':' '$2{print $1":"$2}!$2{print $1":latest"}' \
))

# Get all the images currently available
ALL_IMAGES=($( \
    docker images --format '{{.Repository}}:{{.Tag}}' | \
    sort -u \
))

# Remove the unused images
for i in "${ALL_IMAGES[@]}"; do
    UNUSED=true
    for j in "${USED_IMAGES[@]}"; do
        if [[ "$i" == "$j" ]]; then
            UNUSED=false
        fi
    done
    for k in "${EXCLUDE_FROM_GC[@]}"; do
        if [[ "$i" == "$k" ]]; then
            UNUSED=false
        fi
    done
    if [[ "$UNUSED" == true ]]; then
        docker rmi "$i"
    fi
done
```

## 备份/还原

### 备份

参考: https://docs.gitlab.com/ce/raketasks/backup_restore.html

*/etc/cron.daily/gitlab-backup.sh*

```sh
#!/bin/sh

set -e

BACKUP_DIR=/mnt/backup/
CONTAINER_ID=$(docker ps -q --filter ancestor="gitlab/gitlab-ce:10.5.8-ce.0")
mkdir -p $BACKUP_DIR
#清空上一次本地备份
rm -f /gitlab/data/backups/*.tar
docker exec -t $CONTAINER_ID gitlab-rake gitlab:backup:create SKIP=uploads,builds,artifacts,registry
#清空上一次远程本分
rm -f $BACKUP_DIR/*.tar
tar -czf $BACKUP_DIR/$(date "+etc-gitlab-%s_%F.tar") /gitlab/config
cp /gitlab/data/backups/*.tar  $BACKUP_DIR

exit 0
```

### 还原

```sh
## 还原配置文件（首次初始化的时候需要执行）
tar -xvf /mnt/backup/gitlab/etc-gitlab-xxx.tar -C /

## 拷贝备份文件到/gitlab/data/backup目录
cp /mnt/backup/gitlab/xxxx_gitlab_backup.tar /gitlab/data/backups/

## 还原数据
#找到gitlab对应的pod
kubectl -n devops get pod
kubectl -n devops exec -it gitlab-<b99b8c694-8ckhr> -- bash

#重新读取配置（首次初始化的时候需要执行）
gitlab-ctl reconfigure
gitlab-ctl restart

#还原指令
gitlab-ctl stop unicorn
gitlab-ctl stop sidekiq
# Verify
gitlab-ctl status
chown git:git -R /var/opt/gitlab/backups/
gitlab-rake gitlab:backup:restore BACKUP=1493107454_2018_04_25_10.6.4
gitlab-ctl restart
gitlab-rake gitlab:check SANITIZE=true
```
