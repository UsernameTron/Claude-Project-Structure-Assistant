# Claude-Centric AI Productivity Ecosystem
## Deployment Specification & Implementation Plan

```yaml
meta:
  version: "2.0.0"
  author: "Pete Connor"
  date: "2026-03-03"
  status: "DEPLOYMENT_READY"
  orchestrator: "Claude (Anthropic)"
  environment:
    primary: "claude.ai (web/mobile)"
    development: "Claude Desktop + MCP servers"
    cli: "Claude Code"
  final_tool_count: 10
  skill_count: 30  # 20 ISPN suite + 10 general/platform
```

---

## 1. Design Philosophy

The goal is not to use Claude for everything. The goal is to make Claude the **orchestration layer** that connects, routes, and enriches work across all productive domains. Every tool in this ecosystem either runs natively inside Claude or feeds through Claude as the integration point.

**Core Principle:** Single conversational interface, multi-domain execution. No context switching. No copy-paste bridges. One thread of thought, many outputs.

**Architecture Pattern:** Hub-and-spoke with three layers.

```
LAYER 3 — DELIVERY ──────────────────────────────────────
  Outputs: DOCX, PPTX, XLSX, PDF, HTML dashboards,
  emails, Slack messages, calendar events, code files,
  Netlify deployments, Mermaid diagrams

LAYER 2 — ORCHESTRATION ─────────────────────────────────
  Claude: Skills engine, MCP router, memory system,
  file creation, code execution, conversation context

LAYER 1 — DATA SOURCES ──────────────────────────────────
  Inputs: Fathom transcripts, Genesys exports, UKG data,
  Gmail inbox, Slack channels, uploaded files, user intent
```

**What makes this different from a tool stack:** Traditional productivity stacks are horizontal (one tool per function, manual handoffs between them). This ecosystem is vertical. Claude sits in the middle and data flows through it. A single conversation can read email, analyze an attachment, generate a report, chart the results, draft a follow-up, and schedule a meeting without context switching.

---

## 2. Final Tool Inventory

```yaml
ecosystem_tools:
  orchestrator:
    name: "Claude"
    role: "Central hub — all routing, processing, generation, and decision-making"
    interfaces:
      - "claude.ai (web/mobile) — primary conversational interface"
      - "Claude Desktop — MCP server integrations"
      - "Claude Code (CLI) — agentic coding and file operations"
      - "Anthropic API — programmatic access for automated pipelines"
    capabilities:
      native:
        - "Natural language processing and generation"
        - "Code generation, debugging, refactoring (Python, JS, HTML/CSS)"
        - "File creation (DOCX, PPTX, XLSX, PDF, HTML, SVG, Mermaid)"
        - "Data analysis and visualization (Chart.js, Recharts, D3)"
        - "Memory system (cross-session context retention)"
        - "Custom skills engine (30 domain-specific skills)"
        - "Web search and research"
        - "Image analysis and document parsing"
      via_mcp:
        - "Email read/write (Gmail)"
        - "Team messaging (Slack)"
        - "Calendar management (Google Calendar)"
        - "Diagram rendering (Mermaid Chart)"
        - "Web deployment (Netlify)"
        - "Design asset creation (Canva)"

  connected_tools:
    - name: "Gmail"
      connection: "MCP"
      mcp_url: "https://gmail.mcp.claude.com/mcp"
      category: "Email Assistance"
      operations: ["read", "search", "draft", "send", "label", "archive"]
      data_flow: "bidirectional"
      dependency_level: "critical"

    - name: "Slack"
      connection: "MCP"
      mcp_url: "https://mcp.slack.com/mcp"
      category: "Team Communication"
      operations: ["read_channels", "post_message", "search", "dm"]
      data_flow: "bidirectional"
      dependency_level: "critical"

    - name: "Google Calendar"
      connection: "MCP"
      mcp_url: "https://gcal.mcp.claude.com/mcp"
      category: "Scheduling"
      operations: ["read_events", "create_event", "update_event", "check_availability"]
      data_flow: "bidirectional"
      dependency_level: "standard"

    - name: "Mermaid Chart"
      connection: "MCP"
      mcp_url: "https://mcp.mermaidchart.com/mcp"
      category: "Data Visualization"
      operations: ["validate_diagram", "render_diagram", "get_summary"]
      data_flow: "outbound"
      dependency_level: "standard"

    - name: "Netlify"
      connection: "MCP"
      mcp_url: "https://netlify-mcp.netlify.app/mcp"
      category: "Deployment"
      operations: ["deploy_site", "get_deploy_status", "read_project"]
      data_flow: "outbound"
      dependency_level: "standard"

    - name: "Canva"
      connection: "MCP"
      mcp_url: "https://mcp.canva.com/mcp"
      category: "Graphic Design"
      operations: ["create_design", "list_templates", "export"]
      data_flow: "outbound"
      dependency_level: "optional"

    - name: "Obsidian"
      connection: "MCP (via Claude Desktop)"
      category: "Knowledge Management"
      operations: ["read_notes", "write_notes", "search", "list_files", "append"]
      data_flow: "bidirectional"
      dependency_level: "critical"

    - name: "Fathom"
      connection: "manual_handoff"
      category: "Meeting Capture"
      operations: ["record", "transcribe", "summarize", "export"]
      data_flow: "inbound_only"
      dependency_level: "critical"
      integration_method: "User exports transcript/summary from Fathom, uploads to Claude for enrichment"

    - name: "n8n"
      connection: "manual_handoff"
      category: "Workflow Automation Runtime"
      operations: ["execute_workflows", "schedule_triggers", "webhook_listeners"]
      data_flow: "outbound_only"
      dependency_level: "standard"
      integration_method: "Claude generates workflow JSON definitions, user imports to n8n for execution"

    - name: "GitHub"
      connection: "future_mcp"
      category: "Version Control"
      operations: ["planned — commit, PR, issue, branch management"]
      data_flow: "bidirectional"
      dependency_level: "future"
      integration_method: "Currently via Claude Code CLI; MCP integration anticipated"
```

---

## 3. Hub-and-Spoke Architecture

```
                         ┌──────────────────────┐
                         │    OBSIDIAN VAULT     │
                         │   (Knowledge Layer)   │
                         │                       │
                         │  Decision logs        │
                         │  Project notes        │
                         │  Meeting archives     │
                         │  Operational MOCs     │
                         └──────────┬───────────┘
                                    │ read/write
          ┌─────────────────────────┼─────────────────────────┐
          │                         │                         │
     ┌────▼─────┐           ┌──────▼──────┐           ┌──────▼──────┐
     │  Gmail   │◄──────────┤             ├──────────►│  Google     │
     │  MCP     │  send/    │   CLAUDE    │  create/  │  Calendar   │
     │          │  read     │   (Hub)     │  read     │  MCP        │
     └──────────┘           │             │           └─────────────┘
                            │  30 Skills  │
     ┌──────────┐           │  Memory     │           ┌─────────────┐
     │  Slack   │◄──────────┤  Code Exec  ├──────────►│  Netlify    │
     │  MCP     │  post/    │  File Gen   │  deploy   │  MCP        │
     │          │  read     │  Web Search │           └─────────────┘
     └──────────┘           │             │
                            └──┬───┬───┬──┘
                               │   │   │
                    ┌──────────┘   │   └──────────┐
                    ▼              ▼               ▼
              ┌──────────┐  ┌──────────┐   ┌──────────┐
              │ Mermaid  │  │  Canva   │   │  Fathom  │
              │ Chart    │  │  MCP     │   │ (manual) │
              │ MCP      │  │          │   │          │
              └──────────┘  └──────────┘   └──────────┘

        ┌──────────┐  ┌──────────┐
        │   n8n    │  │  GitHub  │
        │ (manual) │  │ (future) │
        └──────────┘  └──────────┘
```

**Data Flow Rules:**
1. All user intent enters through Claude (conversation, file upload, or CLI command).
2. Claude determines which tools/skills are needed based on context.
3. MCP-connected tools are invoked directly within the conversation.
4. Manual-handoff tools (Fathom, n8n) have defined import/export protocols.
5. All significant outputs are optionally archived to Obsidian for institutional memory.
6. Memory system provides cross-session continuity without re-explaining context.

