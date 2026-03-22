# Claude MCP Ecosystem

**Give Claude Code a team of specialists so it stops forgetting things when your project gets complex.**

As projects grow, Claude's single context window starts losing track of conventions, mixing up patterns, and forgetting past decisions. This system splits work across specialist agents — a frontend expert, an API expert, a data expert — each with their own memory and focus area.

You keep talking to Claude the same way you always have. Behind the scenes, the right specialist picks up each task.

## What This Is (and Isn't)

This is **not** an app, a library, or an npm package. There's nothing to install, no build step, no runtime.

It's a collection of **Markdown, YAML, and Bash files** that teach Claude Code how to organize itself into a team of specialists. You copy these files into your project, and Claude gains the ability to:

- Analyze your project and figure out what specialists you need
- Create and configure those specialists automatically
- Route your requests to the right specialist
- Monitor specialist health and fix issues
- Learn and remember your patterns across sessions

---

## How It Works

Think of it like hiring a team instead of relying on one person to do everything.

### The Three Layers

```
You: "help me organize this project"
         │
    Layer 0 — Router (invisible)
    Detects what you need, routes to the right handler
         │
    Layer 1 — Orchestrators
    Figure out what specialists to create, manage them day-to-day
         │
    Layer 2 — Worker Agents
    Do the actual focused work, each with their own memory
```

**Layer 0** is the `project-guide` skill. It's invisible — you never interact with it directly. It listens to what you say and decides whether you need setup help or management help.

**Layer 1** has two orchestrator skills:
- **`subagent-concierge`** handles initial setup. It scans your project, figures out what specialists you need, and creates them.
- **`subagent-companion`** handles day-to-day management. Check status, add agents, remove agents, diagnose problems.

**Layer 2** has five worker agents that do focused tasks:
- **Architect** — analyzes your project and designs the specialist team
- **Scaffolder** — creates the actual agent files and directories
- **Memory Seeder** — reads your project docs, README, and code patterns to give each specialist starting knowledge
- **Validator** — checks that everything was set up correctly
- **Auditor** — diagnoses health issues (memory bloat, stale agents, configuration drift)

**The key rule:** Agents can't create other agents. Only the orchestrator skills (Layer 1) can invoke agents. This keeps the system predictable and debuggable.

---

## What's Inside

### Slash Commands

| Command | What it does |
|---------|-------------|
| `/prime` | Boots your session — loads context, checks state, detects where you left off |
| `/plan <request>` | Creates an implementation plan before you start building |
| `/build <plan-path>` | Executes a plan with git branches and step-by-step commits |
| `/status` | Shows a dashboard of plans, sessions, git state, and workspace health |
| `/wrap` | Closes your session — logs what you did, notes next steps |
| `/agents` | Lists all deployed specialist agents and their status |
| `/agent-setup` | Initial agent deployment — scans project, creates specialists |
| `/agent-add` | Adds a new specialist agent to your project |
| `/agent-remove` | Removes a specialist agent |
| `/agent-reset` | Resets a specialist agent's memory |
| `/agent-status` | Checks health and status of deployed agents |
| `/agent-diagnose` | Diagnoses issues with specialist agents |

### Skills (Orchestrators)

| Skill | Role |
|-------|------|
| `project-guide` | Invisible router — detects if you need setup or management |
| `subagent-concierge` | Initial setup — scans your project, creates specialists |
| `subagent-companion` | Day-to-day management — status, add, remove, diagnose |

### Pipeline Agents (Workers)

| Agent | What it does | Model |
|-------|-------------|-------|
| `architect` | Analyzes your project, designs the specialist team | inherit |
| `scaffolder` | Creates agent files and memory directories | sonnet |
| `memory-seeder` | Populates each agent's starting knowledge from your project | sonnet |
| `validator` | Quality-checks all created files (runs in isolated worktree) | haiku |
| `auditor` | Diagnoses ecosystem health issues | haiku |

### Project Templates

Seven pre-built blueprints for common project types:

| Template | For projects like... |
|----------|---------------------|
| `web-app` | React, Vue, Next.js, Svelte + backend API |
| `api-backend` | Express, FastAPI, Django, Gin, Actix |
| `data-dashboard` | Pandas, Streamlit, Plotly analytics |
| `content-site` | Gatsby, Hugo, Astro blogs and docs |
| `automation-pipeline` | Airflow, Prefect, Celery workflows |
| `mobile-app` | React Native, Flutter, Expo |
| `ispn-deployment` | Python microservices on AWS EKS |

If your project matches a template, setup is nearly instant. If not, the architect agent designs a custom team.

### Security & Automation

