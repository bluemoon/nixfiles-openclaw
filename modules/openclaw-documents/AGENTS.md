# Agents

## Oracle
- **Purpose:** Strategic technical advisor for complex architecture, hard debugging, code review
- **Model:** `openai/o3`
- **Prompt:** `prompts/oracle-system.md`
- **Label:** `oracle`
- **When to use:** Architecture decisions, 2+ failed fix attempts, security/perf concerns, multi-system tradeoffs
- **When NOT to use:** Simple tasks, first attempts, trivial decisions
