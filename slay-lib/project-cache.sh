#!/usr/bin/env bash
# slay-lib/project-cache.sh - Project discovery and caching

# Requires globals: PROJECTS_DIR, CACHE_FILE, REFRESH_CACHE, HAS_GUM

build_project_cache() {
    # Find all git repositories in the projects directory
    if ! command -v fd &> /dev/null; then
        echo "fd not installed - run: brew install fd" >&2
        exit 1
    fi

    # Ensure cache directory exists
    mkdir -p "$(dirname "$CACHE_FILE")"

    # Find all .git directories and extract project paths
    fd -t d "^\.git$" "$PROJECTS_DIR" --hidden -E backup_projects 2>/dev/null | \
        sed 's|/\.git/?$||' | \
        sort -u > "$CACHE_FILE"
}

get_projects() {
    # Use cache if exists and not forcing refresh
    if [ "$REFRESH_CACHE" = true ] || [ ! -f "$CACHE_FILE" ]; then
        if [ "$HAS_GUM" = true ]; then
            gum spin --spinner "$(random_spinner)" --spinner.foreground="212" --title "Scanning projects..." -- bash -c "$(declare -f build_project_cache); PROJECTS_DIR=\"$PROJECTS_DIR\"; CACHE_FILE=\"$CACHE_FILE\"; build_project_cache"
        else
            echo "Scanning projects..."
            build_project_cache
        fi
    fi
    cat "$CACHE_FILE"
}

get_project_groups() {
    # Extract unique top-level directories under PROJECTS_DIR
    cat "$CACHE_FILE" | \
        sed "s|$PROJECTS_DIR/||" | \
        cut -d'/' -f1 | \
        sort -u
}

# Alias for backward compatibility
get_customer_groups() {
    get_project_groups
}

get_repos_for_group() {
    local group="$1"
    # Return all repos under a group, with paths relative to the group
    grep "^$PROJECTS_DIR/$group/" "$CACHE_FILE" | \
        sed "s|$PROJECTS_DIR/$group/||" | \
        sort -u
}

get_git_repos_for_customer() {
    local customer="$1"
    # Find all git repos under customer folder
    fd -t d "^\.git$" "$PROJECTS_DIR/$customer" --hidden 2>/dev/null | \
        sed -E 's|/\.git/?$||' | \
        sed "s|$PROJECTS_DIR/$customer/||" | \
        sort
}

get_npm_projects_for_customer() {
    local customer="$1"
    # Find all projects with package.json (for npm install)
    fd -t f "^package\.json$" "$PROJECTS_DIR/$customer" --hidden 2>/dev/null | \
        sed 's|/package\.json$||' | \
        sed "s|$PROJECTS_DIR/$customer/||" | \
        sort
}

get_composer_projects_for_customer() {
    local customer="$1"
    # Find all projects with composer.json (for composer install)
    fd -t f "^composer\.json$" "$PROJECTS_DIR/$customer" --hidden 2>/dev/null | \
        sed 's|/composer\.json$||' | \
        sed "s|$PROJECTS_DIR/$customer/||" | \
        sort
}

get_artisan_projects_for_customer() {
    local customer="$1"
    # Find all Laravel projects with artisan file (for schedule:run)
    fd -t f "^artisan$" "$PROJECTS_DIR/$customer" --hidden 2>/dev/null | \
        sed 's|/artisan$||' | \
        sed "s|$PROJECTS_DIR/$customer/||" | \
        sort
}
