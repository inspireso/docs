# VPN 管理脚本

OpenVPN 客户端证书管理工具集。

## 脚本列表

| 脚本 | 用途 |
|------|------|
| `openvpn_batch.sh` | 批量创建客户端证书和配置 |
| `check_ovpn_key.sh` | 检查单个 .ovpn 文件密码状态 |
| `check_ovpn_batch.sh` | 批量检查证书密码保护状态 |
| `rebuild_unencrypted.sh` | 重建未加密用户证书 |

---

## openvpn_batch.sh

批量创建 OpenVPN 客户端证书和配置文件。

### 使用方式

```bash
# 命令行指定用户
./openvpn_batch.sh create user1 user2 user3

# 从文件读取用户列表
./openvpn_batch.sh create -f users.txt

# 仅生成配置文件（证书已存在）
./openvpn_batch.sh build user1
```

### 参数说明

| 参数 | 说明 |
|------|------|
| `create` | 生成客户端证书（带密码）并创建配置文件 |
| `build` | 仅创建配置文件（证书已存在） |
| `-f <file>` | 从文件读取用户名列表（每行一个，支持 # 注释） |

### 密码规则

格式：`用户名@随机8位密码`

示例：`user1@Ab3kL9mP`

### CA 密码

脚本开始时一次性输入 CA 密码，用于签发所有证书。

### 输出文件

- 配置文件：`/etc/openvpn/client/<username>.ovpn`
- 密码记录：`/etc/openvpn/client/passwords.txt`

---

## check_ovpn_key.sh

检查单个 .ovpn 文件私钥是否加密。

### 使用方式

```bash
# 检查是否有密码保护
./check_ovpn_key.sh user1.ovpn

# 验证密码是否正确
./check_ovpn_key.sh user1.ovpn "user1@abc12345"
```

### 输出说明

```
[状态] 私钥已加密 ✓      # 有密码保护
[状态] 私钥未加密 ✗      # 无密码保护
[格式检查] ENCRYPTED PRIVATE KEY (PKCS#8)  # 加密格式
```

---

## check_ovpn_batch.sh

批量检查目录下的 .ovpn 文件密码保护状态，统计并列出未加密用户。

### 使用方式

```bash
# 扫描当前目录（默认）
./check_ovpn_batch.sh

# 扫描指定目录
./check_ovpn_batch.sh /etc/openvpn/client
```

### 输出示例

```
总用户数: 10
已加密: 7
未加密: 3

未加密用户: user1 user3 user5
```

### 返回值

- 0：全部已加密
- 1：有未加密文件

---

## rebuild_unencrypted.sh

重建未加密用户的证书（撤销旧证书，生成带密码的新证书）。

### 使用方式

```bash
# 交互模式（需确认）
./rebuild_unencrypted.sh user1 user2 user3

# 强制模式（跳过确认）
./rebuild_unencrypted.sh --force user1 user2

# 从文件读取用户列表
./rebuild_unencrypted.sh -f users.txt

# 强制模式 + 文件读取
./rebuild_unencrypted.sh --force -f users.txt
```

### 参数说明

| 参数 | 说明 |
|------|------|
| `<username>` | 要重建的用户名 |
| `--force` | 跳过确认步骤，直接重建 |
| `-f <file>` | 从文件读取用户名列表 |

### 执行流程

1. 显示待重建用户列表
2. 确认操作（除非 `--force`）
3. 输入 CA 密码（一次性）
4. 创建备份目录
5. 撤销旧证书
6. 备份旧证书文件（自动）
7. 删除旧证书文件
8. 生成新密码证书
9. 创建配置文件
10. 记录密码
11. 生成 CRL

### 自动备份

重建前自动备份旧证书到 `/etc/openvpn/client/backup/<时间戳>/`

备份文件：
- `<username>.crt` - 证书
- `<username>.key` - 私钥
- `<username>.req` - 请求文件
- `<username>.ovpn` - 配置文件

示例备份路径：`/etc/openvpn/client/backup/20240115_143000/`

### 注意事项

- 重建后需手动重启 OpenVPN 服务：`systemctl restart openvpn-server@jumper`
- 旧配置文件将失效，需分发新密码给用户
- 旧证书已自动备份，可在备份目录中找到

---

## 典型工作流程

### 1. 检查未加密用户

```bash
./check_ovpn_batch.sh /etc/openvpn/client
```

### 2. 重建未加密用户

```bash
# 查看未加密用户后重建
./rebuild_unencrypted.sh user1 user3

# 或使用 --force 自动执行
./rebuild_unencrypted.sh --force user1 user3
```

### 3. 验证重建结果

```bash
./check_ovpn_batch.sh /etc/openvpn/client
```

### 4. 重启服务

```bash
systemctl restart openvpn-server@jumper
```

---

## 用户列表文件格式

`users.txt` 示例：

```
# 这是注释行
user1
user2

user3
# 另一个注释
```

- 每行一个用户名
- 支持 `#` 开头的注释行
- 空行会被忽略

---

## 文件位置

| 文件 | 路径 |
|------|------|
| Easy-RSA 目录 | `/etc/openvpn/easy-rsa/3` |
| 客户端配置目录 | `/etc/openvpn/client` |
| 配置模板 | `/etc/openvpn/client/client.ovpn.tpl` |
| 密码记录文件 | `/etc/openvpn/client/passwords.txt` |