---

## 4. Category Architecture (Detailed)

### 4.1 AI Chatbot (Foundation Layer)

```yaml
category: "AI Chatbot"
layer: "foundation"
role: "Conversational interface through which all other categories are accessed"
tools: ["Claude"]
skills_used: ["All — this is the execution environment"]
```

**What this layer actually does:** Every request originates here. The chatbot layer is not a category alongside the others — it IS the orchestration fabric. Memory, skills, MCPs, code execution, file generation, and web search all live in this layer. The other seven categories are functional domains that Claude serves through this single interface.

**Configuration for maximum effectiveness:**

**Memory System Optimization:**
The memory system is the connective tissue of the ecosystem. It ensures Claude retains operational context across sessions without requiring re-briefing. Current memory contains role context, org structure, direct reports, KPI targets, operational constants, and project status. This should be maintained and expanded as the ecosystem matures.

```yaml
memory_categories:
  organizational:
    - "Role, title, reporting structure"
    - "Direct reports and their responsibilities"
    - "Key stakeholders (Jeff, Scott, Charlie)"
    - "Staffing partner (HelpCafe)"
  operational:
    - "KPI targets (FCR >=70%, AHT <10.7min, AWT <90sec, Utilization >55%)"
    - "Workforce composition (120 techs: 59 L1, 20 L2, 41 L3)"
    - "Systems (Genesys Cloud CX, UKG)"
    - "Active projects and phase status"
  preferences:
    - "Communication style (direct, expert-calibrated, no hedging)"
    - "Technical defaults (Python for data, JS for frontend)"
    - "Visual defaults (Obsidian dark-mode aesthetic)"
    - "Quality priority (exceptional over efficient)"
```

**Skill Dependency Map:**
The 30 skills are not independent. They form dependency chains that the orchestrator skill manages. Understanding these chains is critical for implementation.

```yaml
skill_dependency_tree:
  foundation:
    - "ispn-constants-registry"  # All ISPN skills reference this
  
  orchestration:
    - "ispn-skill-orchestrator"  # Routes to correct skill based on input
    depends_on: ["ispn-constants-registry"]
  
  analytics_chain:
    - "ispn-dpr-analysis"  # Systemic analysis — MUST run before agent-level
    - "ispn-agent-coaching"  # Individual analysis — REQUIRES systemic context
    - "ispn-training-gap"  # Training plans from QA failures
    - "ispn-scorecard-analysis"  # Monthly LT scorecard
    depends_on: ["ispn-constants-registry", "ispn-skill-orchestrator"]
  
  reporting_chain:
    - "ispn-wcs-workbook-builder"  # Builds 22-tab WCS from raw exports
    - "ispn-wcs-historical-trends"  # Trend analysis on WCS data
    - "ispn-weekly-scorecard-builder"  # Weekly KPI scorecard
    - "ispn-board-reporting"  # Cost metrics for board
    - "ispn-visual-dashboard"  # HTML dashboard generation
    depends_on: ["ispn-constants-registry"]
  
  operational_chain:
    - "ispn-capacity-planning"  # FTE modeling, Erlang C
    - "ispn-cost-analytics"  # Financial analysis
    - "ispn-partner-sla"  # Partner SLA monitoring
    - "ispn-wfm-schedule-reconciliation"  # Schedule analysis
    depends_on: ["ispn-constants-registry"]
  
  platform_chain:
    - "genesys-cloud-cx-reporting"  # Export guidance and KPI calculations
    - "genesys-qa-analytics"  # QA evaluation processing
    - "genesys-queue-performance-analysis"  # Queue diagnostics
    - "genesys-skills-routing"  # ACD routing configuration
    depends_on: []  # Platform skills are self-contained
  
  helpdesk_chain:
    - "helpdesk-ticket-analysis"  # Screenshot parsing
    - "helpdesk-csv-analysis"  # CSV export analysis
    depends_on: []
  
  general_purpose:
    - "human-writing"  # Authentic voice generation
    - "mirror-universe-pete"  # Strategic sharp tone
    - "mirror-vision-prompt-crafter"  # SD prompt engineering
    - "obsidian-executive-poc-system"  # Executive demos and POCs
    - "cortex-platform-engineer"  # Cortex monorepo engineering
    - "resume-builder"  # Resume optimization
    - "skill-forge"  # Skill engineering protocol
    - "ultrathink"  # Multi-agent deep analysis
    depends_on: []
```

---

### 4.2 AI Coding Assistance (Build Layer)

```yaml
category: "AI Coding Assistance"
layer: "build"
role: "Code generation, debugging, refactoring, architecture, deployment"
tools: ["Claude", "Netlify MCP", "Mermaid Chart MCP", "GitHub (future)"]
skills_used:
  - "cortex-platform-engineer"
  - "skill-forge"
  - "obsidian-executive-poc-system"
  - "frontend-design"
  - "ispn-visual-dashboard"
```

**Execution Modes:**

```yaml
coding_modes:
  in_conversation:
    description: "Claude generates and executes code within the chat sandbox"
    use_cases:
      - "Quick scripts and one-off analysis"
      - "File generation (docx, pptx, xlsx, pdf, html)"
      - "Data processing and transformation"
      - "Artifact creation (React components, HTML apps)"
    limitations:
      - "Sandbox resets between tasks"
      - "No persistent filesystem"
      - "No access to external APIs from sandbox (except allowed domains)"
    output_paths:
      code_files: "/mnt/user-data/outputs/"
      artifacts: "Rendered inline in conversation"
  
  claude_code_cli:
    description: "Agentic coding via terminal — file editing, testing, git operations"
    use_cases:
      - "Multi-file project scaffolding"
      - "Editing existing codebases (Cortex platform)"
      - "Running test suites"
      - "Git operations (commit, branch, push)"
      - "Complex refactoring across files"
    strengths:
      - "Persistent filesystem access"
      - "Full terminal environment"
      - "Can run linters, formatters, test runners"
    integration_with_ecosystem:
      - "Reads skill files for context"
      - "Deploys via Netlify CLI"
      - "Commits to GitHub"
  
  skill_engineering:
    description: "Code that becomes reusable Claude capabilities"
    use_cases:
      - "Building new ISPN suite skills"
      - "Upgrading existing skills (skill-forge protocol)"
      - "Creating automation templates"
    workflow: "skill-forge 6-gate protocol → SKILL.md + bundled scripts → testing → deployment"
```

**Deployment Pipeline:**

```yaml
deployment_pipeline:
  step_1_develop:
    tool: "Claude in-conversation or Claude Code CLI"
    output: "Working code in /home/claude/ or local project directory"
  
  step_2_test:
    tool: "Claude Code CLI"
    actions:
      - "Run linters (eslint, pylint)"
      - "Execute test suites"
      - "Validate output files"
  
  step_3_deploy:
    tool: "Netlify MCP"
    actions:
      - "Deploy static sites and dashboards"
      - "Get deploy status and preview URLs"
    alternative: "Manual deploy via Netlify CLI from Claude Code"
  
  step_4_document:
    tool: "Mermaid Chart MCP + Obsidian"
    actions:
      - "Generate architecture diagrams"
      - "Update project documentation in vault"
```

---

### 4.3 AI Writing Generation (Communication Layer)

```yaml
category: "AI Writing Generation"
layer: "communication"
role: "All written output — reports, emails, creative content, strategic documents"
tools: ["Claude"]
skills_used:
  - "human-writing"
  - "mirror-universe-pete"
  - "resume-builder"
  - "docx skill"
  - "pdf skill"
  - "pptx skill"
```

**Writing Pipeline Architecture:**

Every piece of writing flows through a three-stage pipeline, though stages can be collapsed for routine work.

