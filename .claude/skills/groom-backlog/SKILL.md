---
name: groom-backlog
description: Groom the "Cosmic Parade v1.0" GitHub Projects (v2) board — triage every Backlog issue (pull requests are skipped) into Refined, Refining, or Blocked, then file a closed dated report issue. Use when the user asks to groom or triage the backlog or the project board. Pass "dry-run" to preview the moves without touching the board.
argument-hint: "[dry-run]"
disable-model-invocation: true
---

Groom the "Cosmic Parade v1.0" GitHub Projects (v2) board.

Run this from a local Claude Code session (not claude.ai/code cloud session) — Projects v2 requires the GitHub GraphQL API, which Claude Code cloud sessions proxy through a REST-only gateway that blocks it. Locally, `gh` talks to GitHub directly.

Usage: `/groom-backlog [dry-run]`
- No arguments: classify every Backlog item, move it on the board, and file the report.
- `dry-run`: classify every Backlog item and print the planned moves in chat only — no `gh project item-edit`, no report issue, no writes of any kind.

This board tracks the full game backlog; new ideas get added to its "Backlog" status over time and need periodic triage into more specific refinement statuses. Use the `gh` CLI for everything (must be authenticated locally — run `gh auth status` first and stop to tell the user if it isn't).

## Board reference
- Org: snackpackgames. Resolve the project number by title each run — it is not hardcoded: `gh project list --owner snackpackgames --format json --jq '.projects[] | select(.title == "Cosmic Parade v1.0") | {number, id}'`. If no such project exists, stop and tell the user the board has to be created first.
- Look up field/option ids fresh each run rather than hardcoding, in case they change: `gh project field-list <number> --owner snackpackgames --format json`. Find the "Status" single-select field and its option ids for Backlog, Refining, Refined, Blocked, Todo, In Progress, Done. Get the project id from `gh project view <number> --owner snackpackgames --format json`.
- List items: `gh project item-list <number> --owner snackpackgames --format json --limit 2000`. Each item has `id` (project item id), `status`, `labels`, and `content` (with `type`, `number`, `title`, `body`, `repository`, `url` for linked issues; draft cards have no `content.number`). Keep the limit high — the board holds far more than 300 items, and a low limit silently drops Backlog items.
- Filter with `gh`'s built-in `--jq` flag (or a script) rather than piping to a standalone `jq` — it isn't installed on every machine.

## What to do
1. Filter items to `status == "Backlog"`, keeping only issues (`content.type == "Issue"`) and draft cards (no `content`). **Skip pull requests entirely** (`content.type == "PullRequest"`) — they're work in progress, not backlog to refine. Don't classify, move, or mention them anywhere, including the report.
2. For each linked issue (skip this step for draft cards), gather its blocking ground truth from two sources:
   - **Native dependency links**: `gh api repos/snackpackgames/cosmicparade/issues/<n>/dependencies/blocked_by --jq '.[] | {number, state}'` — GitHub's "blocked by" relationships, which this repo uses for Wayfinder tickets and follow-ups.
   - **Blocking language in the body**: issue numbers the body says *this issue* is blocked on — phrases like "blocked by", "blocked on", "requires", "depends on", "needs", or "don't start until" (e.g. "requires #685"), and any issue numbers listed under a **"Blocked by"** heading or section, including on the lines after it. Read the surrounding sentence rather than pattern-matching alone:
     - A reference that describes a *different* issue's relationship doesn't count. For example, "#986 (expand slots, blocked by #985)" in a list of related tickets means #986 is blocked, not the issue you're reading.
     - A "Blocked by" section that says "None", or lists only closed issues, doesn't block anything.

     Look up each counted issue's state with `gh issue view <n> --json state`.
3. Classify each item using these rules:
   - **Refined**: fully scoped — a human or agent could start work today with no open design decision. Concrete acceptance criteria, clear technical approach, no "decide X" language.
   - **Refining**: has open questions, needs a design decision, is a vague idea/research task, or otherwise needs more fleshing out. This is the default for most raw backlog items — when in doubt between Refining and Refined, choose Refining.
   - **Blocked**: ONLY if step 2 found a blocking issue that is still OPEN (from either source), or the body names an external (non-issue) dependency in similarly explicit language (e.g. "blocked on Steam approval"). A blocker that is already CLOSED doesn't count. Don't guess at unstated blocking relationships.
4. Unless this is a dry run, move each item to its new status with:
   `gh project item-edit --id <item_id> --project-id <PROJECT_ID> --field-id <STATUS_FIELD_ID> --single-select-option-id <OPTION_ID>`
5. **Never move anything to Todo or In Progress.** Moving to Todo implies committing it to current MVP scope, which is a human decision this skill must never make on its own.
6. **Never add, remove, or change any issue label** (not `ready-for-agent`, not `needs-triage`, nothing). The project board Status field and repo labels are two separate systems here — don't conflate them.
7. Don't close, comment on, or edit issue bodies (other than the report issue below). This skill only moves board status.

## Reporting
Build a report body containing:
- A **Refined** section: table of moved items (number/title/url, one-line reason)
- A **Refining** section: same shape
- A **Blocked** section: same shape, noting what each is blocked on and whether that came from a dependency link or the body text
- An **MVP candidates worth flagging** section: at most a handful of items you think are unusually high-leverage or foundational for other planned work — be conservative, most runs should flag 0-2 items, not act on them
- A "no changes this run" one-liner if Backlog was already empty

**Dry run:** print that report in chat, headed "Dry run — no changes made", and stop.

**Normal run:** create one new GitHub issue in snackpackgames/cosmicparade titled `Backlog grooming report — YYYY-MM-DD` (today's date) with that body. Then immediately close it with `gh issue close <n>` — it's a durable log entry, not an actionable ticket, so it shouldn't sit in the open issues list. Do not add labels to it or add it to the project board. Finish by giving the user the report issue's URL and the per-status counts.

## Style
Keep reasons to one short line each. Work through every Backlog item in one pass — don't stop partway. If an item has no linked issue (draft card), still classify and move it, and refer to it as "(draft card)" instead of a URL in the report.
