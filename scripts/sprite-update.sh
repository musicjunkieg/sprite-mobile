#!/bin/bash
# sprite-update - Pull latest code, rebuild, and restart individual services
# Usage: sprite-update <service-name> [--all]
set -e

# Source sprite config for repo URLs
if [ -f "$HOME/.sprite-config" ]; then
    set -a
    source "$HOME/.sprite-config"
    set +a
fi

SPRITE_MOBILE_REPO="${SPRITE_MOBILE_REPO:-https://github.com/clouvet/sprite-mobile}"
CLAUDE_HUB_REPO="${CLAUDE_HUB_REPO:-https://github.com/clouvet/claude-hub}"

die() {
    echo "error: $1" >&2
    exit 1
}

show_help() {
    cat << 'EOF'
sprite-update - Pull latest code, rebuild, and restart individual services

USAGE:
    sprite-update <service-name>
    sprite-update --all

SERVICES:
    sprite-mobile    Pull latest, install deps (bun install), restart service
    claude-hub       Pull latest, rebuild Go binary, restart service

OPTIONS:
    --all            Update all application services
    --pull-only      Pull latest code without restarting the service
    --help, -h       Show this help message

EXAMPLES:
    sprite-update sprite-mobile          # Update and restart sprite-mobile only
    sprite-update claude-hub             # Update and restart claude-hub only
    sprite-update --all                  # Update and restart both services
    sprite-update sprite-mobile --pull-only  # Pull code only, don't restart
EOF
}

update_sprite_mobile() {
    local pull_only="${1:-false}"
    local dir="$HOME/.sprite-mobile"

    echo "=== Updating sprite-mobile ==="

    if [ ! -d "$dir" ]; then
        echo "Cloning sprite-mobile from $SPRITE_MOBILE_REPO..."
        gh repo clone "$SPRITE_MOBILE_REPO" "$dir"
    elif [ -d "$dir/.git" ]; then
        echo "Pulling latest sprite-mobile..."
        cd "$dir"
        git pull
    else
        echo "Directory exists but is not a git repo, cloning fresh..."
        rm -rf "$dir"
        gh repo clone "$SPRITE_MOBILE_REPO" "$dir"
    fi

    echo "Installing dependencies..."
    cd "$dir"
    bun install

    if [ "$pull_only" = "true" ]; then
        echo "sprite-mobile code updated (restart skipped)"
        return
    fi

    echo "Restarting sprite-mobile service..."
    sprite-env services restart sprite-mobile
    echo "sprite-mobile updated and restarted"
}

update_claude_hub() {
    local pull_only="${1:-false}"
    local dir="$HOME/.claude-hub"

    echo "=== Updating claude-hub ==="

    if [ ! -d "$dir" ]; then
        echo "Cloning claude-hub from $CLAUDE_HUB_REPO..."
        gh repo clone "$CLAUDE_HUB_REPO" "$dir"
    elif [ -d "$dir/.git" ]; then
        echo "Pulling latest claude-hub..."
        cd "$dir"
        git pull
    else
        echo "Directory exists but is not a git repo, cloning fresh..."
        rm -rf "$dir"
        gh repo clone "$CLAUDE_HUB_REPO" "$dir"
    fi

    echo "Building claude-hub..."
    cd "$dir"
    go build -o bin/claude-hub main.go

    if [ "$pull_only" = "true" ]; then
        echo "claude-hub code updated (restart skipped)"
        return
    fi

    echo "Restarting claude-hub service..."
    sprite-env services restart claude-hub
    echo "claude-hub updated and restarted"
}

# Parse arguments
pull_only=false
targets=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --all)
            targets+=("sprite-mobile" "claude-hub")
            shift
            ;;
        --pull-only)
            pull_only=true
            shift
            ;;
        -h|--help|help)
            show_help
            exit 0
            ;;
        sprite-mobile|claude-hub)
            targets+=("$1")
            shift
            ;;
        *)
            die "unknown argument: $1 (try 'sprite-update --help')"
            ;;
    esac
done

if [ ${#targets[@]} -eq 0 ]; then
    show_help
    exit 1
fi

# Remove duplicates
mapfile -t targets < <(printf '%s\n' "${targets[@]}" | sort -u)

for target in "${targets[@]}"; do
    case "$target" in
        sprite-mobile)
            update_sprite_mobile "$pull_only"
            ;;
        claude-hub)
            update_claude_hub "$pull_only"
            ;;
    esac
    echo ""
done

echo "Done!"
