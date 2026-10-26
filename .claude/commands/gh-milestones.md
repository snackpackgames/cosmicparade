List GitHub milestones for the current repository.

`gh milestone list` does NOT exist. Use the API directly:

```bash
gh api repos/{owner}/{repo}/milestones --jq '.[] | {number: .number, title: .title}'
```

To get the owner/repo, run `gh repo view --json name,owner` first if not already known.
