---
name: feedback-logical-commits
description: Split changes into logical commits rather than one big commit
metadata:
  type: feedback
---

Split changes into logical commits of related work rather than committing everything together.

**Why:** Clean, reviewable git history where each commit represents a coherent unit of change.

**How to apply:** Before committing, analyze the diff and group related changes. Each commit should cover one logical change (e.g., a refactor, a new feature, a bug fix, test updates for that feature). See [[feedback-commit-bullets]] for the message body format.
