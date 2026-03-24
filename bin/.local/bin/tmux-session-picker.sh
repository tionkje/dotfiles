#!/usr/bin/env bash
set -euo pipefail
trap 'echo "Error: $(basename "$0"):$LINENO (exit $?)" >&2' ERR

export PATH="$PATH:$HOME/.local/bin"

# --- helpers ---

read_cmdline() {
    local -a args
    mapfile -t -d '' args < "/proc/$1/cmdline" 2>/dev/null || true
    _PROC_RESULT="${args[*]}"
}

get_process_info() {
    local pane_pid="$1" pane_cmd="$2"
    if [[ "$pane_cmd" =~ ^(bash|zsh|fish|sh)$ ]]; then
        local child_pid="${_child_of[$pane_pid]:-}"
        if [[ -n "$child_pid" ]]; then
            read_cmdline "$child_pid"
            return
        fi
        _PROC_RESULT="$pane_cmd"
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
    local combined
    combined=$(git -C "$path" rev-parse --show-toplevel --abbrev-ref HEAD 2>/dev/null) || { BRANCH=""; REPO=""; return 1; }

    local toplevel="${combined%%$'\n'*}"
    local branch="${combined##*$'\n'}"

    if [[ -n "${git_cache_miss[$toplevel]+x}" ]]; then
        BRANCH=""; REPO=""; return 1
    fi
    if [[ -n "${git_cache_branch[$toplevel]+x}" ]]; then
        BRANCH="${git_cache_branch[$toplevel]}"
        REPO="${git_cache_repo[$toplevel]}"
        return 0
    fi

    BRANCH="$branch"

    # Inline repo name extraction
    local url=""
    url=$(git -C "$toplevel" config --get remote.origin.url 2>/dev/null)
    if [[ -z "$url" ]]; then
        local remote
        remote=$(git -C "$toplevel" remote 2>/dev/null | head -1)
        if [[ -n "$remote" ]]; then
            url=$(git -C "$toplevel" config --get "remote.${remote}.url" 2>/dev/null)
        fi
    fi
    REPO=""
    if [[ -n "$url" ]]; then
        url="${url%.git}"
        if [[ "$url" =~ [/:]([^/:]+/[^/:]+)$ ]]; then
            REPO="${BASH_REMATCH[1]}"
        fi
    fi

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

    # Unit separator as field delimiter (session names may contain |, and tab
    # is IFS-whitespace which collapses empty fields in bash read)
    local fs=$'\x1f'

    # Collect all panes for process aggregation per window
    # declare -A window_procs
    # local _PROC_RESULT=""
    # while IFS=$'\x1f' read -r sess widx ppid pcmd; do
    #     local key="${sess}:${widx}"
    #     get_process_info "$ppid" "$pcmd"
    #     if [[ -n "${window_procs[$key]+x}" ]]; then
    #         window_procs["$key"]="${window_procs[$key]}, $_PROC_RESULT"
    #     else
    #         window_procs["$key"]="$_PROC_RESULT"
    #     fi
    # done < <(tmux list-panes -a -F "#{session_name}${fs}#{window_index}${fs}#{pane_pid}${fs}#{pane_current_command}")

    # Get current time once (bash builtin, zero forks)
    local _now
    printf -v _now '%(%s)T' -1

    # Iterate windows (active pane only for cwd/git)
    while IFS=$'\x1f' read -r sess attached last_attached last_visited stack_idx activity ppath pcmd ppid npanes; do
        # local key="${sess}:${widx}"
        local key="${sess}"
        local short_path="${ppath/#$HOME/\~}"

        # Git info
        local branch="" repo=""
        if get_git_info "$ppath"; then
            branch="$BRANCH"
            repo="$REPO"
        fi

        # Processes from all panes in this window
        # local procs="${window_procs[$key]:-$pcmd}"

        # Relative activity time (inlined)
        local diff=$(( _now - activity )) age
        if (( diff < 60 )); then age="${diff}s"
        elif (( diff < 3600 )); then age="$(( diff / 60 ))m"
        elif (( diff < 86400 )); then age="$(( diff / 3600 ))h"
        else age="$(( diff / 86400 ))d"
        fi

        # Attached marker
        local marker=" "
        [[ "$attached" != "0" ]] && marker="*"

        # Sort key: per-window visit timestamp from hook, fallback to session_last_attached
        local sort_key
        if [[ -n "$last_visited" ]]; then
            sort_key="$last_visited"
        elif [[ "$attached" != "0" ]]; then
            sort_key=$(( _now - stack_idx ))
        else
            sort_key=$(( last_attached - stack_idx ))
        fi

        # Format display line
        local display=""
        display+="${C_GREEN}${marker}${C_RESET} "
        display+="${C_BOLD}${sess}${C_RESET}  "
        #display+="${C_BLUE}${short_path}${C_RESET}  "
        if [[ -n "$branch" ]]; then
            display+="${C_YELLOW}${branch}${C_RESET}  "
        fi
        if [[ -n "$repo" ]]; then
            display+="${C_CYAN}${repo}${C_RESET}  "
        fi
        # display+="${procs} "
        display+="${C_DIM}${age}${C_RESET} "
        display+="${C_DIM}${npanes}p${C_RESET}  "

        printf '%s\t%s\t%s\n' "$sort_key" "$key" "$display"
    done < <(tmux list-windows -a -F "#{session_name}${fs}#{session_attached}${fs}#{session_last_attached}${fs}#{@last_visited}${fs}#{window_stack_index}${fs}#{window_activity}${fs}#{pane_current_path}${fs}#{pane_current_command}${fs}#{pane_pid}${fs}#{window_panes}" -f '#{pane_active}')
    # done < <(tmux list-windows -a -F "#{session_name}${fs}#{window_index}${fs}#{session_attached}${fs}#{session_last_attached}${fs}#{@last_visited}${fs}#{window_stack_index}${fs}#{window_activity}${fs}#{pane_current_path}${fs}#{pane_current_command}${fs}#{pane_pid}${fs}#{window_panes}" -f '#{pane_active}')
}

# --- sort by visit time (most recent first), strip sort column ---
sorted_lines() {
    generate_lines | sort -t$'\t' -k1,1rn | cut -f2-
}

# --list mode: output lines only
if [[ "${1:-}" == "--list" ]]; then
    sorted_lines
    exit 0
fi

selected=$(sorted_lines | fzf --ansi --no-sort \
    --delimiter=$'\t' --with-nth=2 \
    --header-lines=1 \
    --preview='tmux capture-pane -t {1} -p -e 2>/dev/null | tr -d "\r" | tail -n 50' \
    --preview-window='right:50%' \
    --prompt='window > ' \
    --no-info \
) || exit 0

target="${selected%%$'\t'*}"
tmux switch-client -t "$target"
