# Issue tracker: GitHub

Issues and PRDs for this repo live as GitHub issues in `snackpackgames/cosmicparade`. Use the `gh` CLI for all operations.

## Conventions

- **Create an issue**: `gh issue create --title "..." --body "..."`. Use a heredoc for multi-line bodies.
- **Read an issue**: `gh issue view <number> --comments`, filtering comments by `jq` and also fetching labels.
- **List issues**: `gh issue list --state open --json number,title,body,labels,comments --jq '[.[] | {number, title, body, labels: [.labels[].name], comments: [.comments[].body]}]'` with appropriate `--label` and `--state` filters.
- **Comment on an issue**: `gh issue comment <number> --body "..."`
- **Apply / remove labels**: `gh issue edit <number> --add-label "..."` / `--remove-label "..."`
- **Close**: `gh issue close <number> --comment "..."`

Infer the repo from `git remote -v` — `gh` does this automatically when run inside a clone.

## Pull requests as a triage surface

**PRs as a request surface: no.** `/triage` only processes issues; external PRs are left out of the triage queue.

## When a skill says "publish to the issue tracker"

Create a GitHub issue.

## When a skill says "fetch the relevant ticket"

Run `gh issue view <number> --comments`.

## Wayfinding operations

Maps and tickets are both GitHub issues in `snackpackgames/cosmicparade`. Use GitHub's native sub-issue and dependency features — they render in the GitHub UI, so the frontier is visible without opening the map issue.

- **Map**: `gh issue create --title "..." --body "..." --label "wayfinder:map"`
- **Ticket (child issue)**: `gh issue create --title "..." --body "..." --label "wayfinder:<type>"`, then link it as a sub-issue of the map. Both endpoints below take the issue's **numeric database id** (from `gh api repos/.../issues/<number> --jq '.id'`), not the issue *number*, and require `-F` (not `-f`) so `gh` sends it as a JSON integer:
  `gh api repos/snackpackgames/cosmicparade/issues/<map_number>/sub_issues -F sub_issue_id=<ticket_db_id>`
- **Claim a ticket**: `gh issue edit <number> --add-assignee <username>`
- **Block a ticket on another**: `gh api repos/snackpackgames/cosmicparade/issues/<blocked_number>/dependencies/blocked_by -F issue_id=<blocking_issue_db_id>` (confirmed working; same numeric-id + `-F` requirement as sub-issues)
- **Frontier query** (open, unblocked, unclaimed children of a map): list sub-issues via the sub-issues endpoint, filter `state=open`, `assignees=[]`, and cross-check `dependencies/blocked_by` is empty or all-closed. No single `gh` one-liner covers this — script it with `gh api` + `jq`.
- **Record a resolution**: `gh issue comment <number> --body "..."` then `gh issue close <number> --comment "..."`
- **Patch a map's body** (adding a missing `**Type:**` line, indexing a handoff into *Decisions so far*): `gh issue edit <number> --body-file <file>` locally, or `gh api -X PATCH repos/snackpackgames/cosmicparade/issues/<number> -f body="$(cat <file>)"` in a cloud session. **A body write replaces the whole body**, so re-read it immediately before writing and edit that exact text — never reconstruct it from memory.

### Destination types and handoff

Every map declares one destination type as a `**Type:**` line under `## Destination`. The four types and their terminal artifacts are defined in [`afk-pipeline.md`](afk-pipeline.md) — that table is the only definition.

- **Chart a map with its type declared**: `/wayfinder-chart "<loose idea>"`
- **Read a map's type**: `gh api repos/snackpackgames/cosmicparade/issues/<map_number> --jq '.body' | grep '^\*\*Type:\*\*'`
- **Hand a finished map off**: `/wayfinder-handoff <map_number>` — gated on a declared type, all tickets closed, and no open decisions. It writes the plan, merges it to `main` **before** filing issues, wires `blocked_by` edges, applies the label, and leaves the map open.
- **Check an issue is genuinely takeable** (what the scheduled routine runs): `gh api repos/snackpackgames/cosmicparade/issues/<n>/dependencies/blocked_by --jq '[.[] | select(.state == "open")] | length'` — `0` means takeable. An issue with no dependencies returns `[]` and exits 0.

## Cloud sessions (Claude Code on the web)

Claude Code cloud sessions reach GitHub through a proxy that allows the REST API but refuses GraphQL (`api.github.com/graphql` returns `403: GitHub GraphQL is not available from Claude Code sessions`). This is a platform restriction, not a repo or token permission, and no session setting lifts it. Local sessions use the developer's own `gh` login and aren't affected.

Most `gh` porcelain commands are built on GraphQL — `gh issue create/view/list/edit/close/comment` and all `gh project` commands — so in a cloud session, use the GitHub MCP tools or `gh api` REST calls instead:

| Operation | REST equivalent |
|---|---|
| Create an issue | MCP `issue_write` (`method: create`), or `gh api repos/snackpackgames/cosmicparade/issues -f title=... -f body=... -f 'labels[]=...'` |
| Set the milestone | `gh api -X PATCH repos/snackpackgames/cosmicparade/issues/<n> -F milestone=<milestone_number>` (list numbers with `gh api repos/snackpackgames/cosmicparade/milestones`) |
| Add labels | `gh api -X POST repos/snackpackgames/cosmicparade/issues/<n>/labels -f 'labels[]=bug' -f 'labels[]=combat'` |
| Comment | MCP `add_issue_comment`, or `gh api repos/snackpackgames/cosmicparade/issues/<n>/comments -f body=...` |
| Close | `gh api -X PATCH repos/snackpackgames/cosmicparade/issues/<n> -f state=closed -f state_reason=completed` |
| Edit an issue or map body | `gh api -X PATCH repos/snackpackgames/cosmicparade/issues/<n> -f body="$(cat <file>)"` — replaces the whole body |
| Create a PR (only if `gh pr create` fails) | `gh api -X POST repos/snackpackgames/cosmicparade/pulls -f title=... -f head=<branch> -f base=main -f body=...` |
| PR labels / assignee / milestone | Use the **issues** endpoints with the PR's number: `.../issues/<pr_number>/labels`, `/assignees`, and `-X PATCH .../issues/<pr_number> -F milestone=<n>`. `gh pr edit` is GraphQL-backed and fails |
| Sub-issues and `blocked_by` links | The `gh api` calls under [Wayfinding operations](#wayfinding-operations) already use REST and work as written |

**Project boards can't be updated from a cloud session.** GitHub exposes Projects (v2), including `Cosmic Parade v1.0`, only through GraphQL, so a cloud session can't add an issue or PR to the board or set its Status. Do everything else, then tell the user which items still need adding to the board or a Status set, so they can do it locally or in the GitHub UI.
