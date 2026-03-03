---
name: subagent-concierge
description: |
  Non-technical entry point for Claude Code subagent setup. Detects when a project
  would benefit from specialist subagents, infers project type from codebase analysis
  (zero-question fast path), auto-resolves all technical decisions, and executes the
  full lifecycle pipeline (architect → scaffolder → memory-seeder → validator) by
  chaining subagents from the main conversation context.

  Presents results in plain English with zero exposure to YAML, frontmatter, scoring
  rubrics, or architecture jargon. Includes template-first fast path for common
  project archetypes and progressive deployment to prevent overwhelm.

  This is a SKILL (not a subagent) because it must chain pipeline subagents in
  sequence. Subagents cannot spawn other subagents — only skills running in the
  main conversation context can invoke subagents.

  REFUSES: Expert-mode architecture design (use architect subagent directly).
  Individual pipeline execution (invoke subagents directly). Domain-specific
  analysis (use project skills). Skill creation (use skill-forge).

  TRIGGERS: "organize my project", "this is getting complicated", "set up agents",
  "help me scale this", "project is too complex", "context keeps filling up",
  "quality is dropping", "structure this project", "I'm new to agents",
  "make this project manageable", "bootstrap this project", "set up specialists",
  "I don't know how subagents work", "agent setup for beginners",
  "vibecoding getting messy", "project getting unwieldy", "too many files"
---

# Subagent Concierge — Zero-to-Specialists for Everyone

## QUICK START

1. Assess the situation: fresh start, growing project, or expansion
2. Run the inference engine against the project directory (zero-question fast path)
3. If confidence ≥ 80 → present template match and deploy on "yes"
4. If confidence 50-79 → ask ONE clarifying question, then deploy
5. If confidence < 50 → fall back to compressed intake (max 3 questions)
6. Auto-resolve all technical decisions using the decision engine
7. Chain pipeline subagents: architect → scaffolder + seeder (parallel) → validator
8. Self-heal any validation findings
9. Present results in plain English with a "what just happened" summary

## WHEN TO USE

Invoke when any of the following are true. The user explicitly says they are new to
agents or don't understand subagents. The user describes project complexity problems
without knowing the solution (context filling up, quality dropping, too many files).
The user asks to "organize," "structure," or "set up" their project. The user has
been vibecoding and the project has grown beyond single-thread comfort. The user asks
for "agents" or "specialists" but doesn't understand the technical details.

This skill is the DEFAULT entry point for anyone who is not an expert agent architect.

## WHEN NOT TO USE

Do not use when the user explicitly requests expert-mode control over architecture
decisions — let them invoke the architect subagent directly. Do not use for domain-specific
operational analysis. Do not use for skill creation. Do not use when the project has fewer
than 3 distinct concerns — tell the user honestly that specialists would add overhead.

---

## PROCESS

### Step 1: Assess the Situation

Before asking questions, gather what you already know. Read the project directory
structure if one exists. Check for an existing `.claude/agents/` directory.

Classify the user into one of three modes.

**Fresh start** — no project exists yet. The user is describing what they want to build.
Use compressed intake (Step 2b).

**Growing project** — project exists, no agents. Run the inference engine (Step 2a).

**Expansion** — agents already exist. Redirect to companion skill for targeted additions,
or invoke the auditor subagent to check ecosystem health first.

Expected output: `{situation_mode}` — fresh_start, growing_project, or expansion.

### Step 2a: Inference Engine (Zero-Question Fast Path)

When a project directory exists, run these five signals before asking any questions.

**Signal 1 — File type census.** Count files by extension, grouped into domains:

| Extensions | Domain | Template |
|:-----------|:-------|:---------|
| .jsx, .tsx, .vue, .svelte, .css, .scss, .html | Frontend | Web App or Content Site |
| .py, .rb, .go, .rs, .java + /api/, /routes/, /endpoints/ | Backend/API | API/Backend or Web App |
| .csv, .json, .xlsx, .parquet + /data/, /analytics/ | Data processing | Data Dashboard |
| .md, .mdx, /content/, /posts/, /blog/ | Content | Content Site |
| /workflows/, /pipelines/, /jobs/, /cron/ | Automation | Automation Pipeline |
| /ios/, /android/, /app/, react-native.config.js | Mobile | Mobile/Cross-Platform |

**Signal 2 — Package manifest.** Read package.json, requirements.txt, Cargo.toml, go.mod:

| Dependency pattern | Inference |
|:-------------------|:----------|
| react/next/vue + express/fastify/django | Full-stack web app |
| flask/fastapi/express with no frontend deps | API/Backend |
| pandas/numpy/matplotlib/plotly/streamlit | Data Dashboard |
| gatsby/hugo/eleventy/astro with content dirs | Content Site |
| react-native/expo/flutter | Mobile |
| airflow/prefect/celery/temporal | Automation Pipeline |

**Signal 3 — Directory structure.** Count top-level directories matching domain patterns.
Projects with 3+ concern directories are specialist-ready.

**Signal 4 — README content.** Scan for project description, tech stack, and goals.
Highest-confidence signal because the user wrote it themselves.

