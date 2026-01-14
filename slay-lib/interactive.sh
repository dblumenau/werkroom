#!/usr/bin/env bash
# slay-lib/interactive.sh - Interactive project picker state machine

# Requires globals: PROJECTS_DIR, CACHE_FILE, HAS_GUM, DEMO_MODE, WATCH_CANCELLED,
#                   URL, TARGET_VERSION, INITIAL_VERSION, CUSTOM_MESSAGE
# Uses functions from: messages.sh, project-cache.sh, git-sync.sh, actions.sh

# URL cache file for remembering health endpoints per project
URL_CACHE_FILE="$HOME/.cache/slay-urls"

# Discover ALL URLs for a project using the configured discovery script
# Returns newline-separated URLs if found, empty string if not
discover_urls() {
    local group="$1"

    # Check if discovery script is configured and exists
    if [ -z "$URL_DISCOVERY_SCRIPT" ]; then
        return
    fi

    # Expand variables in the path
    local script_path
    script_path=$(eval echo "$URL_DISCOVERY_SCRIPT")

    if [ ! -x "$script_path" ]; then
        return
    fi

    # Run discovery script and find ALL URLs for this project group
    # Script outputs: project_group|url (one per line)
    PROJECTS_DIR="$PROJECTS_DIR" "$script_path" 2>/dev/null | \
        grep "^${group}|" | cut -d'|' -f2
}

# Legacy single-URL discover (for backwards compatibility)
discover_url() {
    discover_urls "$1" | head -1
}

# Unified service picker for composer/npm/schedule actions
# Usage: select_service_for_action <title> <subtitle> <discovery_fn> <customer>
# Sets: _selected_service, _selected_service_path (use immediately after call)
# Returns: 0 on selection, 1 on back/cancel
select_service_for_action() {
    local title="$1"
    local subtitle="$2"
    local discovery_fn="$3"
    local customer="$4"

    clear
    echo ""
    gum style --foreground 212 --bold "✨ $title ✨"
    gum style --foreground 82 "Selected: $customer"
    gum style --foreground 250 "$subtitle"
    echo ""

    local services
    services=$($discovery_fn "$customer")

    local service_list="${services}
← Back"

    local filter_height=$(( $(tput lines) - 8 ))
    [ "$filter_height" -lt 10 ] && filter_height=10

    _selected_service=$(echo "$service_list" | gum filter --placeholder "Search projects..." --indicator.foreground="212" --match.foreground="212" --height="$filter_height")

    if [ -z "$_selected_service" ] || [[ "$_selected_service" == "← Back"* ]]; then
        return 1
    fi

    _selected_service_path="$PROJECTS_DIR/$customer/$_selected_service"
    return 0
}

# Get cached URL for a project group
get_cached_url() {
    local group="$1"
    if [ -f "$URL_CACHE_FILE" ]; then
        grep "^${group}|" "$URL_CACHE_FILE" | cut -d'|' -f2 | head -1
    fi
}

# Save URL to cache for a project group
save_url_to_cache() {
    local group="$1"
    local url="$2"

    mkdir -p "$(dirname "$URL_CACHE_FILE")"

    # Remove existing entry for this group, add new one
    if [ -f "$URL_CACHE_FILE" ]; then
        grep -v "^${group}|" "$URL_CACHE_FILE" > "${URL_CACHE_FILE}.tmp" 2>/dev/null || true
        mv "${URL_CACHE_FILE}.tmp" "$URL_CACHE_FILE"
    fi
    echo "${group}|${url}" >> "$URL_CACHE_FILE"
}

