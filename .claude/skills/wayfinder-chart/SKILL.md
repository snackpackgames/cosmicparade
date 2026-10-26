---
name: wayfinder-chart
description: Start a wayfinder effort with its destination type declared up front, so every later session knows what the map is producing — an implementation plan, an ADR, or a system doc.
argument-hint: "<the loose idea this effort is about>"
disable-model-invocation: true
---

Chart a wayfinder map whose destination is **declared, not improvised**.

The vendored `wayfinder` skill treats the destination as open-ended — "a spec to hand off, a decision to lock, a change made in place" — so a charting session has no reason to land on the one this repo actually runs on. The result is tickets shaped for the wrong exit. This skill closes that by making the destination a choice from a closed menu, taken before anything is charted.

## Procedure

1. **Read the menu.** Open `documentation/agents/afk-pipeline.md` and read the *Destination types* table. It is the only definition; do not work from memory, and do not restate it here.

2. **Have the user pick exactly one type.** Present all four with their terminal artifacts and ask. **Do not infer the type from the idea** — a loose idea rarely distinguishes "build this" from "decide this," and guessing wrong is the failure this skill exists to prevent. If the user is unsure, ask what they want to be holding when the effort is over: a merged feature, a merged feature they wrote themselves, a recorded decision, or a written system spec.

3. **Chart the map.** Follow the vendored *Chart the map* procedure:
   - Preferred: invoke `/wayfinder` with the user's idea.
   - **Fallback, if that invocation is refused:** `Read` `.claude/skills/wayfinder/SKILL.md` and follow its *Chart the map* section directly. Its frontmatter sets `disable-model-invocation: true`, which is designed to block model-initiated invocation, so expect this path to be the common one. Reading the file is also update-safe — it reflects whatever the current vendored copy says.

   Either way, do not edit anything under `.claude/skills/wayfinder/`. It is vendored from `mattpocock/skills` and tracked in `skills-lock.json`; reinstalling the skill set overwrites local changes. The local copy's hash has already drifted from the lockfile, so this is a live risk, not a hypothetical one.

4. **Narrow the destination grilling to scope.** The chosen type already fixes the *shape* of the destination, so do not reopen it. Grill only on **scope**: how much of the idea this map covers, and where the boundary falls. Everything past that boundary goes in the map's *Out of scope* section.

5. **Write the type into the map verbatim**, in the format `documentation/agents/afk-pipeline.md` specifies — a `**Type:**` line at the top of `## Destination`, above the prose description. `/wayfinder-handoff` reads this line, so the format is load-bearing.

6. **Shape the tickets for the type.** For `afk-implementation` and `human-implementation`, each ticket resolves a decision a plan author would otherwise have to guess at; the map is done when a plan can be written with no further input.

   Add the type's terminal artifact to the map's `## Notes`, **followed by this disclaimer, which is not optional**:

   > Deliverables are produced only by `/wayfinder-handoff`. This line is orientation, not a *Plan, don't do* override — do not write the plan, the ADR, or the system doc from a `/wayfinder <map>` session.

   The vendored skill reads `## Notes` two ways that make a bare artifact line dangerous: its *Plan, don't do* section says an effort "can override this in its **Notes** — carrying execution into the map itself," and its *Work through the map* step 3 says to "invoke the skills the `## Notes` block names." Without the disclaimer, a mid-map session can reasonably read the artifact line as licence to write the deliverable with tickets still open, bypassing every handoff precondition. **Name no skill in `## Notes`** for the same reason.

7. **Stop.** Charting is one session's work — do not also resolve tickets. Tell the user the map is charted, name the frontier tickets, and point them at `/wayfinder <map>` to work them one per session and `/wayfinder-handoff <map>` when the way is clear.
