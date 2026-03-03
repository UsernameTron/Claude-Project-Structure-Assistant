# Lessons

## Active Rules

### Seed Rules (Pre-loaded)
- [2026-03-03] [Config]: Never modify shared configuration files without checking all downstream consumers first.
- [2026-03-03] [Scope]: If a "quick fix" requires touching more than 3 files, it is not a quick fix. Re-plan.
- [2026-03-03] [Testing]: Always run the full test suite, not just tests for the changed module. Cross-module regressions are common.
- [2026-03-03] [Dependencies]: Never add a new dependency without explicit user approval. Check if a built-in or existing dependency already solves the problem.
- [2026-03-03] [Data]: Never delete or overwrite production data, migration files, or seed data without explicit user approval.

### Learned Rules
- [2026-03-03] [Frontmatter]: When documenting agent frontmatter fields, read the actual file — do not trust subagent summaries. The explore agent fabricated a `memory: project` field on memory-seeder.md that does not exist. Only document fields that are literally present in the YAML frontmatter.
- [2026-03-03] [Counting]: When building file count summaries, separate distinct scopes (root vs plugin) and verify the arithmetic adds up. Do not create tables where the same files appear in multiple rows without explicit subtotals.
- [2026-03-03] [Diffing]: When two files might differ, run `diff` or compare checksums before describing the delta. Never write "incremental revision with refinements" without evidence. If files are identical, say so.

## Patterns

## Archived
