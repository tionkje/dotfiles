#!/usr/bin/env bash
# Claude Code status line script
# Displays: [cwd | org/repo |  branch sync | changes | tokens]

# Colors
GREEN=$'\033[32m'
RED=$'\033[31m'
YELLOW=$'\033[33m'
BLUE=$'\033[34m'
MAGENTA=$'\033[35m'
CYAN=$'\033[36m'
RESET=$'\033[0m'

# Read JSON input from stdin
input=$(cat)

# Get current working directory, replace home with ~
cwd=$(echo "$input" | jq -r '.workspace.current_dir')
cwd=$(echo "$cwd" | sed 's|^/home/bastiaan|~|')

# Change to cwd for git commands
cd "${cwd/#\~/$HOME}" 2>/dev/null

# Initialize variables
remote=""
branch=""
changes=""
context=""
sync=""
stash=""

# Git information (only if in a git repo)
if git rev-parse --git-dir >/dev/null 2>&1; then
    # Extract org/repo from remote URL
    url=$(git config --get remote.origin.url 2>/dev/null)
    if [[ "$url" =~ [:/]([^/]+)/([^/\\.]+) ]]; then
        remote="${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
    fi

    # Branch name (or short SHA if detached)
    branch=$(git branch --show-current 2>/dev/null)
    [ -z "$branch" ] && branch=$(git rev-parse --short HEAD 2>/dev/null)
    [ -n "$branch" ] && branch="  $branch"

    # Working tree changes
    status=$(git -c core.useBuiltinFSMonitor=false status --porcelain 2>/dev/null)
    if [ -n "$status" ]; then
        staged=$(echo "$status" | grep -c '^[AM]')
        modified=$(echo "$status" | grep -c '^ [MD]')
        deleted=$(echo "$status" | grep -c '^ D')
        untracked=$(echo "$status" | grep -c '^??')

        # Staged lines added/removed
        staged_stats=$(git diff --cached --numstat 2>/dev/null | awk '{add+=$1; del+=$2} END {print add" "del}')
        staged_add=$(echo "$staged_stats" | cut -d' ' -f1)
        staged_del=$(echo "$staged_stats" | cut -d' ' -f2)
        [ -z "$staged_add" ] && staged_add=0
        [ -z "$staged_del" ] && staged_del=0

        # Unstaged lines added/removed
        unstaged_stats=$(git diff --numstat 2>/dev/null | awk '{add+=$1; del+=$2} END {print add" "del}')
        unstaged_add=$(echo "$unstaged_stats" | cut -d' ' -f1)
        unstaged_del=$(echo "$unstaged_stats" | cut -d' ' -f2)
        [ -z "$unstaged_add" ] && unstaged_add=0
        [ -z "$unstaged_del" ] && unstaged_del=0

        parts=()
        # Staged files and lines
        if [ "$staged" -gt 0 ]; then
            staged_info="$(printf "${GREEN}+%s${RESET}" "$staged")"
            if [ "$staged_add" -gt 0 ] || [ "$staged_del" -gt 0 ]; then
                staged_info+="("
                [ "$staged_add" -gt 0 ] && staged_info+="$(printf "${GREEN}+%s${RESET}" "$staged_add")"
                [ "$staged_del" -gt 0 ] && staged_info+="$(printf "${RED}-%s${RESET}" "$staged_del")"
                staged_info+=")"
            fi
            parts+=("$staged_info")
        fi
        # Modified files and lines
        if [ "$modified" -gt 0 ]; then
            mod_info="$(printf "${RED}✎%s${RESET}" "$modified")"
            if [ "$unstaged_add" -gt 0 ] || [ "$unstaged_del" -gt 0 ]; then
                mod_info+="("
                [ "$unstaged_add" -gt 0 ] && mod_info+="$(printf "${GREEN}+%s${RESET}" "$unstaged_add")"
                [ "$unstaged_del" -gt 0 ] && mod_info+="$(printf "${RED}-%s${RESET}" "$unstaged_del")"
                mod_info+=")"
            fi
            parts+=("$mod_info")
        fi
        [ "$deleted" -gt 0 ] && parts+=("$(printf "${RED}-%s${RESET}" "$deleted")")
        [ "$untracked" -gt 0 ] && parts+=("$(printf "${YELLOW}?%s${RESET}" "$untracked")")

        [ ${#parts[@]} -gt 0 ] && changes=$(IFS=' '; echo "${parts[*]}")
    fi

    # Ahead/behind upstream (lazygit style: yellow arrows, green checkmark when synced)
    if [ -n "$(git branch --show-current 2>/dev/null)" ]; then
        ahead=$(git rev-list --count @{u}..HEAD 2>/dev/null)
        behind=$(git rev-list --count HEAD..@{u} 2>/dev/null)

        if [ -n "$ahead" ] && [ -n "$behind" ]; then
            if [ "$ahead" -eq 0 ] && [ "$behind" -eq 0 ]; then
                sync="$(printf "${GREEN}✓${RESET}")"
            else
                [ "$ahead" -gt 0 ] && sync+="$(printf "${YELLOW}↑%s${RESET}" "$ahead")"
                [ "$behind" -gt 0 ] && sync+="$(printf "${YELLOW}↓%s${RESET}" "$behind")"
            fi
        fi
    fi

    # Stash count
    stash_count=$(git stash list 2>/dev/null | wc -l)
    [ "$stash_count" -gt 0 ] && stash="$(printf "${CYAN}⚑%s${RESET}" "$stash_count")"
fi

# Context window usage (gradient: green < 50%, yellow 50-79%, red >= 80%)
usage=$(echo "$input" | jq '.context_window.current_usage')
if [ "$usage" != "null" ]; then
    cur=$(echo "$usage" | jq '.input_tokens + .cache_creation_input_tokens + .cache_read_input_tokens')
    sz=$(echo "$input" | jq '.context_window.context_window_size')

    if [ -n "$cur" ] && [ -n "$sz" ] && [ "$sz" -gt 0 ]; then
        pct=$((cur * 100 / sz))
        cur_k=$((cur / 1000))
        sz_k=$((sz / 1000))

        if [ "$pct" -lt 50 ]; then
            cc='32'  # green
        elif [ "$pct" -lt 80 ]; then
            cc='33'  # yellow
        else
            cc='31'  # red
        fi

        context="$(printf '\033[%sm%sk/%sk(%s%%)\033[0m' "$cc" "$cur_k" "$sz_k" "$pct")"
    fi
fi

# Build output with colors: cwd=blue, remote=magenta, branch=cyan
out="[${BLUE}${cwd}${RESET}"
[ -n "$remote" ] && out+=" | ${MAGENTA}${remote}${RESET}"
[ -n "$branch" ] && out+=" |${CYAN}${branch}${RESET}"
[ -n "$sync" ] && out+=" $sync"
[ -n "$stash" ] && out+=" $stash"
[ -n "$changes" ] && out+=" | $changes"
[ -n "$context" ] && out+=" | $context"
out+="]"

printf '%s' "$out"
