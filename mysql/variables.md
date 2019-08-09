
## SHOW VARIABLES Syntax
```sql
SHOW [GLOBAL | SESSION] VARIABLES
    [LIKE 'pattern' | WHERE expr]

-- example
show GLOBAL variables like '%transaction_isolation%';
```

## SET Syntax for Variable Assignment
```sql
SET variable = expr [, variable = expr] ...

variable: {
    user_var_name
  | param_name
  | local_var_name
  | {GLOBAL | @@GLOBAL.} system_var_name
  | [SESSION | @@SESSION. | @@] system_var_name
}
-- example
SET GLOBAL transaction_isolation = 'REPEATABLE-READ';
```