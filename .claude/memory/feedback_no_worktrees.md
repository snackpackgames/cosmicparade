---
name: feedback-no-worktrees
description: Never create git worktrees for this project — they cause permission re-prompting and lint hook failures
metadata:
  type: feedback
---

Never use git worktrees for this project. Do not invoke `EnterWorktree`, `git worktree add`, or any worktree creation flow — even when skills like `using-git-worktrees` or `subagent-driven-development` suggest it.

**Why:** Worktrees cause two concrete problems in a Godot repo set up this way:
1. The pre-push lint hook runs from the main repo CWD, so new files in a worktree are never linted locally — but CI lints everything, causing CI failures that are invisible locally.
2. Claude Code treats each worktree as a new project root, triggering permission re-prompts for every tool that was already approved in the main session.

**How to apply:** Work directly on a feature branch in the main working directory. When `subagent-driven-development` or `executing-plans` calls `using-git-worktrees`, skip that step and proceed without creating a worktree. Subagents should be given the main repo path as their working directory.
