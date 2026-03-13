# Agents

## Oracle
- **Model:** `openai/gpt-5.2`
- **When to use:** Architecture decisions, hard debugging, multi-system tradeoffs

## Pi
- **Model:** `openai/gpt-5.4`
- **Command:** `pi --model openai/gpt-5.4 --print "task"` (exec, 600s timeout)
- **When to use:** Heavy analytical work, multi-step SQL/Python, code design
- **Note:** ACP stalls on interactive auth — use `exec --print`
- **Data env:** Run inside `~/onyx/` (Nix flake devshell with Python 3.13, snowflake-connector-python, pandas, matplotlib, seaborn, scipy). Use `cd ~/onyx && nix develop -c <command>` or activate the venv at `~/onyx/.venv/`. Also has `snow sql` for quick queries.

## undertow
- **Repo:** `github.com:bluemoon/undertow` (`~/shoal/`)
- **Install:** `uv tool install git+https://github.com/bluemoon/undertow`
- **Commands:** `undertow "SELECT ..."` (validate), `snow-safe "SELECT ..."` (validate + execute)
- **What it does:** Validates Snowflake SQL against iConnections conventions (required filters, dedup rules, naming)
