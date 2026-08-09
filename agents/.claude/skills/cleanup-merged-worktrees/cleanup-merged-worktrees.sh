#!/usr/bin/env bash
# Remove the CURRENT worktree and its local branch if the branch's PR is
# already squash-merged on GitHub. Squash merges leave the local branch
# looking "unmerged" to git, so the merge check is `gh`, not git.
# Dry run by default. Pass --apply to actually delete.
set -euo pipefail

apply=false
force=false
for arg in "$@"; do
	case "$arg" in
	--apply) apply=true ;;
	--force) force=true ;;
	*)
		echo "usage: $0 [--apply] [--force]" >&2
		exit 2
		;;
	esac
done

main_wt=$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")
wt=$(git rev-parse --show-toplevel)
if [[ $wt == "$main_wt" ]]; then
	echo "error: this is the main checkout, not a worktree - run inside the worktree to clean" >&2
	exit 1
fi
branch=$(git branch --show-current)
if [[ -z $branch ]]; then
	echo "error: detached HEAD, no branch to match against a PR" >&2
	exit 1
fi

echo "worktree $wt [$branch]"
$apply || echo "DRY RUN - nothing will be deleted (re-run with --apply)"

pr=$(gh pr list --state merged --head "$branch" --limit 1 --json number,headRefOid --jq '.[0]')
if [[ -z $pr || $pr == null ]]; then
	echo "error: no merged PR found for branch $branch - refusing to clean" >&2
	exit 1
fi
num=$(jq -r .number <<<"$pr")
sha=$(jq -r .headRefOid <<<"$pr")
echo "PR #$num merged (head $sha)"

dirty=$(git status --porcelain)
if [[ -n $dirty ]]; then
	echo "! uncommitted changes:"
	sed 's/^/  /' <<<"$dirty"
	$force || {
		echo "refusing (--force to discard)" >&2
		exit 1
	}
fi

# HEAD is an ancestor of the merged PR head => no local-only commits to lose.
if ! git rev-parse -q --verify "$sha^{commit}" >/dev/null; then
	echo "! PR head $sha not in local object store, cannot verify tip" >&2
	$force || {
		echo "refusing (--force to discard)" >&2
		exit 1
	}
elif ! git merge-base --is-ancestor HEAD "$sha"; then
	echo "! local commits beyond the merged PR head:" >&2
	git log --oneline "$sha..HEAD" | sed 's/^/  /' >&2
	$force || {
		echo "refusing (--force to discard)" >&2
		exit 1
	}
fi

locked=false
[[ -e "$(git rev-parse --absolute-git-dir)/locked" ]] && locked=true

# The Claude session running this skill has its cwd here and will be listed -
# that is expected, it closes after the cleanup.
# readlink is allowed to fail: the process can exit between pgrep and readlink.
pgrep -a claude | while read -r pid _; do
	cwd=$(readlink "/proc/$pid/cwd") || continue
	if [[ $cwd == "$wt"* ]]; then
		echo "note: claude pid $pid has cwd in this worktree"
	fi
done

if $apply; then
	cd "$main_wt"
	$locked && git worktree unlock "$wt"
	git worktree remove --force "$wt"
	git branch -D "$branch"
	git worktree prune
else
	$locked && echo "would: git worktree unlock $wt"
	echo "would: git worktree remove --force $wt"
	echo "would: git branch -D $branch"
	echo "would: git worktree prune"
fi
echo "done"
