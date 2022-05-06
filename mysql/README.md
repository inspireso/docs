# MySQL

## 常用查询

### 空间

```sql
# 查询数据 schema 空间
select
    table_schema as '数据库',
    sum(table_rows) as '记录数',
    sum(truncate(data_length/1024/1024, 2)) as '数据容量(MB)',
    sum(truncate(index_length/1024/1024, 2)) as '索引容量(MB)'
from information_schema.tables
group by table_schema
order by sum(data_length) desc, sum(index_length) desc;

# 查询 table 空间
select
    table_schema as '数据库',
    table_name as '表名',
    table_rows as '记录数',
    truncate(data_length/1024/1024, 2) as '数据容量(MB)',
    truncate(index_length/1024/1024, 2) as '索引容量(MB)'
from information_schema.tables
order by data_length desc, index_length desc;

```