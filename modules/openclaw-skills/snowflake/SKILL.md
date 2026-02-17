---
name: snowflake
description: Query Snowflake data warehouse and manage dbt models via the Snowflake CLI.
metadata:
  {
    "openclaw":
      {
        "emoji": "❄️",
        "requires": { "bins": ["snow"] },
      },
  }
---

# Snowflake — Querying & dbt

Use the `snow` CLI (Snowflake CLI v3) to run queries and inspect objects in Snowflake.

## Connection

- **Default connection:** `default` (auto-selected)
- **Account:** `so07687.us-east-2.aws`
- **User:** `BRADFORD_TONEY`
- **Auth:** Snowflake JWT (key-pair)
- **Role:** `ANALYST_ROLE`
- **Warehouse:** `ANALYST_WAREHOUSE`
- **Database:** `DBT_PROD`
- **Schema:** `ANALYTICS`

No credentials need to be passed — `snow` picks up the default connection automatically.

## Running queries

```bash
# Simple query
snow sql -q "SELECT * FROM my_table LIMIT 10"

# JSON output (great for piping / parsing)
snow sql -q "SELECT * FROM my_table LIMIT 10" --format json

# Multi-statement or longer queries — use heredoc
snow sql -q "$(cat <<'SQL'
SELECT
    date_trunc('month', created_at) AS month,
    count(*) AS total
FROM orders
GROUP BY 1
ORDER BY 1 DESC
LIMIT 12
SQL
)"

# Query a specific database/schema
snow sql -q "SELECT * FROM RAW.STRIPE.payments LIMIT 5"
```

## Useful commands

```bash
# List tables in current schema
snow sql -q "SHOW TABLES IN SCHEMA DBT_PROD.ANALYTICS"

# Describe a table
snow sql -q "DESCRIBE TABLE my_table"

# List schemas
snow sql -q "SHOW SCHEMAS IN DATABASE DBT_PROD"

# List warehouses
snow sql -q "SHOW WAREHOUSES"

# Check query history
snow sql -q "SELECT query_id, query_text, execution_status, total_elapsed_time
FROM TABLE(information_schema.query_history())
ORDER BY start_time DESC LIMIT 10"
```

## dbt project

The dbt project lives at `/Users/wz_oc/dbt/`.

- **Models:** `/Users/wz_oc/dbt/models/`
- **Target database:** `DBT_PROD`
- **Target schema:** `ANALYTICS`

Check `memory/snowflake-dbt-tables.md` (if it exists) for a table reference.

## Best practices

1. **Always LIMIT** exploratory queries — Snowflake charges by compute.
2. **Use `--format json`** when you need to parse results programmatically.
3. **Prefer qualified names** (`DATABASE.SCHEMA.TABLE`) when querying outside the default context.
4. **Use `ANALYST_WAREHOUSE`** — it's the default and sized for ad-hoc queries.
5. **Don't run DDL** (CREATE/DROP/ALTER) without explicit user confirmation — use `ANALYST_ROLE` which should be read-focused.
