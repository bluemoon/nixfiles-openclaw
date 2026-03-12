# Agents

## Oracle
- **Purpose:** Strategic technical advisor for complex architecture, hard debugging, code review
- **Model:** `openai/gpt-5.2`
- **Label:** `oracle`
- **When to use:** Architecture decisions, 2+ failed fix attempts, security/perf concerns, multi-system tradeoffs
- **When NOT to use:** Simple tasks, first attempts, trivial decisions

### Oracle System Prompt
You are a strategic technical advisor with deep reasoning capabilities, operating as a specialized consultant within an AI-assisted development environment.

You function as an on-demand specialist invoked by a primary coding agent when complex analysis or architectural decisions require elevated reasoning. Each consultation is standalone—answer efficiently without re-establishing context.

**Decision Framework — Pragmatic Minimalism:**
- Bias toward simplicity. Resist hypothetical future needs.
- Leverage what exists over introducing new components.
- Prioritize readability, maintainability, reduced cognitive load.
- One clear path. Mention alternatives only when trade-offs differ substantially.
- Tag effort: Quick(<1h), Short(1-4h), Medium(1-2d), Large(3d+).

**Response Structure:**
- **Bottom line**: 2-3 sentences. No preamble.
- **Action plan**: ≤7 numbered steps, each ≤2 sentences.
- **Why this approach**: ≤4 bullets (when relevant).
- **Watch out for**: ≤3 bullets (when relevant).
- **Edge cases**: ≤3 bullets (only when genuinely applicable).

**Scope Discipline:**
- Recommend ONLY what was asked. No unsolicited improvements.
- Other issues go in "Optional future considerations" (max 2 items).
- NEVER suggest new dependencies/infrastructure unless asked.

**Principles:** Actionable insight > exhaustive analysis. Dense and useful > long and thorough.

## Pi (Critical Thinker)
- **Purpose:** Deep analytical work requiring extended reasoning — complex data analysis, retention modeling, multi-step SQL/Python pipelines, strategic problem decomposition, code architecture design
- **Runtime:** Direct exec with `--print` flag (ACP sessions stall on interactive auth)
- **Model:** `openai/gpt-5.4`
- **Command:** `pi --model openai/gpt-5.4 --print "task"`
- **Label:** `pi`
- **Dispatch pattern:** `exec` with `--print` flag, `--json` for structured output, 600s timeout, background mode for long tasks
- **When to use:** Multi-query analytical tasks, iterative data exploration, anything needing 10+ tool calls to converge, code architecture/design work, deep reasoning problems
- **When NOT to use:** Quick lookups, simple one-shot queries, conversational replies
- **Environment:** Has access to `snow sql`, Python (pandas/matplotlib/seaborn), workspace files, dbt project at `~/dbt/`, and undertow at `~/shoal/`
- **Note:** ACP runtime (`sessions_spawn`) tends to stall on Pi's interactive model selection. Use direct `exec --print` as the reliable dispatch path.

## SQL Guard (undertow)
- **Purpose:** Validates LLM-generated Snowflake queries against iConnections conventions before execution
- **Repo:** `github.com:bluemoon/undertow`
- **Location:** `~/shoal/sql_guard.py` (+ `snow_safe.py` wrapper)
- **Runtime:** Python CLI (`python3 sql_guard.py "SELECT ..."`)
- **Dependencies:** `sqlglot`
- **When to use:** Before executing any LLM-generated SQL against Snowflake — catches missing required filters, bad patterns, common mistakes
- **Rules enforced:**
  - `MEETING_DATA` must filter: `DERIVED_MEETING_STATUS='Confirmed'`, `CONSOLIDATED_ISDELETED=false`, `ICONNECTIONS_MEETING=false`, `ISDELETED=false`
  - `EVENT_CONTACTS` must filter: `EC_EVENTSTATUS='Confirmed'`, `TIME_ADJUSTED_EVENTSTATUS ILIKE '%Confirmed%'`, `ISDELETED=false`, `EC_ISDELETED=false`
  - No `'Confirmed - Other'` in meeting status
  - `COUNT(DISTINCT MEETINGID)` for meeting counts (per-contact grain)
  - Exclude `iconn` company names in GP queries
  - No `SELECT *`
  - `EVENT_COMPANIES` dedup reminder (`GROUP BY COMPANYID`)
