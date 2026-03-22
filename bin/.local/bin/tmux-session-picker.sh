#!/usr/bin/env bash
set -euo pipefail
trap 'echo "Error: $(basename "$0"):$LINENO (exit $?)" >&2' ERR

export PATH="$PATH:$HOME/.local/bin"

# --- helpers (inlined from tmux-title.sh) ---

get_repo_name() {
    local path="$1" url=""
    url=$(git -C "$path" remote get-url origin 2>/dev/null)
    if [[ -z "$url" ]]; then
        local remote
        remote=$(git -C "$path" remote 2>/dev/null | head -1)
        if [[ -n "$remote" ]]; then
            url=$(git -C "$path" remote get-url "$remote" 2>/dev/null)
        fi
    fi
    if [[ -n "$url" ]]; then
        echo "$url" | sed 's/\.git$//' | sed -E 's/.*[\/:]([^\/]+\/[^\/]+)$/\1/'
    fi
}

get_branch() {
    git -C "$1" rev-parse --abbrev-ref HEAD 2>/dev/null
}

relative_time() {
    local epoch="$1" now diff
    now=$(date +%s)
    diff=$(( now - epoch ))
    if (( diff < 60 )); then echo "${diff}s"
    elif (( diff < 3600 )); then echo "$(( diff / 60 ))m"
    elif (( diff < 86400 )); then echo "$(( diff / 3600 ))h"
    else echo "$(( diff / 86400 ))d"
    fi
}

shorten_path() {
    local home="$HOME"
    echo "${1/#$home/\~}"
}

read_cmdline() {
    local -a args
    mapfile -t -d '' args < "/proc/$1/cmdline" 2>/dev/null || true
    echo "${args[*]}"
}

get_process_info() {
    local pane_pid="$1" pane_cmd="$2"
    if [[ "$pane_cmd" =~ ^(bash|zsh|fish|sh)$ ]]; then
        local child_pid="${_child_of[$pane_pid]:-}"
        if [[ -n "$child_pid" ]]; then
            read_cmdline "$child_pid"
            return
        fi
        echo "$pane_cmd"
        return
    fi
    read_cmdline "$pane_pid"
}

# --- git cache ---
declare -A git_cache_branch
declare -A git_cache_repo
declare -A git_cache_miss

get_git_info() {
    local path="$1"
    local toplevel
    toplevel=$(git -C "$path" rev-parse --show-toplevel 2>/dev/null) || { BRANCH=""; REPO=""; return 1; }

    if [[ -n "${git_cache_miss[$toplevel]+x}" ]]; then
        BRANCH=""; REPO=""; return 1
    fi
    if [[ -n "${git_cache_branch[$toplevel]+x}" ]]; then
        BRANCH="${git_cache_branch[$toplevel]}"
        REPO="${git_cache_repo[$toplevel]}"
        return 0
    fi

    BRANCH=$(get_branch "$toplevel")
    REPO=$(get_repo_name "$toplevel")
    if [[ -z "$BRANCH" && -z "$REPO" ]]; then
        git_cache_miss["$toplevel"]=1
        return 1
    fi
    git_cache_branch["$toplevel"]="$BRANCH"
    git_cache_repo["$toplevel"]="$REPO"
}

# --- colors ---
C_RESET=$'\033[0m'
C_BOLD=$'\033[1m'
C_DIM=$'\033[2m'
C_GREEN=$'\033[32m'
C_YELLOW=$'\033[33m'
C_BLUE=$'\033[34m'
C_MAGENTA=$'\033[35m'
C_CYAN=$'\033[36m'

# --- generate display lines ---
generate_lines() {
    # Build child-pid lookup: parent_pid -> newest child pid (single ps call)
    declare -A _child_of
    while read -r cpid cppid; do
        _child_of["$cppid"]="$cpid"  # last (highest pid) wins = newest
    done < <(ps -eo pid,ppid --no-headers | sort -n -k1)

    # Collect all panes for process aggregation per window
    declare -A window_procs
    while IFS='|' read -r sess widx ppid pcmd; do
        local key="${sess}:${widx}"
        local proc_info
        proc_info=$(get_process_info "$ppid" "$pcmd")
        if [[ -n "${window_procs[$key]+x}" ]]; then
            window_procs["$key"]="${window_procs[$key]}, $proc_info"
        else
            window_procs["$key"]="$proc_info"
        fi
    done < <(tmux list-panes -a -F '#{session_name}|#{window_index}|#{pane_pid}|#{pane_current_command}')

    # Iterate windows (active pane only for cwd/git)
    while IFS='|' read -r sess widx wname wactive attached activity ppath pcmd ppid npanes; do
        local key="${sess}:${widx}"
        local short_path
        short_path=$(shorten_path "$ppath")

        # Git info
        local branch="" repo=""
        if get_git_info "$ppath"; then
            branch="$BRANCH"
            repo="$REPO"
        fi

        # Processes from all panes in this window
        local procs="${window_procs[$key]:-$pcmd}"

        # Relative activity time
        local age
        age=$(relative_time "$activity")

        # Attached marker
        local marker=" "
        [[ "$attached" != "0" ]] && marker="*"

        # Format display line
        local display=""
        display+="${C_GREEN}${marker}${C_RESET} "
        display+="${C_BOLD}${sess}:${widx}${C_RESET}  "
        display+="${C_DIM}${npanes}p${C_RESET}  "
        display+="${C_BLUE}${short_path}${C_RESET}  "
        if [[ -n "$branch" ]]; then
            display+="${C_YELLOW}${branch}${C_RESET}  "
        fi
        if [[ -n "$repo" ]]; then
            display+="${C_CYAN}${repo}${C_RESET}  "
        fi
        display+="${procs}  "
        display+="${C_DIM}${age}${C_RESET}"

        printf '%s\t%s\t%s\n' "$activity" "$key" "$display"
    done < <(tmux list-windows -a -F '#{session_name}|#{window_index}|#{window_name}|#{window_active}|#{session_attached}|#{window_activity}|#{pane_current_path}|#{pane_current_command}|#{pane_pid}|#{window_panes}' -f '#{pane_active}')
}

# --- sort by activity (most recent first), strip epoch column ---
sorted_lines() {
    generate_lines | sort -t$'\t' -k1 -rn | cut -f2-
}

# --list mode: output lines only
if [[ "${1:-}" == "--list" ]]; then
    sorted_lines
    exit 0
fi

selected=$(sorted_lines | fzf --ansi --no-sort \
    --delimiter=$'\t' --with-nth=2 \
    --header-lines=1 \
    --preview='tmux capture-pane -t {1} -p -e 2>/dev/null' \
    --preview-window='right:50%:wrap' \
    --prompt='window > ' \
    --no-info \
) || exit 0

target="${selected%%$'\t'*}"
tmux switch-client -t "$target"
