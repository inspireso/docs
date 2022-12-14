# python

## pip config

```sh
pip3 config set global.index-url https://mirrors.aliyun.com/pypi/simple/
```

或者

```sh
cat <<EOF > ~/.pip/pip.conf
[global]
index-url = https://mirrors.aliyun.com/pypi/simple/

[install]
trusted-host=mirrors.aliyun.com

EOF
```

