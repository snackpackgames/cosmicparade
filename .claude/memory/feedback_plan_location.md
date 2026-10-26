---
name: feedback-plan-location
description: Plans go in documentation/plans/, not docs/superpowers/plans/
metadata:
  type: feedback
---

Save implementation plans to `documentation/plans/`, not `docs/superpowers/plans/`.

**Why:** This project uses `documentation/plans/` for all plan files — the convention carried over from the fiber repo, and the AFK pipeline's handoff stage reads plans from that path.

**How to apply:** When the `writing-plans` skill says to save to `docs/superpowers/plans/`, override that default and use `documentation/plans/` instead.
