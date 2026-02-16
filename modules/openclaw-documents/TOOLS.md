# Tools

## Snowflake CLI
- **Binary:** `/etc/profiles/per-user/wz_oc/bin/snow`
- **Version:** Snowflake CLI 3.11.0
- **Connection:** default (JWT auth)
  - Account: `so07687.us-east-2.aws`
  - User: `BRADFORD_TONEY`
  - Role: `ANALYST_ROLE`
  - Warehouse: `ANALYST_WAREHOUSE`
  - Database: `DBT_PROD`
  - Schema: `ANALYTICS`
- **Query usage:** `snow sql -q "SELECT ..." [--format json]`
- **Config:** managed by Nix at `modules/home.nix`
- **dbt project:** `/Users/wz_oc/dbt/` — see `memory/snowflake-dbt-tables.md` for table reference