```yaml
writing_pipeline:
  stage_1_draft:
    description: "Raw content generation calibrated to context"
    inputs:
      - "User intent (conversational request)"
      - "Memory context (role, org, preferences)"
      - "Source data (uploaded files, search results, prior conversations)"
    processing:
      - "Claude generates draft in appropriate register"
      - "Skill selection based on output type and tone requirements"
    skill_routing:
      professional_sharp: "mirror-universe-pete"
      authentic_human: "human-writing"
      executive_formal: "Default Claude with expert calibration"
      resume_career: "resume-builder"
  
  stage_2_format:
    description: "Package into final deliverable format"
    routing:
      word_document: "docx skill → .docx file"
      presentation: "pptx skill → .pptx file"
      pdf_report: "pdf skill → .pdf file"
      web_content: "HTML/React artifact"
      email_draft: "Gmail MCP → draft in inbox"
      slack_message: "Slack MCP → channel post"
      markdown: "Direct .md file creation"
  
  stage_3_distribute:
    description: "Route deliverable to intended audience"
    channels:
      email: "Gmail MCP — attach file or inline content"
      slack: "Slack MCP — post to channel or DM"
      vault: "Obsidian — archive for knowledge management"
      deploy: "Netlify MCP — publish web content"
      download: "Direct file download from conversation"
```

**Tone Calibration Matrix:**

```yaml
tone_matrix:
  stakeholder_email_up:
    skill: "Default Claude"
    register: "Professional, concise, data-forward"
    example_audience: "Jeff (CEO), Scott (CFO), Charlie (SVP Ops)"
  
  stakeholder_email_lateral:
    skill: "human-writing"
    register: "Collegial, direct, action-oriented"
    example_audience: "Peer directors, partner managers"
  
  team_communication:
    skill: "human-writing"
    register: "Clear, supportive, specific"
    example_audience: "Annie, Harland, Brent, Carlos"
  
  strategic_pushback:
    skill: "mirror-universe-pete"
    register: "Surgical precision, weaponized politeness"
    example_audience: "Vendors, difficult partners, scope creep pushback"
  
  board_materials:
    skill: "ispn-board-reporting + pptx skill"
    register: "Executive, metric-driven, Obsidian aesthetic"
    example_audience: "Board, investors, executive sponsors"
  
  career_materials:
    skill: "resume-builder + human-writing"
    register: "Achievement-oriented, authentic, quantified"
    example_audience: "Recruiters, hiring managers, interview panels"
```

---

### 4.4 AI Email Assistance (Outbound Communication Layer)

```yaml
category: "AI Email Assistance"
layer: "communication"
role: "Draft, summarize, manage, respond to email with full Gmail integration"
tools: ["Claude", "Gmail MCP", "Slack MCP"]
skills_used:
  - "human-writing"
  - "mirror-universe-pete"
```

**Gmail MCP Workflow Patterns:**

```yaml
email_workflows:
  inbox_triage:
    trigger: "Manual — 'summarize my unread emails' or 'what's in my inbox'"
    steps:
      1: "Gmail MCP reads unread messages"
      2: "Claude categorizes by urgency and topic"
      3: "Presents prioritized summary with recommended actions"
      4: "User selects which to respond to"
      5: "Claude drafts responses calibrated to recipient"
      6: "User approves, Claude sends via Gmail MCP"
    frequency: "Daily or on-demand"
  
  compose_with_strategy:
    trigger: "User describes intent — 'email Charlie about the staffing gap'"
    steps:
      1: "Claude pulls context from memory (relationship, recent interactions, topic history)"
      2: "Message compose tool generates 2-3 strategic variants"
      3: "User selects preferred approach"
      4: "Claude sends via Gmail MCP"
    skill_applied: "Tone matrix determines which writing skill to invoke"
  
  follow_up_from_meeting:
    trigger: "After Fathom transcript processing (see 4.6)"
    steps:
      1: "Claude extracts action items and owners from transcript"
      2: "Generates differentiated follow-up emails per audience"
      3: "Executive summary → leadership (concise, decisions + next steps)"
      4: "Detailed action list → team (specific tasks, owners, deadlines)"
      5: "User reviews and approves sends"
  
  attachment_analysis:
    trigger: "User asks about an email attachment"
    steps:
      1: "Gmail MCP retrieves message and attachment"
      2: "Claude analyzes attachment content"
      3: "Provides summary, answers questions, or processes data"
      4: "Optionally routes to spreadsheet/visualization skills"
```

**Slack MCP Integration:**

```yaml
slack_workflows:
  channel_summary:
    trigger: "'What happened in #operations today'"
    steps:
      1: "Slack MCP reads channel history"
      2: "Claude summarizes key discussions and decisions"
      3: "Highlights items requiring Pete's attention"
  
  cross_channel_post:
    trigger: "After generating a report or dashboard"
    steps:
      1: "Claude generates channel-appropriate summary"
      2: "Posts to relevant Slack channel with attachment or link"
      3: "Different channels get different levels of detail"
  
  dm_drafting:
    trigger: "'Message Harland about the schedule change'"
    steps:
      1: "Claude drafts message with appropriate tone"
      2: "User approves, sends via Slack MCP"
```

---

### 4.5 AI Spreadsheet (Data Processing Layer)

```yaml
category: "AI Spreadsheet"
layer: "data_processing"
role: "Data analysis, formula generation, workbook creation, structured data manipulation"
tools: ["Claude"]
skills_used:
  - "xlsx skill"
  - "ispn-wcs-workbook-builder"
  - "ispn-weekly-scorecard-builder"
  - "ispn-scorecard-analysis"
  - "ispn-wfm-schedule-reconciliation"
  - "ispn-cost-analytics"
  - "ispn-board-reporting"
  - "helpdesk-csv-analysis"
  - "genesys-cloud-cx-reporting"
```

**Data Processing Architecture:**

```yaml
data_pipeline:
  input_sources:
    genesys_exports:
      files:
        - "CD_data_2*.csv — Call distribution data"
        - "CD_data_2b*.csv — Call distribution extended"
        - "Call_Detail*.csv — Individual call records"
        - "ACD_data*.csv — ACD queue statistics"
        - "Wait_time*.csv — Wait time distributions"
        - "Outbound*.csv — Outbound call data"
        - "Agent_Status_Summary*.csv — Agent state data"
        - "Activities_*.csv — WFM activities"
        - "ScheduledRequiredAndPerformance_*.csv — WFM schedules"
        - "Full_Call_Reviews*.csv — QA evaluations"
      routing: "ispn-skill-orchestrator detects file type → routes to correct parser"
    
    ukg_exports:
      files:
        - "UKG labor CSVs — hours, costs, attendance"
      routing: "ispn-cost-analytics or ispn-board-reporting"
    
    helpdesk_exports:
      files:
        - "help_tag-report_*.csv — Ticket tag reports"
        - "Daily Ticket Volume screenshots"
      routing: "helpdesk-csv-analysis or helpdesk-ticket-analysis"
    
    manual_data:
      files:
        - "TC_KPI_Metrics_Master*.xlsx — Master KPI tracker"
        - "L1_to_L3_Hours*.csv — Tier hour distribution"
        - "Activities_*.xlsx — Activity tracking"
      routing: "ispn-weekly-scorecard-builder"

  processing_tiers:
    tier_1_raw_parse:
      description: "File detection, validation, column mapping"
      tool: "ispn-skill-orchestrator"
      output: "Structured data objects ready for analysis"
    
    tier_2_calculate:
      description: "KPI calculation, formula application, metric derivation"
      tool: "Domain-specific skill (WCS builder, scorecard, cost analytics)"
      output: "Calculated metrics with formulas preserved"
    
    tier_3_format:
      description: "Excel workbook generation with formatting, charts, validation"
      tool: "xlsx skill"
      output: ".xlsx file with multiple tabs, conditional formatting, embedded charts"
    
    tier_4_visualize:
      description: "Dashboard or presentation generation from processed data"
      tool: "ispn-visual-dashboard or pptx skill"
      output: "HTML dashboard or PPTX slides"
```

**Recurring Report Specifications:**

