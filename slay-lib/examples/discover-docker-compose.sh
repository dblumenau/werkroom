#!/usr/bin/env bash
# Discovery script for docker-compose.yml files
# Scans for docker-compose files with health/app URL environment variables
#
# Setup:
#   1. Copy to ~/.config/slay/discover-urls.sh
#   2. chmod +x ~/.config/slay/discover-urls.sh
#   3. Add to ~/.config/slay/config:
#      URL_DISCOVERY_SCRIPT="$HOME/.config/slay/discover-urls.sh"
#
# Customize:
#   - ENV_VAR_NAMES: Array of env var names to look for
#   - HEALTH_PATH: Path to append to URL (default: /health)

ENV_VAR_NAMES=("HEALTH_URL" "APP_URL" "BASE_URL" "API_URL")
HEALTH_PATH="/health"

# Use PROJECTS_DIR from environment (passed by slay) or default
PROJECTS_DIR="${PROJECTS_DIR:-$HOME/projects}"

if ! command -v fd &> /dev/null; then
    exit 1
fi

fd -e yml -e yaml "docker-compose" "$PROJECTS_DIR" --type f 2>/dev/null | while read -r file; do
    url=""

    # Try each env var name
    for var_name in "${ENV_VAR_NAMES[@]}"; do
        # Look for: VAR_NAME: "url" or VAR_NAME=url patterns
        url=$(grep -E "^\s*${var_name}[=:]" "$file" 2>/dev/null | head -1 | sed -E 's/.*[=:]\s*"?([^"]+)"?.*/\1/')
        [ -n "$url" ] && break
    done

    # Skip if no URL found
    [ -z "$url" ] && continue

    # Skip if URL doesn't look like a URL
    echo "$url" | grep -qE "^https?://" || continue

    # Extract project group (first directory under PROJECTS_DIR)
    project_group=$(echo "$file" | sed "s|$PROJECTS_DIR/||" | cut -d'/' -f1)

    # Check if URL already has a path, if not append health path
    if echo "$url" | grep -qE "^https?://[^/]+$"; then
        url="${url}${HEALTH_PATH}"
    fi

    # Output: project_group|url
    echo "${project_group}|${url}"
done | sort -u
