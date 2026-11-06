# Scheduled routine prompt

The prompt driving the recurring Claude Code cloud routine that implements `ready-for-agent` issues unattended.

> **This copy is authoritative but not live.** The running routine is configured outside the repo, so nothing in a worktree can read or write it — but a Claude Code session can, with the `RemoteTrigger` tool's `update` action. After changing this file, sync the live routine in the same change, or the two will drift.

Cloud sessions reach GitHub through a proxy that refuses GraphQL, and `gh issue list` / `view` / `create` / `edit` / `comment`, `gh pr edit`, `gh pr create`, and every `gh project` command are GraphQL-backed. The prompt below therefore uses `gh api` REST calls for all of them — see [`issue-tracker.md`](issue-tracker.md#cloud-sessions-claude-code-on-the-web) for the REST equivalents.

**`gh pr create` is affected**, contrary to what this file claimed until 2026-11-06. The routine's run of 2026-11-05 proved it: the call returns `HTTP 403: GitHub GraphQL is not available from Claude Code sessions`. That run recovered on its own, at the cost of a turn. Open the PR with `gh api -X POST repos/snackpackgames/cosmicparade/pulls` instead.

**A cloud session has no GitHub login of its own.** It pushes and opens PRs through the repo's Claude GitHub App installation, which GitHub attributes to the installing user — PRs come out authored by that account, and commits by `Claude <noreply@anthropic.com>`. So there is no agent identity to assign an issue to, which is why step 3 below resolves a login instead of naming one. Relatedly, **the App must list this repo** under its installation; while it did not, every run implemented its issue and then lost the work to a 403 on `git push`, reporting success each time.

## The prompt

```text
Read CLAUDE.md at the repo root first for full project context (this is a Godot 4.7.2 / GDScript project called Cosmic Parade). Issues are tracked in GitHub Issues on this repo (snackpackgames/cosmicparade) via the gh CLI — see documentation/agents/issue-tracker.md and documentation/agents/triage-labels.md for the triage label conventions (needs-triage, needs-info, ready-for-agent, ready-for-human, wontfix).

You are running in a cloud session, which cannot use GitHub's GraphQL API. Use `gh api` REST calls, not `gh issue`/`gh pr`/`gh project` porcelain, for every tracker read and write below. That includes `gh pr create`, which is GraphQL-backed and returns HTTP 403 here — open the PR with `gh api -X POST` instead (step 8).

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

3. Confirm the issue you picked is not already claimed by an open PR. This is the
   collision guard that actually holds, so do not skip it:
     gh api "repos/snackpackgames/cosmicparade/pulls?state=open&per_page=100" \
       --jq '.[] | {number, title, head: .head.ref, body}'
   If an open PR references the issue or carries a branch named for it, move to the
   next candidate.

   Then try to claim the issue as well. You have no login of your own, so resolve
   one rather than guessing:
     ME="$(gh api user --jq .login 2>/dev/null)"
     if [ -n "$ME" ]; then
       gh api -X POST repos/snackpackgames/cosmicparade/issues/<n>/assignees \
         -f "assignees[]=$ME" --jq '[.assignees[].login]'
     fi
   Read that output back. GitHub answers 201 for an assignee it does not recognise
   and assigns nobody, so a guessed login fails silently — never send this call to
   /dev/null. If no login resolves, leave the issue unassigned, note it in the PR
   body, and rely on the open-PR check above. Do not substitute a name you have not
   verified, the repo owner and the org included: a wrong assignee is worse than
   none, because it reads as a human having taken the issue.

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
   (e.g. "Closes #N"), with a summary and a test plan:
     gh api -X POST repos/snackpackgames/cosmicparade/pulls \
       -f title="<title>" -f head="<branch>" -f base=main -F body=@<file>
   Apply the full PR metadata
   from CONTRIBUTING.md → Pull Requests → PR metadata. A cloud session cannot set
   the project board or Status — do everything else, then say which items still
   need adding to the board so a human can finish it.

If no issue is safely unblocked and implementable in one session, do not force it.
Leave a comment on the most promising issue explaining what additional info or
decisions are needed, and do not open a PR:
  gh api repos/snackpackgames/cosmicparade/issues/<n>/comments -f body='...'
```