```yaml
recurring_reports:
  weekly_call_statistics:
    frequency: "Weekly"
    inputs: "6 Genesys CSV exports"
    skill: "ispn-wcs-workbook-builder"
    output: "22-tab Excel workbook with charts, rolling averages, YTD cumulative"
    distribution: "Email to leadership, archive to vault"
    validation: "ispn-wcs-historical-trends for anomaly detection"
  
  weekly_kpi_scorecard:
    frequency: "Weekly"
    inputs: "7 source files (see ispn-weekly-scorecard-builder triggers)"
    skill: "ispn-weekly-scorecard-builder"
    output: "44 metrics across 8 sections, 6 integrity checks, verification DOCX"
    distribution: "Email to Charlie, archive to vault"
    grading: "11 FY25 targets"
  
  monthly_lt_scorecard:
    frequency: "Monthly"
    inputs: "*Scorecard*.xlsx"
    skill: "ispn-scorecard-analysis"
    output: "KPI extraction, trend analysis, threshold grading, capacity planning"
    distribution: "Board deck inclusion, email to Jeff/Scott"
  
  board_cost_report:
    frequency: "Monthly"
    inputs: "UKG labor CSVs + scorecard data"
    skill: "ispn-board-reporting"
    output: "Cost per call, cost per minute, labor vs budget, savings opportunity"
    formats: ["PDF report", "PPTX slides (Obsidian-styled)", "JSON structured data"]
    distribution: "Board deck, email to Jeff/Scott"
```

---

### 4.6 AI Meeting Notes (Capture-to-Action Layer)

```yaml
category: "AI Meeting Notes"
layer: "capture_to_action"
role: "Close the loop between live conversations and documented outcomes"
tools: ["Fathom", "Claude", "Gmail MCP", "Slack MCP", "Google Calendar MCP", "Obsidian"]
skills_used:
  - "human-writing"
```

**The Capture Gap and Why It Is Strategic:**

Claude cannot join a live call. This is the one hard dependency on an external tool for real-time capture. But the gap is narrow and well-defined: Claude needs a transcript and a summary as input. Everything downstream (analysis, enrichment, distribution, archival) runs through Claude. Fathom is the designated capture tool.

**Why Fathom:**

```yaml
fathom_selection_rationale:
  cost: "Free tier covers unlimited recording, transcription, and AI summaries"
  speaker_attribution: "Identifies who said what — critical for action item assignment"
  native_ai_summaries: "Pre-processes transcript into structured summary before Claude enrichment"
  calendar_integration: "Auto-joins scheduled meetings via Google Calendar sync"
  export_quality: "Clean transcript export that Claude can immediately parse"
  capture_friction: "Zero — auto-joins, auto-records, no manual start/stop"
```

**Two-Tier Processing Model:**

Not every meeting needs Claude. This distinction prevents the ecosystem from creating unnecessary overhead.

```yaml
processing_tiers:
  tier_1_fathom_only:
    description: "Lightweight — Fathom native summary is sufficient"
    use_cases:
      - "Daily standups"
      - "Routine team syncs"
      - "Status updates with no decisions"
      - "Informational meetings (webinars, vendor demos)"
    workflow: "Fathom auto-captures → review AI summary in Fathom → done"
    claude_involvement: "None"
  
  tier_2_fathom_to_claude:
    description: "Deep processing — transcript needs enrichment and distribution"
    use_cases:
      - "Leadership reviews with Jeff/Scott/Charlie"
      - "Partner escalation calls"
      - "Board prep meetings"
      - "Strategy sessions with cross-functional impact"
      - "Interview debriefs (Pete's own interviews)"
      - "QBRs and performance reviews"
    workflow: "See detailed pipeline below"
    claude_involvement: "Full enrichment, distribution, and archival"
```

**Tier 2 Processing Pipeline (Detailed):**

```yaml
tier_2_pipeline:
  step_01_capture:
    tool: "Fathom"
    action: "Auto-join via calendar → record → transcribe → generate AI summary"
    output: "Speaker-attributed transcript + structured summary"
  
  step_02_upload:
    tool: "Claude (manual upload)"
    action: "User copies Fathom transcript/summary into Claude conversation"
    input_format: "Plain text with speaker labels"
  
  step_03_context_enrichment:
    tool: "Claude memory + past chats"
    action: "Cross-reference discussion against known projects, people, KPIs, and prior decisions"
    output: "Enriched transcript with contextual annotations"
    example: "When Charlie mentions 'the staffing gap', Claude connects this to the capacity planning analysis from last week's conversation and the current 120-tech roster composition"
  
  step_04_decision_extraction:
    tool: "Claude"
    action: "Identify explicit and implicit decisions with owners, dates, and dependencies"
    output_format:
      decision: "What was decided"
      owner: "Who is responsible"
      deadline: "When it's due"
      dependencies: "What must happen first"
      reversibility: "Can this be undone? By when?"
  
  step_05_action_item_generation:
    tool: "Claude"
    action: "Generate prioritized task list with suggested owners and deadlines"
    output_format:
      action: "Specific task description"
      owner: "Assigned person"
      deadline: "Due date"
      priority: "Critical / High / Standard"
      context: "Why this matters"
  
  step_06_risk_identification:
    tool: "Claude"
    action: "Flag what was NOT addressed, what needs follow-up, what contradicts prior decisions"
    output_format:
      gap: "Topic that should have been discussed but wasn't"
      contradiction: "New decision that conflicts with prior commitment"
      escalation: "Item that requires higher-level attention"
  
  step_07_commitment_tracking:
    tool: "Claude → xlsx skill"
    action: "Update running commitment log across meetings"
    output: "Spreadsheet row appended with new commitments"
    fields: ["date", "meeting", "person", "commitment", "deadline", "status"]
  
  step_08_distribution:
    tool: "Claude → Gmail MCP + Slack MCP"
    action: "Generate differentiated summaries per audience and distribute"
    variants:
      executive_summary:
        audience: "Jeff, Scott, Charlie"
        format: "3-5 bullet decisions, 2-3 key metrics, next steps"
        channel: "Gmail"
      team_detail:
        audience: "Annie, Harland, Brent, Carlos"
        format: "Full action items with owners and deadlines"
        channel: "Slack channel post"
      partner_summary:
        audience: "External partners (if applicable)"
        format: "Agreed outcomes only, no internal context"
        channel: "Gmail"
  
  step_09_calendar_events:
    tool: "Claude → Google Calendar MCP"
    action: "Create events for follow-up meetings and deadline checkpoints"
    logic: "Any action item with a deadline gets a calendar event 2 days before due date"
  
  step_10_archival:
    tool: "Claude → Obsidian"
    action: "Create structured meeting note in vault"
    vault_location: "Meetings/YYYY-MM-DD - Meeting Title.md"
    template:
      frontmatter: "date, attendees, type, project_links"
      sections: ["Summary", "Decisions", "Action Items", "Open Questions", "Risks"]
      links: "Bidirectional links to project notes, people notes, and prior meeting notes"
```

**Integration Architecture:**

```
┌──────────┐     ┌──────────────────────────────────────────────────────┐
│          │     │                    CLAUDE (Hub)                      │
│  FATHOM  │────►│                                                      │
│ (capture)│     │  ┌──────────┐  ┌──────────┐  ┌───────────────────┐  │
│          │     │  │ Enrich   │→ │ Extract  │→ │   Distribute      │  │
└──────────┘     │  │ context  │  │ decisions │  │   & archive       │  │
                 │  │ (memory) │  │ actions  │  │                   │  │
                 │  └──────────┘  │ risks    │  └─────┬──┬──┬──┬───┘  │
                 │                └──────────┘        │  │  │  │      │
                 └────────────────────────────────────┼──┼──┼──┼──────┘
                                                      │  │  │  │
                              ┌────────────────────────┘  │  │  │
                              ▼              ▼            ▼  ▼
                          Gmail MCP    Slack MCP    Calendar  Obsidian
                         (summaries)  (highlights)  (events) (archive)
```

---

### 4.7 AI Knowledge Management (Memory and Context Layer)

```yaml
category: "AI Knowledge Management"
layer: "memory_and_context"
role: "Persistent organizational memory, documentation, decision logging, contextual retrieval"
tools: ["Claude", "Obsidian"]
skills_used:
  - "ispn-skill-orchestrator"
  - "ispn-constants-registry"
  - "skill-forge"
  - "All skills (they ARE codified knowledge)"
```

**Knowledge Architecture:**

This is the most structurally important category. It is the foundation that makes every other category more effective over time. Without it, every conversation starts from zero. With it, Claude operates with institutional memory.

**Five Knowledge Tiers:**

