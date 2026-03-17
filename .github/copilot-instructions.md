# Copilot Instructions — zitadel

This is **ZITADEL**, an open-source identity infrastructure platform written in Go (backend) with Angular/TypeScript frontends.

## Key conventions
- Backend is Go 1.23, event-driven CQRS pattern
- APIs defined via Protocol Buffers (`proto/`) with gRPC + grpc-gateway REST
- Angular admin console in `console/`, TypeScript login UI in `login/`
- PostgreSQL 14+ as primary datastore
- OpenTelemetry for observability

## Memagent Integration

This project is tracked in the memagent memory system at `~/work/memagent/projects/zitadel/`.

### Context files
- `~/work/memagent/projects/zitadel/context.md` — Project state, architecture, resume point
- `~/work/memagent/projects/zitadel/tasks.md` — Active and backlog tasks
- `~/work/memagent/projects/zitadel/learnings.md` — Discoveries and gotchas (append-only)
- `~/work/memagent/projects/zitadel/changelog.md` — Session changelog (append-only)

### Agent responsibilities
1. **Read `context.md → ## Resume`** at the start of every session to understand where work left off.
2. **Update `## Resume`** at the end of every session with what was done and what's next.
3. **Append to `learnings.md`** when discovering gotchas, patterns, or architectural decisions. Use ISO 8601 timestamps. Check for duplicates first.
4. **Append to `changelog.md`** at session end with a summary of changes made.
5. **Never delete or overwrite** existing entries in learnings or changelog — append only.
6. **Keep dates current**: When appending to changelog.md, also update the `Last active` field in `~/work/memagent/projects/zitadel/context.md` and the `> Last updated:` line in `~/work/memagent/global/daily-overview.md` to today's date (YYYY-MM-DD).

### Context-Switching Protocol

On **session entry**: Read `focus.md` for cross-project priorities, this project's `context.md` (especially `## Resume`), and the tail of `learnings.md` for recent gotchas.

On **session exit** (or before switching projects): **Overwrite `## Resume`** in `context.md` with current state — what was just done, what's next, any blockers. This is the single most important update. Also append to `changelog.md` and `learnings.md` as appropriate.