- **Bash security hook** — blocks dangerous commands (`rm -rf /`, `DROP TABLE`, `curl | bash`, etc.) before they run
- **Auto-lint hook** — formats files after every write (Prettier for JS/TS, Ruff/Black for Python, gofmt for Go)
- **Agent health check** — runs automatically after every agent completes, validates frontmatter and memory file sizes

### Governance System

- **CLAUDE.md** — the operating system for Claude sessions. Defines workflow rules, quality checks, and autonomy boundaries.
- **tasks/lessons.md** — accumulated rules from past mistakes. Claude reads these at session start so it doesn't repeat errors.
- **Operator context** — private files (`context/role.md`, `context/org.md`, etc.) that tell Claude who you are and what you're working on.

---

## Quick Start

### Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed and working
- A project you want to organize (any language, any framework)

### Setup (5 minutes)

**1. Clone this repo**

```bash
git clone <repo-url> claude-mcp-ecosystem
```

**2. Copy the plugin files into your project**

```bash
# From your project root:

# Skills (the orchestrators)
cp -r /path/to/claude-mcp-ecosystem/subagent-lifecycle/skills/ .claude/skills/

# Agents (the workers)
cp -r /path/to/claude-mcp-ecosystem/subagent-lifecycle/agents/ .claude/agents/

# Health check script
mkdir -p .claude/scripts
cp /path/to/claude-mcp-ecosystem/subagent-lifecycle/scripts/agent-health-check.sh .claude/scripts/

# Reference docs (agents need these for design decisions)
cp -r /path/to/claude-mcp-ecosystem/subagent-lifecycle/references/ .claude/references/

# Templates (project blueprints)
cp -r /path/to/claude-mcp-ecosystem/subagent-lifecycle/templates/ .claude/templates/
```

**3. Add the health check hook to your project's settings**

Create or edit `.claude/settings.json`:

```json
{
  "hooks": {
    "SubagentStop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/scripts/agent-health-check.sh"
          }
        ]
      }
    ]
  }
}
```

This runs a quick health check every time an agent finishes work.

**4. (Optional) Add security and lint hooks**

```bash
mkdir -p .claude/hooks
cp /path/to/claude-mcp-ecosystem/.claude/hooks/pre-bash-security.sh .claude/hooks/
cp /path/to/claude-mcp-ecosystem/.claude/hooks/post-write-lint.sh .claude/hooks/
chmod +x .claude/hooks/*.sh
```

Then add to `.claude/settings.json`:

```json
{
  "permissions": {
    "deny": [
      "Read(.env)",
      "Read(.env.*)",
      "Read(./secrets/**)",
      "Bash(sudo:*)"
    ]
  },
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/pre-bash-security.sh",
            "timeout": 10
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/post-write-lint.sh",
            "timeout": 30
          }
        ]
      }
    ],
    "SubagentStop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/scripts/agent-health-check.sh"
          }
        ]
      }
    ]
  }
}
```

**5. Start Claude Code and go**

```bash
claude
> help me organize this project
```

The system scans your files, suggests specialists, and asks for one confirmation. Say "yes" and your team is deployed.

---

## Deploying Subagents

### The Automatic Way (Recommended)

When you say something like "help me organize this project," "this is getting messy," or "set up agents for this repo," here's what happens:

**Step 1: Project Analysis**

The concierge skill scans your project automatically:
- **File types** — counts `.jsx`, `.py`, `.go`, etc. to identify your tech stack
- **Package manifests** — reads `package.json`, `requirements.txt`, `Cargo.toml`
- **Directory structure** — looks for distinct domains (`src/components/`, `api/`, `data/`)
- **README** — reads what your project describes itself as
- **Git history** — checks if commits span multiple domains

**Step 2: Confidence Scoring**

Based on what it finds, the system assigns a confidence score:
- **80+ points** — high confidence. It shows you the proposed specialists and asks one question: "Want me to set this up?" Zero additional questions.
- **50-79 points** — medium confidence. One clarifying question, then setup.
- **Below 50** — low confidence. Up to 3 questions max, then setup.

**Step 3: Specialist Creation**

After you say "yes," the system chains through the pipeline:

1. **Architect** designs the specialist team (skipped if a template matches your project)
2. **Scaffolder** creates `.claude/agents/` files with proper configuration
3. **Memory Seeder** reads your project docs and code to give each specialist starting knowledge
4. **Validator** checks everything was set up correctly in an isolated environment

Each specialist gets:
- An agent definition file (`.claude/agents/specialist-name.md`)
- A memory directory (`.claude/agent-memory/specialist-name/MEMORY.md`)
- Proper tool access (read-only agents only get read tools, editors get write tools)

