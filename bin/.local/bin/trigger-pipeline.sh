#!/usr/bin/env bash
set -euo pipefail

# Configuration
CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/pipeline-trigger/config"

# Get git remote URL
REMOTE_URL=$(git remote get-url origin 2>/dev/null || echo "")

if [[ -z "$REMOTE_URL" ]]; then
    echo "Error: Not in a git repository or no origin remote configured" >&2
    exit 1
fi

# Detect platform
if [[ "$REMOTE_URL" == *"github.com"* ]]; then
    PLATFORM="github"
elif [[ "$REMOTE_URL" == *"bitbucket.org"* ]]; then
    PLATFORM="bitbucket"
else
    echo "Error: Unknown platform. Only GitHub and Bitbucket are supported." >&2
    exit 1
fi

# GitHub implementation
trigger_github() {
    if ! command -v gh &>/dev/null; then
        echo "Error: 'gh' CLI not found. Install it: https://cli.github.com" >&2
        exit 1
    fi

    # List workflows and select with fzf
    WORKFLOW=$(gh workflow list --json name,path,state | \
        jq -r '.[] | select(.state == "active") | .name' | \
        fzf --prompt="Select GitHub workflow: " --height=40% --reverse)

    if [[ -z "$WORKFLOW" ]]; then
        echo "No workflow selected" >&2
        exit 1
    fi

    # Trigger the workflow on the current or specified branch
    BRANCH="${BRANCH:-$(git branch --show-current)}"
    echo "Triggering workflow '$WORKFLOW' on branch '$BRANCH'..."
    gh workflow run "$WORKFLOW" --ref "$BRANCH"
    echo "✓ Workflow triggered successfully"
}

# Bitbucket implementation
trigger_bitbucket() {
    # Check dependencies
    if ! command -v yq &>/dev/null; then
        echo "Error: 'yq' not found. Install it: https://github.com/mikefarah/yq" >&2
        exit 1
    fi

    if ! command -v curl &>/dev/null; then
        echo "Error: 'curl' not found" >&2
        exit 1
    fi

    # Load access token from config
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo "Error: Config file not found at $CONFIG_FILE" >&2
        echo "Create it with: BB_ACCESS_TOKEN=your_token_here" >&2
        echo "Get token from: Bitbucket → Personal settings → Personal access tokens" >&2
        exit 1
    fi

    source "$CONFIG_FILE"

    if [[ -z "${BB_ACCESS_TOKEN:-}" ]]; then
        echo "Error: BB_ACCESS_TOKEN not set in $CONFIG_FILE" >&2
        exit 1
    fi

    # Find bitbucket-pipelines.yml
    if [[ ! -f "bitbucket-pipelines.yml" ]]; then
        echo "Error: bitbucket-pipelines.yml not found in repository root" >&2
        exit 1
    fi

    # Extract custom pipeline names
    PIPELINES=$(yq -r '.pipelines.custom | keys | .[]' bitbucket-pipelines.yml 2>/dev/null || echo "")

    if [[ -z "$PIPELINES" ]]; then
        echo "Error: No custom pipelines found in bitbucket-pipelines.yml" >&2
        exit 1
    fi

    # Select pipeline with fzf
    PIPELINE=$(echo "$PIPELINES" | fzf --prompt="Select Bitbucket pipeline: " --height=40% --reverse)

    if [[ -z "$PIPELINE" ]]; then
        echo "No pipeline selected" >&2
        exit 1
    fi

    # Extract workspace and repo from remote URL
    # Format: git@bitbucket.org:workspace/repo.git or https://bitbucket.org/workspace/repo.git
    if [[ "$REMOTE_URL" =~ bitbucket\.org[:/]([^/]+)/([^/.]+) ]]; then
        WORKSPACE="${BASH_REMATCH[1]}"
        REPO="${BASH_REMATCH[2]}"
    else
        echo "Error: Could not parse workspace and repo from remote URL: $REMOTE_URL" >&2
        exit 1
    fi

    # Get branch
    BRANCH="${BRANCH:-$(git branch --show-current)}"

    echo "Triggering pipeline '$PIPELINE' on branch '$BRANCH' for $WORKSPACE/$REPO..."

    # Trigger pipeline via Bitbucket API
    RESPONSE=$(curl -s -X POST \
        -H "Authorization: Bearer $BB_ACCESS_TOKEN" \
        -H "Content-Type: application/json" \
        "https://api.bitbucket.org/2.0/repositories/$WORKSPACE/$REPO/pipelines/" \
        -d "{
            \"target\": {
                \"ref_type\": \"branch\",
                \"type\": \"pipeline_ref_target\",
                \"ref_name\": \"$BRANCH\",
                \"selector\": {
                    \"type\": \"custom\",
                    \"pattern\": \"$PIPELINE\"
                }
            }
        }")

    # Check for errors
    if echo "$RESPONSE" | jq -e '.error' &>/dev/null; then
        echo "Error: $(echo "$RESPONSE" | jq '.error.message')" >&2
        echo "$RESPONSE" | jq .;
        exit 1
    fi

    PIPELINE_UUID=$(echo "$RESPONSE" | jq -r '.uuid // empty')
    BUILD_NUMBER=$(echo "$RESPONSE" | jq -r '.build_number // empty')

    if [[ -n "$PIPELINE_UUID" ]]; then
        echo "✓ Pipeline triggered successfully"
        [[ -n "$BUILD_NUMBER" ]] && echo "  Build number: $BUILD_NUMBER"
        echo "  View at: https://bitbucket.org/$WORKSPACE/$REPO/pipelines"
    else
        echo "Pipeline triggered (no confirmation received)"
    fi
}

# Execute based on platform
case "$PLATFORM" in
    github)
        trigger_github
        ;;
    bitbucket)
        trigger_bitbucket
        ;;
    *)
        echo "Error: Unknown platform: $PLATFORM" >&2
        exit 1
        ;;
esac
