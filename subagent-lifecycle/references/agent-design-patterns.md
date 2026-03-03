# Agent Design Patterns

Seven proven patterns for subagent architecture. Use these when designing agent rosters
to match common project shapes.

## Pattern 1: The Explorer

Purpose: Read-only analysis, research, and reconnaissance.
Tools: Read, Glob, Grep, Bash
Model: haiku (pattern matching, not reasoning)
Use when: You need to understand a codebase, audit files, or gather information
without modifying anything.
Examples: auditor, validator, code-reviewer, dependency-scanner.

## Pattern 2: The Builder

Purpose: Creates new files, components, and modules from scratch.
Tools: Read, Write, Bash, Glob, Grep
Model: sonnet (creative generation)
Use when: You need to produce new artifacts that don't exist yet.
Examples: scaffolder, component-generator, template-creator, documentation-writer.

## Pattern 3: The Surgeon

Purpose: Modifies existing code with precision.
Tools: Read, Write, Edit, Bash, Glob, Grep
Model: sonnet or inherit (needs to understand context)
Use when: You need to change existing files while preserving surrounding code.
Examples: bug-fixer, refactorer, style-migrator, dependency-updater.

## Pattern 4: The Orchestrator

Purpose: Coordinates multi-step workflows across tools and services.
Tools: Read, Write, Bash, Glob, Grep + relevant MCPs
Model: sonnet (needs planning ability)
Use when: A task requires multiple steps across different services.
Examples: deployer, CI/CD-manager, release-coordinator.
Note: Orchestrators should be SKILLS not subagents if they need to invoke other agents.

## Pattern 5: The Specialist

Purpose: Deep domain expertise in one narrow area.
Tools: Domain-appropriate subset
Model: sonnet (needs domain knowledge)
Use when: A domain requires specific conventions, libraries, or approaches.
Examples: frontend-dev, api-builder, data-engineer, mobile-ui.
Key trait: Memory is critical — specialists improve with use.

## Pattern 6: The Guardian

Purpose: Validates, tests, and enforces quality standards.
Tools: Read, Bash, Glob, Grep (usually read-only)
Model: haiku (rule-checking, not creative)
Use when: You need automated quality enforcement.
Examples: tester, linter, security-scanner, accessibility-checker.
Key trait: disallowedTools: Write, Edit — guardians observe, they don't modify.

## Pattern 7: The Connector

Purpose: Bridges the project with external services.
Tools: Read, Write, Bash, Glob, Grep + MCPs
Model: sonnet
Use when: The project integrates with external APIs, services, or platforms.
Examples: integration-dev, notification-sender, data-syncer.
Key trait: mcpServers field maps to configured services.

## Composition Rules

Most projects need 3-5 agents combining these patterns. Common compositions:

Web App: 1 Specialist (frontend) + 1 Specialist (backend) + 1 Guardian (tester) + 1 Connector (deployer)

Data Project: 1 Builder (ETL) + 1 Specialist (analyst) + 1 Specialist (visualizer)

API Service: 1 Specialist (routes) + 1 Specialist (data layer) + 1 Guardian (tester)

Automation: 1 Builder (pipeline) + 1 Connector (integrations) + 1 Explorer (monitor)

Avoid composing two agents with the same pattern for the same domain — that's a sign
they should be merged into one agent.
