---
name: subagent-companion
description: |
  Day-to-day management interface for deployed Claude Code subagent ecosystems.
  Handles 8 operation types through conversational language: status checks, agent
  addition, agent removal, diagnosis of issues, memory inspection, agent reset,
  agent modification, and ecosystem explanation.

  Runs a silent self-healing preflight before every interaction to catch and repair
  broken agent states without surfacing technical details. Wraps auditor subagent
  diagnostics in accessible, scannable language following the 40% output reduction
  target.

  This is a SKILL (not a subagent) because it invokes the auditor subagent for
  diagnostics. Subagents cannot spawn other subagents.

  REFUSES: Initial project setup (use concierge). Expert architecture design (use
  architect subagent directly). Domain-specific work (route to appropriate specialist).
  Skill creation (use skill-forge).

  TRIGGERS: "agent status", "how are my agents", "specialist status", "remove agent",
  "remove specialist", "add agent", "add specialist", "what's wrong with my agents",
  "agent isn't working", "specialist broken", "what has my agent learned",
  "agent memory", "reset agent", "start agent fresh", "modify agent", "change agent",
  "explain my agents", "what do my specialists do", "why do I have these agents",
  "agent tune-up", "specialist health", "clean up agents", "unused agents",
  "which agents do I have", "/agents status", "agent diagnostic"
---

# Subagent Companion — Ecosystem Management for Everyone

## QUICK START

1. Run the silent self-healing preflight (ALWAYS — before any user-facing work)
2. Classify the user's request into one of 8 operation types
3. Execute the operation using simplified output templates
4. If diagnosis is needed, invoke the auditor subagent and translate findings
5. Present results following the scannable output format (max 5 lines healthy, 8 with issues)

## WHEN TO USE

Invoke when the user has existing specialists deployed (`.claude/agents/` is populated)
and is asking about their status, health, behavior, or wants to modify the roster. Also
invoke when the user reports quality issues, forgotten context, or specialist misbehavior.

## WHEN NOT TO USE

Do not use for initial project setup when no agents exist — that's the concierge's job.
Do not use for expert-level architecture redesigns. Do not use for domain-specific work
that specialists handle directly.

---

## PROCESS

### Step 0: Silent Self-Healing Preflight

**This step runs EVERY TIME the companion activates, BEFORE doing anything the user
asked.** The preflight is invisible — it produces no user-facing output unless a repair
requires the user's input.

**Performance target:** Complete all four checks in under 2 seconds for up to 8 agents.
Read all agent files in a single directory scan. Parse frontmatter with string splitting.
Check file existence with `test -f`. Only read MEMORY.md contents if `wc -l` exceeds
threshold.

#### Check 1 — Agent File Integrity

Verify every .md file in `.claude/agents/` has valid YAML frontmatter (opens with `---`,
closes with `---`, contains `name` and `description` — the only two required fields per
Claude Code docs). System prompt section must exist below frontmatter.

| Failure | Auto-repair |
|:--------|:------------|
| Missing closing `---` | Add at first blank line after opening `---` |
| Missing `name` field | Infer from filename (strip .md, replace hyphens with spaces) |
| Missing `description` field | Add: "Specialist for {name} tasks" |
| Empty system prompt section | Add: "You are the {name} specialist." |
| File completely unparseable | Delete file. Log removal. Inform user at END of interaction. |

Note: `model` and `tools` are NOT required. Omitting `model` defaults to `inherit`.
Omitting `tools` inherits all tools. Do NOT flag these as errors.

#### Check 2 — Memory File Health

Verify each agent with a `memory` field has a corresponding MEMORY.md in the correct
location. Memory paths per the docs: `~/.claude/agent-memory/{name}/` for `user` scope,
`.claude/agent-memory/{name}/` for `project` scope, `.claude/agent-memory-local/{name}/`
for `local` scope.

| Failure | Auto-repair |
|:--------|:------------|
| Memory directory missing | Create directory + empty MEMORY.md with section headers |
| MEMORY.md > 200 lines | Prune: entries >90 days old → low-confidence entries → near-duplicates. Target: 180 lines. |
| MEMORY.md not valid markdown | Salvage lines starting with `- ` or `### `, rebuild file |
| Entries from wrong agent | Remove misplaced entries (check topic alignment with agent description) |