```yaml
knowledge_tiers:
  tier_1_claude_memory:
    description: "Cross-session recall of preferences, projects, org context"
    storage: "Claude memory system (userMemories)"
    access: "Automatic — injected into every conversation"
    update_method: "memory_user_edits tool"
    content_types:
      - "Role and organizational context"
      - "Direct reports and stakeholders"
      - "Active projects and their status"
      - "Communication preferences"
      - "Technical preferences"
      - "Operational targets and constants"
    maintenance: "Review monthly — remove stale items, update project status"
    capacity: "30 edits max, 100K chars per edit"
  
  tier_2_custom_skills:
    description: "Codified operational knowledge — processes, formulas, domain expertise"
    storage: "SKILL.md files in /mnt/skills/user/"
    access: "Triggered by context matching or explicit invocation"
    update_method: "skill-forge protocol (6-gate engineering)"
    content_types:
      - "KPI calculation formulas"
      - "Data processing pipelines"
      - "Reporting templates and structures"
      - "Platform-specific guidance (Genesys, UKG)"
      - "Decision frameworks"
    maintenance: "Audit quarterly — check for trigger collisions, scope creep, stale data"
    current_count: 30
  
  tier_3_obsidian_vault:
    description: "Structured knowledge base with linked notes, templates, MOCs"
    storage: "Obsidian vault (local, accessed via MCP)"
    access: "On-demand via Obsidian MCP read/search operations"
    update_method: "Claude writes notes via Obsidian MCP or manual editing"
    content_types:
      - "Meeting notes and decision logs"
      - "Project documentation"
      - "Process runbooks"
      - "Partner profiles and SLA history"
      - "Agent performance history"
      - "Training curriculum and gap analysis"
    structure:
      top_level_mocs:
        - "Operations MOC — links to all operational docs"
        - "People MOC — agent profiles, team structures"
        - "Partners MOC — partner profiles, SLA status"
        - "Projects MOC — active project tracking"
        - "Meetings MOC — meeting note index"
      naming_convention: "YYYY-MM-DD - Descriptive Title.md"
      template_types: ["Meeting Note", "Decision Log", "Project Brief", "Agent Profile"]
  
  tier_4_past_chats:
    description: "Searchable conversation history for continuity"
    storage: "Claude past chats system"
    access: "conversation_search and recent_chats tools"
    content_types:
      - "Previous analysis results"
      - "Decisions made in prior conversations"
      - "Context from earlier work sessions"
    limitations:
      - "Search is keyword-based, not semantic"
      - "Results are conversation snippets, not full transcripts"
      - "Deleted conversations are eventually purged"
  
  tier_5_constants_registry:
    description: "Single source of truth for shared values across all ISPN skills"
    storage: "ispn-constants-registry skill"
    access: "Referenced by all ISPN suite skills"
    content_types:
      - "Financial rates (blended rate, cost per hour)"
      - "Operational targets (FCR, AHT, AWT, utilization)"
      - "Staffing constants (headcount, tier distribution)"
      - "Seasonal model parameters"
      - "Partner SLA thresholds"
    maintenance: "Update here FIRST, then cascade to referenced skills"
```

**Knowledge Flow Diagram:**

```
┌─────────────────────────────────────────────────────────┐
│                   KNOWLEDGE LAYER                       │
│                                                         │
│  ┌─────────────┐  ┌─────────────┐  ┌────────────────┐  │
│  │   Claude     │  │  Obsidian   │  │   Custom       │  │
│  │   Memory     │  │  Vault      │  │   Skills       │  │
│  │             │  │             │  │               │  │
│  │  Auto-inject │  │  On-demand  │  │  Context-      │  │
│  │  every chat  │  │  retrieval  │  │  triggered     │  │
│  └──────┬──────┘  └──────┬──────┘  └───────┬────────┘  │
│         │                │                  │           │
│         └────────────────┼──────────────────┘           │
│                          ▼                              │
│              ┌──────────────────────┐                   │
│              │   CLAUDE CONTEXT     │                   │
│              │   WINDOW             │                   │
│              │                      │                   │
│              │   Memory + Skills +  │                   │
│              │   Vault Notes +      │                   │
│              │   Past Chats +       │                   │
│              │   Constants          │                   │
│              └──────────┬───────────┘                   │
│                         │                               │
│                         ▼                               │
│              Every response is informed                 │
│              by accumulated knowledge                   │
└─────────────────────────────────────────────────────────┘
```

---

### 4.8 AI Data Visualization (Insight Presentation Layer)

```yaml
category: "AI Data Visualization"
layer: "insight_presentation"
role: "Transform data into visual narratives — dashboards, charts, diagrams, interactive displays"
tools: ["Claude", "Mermaid Chart MCP", "Canva MCP", "Netlify MCP"]
skills_used:
  - "ispn-visual-dashboard"
  - "obsidian-executive-poc-system"
  - "cortex-platform-engineer"
  - "frontend-design"
```

**Visualization Rendering Matrix:**

```yaml
rendering_matrix:
  operational_dashboard:
    skill: "ispn-visual-dashboard"
    output: "Standalone .html file"
    tech_stack: "Chart.js + Obsidian design tokens"
    features: ["Filterable KPI cards", "Trend charts", "Gauge visualizations", "Data tables"]
    distribution: "Email attachment, Slack link, Netlify deploy"
    use_case: "Weekly operations review, team performance tracking"
  
  executive_poc:
    skill: "obsidian-executive-poc-system"
    output: "React artifact (.jsx) rendered in conversation"
    tech_stack: "React + Recharts + Tailwind + Obsidian design system"
    features: ["Interactive simulations", "ROI calculators", "Transformation roadmaps"]
    distribution: "Live demo in conversation, export as HTML"
    use_case: "Board presentations, stakeholder demos, portfolio pieces"
  
  architecture_diagram:
    tool: "Mermaid Chart MCP"
    output: "Rendered Mermaid diagram"
    types: ["Flowcharts", "Sequence diagrams", "ER diagrams", "Gantt charts", "Class diagrams"]
    distribution: "Embed in documents, export as image"
    use_case: "System architecture, process flows, project timelines"
  
  presentation_charts:
    skill: "pptx skill"
    output: "Charts embedded in .pptx slides"
    tech_stack: "python-pptx chart objects"
    features: ["Bar", "Line", "Pie", "Combo charts with Obsidian styling"]
    distribution: "PPTX file for board/stakeholder meetings"
    use_case: "Monthly board deck, QBR presentations"
  
  quick_analysis_chart:
    output: "React artifact in conversation"
    tech_stack: "Recharts or Chart.js in .jsx"
    features: ["Interactive tooltips", "Responsive layout", "Real-time data binding"]
    distribution: "Inline in conversation for rapid iteration"
    use_case: "Ad-hoc analysis, exploring data before committing to format"
  
  pdf_dashboard:
    skill: "pdf skill"
    output: ".pdf file"
    tech_stack: "ReportLab or HTML-to-PDF conversion"
    distribution: "Email attachment, print-ready"
    use_case: "Board distribution, compliance documentation"
  
  design_assets:
    tool: "Canva MCP"
    output: "Canva design (social media, infographics, branded materials)"
    distribution: "Export from Canva"
    use_case: "External-facing visuals, marketing materials, branded reports"
```

**Design System Consistency:**

All visualizations produced through the ecosystem share the Obsidian design language for executive contexts.

```yaml
obsidian_design_tokens:
  palette:
    background_primary: "#0D1117"
    background_secondary: "#161B22"
    background_card: "#1C2128"
    accent_primary: "#00D4AA"
    accent_secondary: "#7B68EE"
    accent_warning: "#FF6B35"
    text_primary: "#E6EDF3"
    text_secondary: "#8B949E"
    text_muted: "#484F58"
    border: "#30363D"
    success: "#3FB950"
    danger: "#F85149"
  
  typography:
    heading_font: "Inter, system-ui, sans-serif"
    body_font: "Inter, system-ui, sans-serif"
    mono_font: "JetBrains Mono, monospace"
    heading_weight: 600
    body_weight: 400
  
  layout:
    card_radius: "12px"
    card_padding: "24px"
    grid_gap: "16px"
    max_content_width: "1400px"
  
  signature_element: "One distinctive visual element per deliverable — never generic"
```

