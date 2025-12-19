#!/usr/bin/env bash
# Generate tmux window title for ActivityWatch tracking
# Format: [command] repo:branch
# - Uses git remote origin URL (extracts repo name)
# - Falls back to other remotes, then local directory name
# - Shows the current running command (e.g., nvim, claude, zsh)

pane_path="$1"
pane_cmd="$2"

# Get repo name from git remote origin, fallback to other remotes, then local path
get_repo_name() {
    local path="$1"
    local url=""

    # Try origin first
    url=$(git -C "$path" remote get-url origin 2>/dev/null)

    # Fallback to first available remote
    if [[ -z "$url" ]]; then
        local remote=$(git -C "$path" remote 2>/dev/null | head -1)
        if [[ -n "$remote" ]]; then
            url=$(git -C "$path" remote get-url "$remote" 2>/dev/null)
        fi
    fi

    # Extract org/repo from URL
    if [[ -n "$url" ]]; then
        # Handle various URL formats:
        # git@github.com:org/repo.git -> org/repo
        # https://github.com/org/repo.git -> org/repo
        echo "$url" | sed 's/\.git$//' | sed -E 's/.*[\/:]([^\/]+\/[^\/]+)$/\1/'
    else
        # Fallback to directory basename
        basename "$path"
    fi
}

# Get branch name
get_branch() {
    local path="$1"
    git -C "$path" rev-parse --abbrev-ref HEAD 2>/dev/null
}

repo=$(get_repo_name "$pane_path")
branch=$(get_branch "$pane_path")
cmd="$pane_cmd"

# Build title: repo:branch [cmd]
if [[ -n "$branch" ]]; then
    echo "$repo:$branch [$cmd]"
else
    echo "$repo [$cmd]"
fi