**Signal 5 — Git history.** If available, check recent commit messages for domain
distribution across 4+ distinct directories.

**Confidence scoring:**

| Condition | Score |
|:----------|:------|
| File census matches single template clearly (>60% in one domain) | +30 |
| Package manifest confirms the template's stack | +25 |
| Directory structure has 3+ distinct concern directories | +15 |
| README description aligns with template purpose | +20 |
| Git history shows multi-domain activity | +10 |

**80+ → Zero-question path.** Present summary and deploy on "yes."
**50-79 → One-question path.** Ask the single most ambiguous question, then deploy.
**Below 50 → Compressed intake** (Step 2b).

**Zero-question presentation format:**

```
I looked at your project. It's a [template name] with [N] main areas of work.

I'd set up [N] specialists:
• [Name] — [one sentence, plain English]
• [Name] — [one sentence, plain English]
• [Name] — [one sentence, plain English]

Want me to set this up?
```

One message, one "yes." Two interactions total.

Expected output: `{template_match}` with confidence score, or fall through to Step 2b.

### Step 2b: Compressed Intake (Fallback)

Used when inference confidence is below 50, or when no project directory exists.

**For fresh starts (no project directory):** Ask ONE open-ended question:
"Describe what you're building in one or two sentences — what does it do and who uses it?"
From the answer, match a template. If match is 80+, present and deploy. If ambiguous,
ask one clarifying question. Maximum: two questions for a fresh start.

**For low-confidence existing projects:** Ask a maximum of THREE questions, selected
from this bank based on what information is missing:

Q1 — "What are the main things this project does? If you had to explain it in three
bullet points to a friend, what would they be?"

Q2 — "What files or data does the project work with? Things like CSVs, images, API
responses, user uploads?"

Q3 — "Where do the results end up? Does the project send emails, post to Slack, update
a website, generate reports?"

Present all selected questions at once. Non-coders disengage if interrogated sequentially.

Expected output: `{intake_synthesis}` — structured inventory for the decision engine.

### Step 3: Auto-Resolve Technical Decisions

Every technical decision is resolved automatically using these rules. The non-coder
never chooses a model, a tool profile, or a memory scope.

**How many agents?** Count distinct functional domains. If two domains share 70%+ of
data sources, merge into one agent. Target: 3-8 agents. Fewer than 3 → tell the user
specialists would add overhead. More than 8 → consolidate until under 8.

**Which model?** Default: `sonnet` for everything. Override to `haiku` only for agents
doing pure file reading or simple pattern matching. Never default to `opus`.

**Which tools?** Three profiles based on agent type:
- Read-only agents: `Read, Grep, Glob`
- File-creating agents: `Read, Write, Bash, Glob, Grep`
- Code-modifying agents: `Read, Write, Edit, Bash, Glob, Grep`

**Which memory scope?** Default: `project`. Override to `user` only for communication-
pattern agents. Override to `local` for sensitive data projects.

**Which MCP servers?** Default: none. Add only when the user explicitly mentions a
service. "Sends emails" → Gmail. "Posts to Slack" → Slack. "Deploys to Netlify" → Netlify.

**Which skills to load?** Check installed skills. If an agent's domain aligns with an
existing skill (frontend agent → frontend-design skill), add it. Max 2 skills per agent.

**System prompt depth?** Keep agent system prompts concise: 20-40 lines. Include role
statement, 3-5 processing steps, memory read/write instructions, and return spec.

**Parallel groups?** If two agents have zero data dependency, group as parallel.

Expected output: `{auto_spec}` — complete architecture specification for the pipeline.

### Step 4: Execute the Pipeline

Chain pipeline subagents from the main conversation context. Each subagent runs in
its own isolated context window, does its work, and returns results. The concierge
passes relevant context from one to the next.

**Phase A — Design (if needed).** Invoke the `architect` subagent with the auto_spec.
For template matches, skip this phase — the template IS the spec. For custom designs,
the architect produces the full specification.

**Phase B — Scaffold + Scan (parallel).** Invoke the `scaffolder` subagent (runs as
background task with `permissionMode: acceptEdits`). Simultaneously, begin the seeder's
project scan phase. The scaffolder creates .md files in `.claude/agents/`, writes routing
configuration, configures MCP servers in settings.json, and creates memory directories.

**Phase C — Seed memory.** After the scaffolder completes, invoke the `memory-seeder`
subagent to write MEMORY.md files. It uses knowledge sources identified during the
parallel scan: README files, configuration files, documentation, code comments. Each
MEMORY.md stays under 100 lines (reserving half of the 200-line limit for organic growth).

**Phase D — Validate.** Invoke the `validator` subagent with `isolation: worktree`.
It runs in a temporary isolated copy of the repository, checking structural correctness:
valid frontmatter, parseable system prompts, referenced tools exist, referenced skills
exist, referenced MCPs configured. The worktree is automatically discarded.

**Phase E — Self-heal.** If validation finds issues, fix them in the main thread.
Common fixes: remove nonexistent skill references, remove unconfigured MCP references,
adjust tool lists. Only surface issues requiring user input.

After each phase, record results and auto-resolved issues.