---

## 5. Cross-Category Workflow Specifications

These are the recurring multi-category workflows that demonstrate the ecosystem's integration value. Each workflow crosses at least three categories and would require significant manual effort without orchestration.

### 5.1 Weekly Operations Cycle

```yaml
workflow: "Weekly Operations Cycle"
frequency: "Every Monday"
categories_crossed: ["Spreadsheet", "Data Visualization", "Email", "Knowledge Management"]
estimated_time_with_ecosystem: "30-45 minutes"
estimated_time_without: "3-4 hours"

steps:
  1_data_collection:
    action: "Upload 6 Genesys CSV exports to Claude"
    tool: "Claude file upload"
    time: "2 minutes"
  
  2_workbook_generation:
    action: "ispn-skill-orchestrator routes files → ispn-wcs-workbook-builder generates 22-tab workbook"
    tool: "Claude skills"
    output: "WCS_Week_XX.xlsx"
    time: "5-8 minutes"
  
  3_anomaly_check:
    action: "ispn-wcs-historical-trends validates current week against 104-week baseline"
    tool: "Claude skills"
    output: "Flags any metrics outside 2-sigma bounds"
    time: "3-5 minutes"
  
  4_dashboard_generation:
    action: "ispn-visual-dashboard creates interactive HTML dashboard from WCS data"
    tool: "Claude skills"
    output: "WCS_Dashboard_Week_XX.html"
    time: "5-8 minutes"
  
  5_summary_draft:
    action: "Claude generates executive summary highlighting trends, anomalies, and actions needed"
    tool: "Claude + human-writing skill"
    output: "Email body text"
    time: "3-5 minutes"
  
  6_distribution:
    action: "Email summary + attached workbook + dashboard link to leadership"
    tool: "Gmail MCP"
    output: "Sent email to Charlie/Jeff/Scott"
    time: "2 minutes"
  
  7_slack_post:
    action: "Post abbreviated highlights to #operations channel"
    tool: "Slack MCP"
    output: "Channel message with key metrics"
    time: "2 minutes"
  
  8_archival:
    action: "Create weekly operations note in Obsidian vault"
    tool: "Obsidian MCP"
    output: "Meetings/YYYY-MM-DD - Week XX Operations Review.md"
    time: "2 minutes"
```

### 5.2 Board Reporting Pipeline

```yaml
workflow: "Board Reporting Pipeline"
frequency: "Monthly"
categories_crossed: ["Spreadsheet", "Data Visualization", "Writing", "Email"]
estimated_time_with_ecosystem: "1-2 hours"
estimated_time_without: "6-8 hours"

steps:
  1_data_assembly:
    action: "Upload UKG labor CSVs + monthly scorecard"
    tool: "Claude file upload"
  
  2_cost_calculation:
    action: "ispn-board-reporting calculates 4 board metrics"
    tool: "Claude skills"
    output: "Cost per call, cost per minute, labor vs budget, savings opportunity"
  
  3_trend_analysis:
    action: "Compare against prior months for trend narrative"
    tool: "ispn-cost-analytics + ispn-wcs-historical-trends"
    output: "MoM and YoY trend data"
  
  4_slide_generation:
    action: "Generate Obsidian-styled PPTX deck"
    tool: "pptx skill + obsidian-executive-poc-system design tokens"
    output: "Board_Report_Month_Year.pptx"
  
  5_pdf_generation:
    action: "Export PDF version for email distribution"
    tool: "pdf skill"
    output: "Board_Report_Month_Year.pdf"
  
  6_review_draft:
    action: "Claude drafts email to Jeff/Scott with report summary"
    tool: "Gmail MCP + human-writing"
    output: "Draft email with attachments"
  
  7_distribution:
    action: "Send after Pete's review and approval"
    tool: "Gmail MCP"
```

### 5.3 Meeting-to-Action Pipeline

```yaml
workflow: "Meeting-to-Action Pipeline"
frequency: "After every Tier 2 meeting"
categories_crossed: ["Meeting Notes", "Email", "Knowledge Management", "Spreadsheet", "Scheduling"]

steps:
  1_capture:
    tool: "Fathom"
    action: "Auto-capture, transcribe, generate AI summary"
  
  2_upload_and_enrich:
    tool: "Claude"
    action: "Upload transcript → context enrichment via memory"
  
  3_extract:
    tool: "Claude"
    action: "Decisions, action items, risks, open questions"
  
  4_distribute_executive:
    tool: "Gmail MCP"
    action: "Executive summary to leadership"
  
  5_distribute_team:
    tool: "Slack MCP"
    action: "Action items to relevant channel"
  
  6_schedule_followups:
    tool: "Google Calendar MCP"
    action: "Calendar events for deadlines and check-ins"
  
  7_update_commitment_log:
    tool: "Claude → xlsx skill"
    action: "Append new commitments to tracking spreadsheet"
  
  8_archive:
    tool: "Obsidian MCP"
    action: "Structured meeting note in vault"
```

### 5.4 Incident Response Pattern

```yaml
workflow: "Incident Response"
frequency: "Ad-hoc"
categories_crossed: ["Coding", "Spreadsheet", "Writing", "Email", "Knowledge Management"]

steps:
  1_diagnose:
    tool: "Claude + genesys-queue-performance-analysis"
    action: "Analyze queue metrics to identify root cause"
  
  2_assess_impact:
    tool: "Claude + ispn-cost-analytics"
    action: "Calculate financial and SLA impact"
  
  3_remediate:
    tool: "Claude + genesys-skills-routing"
    action: "Recommend routing or staffing adjustments"
  
  4_communicate:
    tool: "Gmail MCP + Slack MCP"
    action: "Stakeholder notification with impact assessment and remediation plan"
  
  5_document:
    tool: "Obsidian MCP"
    action: "Incident postmortem in vault with linked root cause analysis"
  
  6_prevent:
    tool: "Claude + ispn-partner-sla"
    action: "Update SLA monitoring thresholds if gap identified"
```

### 5.5 Skill Development Lifecycle

```yaml
workflow: "Skill Development Lifecycle"
frequency: "As needed"
categories_crossed: ["Coding", "Knowledge Management", "Writing"]

steps:
  1_identify_need:
    tool: "Claude conversation"
    action: "Recognize repeating pattern that should be codified"
  
  2_design:
    tool: "skill-forge protocol"
    action: "6-gate engineering: scope → structure → implement → test → document → deploy"
  
  3_implement:
    tool: "Claude Code CLI"
    action: "Write SKILL.md + bundled scripts"
  
  4_test:
    tool: "skill-creator evals"
    action: "Benchmark trigger accuracy and output quality"
  
  5_deploy:
    tool: "File placement in /mnt/skills/user/"
    action: "Skill becomes available in future conversations"
  
  6_maintain:
    tool: "skill-forge audit"
    action: "Quarterly review for trigger collisions, scope creep, stale data"
```

---

## 6. n8n Automation Specifications

Claude designs automations. n8n executes them. These are the specific automation workflows Claude should generate for n8n deployment.

```yaml
n8n_workflows:
  scheduled_report_trigger:
    purpose: "Automatically prepare data files for weekly operations cycle"
    trigger: "Cron — Monday 6:00 AM CT"
    nodes:
      - "Genesys Cloud API → fetch weekly exports"
      - "File write → save CSVs to staging directory"
      - "Notification → Slack message to Pete: 'Weekly data ready for processing'"
    claude_role: "Generates the n8n workflow JSON definition"
    human_role: "Imports to n8n, configures API credentials, activates"
  
  email_digest:
    purpose: "Daily email summary pushed to Slack"
    trigger: "Cron — daily 8:00 AM CT"
    nodes:
      - "Gmail API → fetch unread from priority senders"
      - "Claude API → summarize and prioritize"
      - "Slack API → post digest to #daily-digest channel"
    claude_role: "Designs the workflow, writes the prompt for the Claude API node"
    human_role: "Configures credentials, tests, activates"
  
  sla_breach_alert:
    purpose: "Real-time SLA monitoring with escalation"
    trigger: "Webhook from Genesys Cloud"
    nodes:
      - "Webhook receiver → parse event payload"
      - "IF node → check against SLA thresholds from constants registry"
      - "Slack API → post alert to #alerts channel"
      - "Gmail API → send escalation email if critical"
    claude_role: "Defines threshold logic, message templates, escalation rules"
    human_role: "Configures webhook endpoint, credentials, activates"
  
  fathom_transcript_processor:
    purpose: "Auto-process Fathom exports for Tier 2 meetings"
    trigger: "File watcher on Fathom export directory OR manual trigger"
    nodes:
      - "File read → load transcript"
      - "Claude API → enrich with system prompt containing org context"
      - "Gmail API → send differentiated summaries"
      - "Google Calendar API → create follow-up events"
    claude_role: "Writes the enrichment prompt, defines distribution logic"
    human_role: "Configures file path, credentials, activates"
```

