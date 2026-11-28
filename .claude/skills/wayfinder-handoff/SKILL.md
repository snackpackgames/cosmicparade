---
name: wayfinder-handoff
description: Turn a finished wayfinder map into its terminal artifact — committed implementation plans plus labelled issues, or an ADR or system doc — once every ticket is closed and no decision is left open.
argument-hint: "<map issue number or URL>"
disable-model-invocation: true
---

Hand a finished map off to whoever implements it: the scheduled routine, a human, or nobody if the destination was a decision.

Read `documentation/agents/afk-pipeline.md` first. It holds the destination menu, the preconditions, the per-type procedures, and the issue body template, and it is the only definition of each — follow it rather than the summary here, which exists to tell you the order of operations.

## Preconditions

Each is a hard gate: on failure, report precisely what is missing and **stop**. Never emit a partial handoff — the output of a bad guess here is an issue an unattended agent will act on.

**Preconditions 1 and 2 are entry gates**, checked before anything is written. **Precondition 3 is a standing gate** that applies at every point in drafting, including after the plan has already merged — it cannot be discharged up front, and finding no open question at the start does not satisfy it.

1. **The map has a `**Type:**` line.** Fetch the map body and look for it under `## Destination`. If it is absent — any map charted before this convention — **ask the maintainer which of the four types applies and patch the map** before continuing. Do not infer it from the map's title, prose, or ticket mix.

2. **Every child ticket is closed.** List the map's sub-issues and check each one's state. An open ticket means the way is not clear yet; name the open ones and stop.

3. **No unresolved decision is about to be written into an issue** — standing, not entry. At any point in drafting, if a question surfaces that the map never answered, **file it as a fresh child ticket on the map and stop**, labelled with one of the vendored types (`wayfinder:research`, `wayfinder:prototype`, `wayfinder:grilling`, `wayfinder:task` — see the vendored skill's *Ticket Types*; never create a literal `wayfinder:<type>` label). Do not write the question into the issue as a "decide before merging" note: an agent-ready issue must be answerable without a human, and such a section contradicts that by construction. Issue #1001 is the example to not repeat.

## Dispatch on the declared type

Read the type, then follow that type's procedure in `afk-pipeline.md`.

**`afk-implementation` and `human-implementation`** — identical but for the label applied at the end (`ready-for-agent` and `ready-for-human` respectively):

1. Slice: one plan per feature, one issue per plan phase, each sized to a single routine session.
2. Write the plan(s) with the `superpowers:writing-plans` skill into `documentation/plans/YYYY-MM-DD-<slug>-plan.md`. Not `docs/superpowers/plans/` — this repo uses `documentation/plans/`. Then run the extra self-review check below, which that skill's own five do not cover.
3. Commit on a `docs/<map-number>-<slug>` branch — the map is the tracked issue for this PR, since the implementation issues do not exist until step 4 — then open a PR with full metadata and **stop and ask the maintainer to merge it.** Do not merge your own PR unawaited. Resume at step 4 once merge is confirmed.
4. File the issues on the template in `afk-pipeline.md`, wire `blocked_by` edges in a second pass once every issue has a number, then apply the label last.
5. Index the handoff in the map's *Decisions so far* and **leave the map open.**

**`decision-record` and `system-spec`**: write the ADR or system doc, merge it the same way, index it on the map. **Emit no issue and apply no label** — there is nothing for an agent to implement. Stop after indexing.

## Sixth self-review check: can each test step pass against its own implementation step?

`superpowers:writing-plans` ends with five self-review checks. Its nearest, *Type consistency*, compares names and signatures **across** tasks; none of the five reads a task's test step against the implementation step meant to satisfy it. Run this one too, per task, before step 3.

For each task, take its Step 1 assertions and its Step 3 instruction together and ask: **can this test pass against that implementation?** A plan can state a rule, give a correct example of it, and still write a test that violates it — the two artifacts are drafted separately and nothing in the five checks executes them against each other.

**The trap this catches, which is GDScript-specific:** GUT's `assert_eq` on two Objects is **reference identity**, not value equality. So an assertion comparing a post-call board read against a reference captured *before* the call passes **only if the call mutates that object in place**. Where the plan's own constraint says the call **replaces** — which most of this project's settled decisions favour, via `relocated()` and friends — the test and the constraint cannot both hold. Assert against the *result* of the replacement, or against a freshly derived value, never against the pre-call reference.

This is not hypothetical: `documentation/plans/2026-11-25-board-piece-placement-seam-plan.md` shipped it twice, at line 630 (`assert_eq(state.placements[0], placeable, "one object, not a copy")`) and line 881 (`assert_eq(state.altar_hexes(), altar.hexes, ...)`), each contradicting its own task's Step 3 about 30 lines later. That plan also had the correct shape at line 549 (`assert_eq(state.altar_hexes(), moved)`, comparing against `relocated()`'s result), so the rule was known and the samples still broke it. Both implementing agents caught it and chose replacement; the cost was paid twice at implementation time instead of once here. See [#125](https://github.com/snackpackgames/cosmicparade/issues/125).

A plan that fails this check is fixed here, not left for the implementer to adjudicate: an unattended agent that resolves it the other way will write mutation into production.

## Resuming after the merge pause

Step 3 ends the session if the maintainer merges later. A fresh `/wayfinder-handoff <map>` run must therefore **detect work already done and continue, not repeat it**.

**Re-run all three preconditions on every resume, before matching any bullet below.** Precondition 2 especially: a precondition-3 stop deliberately leaves a fresh **open** ticket on the map, so a resume that skips the gates will walk straight past it and carry the unresolved decision into an issue — reproducing #1001 through the resume door.

- Plan file already on `main` and the map's *Decisions so far* does not yet link emitted issues → resume at step 4.
- Issues already filed for this plan (check the map's sub-issues and search for issues referencing the plan path) → do not file duplicates. Verify the `blocked_by` edges and labels are in place, finish step 5, and report what was already done.
- Nothing merged yet → re-check the PR's state before assuming anything, and say so rather than writing a second plan.

## Tracker mechanics

Use `documentation/agents/issue-tracker.md` for the exact `gh` calls — sub-issue linking, `blocked_by` edges, and the frontier query. Both the sub-issue and dependency endpoints take an issue's **numeric database id**, not its number, and need `-F` so `gh` sends an integer.

**In a cloud session**, `gh issue` and `gh project` porcelain are refused by the GraphQL proxy; use the REST equivalents in that doc's *Cloud sessions* table, and leave the project board to the maintainer.