Note: Claude Code has built-in memory curation at 200 lines. This check catches cases
where built-in curation failed (corruption, rapid single-session growth). Do not replace
the built-in behavior — supplement it.

#### Check 3 — Reference Integrity

Verify every skill name, MCP server name, and tool referenced in agent frontmatter
actually exists in the project.

| Failure | Auto-repair |
|:--------|:------------|
| Referenced skill doesn't exist | Remove from frontmatter. Agent works without it. |
| Referenced MCP not configured | Remove from frontmatter. Log: "{name} lost access to {service}." |
| Referenced tool unavailable | Remove tool. If critical (Write for file-creating agent), flag for user. |

#### Check 4 — Usage Staleness

Check last-modified timestamp of each agent's MEMORY.md.

| Condition | Action |
|:----------|:-------|
| Not modified in 30+ days | Queue suggestion: "Your {name} specialist hasn't been used. Keep or remove?" |
| Not modified in 90+ days | Auto-remove agent. Log. Inform user at end of interaction. |
| Modified recently | Healthy. No action. |

#### Repair Log

All silent repairs logged to `.claude/agent-memory/repair-log.md`. Never shown to user
unless they explicitly ask ("show me repair log," "what did you fix").

```markdown
## Repair Log
- [timestamp]: Fixed missing description in frontend-dev.md (generated from filename)
- [timestamp]: Pruned 23 stale entries from data-processor MEMORY.md (211→178 lines)
- [timestamp]: Removed reference to nonexistent skill graphql-patterns
```

### Step 1: Classify the Operation

Classify the user's request into one of 8 operation types.

| Operation | Trigger Pattern | Action |
|:----------|:---------------|:-------|
| **Status** | "how are my agents," "specialist status," "what agents do I have" | Read all agents, produce scannable health report |
| **Addition** | "add an agent for," "I need a new specialist," "create an agent" | Design, scaffold, seed, validate a single new agent |
| **Removal** | "remove the tester," "delete the API agent," "I don't need X" | Confirm → remove agent file + memory dir + routing references |
| **Diagnosis** | "X isn't working right," "quality dropped on Y," "what's wrong" | Invoke auditor subagent → translate findings to plain English |
| **Memory Inspection** | "what has X learned," "show me agent memory," "what does X know" | Read MEMORY.md → present as human-readable summary |
| **Reset** | "start X fresh," "reset the tester," "wipe agent memory" | Confirm → clear MEMORY.md contents, keep agent file intact |
| **Modification** | "change X's model," "add Slack to the deployer," "update agent" | Modify frontmatter fields → validate → confirm |
| **Explanation** | "what do my specialists do," "explain my agents," "why do I have these" | Read all agents → produce plain-English ecosystem overview |

### Step 2: Execute the Operation

#### Status Operation

Read all .md files in `.claude/agents/`. For each, extract name and description from
frontmatter. Check MEMORY.md existence and line count. Assess health.

**Output format (max 4 lines per agent, scannable in 3 seconds):**

```
[N] specialists running:

**[Name]** — healthy, knows your project well ([N] patterns learned)
**[Name]** — healthy, learning your conventions ([N] patterns)
**[Name]** — needs a tune-up (I can fix this)
**[Name]** — hasn't been used yet. Keep it or remove it?
```

One line per specialist. One status. One action if needed. Add at the end:
"Type /agents for a quick status check anytime."

#### Addition Operation

Use the concierge's auto-resolve logic for a single new agent. Ask at most ONE question:
"What should this specialist handle?" Create the agent using the scaffolder and seeder
subagents. Validate with the validator subagent.

**Output format:**

```
Added **[Name]** — [one-sentence description]. You now have [N] specialists.
```

#### Removal Operation

Confirm before destructive action. Use the simplified format:

```
Remove the [name]? This deletes what it's learned. (yes/no)
```

After confirmation: delete the agent .md file, remove the memory directory, clean
routing references from CLAUDE.md and settings.json. Output:

```
Done. [N] specialists left.
```

#### Diagnosis Operation

Invoke the `auditor` subagent to perform technical analysis. The auditor runs with
`disallowedTools: Write, Edit` (read-only) and `model: haiku`. It checks: memory bloat,
trigger collisions, routing alignment, configuration drift, and performance patterns.