Expected output: `{pipeline_results}` — files created, issues resolved, user attention items.

### Step 5: Present Results

Translate everything into language a non-coder understands. Follow the Phase 5 output
format from the improvement plan:

```
Set up [N] specialists for your project:

**[Name]** — [one sentence, plain English]
**[Name]** — [one sentence, plain English]
**[Name]** — [one sentence, plain English]

Just keep building normally. The right specialist picks up each task automatically.
You can type /agents anytime to see your specialists.
```

Do NOT include: YAML frontmatter, scoring rubrics, viability matrices, validation
reports, technical file paths, tool profiles, memory scopes, or architecture jargon.

### Step 6: Offer Next Steps

Offer exactly two options:

"Want me to show you how one of these specialists handles a real task from your project?"

"Or just keep building — the specialists activate automatically."

If the user picks the demo, execute Demo Mode (see below).

---

## DEMO MODE

### When It Activates

Path A: User asks ("show me how this works," "what do specialists actually do").
Path B: Concierge offers after setup and user accepts.

### The Sequence

**Pick the most impactful specialist.** Choose the one whose domain has the most files
or most recent git activity.

**Pick a small, visible task.** Must produce a visible result in under 30 seconds.
Must be ADDITIVE (create a new file), never modification of existing code.

| Template | Demo Task |
|:---------|:---------|
| Web App | Frontend specialist adds a footer component |
| Data Dashboard | Data specialist summarizes patterns in a data file |
| API/Backend | API specialist adds a health check endpoint |
| Content Site | Content specialist generates a blog post template |
| Automation | Pipeline specialist maps out current workflow steps |
| Mobile | UI specialist creates a placeholder settings screen |

**Run with maxTurns: 10.** Prevents runaway behavior. If the specialist hits the limit,
catch it: "The demo hit a limit — but you get the idea."

**Show the result, then the contrast:**

```
Done. Your frontend specialist just built that footer.

Here's what happened behind the scenes:
- It read your existing components to match your style
- It created the footer using your naming conventions
- It remembered your Tailwind patterns from other components

Next time you ask for UI work, this happens automatically —
no need to explain your conventions every time.
```

**Synthetic fallback.** If the project is empty, create a minimal demo project (3 files
across 2 domains), run the demo, then offer: "This was a sample project. Want me to set
up specialists for your real project, or are you just exploring?"

After the demo, stop explaining. Say: "That's how it works. Keep building — the
specialists handle things automatically." Let the user experience value organically.

---

## TEMPLATES

Templates are externalized in the `templates/` directory as YAML files. Read the
appropriate template file at runtime based on the inference engine's match. Each
template specifies: agent roster, tool profiles, memory scopes, MCP mappings,
routing rules, and parallel groups.

Six templates available: web-app, data-dashboard, api-backend, content-site,
automation-pipeline, mobile-app.

When multiple templates partially match, prefer the one aligning with the project's
PRIMARY output. A project that "builds a dashboard from an API" is data-dashboard
(the dashboard is the deliverable).

When a project is genuinely hybrid, combine agents from both templates and deduplicate.
Maximum combined roster: 6 agents.

---

## PROGRESSIVE DEPLOYMENT

Do not deploy all agents at once for complex projects.

**Wave 1 (Immediate):** Deploy 2-3 agents covering the user's stated pain points or
most active work areas.

**Wave 2 (After first successful use):** Offer remaining agents: "Your [agent]
specialist worked well on that. Ready to add [next agent] for [description]?"

**Wave 3 (After one week):** Run auditor logic to check memory health and trigger
alignment. Suggest removing unused agents.

---

## ERROR HANDLING

| Condition | Action |
|:----------|:-------|
| Project has < 3 concerns | "Your project is simple enough that specialists would add overhead. Keep building in the main thread." |
| Description too vague | Ask ONE follow-up: "Can you describe the most important thing this project does?" |
| Template match ambiguous | Present top 2 matches with one-sentence descriptions. Let user pick. |
| No MCPs configured | Design agents without MCPs. Note capabilities they COULD have. |
| Scaffolding hits file conflicts | Auto-resolve by appending -v2 suffix. Note in summary. |
| Validation finds structural issues | Auto-fix in self-heal phase. Only surface issues needing user input. |
| User wants to undo | Delete `.claude/agents/`, remove agent routing, delete memory dirs. "Specialists removed. Back to single-thread mode." |
| Any unexpected failure | "Something went wrong with [plain description]. Want me to **fix it**, **start over**, or **explain what happened**?" |

---

## EXPERT MODE ESCAPE HATCH

If the user mentions frontmatter, viability criteria, tool profiles, or architecture specs:

"Looks like you know your way around agent architecture. Want me to keep handling the
technical decisions, or would you prefer full control? You can invoke the architect
subagent directly for expert mode."

---

## MANIFEST

```yaml
name: subagent-concierge
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
  rationale: "Non-coder setup interface applies to any Claude Code project"
chain_position: "Layer 1 — orchestration skill invoked by project-guide"
type: "SKILL (not subagent — must chain pipeline subagents)"
templates: 6
decision_engine_rules: 7
progressive_deployment_waves: 3
```
