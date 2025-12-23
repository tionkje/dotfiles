#!/usr/bin/env bash
# Claude Code status line script
# Displays: [cwd | org/repo |  branch sync | changes | tokens]

# Colors
GREEN='\033[32m'
RED='\033[31m'
YELLOW='\033[33m'
RESET='\033[0m'

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

        parts=()
        [ "$staged" -gt 0 ] && parts+=("$(printf "${GREEN}+%s${RESET}" "$staged")")
        [ "$modified" -gt 0 ] && parts+=("$(printf "${RED}●%s${RESET}" "$modified")")
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

# Build output
out="[$cwd"
[ -n "$remote" ] && out+=" | $remote"
[ -n "$branch" ] && out+=" |$branch"
[ -n "$sync" ] && out+=" $sync"
[ -n "$changes" ] && out+=" | $changes"
[ -n "$context" ] && out+=" | $context"
out+="]"

printf '%s' "$out"