select_project() {
    if ! command -v gum &> /dev/null; then
        echo "Interactive mode requires gum - run: brew install gum" >&2
        echo "Or provide URL and version directly: slay <url> <version>" >&2
        exit 1
    fi

    # Ensure cache exists
    get_projects > /dev/null

    if [ ! -f "$CACHE_FILE" ] || [ ! -s "$CACHE_FILE" ]; then
        gum style --foreground 196 "No projects found in $PROJECTS_DIR"
        exit 1
    fi

    # State machine for navigation
    local state="select_customer"
    local selected_customer selected_service selected_service_path selected_url
    local current_version watch_mode action_choice

    while true; do
        case "$state" in
            select_customer)
                clear
                echo ""
                gum style --foreground 212 --bold "✨ SLAY ✨"
                gum style --foreground 250 "$(random_greeting)"
                echo ""

                # Build project group list
                local customer_list
                customer_list=$(get_customer_groups)

                # Add demo entry
                customer_list="${customer_list}
⚡ demo"

                # Dynamic height
                local filter_height=$(( $(tput lines) - 6 ))
                [ "$filter_height" -lt 10 ] && filter_height=10

                selected_customer=$(echo "$customer_list" | gum filter --placeholder "Search projects... (ESC to exit)" --indicator.foreground="212" --match.foreground="212" --height="$filter_height")

                if [ -z "$selected_customer" ]; then
                    gum style --foreground 214 "Exiting..."
                    exit 0
                fi

                # Check for demo mode
                if [[ "$selected_customer" == *"⚡"* ]]; then
                    DEMO_MODE=true
                    state="demo_run"
                    continue
                fi

                state="choose_action"
                ;;

            choose_action)
                clear
                echo ""
                gum style --foreground 212 --bold "✨ SLAY ✨"
                gum style --foreground 82 "Selected: $selected_customer"
                echo ""

                action_choice=$(gum choose --cursor.foreground="212" --selected.foreground="212" \
                    "Watch for new tag" \
                    "Sync to master" \
                    "Composer install" \
                    "npm install" \
                    "Run schedule" \
                    "Open in VSCode" \
                    "Open in PhpStorm" \
                    "← Back")

                if [ -z "$action_choice" ] || [[ "$action_choice" == "← Back"* ]]; then
                    state="select_customer"
                    continue
                fi

                case "$action_choice" in
                    "Watch for new tag")
                        state="enter_url"
                        ;;
                    "Sync to master")
                        local services
                        services=$(get_git_repos_for_customer "$selected_customer")
                        local service_count=$(echo "$services" | wc -l | tr -d ' ')

                        if [ "$service_count" -eq 1 ]; then
                            selected_service="$services"
                            selected_service_path="$PROJECTS_DIR/$selected_customer/$selected_service"
                            state="sync_to_master"
                        else
                            state="select_service_for_sync"
                        fi
                        ;;
                    "Open in VSCode")
                        run_editor_scope "$selected_customer" "code" "VSCode"
                        state="choose_action"
                        ;;
                    "Open in PhpStorm")
                        # macOS uses 'open -a', Linux uses direct command
                        if [[ "$OSTYPE" == darwin* ]]; then
                            run_editor_scope "$selected_customer" "open -a PhpStorm" "PhpStorm"
                        else
                            run_editor_scope "$selected_customer" "phpstorm" "PhpStorm"
                        fi
                        state="choose_action"
                        ;;
                    "Composer install")
                        local services
                        services=$(get_composer_projects_for_customer "$selected_customer")
                        local service_count=$(echo "$services" | wc -l | tr -d ' ')

                        if [ -z "$services" ]; then
                            gum style --foreground 196 "No composer.json found in any $selected_customer projects"
                            sleep 1.5
                            continue
                        elif [ "$service_count" -eq 1 ]; then
                            selected_service="$services"
                            selected_service_path="$PROJECTS_DIR/$selected_customer/$selected_service"
                            state="run_command"
                        else
                            state="select_service_for_composer"
                        fi
                        ;;
                    "npm install")
                        local services
                        services=$(get_npm_projects_for_customer "$selected_customer")
                        local service_count=$(echo "$services" | wc -l | tr -d ' ')

                        if [ -z "$services" ]; then
                            gum style --foreground 196 "No package.json found in any $selected_customer projects"
                            sleep 1.5
                            continue
                        elif [ "$service_count" -eq 1 ]; then
                            selected_service="$services"
                            selected_service_path="$PROJECTS_DIR/$selected_customer/$selected_service"
                            state="run_command"
                        else
                            state="select_service_for_npm"
                        fi
                        ;;
                    "Run schedule")
                        local services
                        services=$(get_artisan_projects_for_customer "$selected_customer")
                        local service_count=$(echo "$services" | wc -l | tr -d ' ')

                        if [ -z "$services" ]; then
                            gum style --foreground 196 "No artisan file found in any $selected_customer projects"
                            sleep 1.5
                            continue
                        elif [ "$service_count" -eq 1 ]; then
                            selected_service="$services"
                            selected_service_path="$PROJECTS_DIR/$selected_customer/$selected_service"
                            state="run_schedule"
                        else
                            state="select_service_for_schedule"
                        fi
                        ;;
                esac
                ;;

            enter_url)
                clear
                echo ""
                gum style --foreground 212 --bold "✨ WATCH FOR NEW TAG ✨"
                gum style --foreground 82 "Project: $selected_customer"
                echo ""

                # Try to discover URLs via plugin, then check cache
                local discovered_urls discovered_url cached_url url_count
                discovered_urls=$(discover_urls "$selected_customer")
                url_count=$(echo "$discovered_urls" | grep -c . 2>/dev/null || echo 0)
                cached_url=$(get_cached_url "$selected_customer")

                # Multiple discovered URLs - show picker
                if [ "$url_count" -gt 1 ]; then
                    gum style --foreground 250 "Found $url_count endpoints for $selected_customer:"
                    echo ""

                    # Build list with friendly names (extract subdomain from URL)
                    local url_list=""
                    while IFS= read -r url; do
                        [ -z "$url" ] && continue
                        # Extract meaningful name from URL (e.g., myapp-staging from https://myapp-staging.example.com/healthz)
                        local friendly_name
                        friendly_name=$(echo "$url" | sed 's|https\?://||' | cut -d'.' -f1)
                        url_list+="${friendly_name}|${url}"$'\n'
                    done <<< "$discovered_urls"

                    # Add options
                    url_list+="Enter different URL|__MANUAL__"$'\n'
                    url_list+="← Back|__BACK__"

                    local filter_height=$(( $(tput lines) - 10 ))
                    [ "$filter_height" -lt 10 ] && filter_height=10

                    local selected_entry
                    selected_entry=$(echo "$url_list" | cut -d'|' -f1 | gum filter --placeholder "Search endpoints..." --indicator.foreground="212" --match.foreground="212" --height="$filter_height")

                    if [ -z "$selected_entry" ] || [ "$selected_entry" = "← Back" ]; then
                        state="choose_action"
                        continue
                    fi

                    if [ "$selected_entry" = "Enter different URL" ]; then
                        # Fall through to manual URL input below
                        :
                    else
                        # Find the URL for the selected entry
                        discovered_url=$(echo "$url_list" | grep "^${selected_entry}|" | cut -d'|' -f2)
                        URL="$discovered_url"
                        save_url_to_cache "$selected_customer" "$URL"
                        state="fetch_version"
                        continue
                    fi
                # Single discovered URL - show it with options
                elif [ "$url_count" -eq 1 ] && [ -n "$discovered_urls" ]; then
                    discovered_url="$discovered_urls"
                    local has_options=true
                    gum style --foreground 250 "Auto-discovered endpoint:"
                    gum style --border rounded --border-foreground 212 --padding "0 2" --foreground 82 "🔗 $discovered_url"
                    echo ""

                    if [ -n "$cached_url" ] && [ "$cached_url" != "$discovered_url" ]; then
                        gum style --foreground 250 "Previously used:"
                        gum style --border rounded --border-foreground 240 --padding "0 2" --foreground 51 "🔗 $cached_url"
                        echo ""
                    fi

                    # Build choice menu dynamically
                    local choices=()
                    choices+=("Use discovered URL")
                    [ -n "$cached_url" ] && [ "$cached_url" != "$discovered_url" ] && choices+=("Use cached URL")
                    choices+=("Enter different URL" "← Back")

                    local url_choice
                    url_choice=$(printf '%s\n' "${choices[@]}" | gum choose --cursor.foreground="212" --selected.foreground="212")

                    case "$url_choice" in
                        "Use discovered URL")
                            URL="$discovered_url"
                            save_url_to_cache "$selected_customer" "$URL"
                            state="fetch_version"
                            continue
                            ;;
                        "Use cached URL")
                            URL="$cached_url"
                            state="fetch_version"
                            continue
                            ;;
                        "Enter different URL")
                            # Fall through to URL input below
                            ;;
                        *)
                            state="choose_action"
                            continue
                            ;;
                    esac
                # No discovered URLs - check cache only
                elif [ -n "$cached_url" ]; then
                    gum style --foreground 250 "Previously used:"
                    gum style --border rounded --border-foreground 240 --padding "0 2" --foreground 51 "🔗 $cached_url"
                    echo ""

                    local url_choice
                    url_choice=$(printf '%s\n' "Use cached URL" "Enter different URL" "← Back" | gum choose --cursor.foreground="212" --selected.foreground="212")

                    case "$url_choice" in
                        "Use cached URL")
                            URL="$cached_url"
                            state="fetch_version"
                            continue
                            ;;
                        "Enter different URL")
                            # Fall through to URL input below
                            ;;
                        *)
                            state="choose_action"
                            continue
                            ;;
                    esac
                fi

                echo ""
                local new_url
                new_url=$(gum input --placeholder "https://example.com/healthz" \
                    --cursor.foreground="212" --prompt.foreground="212" \
                    --prompt "Health endpoint URL: ")

                if [ -z "$new_url" ]; then
                    state="choose_action"
                    continue
                fi

                URL="$new_url"
                save_url_to_cache "$selected_customer" "$URL"
                state="fetch_version"
                ;;

            select_service_for_composer)
                if select_service_for_action "COMPOSER INSTALL" "Which project needs dependencies?" get_composer_projects_for_customer "$selected_customer"; then
                    selected_service="$_selected_service"
                    selected_service_path="$_selected_service_path"
                    state="run_command"
                else
                    state="choose_action"
                fi
                ;;

            select_service_for_npm)
                if select_service_for_action "NPM INSTALL" "Which project needs dependencies?" get_npm_projects_for_customer "$selected_customer"; then
                    selected_service="$_selected_service"
                    selected_service_path="$_selected_service_path"
                    state="run_command"
                else
                    state="choose_action"
                fi
                ;;

            select_service_for_schedule)
                if select_service_for_action "ARTISAN SCHEDULE" "Which Laravel project needs a schedule run?" get_artisan_projects_for_customer "$selected_customer"; then
                    selected_service="$_selected_service"
                    selected_service_path="$_selected_service_path"
                    state="run_schedule"
                else
                    state="choose_action"
                fi
                ;;

            select_service_for_sync)
                clear
                echo ""
                gum style --foreground 212 --bold "✨ SYNC TO MASTER ✨"
                gum style --foreground 82 "Selected: $selected_customer"
                gum style --foreground 250 "Which repo needs rescuing?"
                echo ""

                local services
                services=$(get_git_repos_for_customer "$selected_customer")

                local service_list="${services}