**Step 4: Progressive Deployment**

Not everything deploys at once:
- **Wave 1** (immediate): 2-3 highest-impact specialists
- **Wave 2** (after Wave 1 succeeds): remaining specialists
- **Wave 3** (after one week): auto-cleanup of unused specialists

### The Manual Way (Power Users)

You can create agent files by hand. Create a file at `.claude/agents/your-agent.md`:

```markdown
---
name: code-reviewer
description: Reviews code for quality, security, and maintainability. Use proactively after code changes.
tools: Read, Grep, Glob, Bash
model: sonnet
memory: project
---

You are a senior code reviewer.

When invoked:
1. Run `git diff` to see changes
2. Review modified files for issues
3. Report findings as Critical / Warning / Suggestion
```

**Key frontmatter fields:**

| Field | What it controls | Options |
|-------|-----------------|---------|
| `name` | Agent identifier | Lowercase, hyphens only |
| `description` | When Claude invokes this agent | Include trigger words |
| `tools` | What the agent can do | `Read`, `Write`, `Edit`, `Bash`, `Glob`, `Grep` |
| `model` | Which Claude model to use | `sonnet` (default), `haiku` (fast), `opus` (powerful), `inherit` |
| `memory` | Where it stores knowledge | `project` (this repo), `user` (all repos), `local` (private) |
| `permissionMode` | How permissions work | `default`, `acceptEdits`, `plan` (read-only) |
| `maxTurns` | Max conversation turns | Number (e.g., `20`) |

To give your agent starting knowledge, create its memory file:

```bash
mkdir -p .claude/agent-memory/code-reviewer
```

Then create `.claude/agent-memory/code-reviewer/MEMORY.md` with relevant context (max 200 lines — the system enforces this limit).

### Managing Your Agents

Once specialists are deployed, use natural language:

| What you want | What to say |
|---------------|-------------|
| Check status | "how are my agents doing?" or type `/agents` |
| Add a specialist | "add a specialist for deployment" |
| Remove one | "remove the tester" |
| Diagnose issues | "something feels off with the frontend agent" |
| See what one knows | "what does my API specialist know?" |
| Reset one | "reset the frontend agent's memory" |
| Start over | "remove all specialists and start fresh" |

The companion skill runs 4 automatic health checks before every management operation:
1. Agent file integrity (valid configuration)
2. Memory file health (auto-prunes if too large)
3. Reference integrity (removes dead links)
4. Usage staleness (flags agents not used in 30+ days)

---

## Slash Commands Reference

| Command | When to use it | Example |
|---------|---------------|---------|
| `/prime` | Start of every session | Just type `/prime` — it loads your context and picks up where you left off |
| `/plan <request>` | Before building anything non-trivial | `/plan add user authentication with OAuth` |
| `/build <plan-path>` | After a plan is approved | `/build plans/2026-03-12-auth-system.md` |
| `/status` | When you want an overview | `/status` — shows plans, git state, session history |
| `/wrap` | End of every session | `/wrap` — logs what happened, notes what's next |

---

## Project Templates

Templates are pre-built configurations for common project types. When the concierge detects your project matches one, it skips the architect agent entirely and uses the template directly.

| Template | Tech stacks | Typical agents |
|----------|------------|----------------|
| **Web App** | React, Vue, Next.js, Svelte + backend | Frontend, API, Testing (3-4 agents) |
| **API Backend** | Express, FastAPI, Django, Gin, Actix | Routes, Data, Auth, Testing (3-5 agents) |
| **Data Dashboard** | Pandas, Streamlit, Plotly | Data Processing, Visualization, Pipeline (2-3 agents) |
| **Content Site** | Gatsby, Hugo, Astro | Content, Styling, Build (2-3 agents) |
| **Automation Pipeline** | Airflow, Prefect, Celery | Orchestration, Tasks, Monitoring (2-4 agents) |
| **Mobile App** | React Native, Flutter, Expo | UI, Navigation, State, Platform (3-5 agents) |
| **ISPN Deployment** | Python microservices on AWS EKS | 27 domain-specific agents |

---

## Customization

### Operator Context (Tell Claude Who You Are)

Fill in these files to personalize how agents work with you. They're gitignored — your data stays private.

| File | What to put in it |
|------|------------------|
| `context/role.md` | Your name, title, responsibilities, working style |
| `context/org.md` | Your company, team structure, key systems |
| `context/priorities.md` | Current goals ranked by importance, deadlines |
| `context/metrics.md` | KPIs, performance numbers, project status |

See `context/_templates/` for examples of each file.

