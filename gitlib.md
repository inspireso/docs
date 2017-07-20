# [Gitlib](https://docs.gitlab.com/omnibus/)

## 启动

```sh
docker run -d \
    --hostname gitlab \
    --publish 8443:443 --publish 80:80 --publish 2222:22 \
    --name gitlab \
    --restart always \
    --volume $GITLAB_HOME/config:/etc/gitlab \
    --volume $GITLAB_HOME/logs:/var/log/gitlab \
    --volume $GITLAB_HOME/data:/var/opt/gitlab \
    gitlab/gitlab-ce
```

## [配置](https://docs.gitlab.com/omnibus/)

```sh
docker exec -t -i gitlab vim /etc/gitlab/gitlab.rb
```

## 重启

```sh
docker restart gitlab
```

