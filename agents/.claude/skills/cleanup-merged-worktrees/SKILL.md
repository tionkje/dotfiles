---
name: cleanup-merged-worktrees
description: Delete the current git worktree and its local branch after its PR was squash-merged on GitHub. Explicit /cleanup-merged-worktrees invocation only.
disable-model-invocation: true
---

# Cleanup merged worktree

Squash merge rewrites history, so `git branch -d` and Claude's session-exit
check both still see the branch as unmerged and refuse to clean up. The merged
state lives on GitHub, not in local history — so ask `gh`, not git.

**Scope: only the worktree this skill is executed in.** It never touches other
worktrees or branches, and it refuses to run in the main checkout.

## Run it

```
~/.claude/skills/cleanup-merged-worktrees/cleanup-merged-worktrees.sh
```

Dry run by default: prints the checks and the exact commands it would run. Show
that output to the user, then re-run with `--apply` once they agree. Never pass
`--apply` on the first run.

- `--apply` — actually delete
- `--force` — proceed despite uncommitted changes or commits beyond the merged
  PR head. Only when the user asks for it; this destroys work.

## What it checks

1. Current branch has a merged PR (`gh pr list --state merged --head <branch>`)
   — otherwise it refuses, always.
2. `git status --porcelain` is clean.
3. HEAD is an ancestor of the merged PR's head commit, so no local-only commits
   are lost.

Failing 2 or 3 aborts unless `--force`. On `--apply` it cds to the main
checkout, then: `git worktree unlock` if locked, `git worktree remove --force`,
`git branch -D` (capital D — squash merges make `-d` refuse), `git worktree
prune`.

The shell cwd of the session that ran it disappears with the worktree — that is
expected; close the session afterwards. It does not push or delete remote
branches.