### Adding Your Own Hooks

Hooks are scripts that run automatically before or after Claude uses a tool. The ecosystem includes two:

- **`pre-bash-security.sh`** — blocks dangerous bash commands before they execute
- **`post-write-lint.sh`** — auto-formats files after every write

To add your own, create a script in `.claude/hooks/` and register it in `.claude/settings.json`. See `.claude/hooks/README.md` for the full guide.

### Architecture Decision Records

When you make important design decisions, log them in `decisions/` using the template at `decisions/_template.md`. This creates a searchable history of why things were built the way they were.

---

## Directory Structure

```
Claude MCP Ecosystem/
├── README.md                    # You are here
├── CLAUDE.md                    # Governance rules for Claude sessions
├── architecture.md              # Full technical reference
├── .gitignore
│
├── commands/                    # 12 slash command definitions for the plugin
├── skills/                      # Symlinks to subagent-lifecycle/skills/ for plugin discovery
│
├── .claude/
│   ├── agents/                  # Active agent definitions (5 symlinks + 1 standalone)
│   ├── commands/                # Workspace commands (/prime, /plan, /build, /status, /wrap)
│   ├── hooks/                   # Security and lint hook scripts
│   ├── scripts/                 # Agent health check (symlinked from plugin)
│   └── settings.json            # Permissions, deny rules, hook registration
│
├── subagent-lifecycle/          # The core plugin (self-contained unit)
│   ├── plugin.json              # Component registry and version info
│   ├── agents/                  # Source of truth for 5 pipeline agents
│   ├── skills/                  # 3 orchestrator skills (guide, concierge, companion)
│   ├── templates/               # 7 project type blueprints
│   ├── references/              # 15 knowledge files agents use for decisions
│   ├── scripts/                 # Health check script (source)
│   └── docs/                    # Architecture docs, plain-English guide, expert guide
│
├── tasks/                       # Task tracking (committed to git)
│   ├── todo.md                  # Current task plan with checkboxes
│   └── lessons.md               # Rules learned from past mistakes
│
├── context/                     # Your identity and priorities (gitignored)
│   ├── _templates/              # Example files to copy from (committed)
│   ├── role.md                  # Who you are
│   ├── org.md                   # Your organization
│   ├── priorities.md            # What matters right now
│   └── metrics.md               # Current numbers
│
├── state/                       # Session history (gitignored)
│   ├── session-log.md           # What happened in each session
│   └── decisions.md             # Design decisions made
│
├── plans/                       # Implementation plans from /plan (gitignored)
├── outputs/                     # Work products (gitignored)
├── decisions/                   # Architecture Decision Records (committed)
│   └── _template.md
│
├── docs/                        # Ecosystem-level planning and handoff documents
│   └── DEVOPS-HANDOFF.md        # DevOps delivery reference
```

---

## Troubleshooting

**"Nothing happened when I said 'organize my project'"**
Check that skills are copied correctly to `.claude/skills/` in your project. Each skill needs a `SKILL.md` file inside its directory (e.g., `.claude/skills/project-guide/SKILL.md`).

**"An agent seems confused or off"**
Say "something feels off with the [name] agent." The companion skill diagnoses the issue and offers three options: fix it, start over, or explain what happened.

**"I want to start completely over"**
Say "remove all specialists and start fresh." The system confirms before deleting anything.

**"How do I see what an agent has learned?"**
Say "what does my [name] specialist know?" The companion reads the agent's memory file and summarizes it.

**"The health check is failing"**
Run it manually to see the output:
```bash
bash .claude/scripts/agent-health-check.sh
```
Common issues: malformed YAML frontmatter in agent files, or memory files exceeding the 200-line limit.

**"I want more control over agent configuration"**
See the [expert guide](subagent-lifecycle/docs/for-experts.md) for full frontmatter reference and advanced configuration.

---

## Documentation

| Document | Audience | What it covers |
|----------|----------|---------------|
| [Architecture Reference](architecture.md) | Technical | Full component inventory, directory map, three-layer pipeline details |
| [Plain-English Guide](subagent-lifecycle/docs/for-vibecoders.md) | Beginners | How specialists work without any technical jargon |
| [Expert Guide](subagent-lifecycle/docs/for-experts.md) | Power users | All frontmatter fields, manual configuration, advanced patterns |
| [Plugin Architecture](subagent-lifecycle/docs/architecture.md) | Developers | Internal pipeline design and component relationships |
| [DevOps Handoff](docs/DEVOPS-HANDOFF.md) | DevOps / Ops | Environment, configuration, security, known tech debt |

---

## License

MIT
