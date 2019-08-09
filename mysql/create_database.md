**创建数据库**
```sql
create database IF NOT EXISTS demo
  character set utf8mb4;
```

**创建用户**
```sql
create user demo identified by '123456';
```


**授权指定的数据库给指定的用户**
```sql
grant all privileges on demo.* to 'demo'@'%';
```

**显示指定用户的权限**
```sql
show grants for 'united'@'%';
```