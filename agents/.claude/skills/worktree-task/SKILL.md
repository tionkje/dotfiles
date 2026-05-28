---
name: worktree-task
description: Execute a task in an isolated git worktree, then rebase and fast-forward merge it back into a chosen starting branch with full cleanup. Use when the user wants to do work in a worktree and have it merged back automatically, says "run this in a worktree", "do this in a worktree and merge back", or invokes `/worktree-task`.
---

# Worktree Task

Spin up a worktree, do the work, rebase, fast-forward into the starting branch, clean everything up. One opinionated flow.

## Resume check (do this first)

If a previous run paused (rebase conflict, blocker), the conversation may be mid-flight. Before anything else:

1. Run `git worktree list` and check whether a worktree under `.claude/worktrees/` matches a branch from earlier in this conversation.
2. If so: `cd` into it, run `git status` to detect mid-rebase / dirty state, and resume at the appropriate step below. Don't re-create.

## Inputs

1. **Task** — argument to the skill invocation. If missing, ask once.
2. **Starting branch** — ask the user, default to `git rev-parse --abbrev-ref HEAD` at invocation time. Always ask (even though there's a default).

## Workflow

1. **Pick branch name.** Slugify the task (lowercase, dashes, alnum only). Check `git show-ref --verify --quiet refs/heads/<name>` and `test -d .claude/worktrees/<name>`. On collision, append `-2`, `-3`, ... until both are free. No confirmation prompt.

2. **Create worktree.** Run `git worktree add .claude/worktrees/<name> -b <name> <starting-branch>`, then `cd` into it. Uncommitted changes in the source checkout stay where they are — the worktree branches from the committed state. If you're already inside a worktree, that's fine: treat the current branch as the starting branch and proceed (do not refuse; do not use `EnterWorktree` — use raw `git worktree add`).

   **Before leaving the source checkout, scan its dirty state** (`git -C <source> status --porcelain` and `git -C <source> diff HEAD`) and judge whether those in-progress edits overlap with the task you're about to do (same files, same area). If yes, mirror them into the new worktree as a patch before implementing — otherwise you'll do work against a stale base and rebase will fight you later. Tracked changes: `git -C <source> diff HEAD | git apply -` from inside the new worktree. Untracked files: copy them over explicitly. The source checkout is not modified — the user keeps editing there in parallel.

3. **Plan if needed.** Judge from the task description: if it's small and clear (one-liner, obvious change, config tweak), implement directly. If it's vague or multi-step, invoke [[brainstorming]] / [[writing-plans]] before touching code.

4. **Implement and commit.** Do the work. Commit in whatever logical units emerge naturally — no forced squash, no forced split.

5. **Verify if applicable.** If the task touches code that has tests / typecheck / build (not pure docs or config), invoke [[verification-before-completion]]. Skip verification for docs/dotfiles/config-only changes.

6. **Rebase onto starting branch.** From inside the worktree: `git rebase <starting-branch>`. This picks up any commits that landed on the starting branch since the worktree was created.

   - **Clean rebase:** continue to step 7.
   - **Conflict:** read `git log <starting-branch>..HEAD` and `git log HEAD..<starting-branch>` to understand both sides' intentions, inspect the conflict markers, and synthesize a resolution that preserves both sides' intent. Stage, `git rebase --continue`. If you cannot confidently resolve, stop, print the conflicting files and what's unclear, and ask the user how to proceed (see "Blockers" below).

7. **Merge fast-forward into the main checkout.** The starting branch is (typically) still checked out in the main checkout while the user works there in parallel. `git push . HEAD:<starting-branch>` would refuse to update a checked-out branch, so the merge has to happen in the main checkout itself. The main checkout's working tree may be dirty — stash it, merge, pop.

   Find the main checkout path (`git worktree list --porcelain`, pick the entry that is not the current worktree; or `dirname $(git rev-parse --git-common-dir)`). Then, in order:

   1. `BEFORE=$(git -C <main> rev-parse HEAD)` — record pre-merge SHA for rollback.
   2. If `git -C <main> status --porcelain` is non-empty: `git -C <main> stash push --include-untracked -m "worktree-task <name>"`. Remember that a stash was created.
   3. `git -C <main> merge --ff-only <name>`
   4. If a stash was created: `git -C <main> stash pop`

   **On any failure in steps 2–4, recover immediately before investigating anything:**

   1. `git -C <main> reset --hard "$BEFORE"` — restores both the branch ref and the main working tree to the pre-merge state.
   2. If a stash was created and is still on the stack: `git -C <main> stash pop` (or `stash apply` if pop refuses; the user's dirty state was made against `$BEFORE`, so it should apply cleanly now).
   3. Confirm `git -C <main> status` looks like the pre-merge state (branch at `$BEFORE`, original dirty changes restored).
   4. **Only now** investigate what failed (which step? what was the error?) and report it. Treat this as a blocker (see below) — leave the worktree and branch intact.

8. **Cleanup.** Only if step 7 succeeded end-to-end. `cd` back to the main checkout. Then:

   ```
   git worktree remove .claude/worktrees/<name>
   git branch -d <name>
   ```

   Both should succeed because the branch is fully merged. Do not push to remote.

## Blockers

If the implementation can't be completed (verification keeps failing, unresolvable conflict, missing decision, dependency you can't install) — **do not** abort or clean up. Leave the worktree and branch intact, report what's blocking in plain terms, and ask the user what they want to do to continue. When they respond, resume from the appropriate step.

## Notes

- This skill runs in the main agent / current conversation. Do not dispatch a subagent for the implementation.
- The starting branch's local state is the rebase target. No `git fetch`. If the user wants remote freshness, they pull first.
- Worktrees live under `.claude/worktrees/<name>/` relative to the repo root.
