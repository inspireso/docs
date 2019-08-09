修改数据库字符集：
```sql
ALTER DATABASE db_name DEFAULT CHARACTER SET character_name [COLLATE ...];
```

把表默认的字符集和所有字符列（CHAR,VARCHAR,TEXT）改为新的字符集：
```sql
ALTER TABLE tbl_name CONVERT TO CHARACTER SET character_name [COLLATE ...]
如：ALTER TABLE logtest CONVERT TO CHARACTER SET utf8 COLLATE utf8_general_ci;
```

只是修改表的默认字符集：
```sql
ALTER TABLE tbl_name DEFAULT CHARACTER SET character_name [COLLATE...];
如：ALTER TABLE logtest DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
```
修改字段的字符集：

```sql
ALTER TABLE tbl_name CHANGE c_name c_name CHARACTER SET character_name [COLLATE ...];
如：ALTER TABLE logtest CHANGE title title VARCHAR(100) CHARACTER SET utf8 COLLATE utf8_general_ci;
```
查看数据库编码：
```sql
SHOW CREATE DATABASE db_name;
```
查看表编码：
```sql
SHOW CREATE TABLE tbl_name;
```
查看字段编码：
```sql
SHOW FULL COLUMNS FROM tbl_name;
```
