#!/usr/bin/env bash
# Discovery script for .env files (Laravel, Node.js, etc.)
# Scans for .env files with APP_URL or similar variables
#
# Setup:
#   1. Copy to ~/.config/slay/discover-urls.sh
#   2. chmod +x ~/.config/slay/discover-urls.sh
#   3. Add to ~/.config/slay/config:
#      URL_DISCOVERY_SCRIPT="$HOME/.config/slay/discover-urls.sh"
#
# Customize:
#   - ENV_VAR_NAMES: Array of env var names to look for
#   - HEALTH_PATH: Path to append to URL (default: /api/health)
#   - ENV_FILES: Which env files to scan

ENV_VAR_NAMES=("APP_URL" "BASE_URL" "API_URL" "VITE_API_URL" "NEXT_PUBLIC_API_URL")
HEALTH_PATH="/api/health"
ENV_FILES=(".env" ".env.production" ".env.staging")

# Use PROJECTS_DIR from environment (passed by slay) or default
PROJECTS_DIR="${PROJECTS_DIR:-$HOME/projects}"

if ! command -v fd &> /dev/null; then
    exit 1
fi

# Find all .env files
for env_file in "${ENV_FILES[@]}"; do
    fd -H "^${env_file}$" "$PROJECTS_DIR" --type f 2>/dev/null | while read -r file; do
        url=""

        # Try each env var name
        for var_name in "${ENV_VAR_NAMES[@]}"; do
            # Look for: VAR_NAME=url pattern
            url=$(grep -E "^${var_name}=" "$file" 2>/dev/null | head -1 | sed 's/.*=//' | tr -d '"' | tr -d "'")
            [ -n "$url" ] && break
        done

        # Skip if no URL found
        [ -z "$url" ] && continue

        # Skip if URL doesn't look like a URL
        echo "$url" | grep -qE "^https?://" || continue

        # Skip localhost URLs
        echo "$url" | grep -qE "localhost|127\.0\.0\.1" && continue

        # Extract project group (first directory under PROJECTS_DIR)
        project_group=$(echo "$file" | sed "s|$PROJECTS_DIR/||" | cut -d'/' -f1)

        # Check if URL already has a path, if not append health path
        if echo "$url" | grep -qE "^https?://[^/]+$"; then
            url="${url}${HEALTH_PATH}"
        fi

        # Output: project_group|url
        echo "${project_group}|${url}"
    done
done | sort -u
