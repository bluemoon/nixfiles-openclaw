# Agents

## Oracle
- **Model:** `openai/gpt-5.2`
- **When to use:** Architecture decisions, hard debugging, multi-system tradeoffs

## Pi
- **Model:** `openai/gpt-5.4`
- **Command:** `pi --model openai/gpt-5.4 --print "task"` (exec, 600s timeout)
- **When to use:** Heavy analytical work, multi-step SQL/Python, code design
- **Note:** ACP stalls on interactive auth — use `exec --print`

## Data Analysis Workflow
- **Env:** `~/onyx/` — Nix flake (Python 3.13, snowflake-connector-python, pandas, matplotlib, seaborn, scipy)
- **Run:** `cd ~/onyx && nix develop --command python3 scripts/{date}-{request}.py`
- **Snowflake:** JWT auth via `/run/agenix/snowflake-rsa-key`, account `so07687.us-east-2.aws`, user `BRADFORD_TONEY`, role `ANALYST_ROLE`, database `DBT_PROD`
- **Script convention:** For every analysis request, write a self-contained script to `~/onyx/scripts/{YYYY-MM-DD}-{short-slug}.py`. Scripts should:
  - Connect to Snowflake via `snowflake.connector` with JWT auth
  - Run queries, transform with pandas
  - Save output to `~/onyx/output/` (CSV, PNG, etc.)
  - Print a clean summary to stdout
  - Be rerunnable — no hardcoded temp state
- **Quick queries:** `snow sql -q "..."` or `snow sql -f /tmp/file.sql` is fine for one-offs
- **Charts:** Save to `~/onyx/output/{date}-{name}.png`, use matplotlib/seaborn

## undertow
- **Repo:** `github.com:bluemoon/undertow` (`~/shoal/`)
- **Install:** `uv tool install git+https://github.com/bluemoon/undertow`
- **Commands:** `undertow "SELECT ..."` (validate), `snow-safe "SELECT ..."` (validate + execute)
- **What it does:** Validates Snowflake SQL against iConnections conventions (required filters, dedup rules, naming)
