# Scheduled routine prompt

The prompt driving the recurring Claude Code cloud routine that implements `ready-for-agent` issues unattended.

> **This copy is authoritative but not live.** The running routine is configured in Claude Code's `/schedule`, which nothing in this repo can reach. After changing this file, paste it into the routine by hand, or the two will drift.

Cloud sessions reach GitHub through a proxy that refuses GraphQL, and `gh issue list` / `view` / `create` / `edit` / `comment`, `gh pr edit`, and every `gh project` command are GraphQL-backed. The prompt below therefore uses `gh api` REST calls for all of those. `gh pr create` is **not** affected and stays in use — see [`issue-tracker.md`](issue-tracker.md#cloud-sessions-claude-code-on-the-web) for the REST equivalents, including creating a PR if `gh pr create` ever fails.

## The prompt

```text
Read CLAUDE.md at the repo root first for full project context (this is a Godot 4.6 / GDScript project called Cosmic Parade). Issues are tracked in GitHub Issues on this repo (snackpackgames/cosmicparade) via the gh CLI — see documentation/agents/issue-tracker.md and documentation/agents/triage-labels.md for the triage label conventions (needs-triage, needs-info, ready-for-agent, ready-for-human, wontfix).

You are running in a cloud session, which cannot use GitHub's GraphQL API. Use `gh api` REST calls, not `gh issue`/`gh pr edit`/`gh project` porcelain, for every tracker read and write below. `gh pr create` is not GraphQL-backed and is fine to use.

Your task:

1. List candidates:
     gh api "repos/snackpackgames/cosmicparade/issues?state=open&labels=ready-for-agent&per_page=100" \
       --jq '.[] | select(.pull_request == null) | {number, title}'
   If that yields nothing, fall back to all open issues, but prefer labeled-ready ones.

2. Walk that candidate list oldest-first and take the FIRST issue that passes both
   checks below. Stop walking as soon as one passes — do not pre-screen the whole
   list, which may be dozens of issues and would spend most of the session on selection.

   a. Not blocked:
        gh api repos/snackpackgames/cosmicparade/issues/<n>/dependencies/blocked_by \
          --jq '[.[] | select(.state == "open")] | length'
      A result of 0 means takeable; anything higher means skip to the next
      candidate. An issue with no dependencies returns [] and exits 0. This
      native dependency edge is authoritative — prose in the issue body is not,
      and an issue whose body claims it is unblocked is still blocked if this
      query says so.

   b. Has enough detail to act on, and does not depend on an external decision.

3. Confirm the issue you picked is not already claimed by an open PR:
     gh api "repos/snackpackgames/cosmicparade/pulls?state=open&per_page=100" \
       --jq '.[] | {number, title, head: .head.ref, body}'
   Then claim it so other agents do not pick it up:
     gh api -X POST repos/snackpackgames/cosmicparade/issues/<n>/assignees \
       -f 'assignees[]=<your-username>'

4. Read any relevant system docs in documentation/. If the issue names an
   implementation plan under documentation/plans/, that plan is the contract —
   follow it step by step, task by task, committing after each task as it
   directs. Also check notes/ for prior context before writing code.

5. Implement on a new branch (naming convention: see CONTRIBUTING.md → Branches;
   topic-prefixed, never an auto-generated codename branch). Follow existing code
   conventions and the guidance in CLAUDE.md (no unnecessary abstractions, no
   comments unless the WHY is non-obvious).

6. If you add a new class_name script, run `bash scripts/import.sh` to rebuild the
   class cache.

7. Write or update GUT tests under test/unit/ mirroring the source tree, and run
   `bash scripts/test.sh` (or a scoped subset) to confirm they pass.

8. Commit, push the branch, and open a PR against main referencing the issue
   (e.g. "Closes #N"), with a summary and a test plan. Apply the full PR metadata
   from CONTRIBUTING.md → Pull Requests → PR metadata. A cloud session cannot set
   the project board or Status — do everything else, then say which items still
   need adding to the board so a human can finish it.

If no issue is safely unblocked and implementable in one session, do not force it.
Leave a comment on the most promising issue explaining what additional info or
decisions are needed, and do not open a PR:
  gh api repos/snackpackgames/cosmicparade/issues/<n>/comments -f body='...'
```
