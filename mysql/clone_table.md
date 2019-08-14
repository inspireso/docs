## 复制表结构

```sql
create table tbl_name_bak like tbl_name;
```

## 复制表结构和数据

```sql
create table tbl_name_bak like tbl_name;
insert into tbl_name_bak
select *
from tbl_name;
```