---

## 7. MCP Integration Map (Detailed)

```yaml
mcp_integrations:
  gmail:
    url: "https://gmail.mcp.claude.com/mcp"
    primary_category: "Email Assistance"
    secondary_categories: ["Writing", "Meeting Notes"]
    operations:
      read: "Search and retrieve emails by sender, subject, date, label"
      draft: "Create email drafts with subject, body, recipients, attachments"
      send: "Send emails (requires user confirmation per safety rules)"
      label: "Apply labels for organization"
    workflow_connections:
      inbound: "Fathom → Claude → Gmail (meeting follow-ups)"
      outbound: "Gmail → Claude → Obsidian (important email → vault archive)"
      bidirectional: "Inbox triage, compose with strategy, attachment analysis"
    rate_limits: "Standard Gmail API limits apply"
  
  slack:
    url: "https://mcp.slack.com/mcp"
    primary_category: "Team Communication"
    secondary_categories: ["Meeting Notes", "Data Visualization"]
    operations:
      read: "Read channel history, search messages"
      post: "Post messages to channels or DMs"
      search: "Search across workspace"
    workflow_connections:
      inbound: "Operations dashboard → Slack highlights post"
      outbound: "Slack thread → Claude analysis → response draft"
  
  google_calendar:
    url: "https://gcal.mcp.claude.com/mcp"
    primary_category: "Scheduling"
    secondary_categories: ["Meeting Notes"]
    operations:
      read: "Check availability, list upcoming events"
      create: "Create events with title, time, attendees, description"
      update: "Modify existing events"
    workflow_connections:
      inbound: "Meeting action items → Calendar events"
      outbound: "Calendar context → Meeting prep notes"
  
  mermaid_chart:
    url: "https://mcp.mermaidchart.com/mcp"
    primary_category: "Data Visualization"
    secondary_categories: ["Coding", "Knowledge Management"]
    operations:
      render: "Validate and render Mermaid diagram syntax"
      summarize: "Generate description of diagram content"
    workflow_connections:
      inbound: "Architecture discussion → rendered diagram"
      outbound: "Diagram → embedded in PPTX or DOCX"
  
  netlify:
    url: "https://netlify-mcp.netlify.app/mcp"
    primary_category: "Deployment"
    secondary_categories: ["Coding", "Data Visualization"]
    operations:
      deploy: "Deploy static sites"
      status: "Check deployment status"
      read: "Read project configuration"
    workflow_connections:
      inbound: "HTML dashboard → Netlify deploy → shareable URL"
      outbound: "Deploy status → Slack notification"
  
  canva:
    url: "https://mcp.canva.com/mcp"
    primary_category: "Graphic Design"
    secondary_categories: ["Data Visualization", "Writing"]
    operations:
      create: "Create designs from templates"
      export: "Export designs in various formats"
    workflow_connections:
      inbound: "Claude defines content/layout → Canva renders"
      outbound: "Canva asset → embedded in presentation or email"
```

---

## 8. Gaps and Mitigation Strategy

```yaml
known_gaps:
  live_meeting_capture:
    severity: "HIGH — cannot be worked around"
    description: "Claude cannot join live calls or record audio"
    mitigation: "Fathom as sole external dependency for capture"
    residual_risk: "Manual handoff required (copy transcript to Claude)"
    future_state: "If Fathom releases an API or MCP server, this handoff automates"
  
  image_generation:
    severity: "LOW — infrequent need"
    description: "Claude cannot generate visual assets from scratch"
    mitigation: "Mirror-vision skill crafts prompts for manual Stable Diffusion use; generated images uploaded back to Claude for embedding"
    residual_risk: "Manual workflow, not orchestrated"
    future_state: "Anthropic or third-party image generation MCP would close this"
  
  scheduling_optimization:
    severity: "LOW — Calendar MCP covers 90% of needs"
    description: "Calendar MCP creates events but does not optimize schedule patterns"
    mitigation: "Claude provides scheduling logic and recommendations; Calendar MCP handles event CRUD"
    residual_risk: "No automatic time-block optimization"
    future_state: "Claude could analyze calendar patterns and suggest restructuring"
  
  workflow_runtime:
    severity: "MEDIUM — affects automation depth"
    description: "Claude designs automations but cannot execute them persistently"
    mitigation: "n8n as execution engine; Claude generates workflow definitions and configurations"
    residual_risk: "User must import and activate workflows in n8n manually"
    future_state: "n8n MCP server would allow Claude to deploy workflows directly"
  
  persistent_state:
    severity: "MEDIUM — affects complex multi-session work"
    description: "Claude's sandbox resets between tasks; artifacts lose state between sessions"
    mitigation: "Persistent storage API for artifacts; Obsidian vault for durable data; memory system for key facts"
    residual_risk: "Complex stateful applications require re-loading context"
    future_state: "Improved persistent storage and memory capabilities"
```

---

## 9. Implementation Roadmap

### Phase 1: Foundation (CURRENT STATE — Complete)

```yaml
phase_1:
  status: "COMPLETE"
  description: "Core ecosystem operational"
  completed_items:
    - item: "Claude as primary chatbot with memory system"
      status: "ACTIVE"
      notes: "Memory contains org context, preferences, project status"
    
    - item: "Gmail MCP connected and operational"
      status: "ACTIVE"
      notes: "Read, draft, send capabilities confirmed"
    
    - item: "Slack MCP connected and operational"
      status: "ACTIVE"
      notes: "Channel read/post capabilities confirmed"
    
    - item: "Google Calendar MCP connected and operational"
      status: "ACTIVE"
      notes: "Event creation and retrieval confirmed"
    
    - item: "Mermaid Chart MCP connected"
      status: "ACTIVE"
      notes: "Diagram rendering operational"
    
    - item: "Netlify MCP connected"
      status: "ACTIVE"
      notes: "Deployment capability available"
    
    - item: "Canva MCP connected"
      status: "ACTIVE"
      notes: "Design capabilities available"
    
    - item: "ISPN skill suite (20 skills) operational"
      status: "ACTIVE"
      notes: "Full analytics, reporting, and operational skill suite"
    
    - item: "General skills (10) operational"
      status: "ACTIVE"
      notes: "Writing, design, engineering, resume, ultrathink"
    
    - item: "Obsidian vault as knowledge layer"
      status: "ACTIVE"
      notes: "Accessible via Claude Desktop MCP"
    
    - item: "Document creation skills (docx, pptx, xlsx, pdf)"
      status: "ACTIVE"
      notes: "Full file generation capabilities"
    
    - item: "Fathom deployed for meeting capture"
      status: "ACTIVE"
      notes: "Company-standard tool, calendar auto-join enabled"
```

### Phase 2: Workflow Standardization (Next 30 Days)