Translate the auditor's technical report into plain English. Follow the simplified format:

```
Found it — [one sentence describing the problem]. [One sentence describing the fix].
Should work better now.
```

If the fix requires user input:

```
Found an issue — [one sentence describing the problem].
Want me to **fix it**, **start over**, or **explain what happened**?
```

#### Memory Inspection Operation

Read the target agent's MEMORY.md. Present as a human-readable list (this is one case
where a list IS the right format — memory is inherently a list of things).

```
Your [name] specialist knows:
- [pattern 1 in plain English]
- [pattern 2 in plain English]
- [pattern 3 in plain English]

Learning for about [duration].
```

One line per memory item. Skip internal metadata entries.

#### Reset Operation

Confirm before clearing. After confirmation, clear MEMORY.md contents but preserve
the file and section headers. The agent file itself is untouched.

```
Reset **[name]** — starting fresh with a clean slate. The specialist itself is
unchanged, it just forgot everything it learned.
```

#### Modification Operation

Parse the user's request for which field to change. Modify the frontmatter directly.
Run the validator subagent to confirm the change is valid.

```
Updated **[name]** — [one sentence describing the change].
```

#### Explanation Operation

Read all agents and produce a narrative overview:

```
You have [N] specialists handling different parts of your project:

**[Name]** takes care of [plain English domain]. It's been learning for [duration]
and knows [N] of your patterns.

**[Name]** handles [plain English domain]. [similar detail].

They work automatically — when you ask for something, the right specialist picks it up.
Type /agents to check on them anytime.
```

---

## THE UNIVERSAL ERROR FORMAT

Whenever something goes wrong in any operation, present the same format:

```
Something went wrong with [plain English description of what was attempted].

Want me to **fix it**, **start over**, or **explain what happened**?
```

Three options. Always the same three.

- **"Fix it"** → attempt auto-repair, report the result
- **"Start over"** → delete the relevant agent(s) and re-scaffold from scratch
- **"Explain what happened"** → plain-English description of the issue (still no jargon)

---

## ONE SUGGESTION MAXIMUM RULE

When performing any operation, the companion may observe opportunities for improvement
(unused agents, memory bloat, missing MCPs). It may offer ONE suggestion maximum per
interaction, always AFTER completing the user's actual request.

"By the way — your [name] specialist hasn't been used in a while. Want to keep it or
remove it?"

Never offer more than one suggestion. Never lead with the suggestion before completing
the user's request. Never suggest during urgent work.

---

## ERROR HANDLING

| Condition | Action |
|:----------|:-------|
| No agents exist when companion triggers | "No specialists set up yet. Want me to organize your project?" (Route to concierge.) |
| Agent file references nonexistent agent | Auto-remove stale reference in preflight. |
| User asks about agent that doesn't exist | "I don't see a [name] specialist. Here's what you have: [list]." |
| Auditor subagent returns no findings | "Everything looks healthy. All [N] specialists are running normally." |
| User wants to undo a removal | "I can set that specialist back up. It won't remember what it learned before, but it'll start learning again right away." Route to addition flow. |

---

## RELATIONSHIP TO OTHER COMPONENTS

| Component | Relationship |
|:----------|:-------------|
| project-guide (skill) | Routes management requests to companion |
| subagent-concierge (skill) | Companion routes setup requests to concierge when no agents exist |
| auditor (subagent) | Companion invokes auditor for diagnosis operations |
| scaffolder (subagent) | Companion invokes scaffolder for addition operations |
| memory-seeder (subagent) | Companion invokes seeder for addition operations |
| validator (subagent) | Companion invokes validator after modifications and additions |

---

## MANIFEST

```yaml
name: subagent-companion
version: "3.0.0"
created: "2026-03-03"
author: "Pete Connor"
pattern: "context-aware-branching"
forge_gate_scores:
  specificity: 3
  trigger_clarity: 3
  scope_boundary: 3
  differentiation: 3
  total: "12/12"
deployment:
  scope: "user"
  rationale: "Agent management applies to any Claude Code project with deployed agents"
chain_position: "Layer 1 — orchestration skill invoked by project-guide"
type: "SKILL (not subagent — must invoke auditor subagent for diagnostics)"
operations: 8
output_reduction_target: "40%"
preflight_checks: 4
```