← Back"

                # Dynamic height like project picker
                local filter_height=$(( $(tput lines) - 8 ))
                [ "$filter_height" -lt 10 ] && filter_height=10

                selected_service=$(echo "$service_list" | gum filter --placeholder "Search repos..." --indicator.foreground="212" --match.foreground="212" --height="$filter_height")

                if [ -z "$selected_service" ] || [[ "$selected_service" == "← Back"* ]]; then
                    state="choose_action"
                    continue
                fi

                selected_service_path="$PROJECTS_DIR/$selected_customer/$selected_service"

                state="sync_to_master"
                ;;

            sync_to_master)
                run_sync_to_master
                state="choose_action"
                ;;

            fetch_version)
                echo ""
                # Extract hostname from URL for display
                local display_name
                display_name=$(echo "$URL" | sed 's|https\?://||' | cut -d'/' -f1)

                gum style --foreground 82 "Selected: $display_name"
                echo ""
                gum style --border rounded --border-foreground 212 --padding "0 2" --foreground 250 "🔗 $URL"

                gum spin --spinner "$(random_spinner)" --spinner.foreground="212" --title "Fetching current version..." -- sleep 0.3
                current_version=$(curl -s "$URL" | grep -o '"version":"[^"]*"' | cut -d'"' -f4)

                if [ -z "$current_version" ]; then
                    gum style --foreground 196 "Could not fetch current version from $URL"
                    gum style --foreground 214 "Press Enter to go back..."
                    read -r
                    state="enter_url"
                    continue
                fi

                state="choose_mode"
                ;;

            choose_mode)
                echo ""
                gum style --foreground 250 "Currently deployed: $(gum style --foreground 51 --bold "v$current_version")"
                echo ""

                watch_mode=$(gum choose --cursor.foreground="212" --selected.foreground="212" \
                    "When version changes (any new version)" \
                    "When specific version deploys" \
                    "← Back")

                if [ -z "$watch_mode" ] || [[ "$watch_mode" == "← Back"* ]]; then
                    state="enter_url"
                    continue
                fi

                # Extract hostname for message
                local display_name
                display_name=$(echo "$URL" | sed 's|https\?://||' | cut -d'/' -f1)

                if [[ "$watch_mode" == "When version changes"* ]]; then
                    TARGET_VERSION="__ANY_CHANGE__"
                    INITIAL_VERSION="$current_version"
                    CUSTOM_MESSAGE="$display_name changed from v$current_version"
                    return 0
                else
                    state="enter_version"
                fi
                ;;

            enter_version)
                echo ""
                TARGET_VERSION=$(gum input --placeholder "Version to watch for, or ESC to go back" --cursor.foreground="212" --prompt.foreground="212" --prompt "Target version: ")

                if [ -z "$TARGET_VERSION" ]; then
                    state="choose_mode"
                    continue
                fi

                if [ "$TARGET_VERSION" = "$current_version" ]; then
                    gum style --foreground 82 --bold "That version is already live! Nothing to watch for."
                    sleep 1.5
                    state="choose_mode"
                    continue
                fi

                state="enter_message"
                ;;

            enter_message)
                echo ""
                CUSTOM_MESSAGE=$(gum input --placeholder "Custom message (optional, Enter to skip, ESC to go back)" --cursor.foreground="212" --prompt.foreground="212" --prompt "Message: ")

                # ESC returns empty string, but so does just pressing Enter
                # We'll treat empty as "skip" and move forward
                if [ -z "$CUSTOM_MESSAGE" ]; then
                    local display_name
                    display_name=$(echo "$URL" | sed 's|https\?://||' | cut -d'/' -f1)
                    CUSTOM_MESSAGE="$display_name deployed v$TARGET_VERSION"
                fi

                return 0
                ;;

            run_command)
                run_project_command "$action_choice" "$selected_customer" "$selected_service" "$selected_service_path"
                state="choose_action"
                ;;

            run_schedule)
                run_schedule_command "$selected_customer" "$selected_service" "$selected_service_path"
                state="choose_action"
                ;;

            demo_run)
                run_demo_mode
                state="select_customer"
                ;;
        esac
    done
}