```yaml
phase_2:
  status: "IN_PROGRESS"
  description: "Standardize recurring workflows and close integration gaps"
  target_completion: "2026-04-03"
  
  workstreams:
    meeting_notes_pipeline:
      priority: "HIGH"
      tasks:
        - task: "Define Tier 1 vs Tier 2 meeting classification criteria"
          action: "Create decision matrix: which meetings get Claude processing?"
          deliverable: "Classification guide in Obsidian vault"
          effort: "1 hour"
        
        - task: "Create Fathom → Claude transcript processing template"
          action: "Build a reusable prompt template that includes org context for meeting enrichment"
          deliverable: "Prompt template stored as Claude skill or Obsidian note"
          effort: "2 hours"
        
        - task: "Build meeting note Obsidian template"
          action: "Standardize vault structure for meeting archives"
          deliverable: "Template with frontmatter, sections, link patterns"
          effort: "1 hour"
        
        - task: "Test end-to-end pipeline with 3 real meetings"
          action: "Run Tier 2 pipeline on next 3 leadership meetings"
          deliverable: "Validated workflow, identified friction points"
          effort: "3 hours (spread across meetings)"
        
        - task: "Create commitment tracking spreadsheet"
          action: "Build xlsx template for cross-meeting commitment log"
          deliverable: "Commitment_Tracker.xlsx with columns: date, meeting, person, commitment, deadline, status"
          effort: "1 hour"
    
    email_workflow_templates:
      priority: "HIGH"
      tasks:
        - task: "Build inbox triage prompt pattern"
          action: "Create repeatable prompt for daily email summarization and prioritization"
          deliverable: "Triage template that produces consistent, actionable summaries"
          effort: "1 hour"
        
        - task: "Define audience-specific email templates"
          action: "Create tone/format templates for: executive up, peer lateral, team down, partner external"
          deliverable: "4 email templates with tone matrix mapping"
          effort: "2 hours"
        
        - task: "Test Gmail MCP → Slack MCP cross-posting"
          action: "Validate that email summaries can be reformatted and posted to Slack channels"
          deliverable: "Confirmed cross-channel workflow"
          effort: "30 minutes"
    
    report_orchestration:
      priority: "MEDIUM"
      tasks:
        - task: "Document weekly operations cycle as step-by-step runbook"
          action: "Write the exact sequence of uploads, skill invocations, and distribution steps"
          deliverable: "Runbook in Obsidian vault"
          effort: "2 hours"
        
        - task: "Document board reporting pipeline as step-by-step runbook"
          action: "Same as above for monthly board cycle"
          deliverable: "Runbook in Obsidian vault"
          effort: "2 hours"
        
        - task: "Test dashboard deployment to Netlify"
          action: "Generate HTML dashboard → deploy via Netlify MCP → confirm shareable URL"
          deliverable: "Live dashboard URL"
          effort: "1 hour"
    
    n8n_automation_design:
      priority: "MEDIUM"
      tasks:
        - task: "Design scheduled report trigger workflow"
          action: "Claude generates n8n workflow JSON for Monday morning data prep"
          deliverable: "n8n_weekly_trigger.json"
          effort: "2 hours"
        
        - task: "Design SLA breach alert workflow"
          action: "Claude generates n8n workflow JSON for real-time SLA monitoring"
          deliverable: "n8n_sla_alert.json"
          effort: "2 hours"
        
        - task: "Import and test in n8n"
          action: "Deploy both workflows, configure credentials, validate"
          deliverable: "2 active n8n workflows"
          effort: "3 hours"
```

### Phase 3: Scale and Optimize (Days 31-90)

```yaml
phase_3:
  status: "PLANNED"
  description: "Measure effectiveness, expand coverage, prepare for team adoption"
  target_completion: "2026-06-01"
  
  workstreams:
    measurement:
      priority: "HIGH"
      tasks:
        - task: "Baseline time-to-deliverable for recurring reports"
          action: "Time the weekly ops cycle and board reporting pipeline for 4 consecutive weeks"
          deliverable: "Baseline metrics spreadsheet"
        
        - task: "Track context switches per complex task"
          action: "Log app switching during multi-category workflows for 2 weeks"
          deliverable: "Context switch reduction data"
        
        - task: "Calculate cost savings from ecosystem consolidation"
          action: "Compare cost of replaced tools vs Claude subscription + MCP connections"
          deliverable: "ROI analysis"
        
        - task: "Measure knowledge retrieval accuracy"
          action: "Track how often Claude surfaces relevant context from memory/skills/vault"
          deliverable: "Hit rate metrics"
    
    expansion:
      priority: "MEDIUM"
      tasks:
        - task: "Identify 3 new repeating patterns for skill codification"
          action: "Review past 30 days of conversations for patterns that should be skills"
          deliverable: "3 new skill candidates via skill-forge protocol"
        
        - task: "Build QA category analysis skill"
          action: "Complete Phase 2 training gap work — QA category data for training gap analysis"
          deliverable: "Updated ispn-training-gap skill with QA category mapping"
        
        - task: "Expand Obsidian vault structure"
          action: "Build out MOC structure for all operational domains"
          deliverable: "Complete vault architecture with bidirectional linking"
        
        - task: "Evaluate GitHub MCP when available"
          action: "Test version control integration for Cortex platform and skill development"
          deliverable: "GitHub MCP deployment decision"
    
    team_adoption_prep:
      priority: "LOW"
      tasks:
        - task: "Document ecosystem architecture for team members"
          action: "Create onboarding guide for direct reports to leverage parts of the ecosystem"
          deliverable: "Team Ecosystem Guide (docx or Obsidian)"
        
        - task: "Identify which workflows can be delegated"
          action: "Map which parts of weekly ops cycle Annie/Harland/Brent/Carlos can own"
          deliverable: "Delegation matrix"
        
        - task: "Build portfolio case study from ecosystem metrics"
          action: "Package time savings, cost reduction, and workflow consolidation data for interview portfolio"
          deliverable: "AI Ecosystem Transformation case study"
```

---

## 10. Success Metrics

```yaml
success_metrics:
  consolidation:
    metric: "Tools consolidated into single interface"
    target: "8+ categories via Claude"
    measurement: "Count of standalone tools eliminated"
    current: "8 categories covered (6 fully, 2 partially)"
  
  context_switching:
    metric: "App switches per complex task"
    target: "<3 switches for any multi-category workflow"
    measurement: "Manual tracking during workflow execution"
    baseline: "TBD — measure in Phase 3"
  
  time_to_deliverable:
    metric: "Time from data to finished report"
    target: "50% reduction for recurring reports"
    measurement: "Before/after timing comparison"
    baseline: "TBD — measure in Phase 3"
  
  knowledge_retrieval:
    metric: "Relevant context surfaced without re-explaining"
    target: ">90% hit rate"
    measurement: "Track instances where memory/skills/vault provided needed context"
    baseline: "TBD — measure in Phase 3"
  
  workflow_completion:
    metric: "End-to-end task completion within Claude"
    target: "80% of multi-category tasks completed without leaving ecosystem"
    measurement: "Workflow audit — track which tasks required external tools"
    baseline: "TBD — measure in Phase 3"
  
  automation_coverage:
    metric: "Recurring tasks with n8n automation"
    target: "4+ automated workflows active"
    measurement: "Count of active n8n workflows"
    current: "0 — Phase 2 target"
```

---

## 11. Ecosystem Evolution Triggers

```yaml
evolution_triggers:
  new_mcp_available:
    condition: "GitHub, Google Drive, or n8n release MCP servers"
    action: "Evaluate and integrate — each closes a current manual handoff"
    impact: "Reduces manual handoffs, increases orchestration depth"
  
  new_skill_needed:
    condition: "Same manual process repeated 3+ times"
    action: "Trigger skill-forge protocol to codify as reusable skill"
    impact: "Converts ad-hoc work into institutional capability"
  
  team_member_onboarding:
    condition: "Direct report ready to leverage ecosystem components"
    action: "Provide targeted training on relevant workflows"
    impact: "Multiplies ecosystem value across team"
  
  role_change:
    condition: "Pete moves to new role (CX Director, AI leadership)"
    action: "Fork ecosystem — carry general skills, rebuild domain-specific skills for new org"
    impact: "Ecosystem architecture is portable; domain skills are not"
  
  claude_capability_expansion:
    condition: "New Claude features (persistent memory, agentic tools, live integrations)"
    action: "Re-evaluate gaps table, close newly addressable gaps"
    impact: "Reduces external tool dependencies"
```

---

*This specification is structured for both human decision-making and machine interpretation. YAML blocks are parseable by Claude Code for task extraction, dependency resolution, and progress tracking. Markdown sections provide strategic context for human review. Together, they form a deployable blueprint for a Claude-centric AI productivity ecosystem.*
