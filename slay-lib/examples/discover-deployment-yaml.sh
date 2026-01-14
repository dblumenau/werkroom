#!/usr/bin/env bash
# Discovery script for Kubernetes deployment.yaml files
# Scans for deployment.yaml files with APP_URL environment variable
#
# Setup:
#   1. Copy to ~/.config/slay/discover-urls.sh
#   2. chmod +x ~/.config/slay/discover-urls.sh
#   3. Add to ~/.config/slay/config:
#      URL_DISCOVERY_SCRIPT="$HOME/.config/slay/discover-urls.sh"
#
# Customize:
#   - DOMAIN_FILTER: Only include URLs matching this pattern (optional)
#   - ENV_VAR_NAME: Change from APP_URL if your setup uses different name
#   - HEALTH_PATH: Path to append to URL (default: /healthz)

DOMAIN_FILTER=""        # e.g., "example.com" to only match that domain
ENV_VAR_NAME="APP_URL"  # The environment variable containing the URL
HEALTH_PATH="/healthz"  # Path to append for health checks

# Use PROJECTS_DIR from environment (passed by slay) or default
PROJECTS_DIR="${PROJECTS_DIR:-$HOME/projects}"

if ! command -v fd &> /dev/null; then
    exit 1
fi

fd deployment.yaml "$PROJECTS_DIR" --type f 2>/dev/null | while read -r file; do
    # Extract URL from deployment.yaml
    url=$(grep -A1 "name: $ENV_VAR_NAME" "$file" 2>/dev/null | grep "value:" | head -1 | sed 's/.*value: *"\([^"]*\)".*/\1/')

    # Skip if no URL found
    [ -z "$url" ] && continue

    # Apply domain filter if set
    if [ -n "$DOMAIN_FILTER" ]; then
        echo "$url" | grep -q "$DOMAIN_FILTER" || continue
    fi

    # Extract project group (first directory under PROJECTS_DIR)
    project_group=$(echo "$file" | sed "s|$PROJECTS_DIR/||" | cut -d'/' -f1)

    # Output: project_group|url
    echo "${project_group}|${url}${HEALTH_PATH}"
done | sort -u
