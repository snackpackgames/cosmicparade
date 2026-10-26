# AFK Implementation Pipeline

How a loose idea becomes a merged feature without a human writing code. Four stages, each a separate session.

```
/wayfinder-chart "<loose idea>"      session 1
    pick a destination type → map issue + child tickets + blocked_by edges

/wayfinder <map>                     sessions 2..n
    resolve one ticket per session (vendored skill, unchanged)

/wayfinder-handoff <map>             final session
    plan(s) → merged to main → labelled issue(s)

scheduled routine                    unattended, repeating
    pick one genuinely-unblocked issue → branch → tests → PR
```

The routine's prompt lives in [`scheduled-routine-prompt.md`](scheduled-routine-prompt.md).

## Destination types

Every map declares exactly one. This table is the only definition — skills reference it rather than restating it.

| Type | Terminal artifact |
|---|---|
| `afk-implementation` | plan(s) in `documentation/plans/` + `ready-for-agent` issue(s) |
| `human-implementation` | plan(s) in `documentation/plans/` + `ready-for-human` issue(s) |
| `decision-record` | ADR in `documentation/adr/` |
| `system-spec` | doc in `documentation/<system>_system.md` |

Destination types are this pipeline's vocabulary and are separate from the tracker's labels. A type maps onto one of the five canonical labels in [`triage-labels.md`](triage-labels.md); it never introduces a new one.

The type is recorded in the map body as a machine-readable line, additive to the vendored skill's template so `wayfinder` keeps parsing the map it expects:

```markdown
## Destination

**Type:** `afk-implementation`

Projectile ricochet, homing, and deflection are built and merged.
```

A map charted before this convention has no type line. Handoff asks the maintainer which type applies and patches the map — it never infers the type.

## Handoff preconditions

Hard gates. On any failure, report what is missing and stop without emitting anything.

Preconditions 1 and 2 are **entry gates**, checked before anything is written. Precondition 3 is a **standing gate** — it applies at every point in drafting, including after the plan has merged, and finding no open question up front does not discharge it. Re-run all three on every resumed handoff.

1. The map carries a `**Type:**` line. If absent, ask and patch the map first.
2. Every child ticket is closed. An open ticket means the way is not clear yet.
3. No unresolved decision is about to be written into an emitted issue. If drafting the plan or issue bodies surfaces a question the map never answered, file it as a fresh child ticket on the map — labelled with one of the vendored ticket types (`wayfinder:research`, `wayfinder:prototype`, `wayfinder:grilling`, `wayfinder:task`) — and stop. An agent-ready issue must be answerable without a human, which a "decide before merging" section contradicts by construction.

## Handoff: `afk-implementation` and `human-implementation`

Identical procedures; they differ only in the label applied at the end.

1. **Slice.** One plan per feature. One issue per plan phase, each sized to a single routine session.
2. **Write** the plan(s) with the `superpowers:writing-plans` skill, into `documentation/plans/YYYY-MM-DD-<slug>-plan.md`.
3. **Merge the plan to `main` before filing any issue.** Commit on a `docs/<map-number>-<slug>` branch per `CONTRIBUTING.md → Branches` — the map is the tracked issue for this PR, since the implementation issues do not exist until step 4 — open a PR with the full metadata from `CONTRIBUTING.md → Pull Requests → PR metadata`, then stop and ask the maintainer to merge. Resume at step 4 once merge is confirmed.

   This ordering is not stylistic. The routine branches from `main` and reads the plan from its worktree, so a plan on an unmerged branch is invisible to it and an issue pointing at one sends the routine to a file that does not exist.
4. **File the issues** on this template:

   ```markdown
   ## Overview

   <what this delivers, and which map decisions narrowed it — link each>

   ## Instructions

   Follow the implementation plan step by step, task by task,
   committing after each task as the plan directs:

   **`documentation/plans/<file>.md`**

   <which phase or tasks of the plan this issue covers, and the scoped
    test command to run per task>

   ## Acceptance Criteria

   - [ ] <behaviour, one per line>
   - [ ] All new and existing GUT tests pass (`bash scripts/test.sh`)
   - [ ] PR opened per CONTRIBUTING.md conventions, with full PR metadata applied

   ## Out of Scope

   <what belongs to sibling issues, or was ruled out of scope on the map>
   ```

   Link decision provenance by issue reference and the plan by its path on `main`. Apply the full issue metadata, then wire native `blocked_by` edges in a second pass once every issue has a number (the endpoints need numeric database ids — see [`issue-tracker.md`](issue-tracker.md#wayfinding-operations)). Apply the label last: `ready-for-agent` for `afk-implementation`, `ready-for-human` for `human-implementation`.
5. **Index the handoff** in the map's *Decisions so far*, linking the merged plan and every emitted issue. **Leave the map open.** It closes when the emitted issues have merged, not when they are filed — until then the map is the only record of what the effort was for, and a reader who finds an in-flight issue needs it reachable.

## Handoff: `decision-record` and `system-spec`

Write the ADR or system doc, merge it the same way (steps 2 and 3 above), and index it on the map. **No issue is emitted and no label is applied**, because there is nothing for an agent to implement.

## Why the routine reads dependency edges

The whole `ready-for-agent` chain is labelled at once. Readiness is expressed as GitHub's native `blocked_by` edges, which render in the GitHub UI, and the routine queries them rather than reading prose:

```bash
gh api repos/snackpackgames/cosmicparade/issues/<n>/dependencies/blocked_by \
  --jq '[.[] | select(.state == "open")] | length'
```

`0` means takeable. An issue with no dependencies returns `[]` and exits 0, so the query is safe to run on every candidate.
