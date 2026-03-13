# Agents

## Oracle
- **Model:** `openai/gpt-5.2`
- **When to use:** Architecture decisions, hard debugging, multi-system tradeoffs

## Pi
- **Model:** `openai/gpt-5.4`
- **Command:** `pi --model openai/gpt-5.4 --print "task"` (exec, 600s timeout)
- **When to use:** Heavy analytical work, multi-step SQL/Python, code design
- **Note:** ACP stalls on interactive auth — use `exec --print`

## Data Analysis
- **Use the `onyx` skill** for all data analysis work (see skills/onyx/SKILL.md)
- **Env:** `~/onyx/` — `cd ~/onyx && nix develop --command python3 scripts/{date}-{slug}.py`

## undertow
- **Repo:** `github.com:bluemoon/undertow` (`~/shoal/`)
- **Install:** `uv tool install git+https://github.com/bluemoon/undertow`
- **Commands:** `undertow "SELECT ..."` (validate), `snow-safe "SELECT ..."` (validate + execute)
- **What it does:** Validates Snowflake SQL against iConnections conventions (required filters, dedup rules, naming)
