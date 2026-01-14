#!/usr/bin/env bash
# slay-lib/actions.sh - Action helper functions for interactive mode

# Requires globals: PROJECTS_DIR, DEMO_MODE, WATCH_CANCELLED, TARGET_VERSION
# Uses functions from: messages.sh, project-cache.sh

# Demo mode runner
run_demo_mode() {
    clear
    echo ""
    gum style --foreground 212 --bold "✨ DEMO MODE ✨"
    gum style --foreground 250 "Showcasing all three spinner phases..."
    gum style --foreground 250 --italic "Ctrl+C to go back"
    echo ""

    # Initialize wait messages for demo
    TARGET_VERSION="demo"
    init_wait_messages

    # Phase 1: Chill (pink, 5 seconds)
    gum style --foreground 212 --bold "Phase 1: Chill vibes (0-30s normally)"
    for i in 1 2 3 4 5; do
        [ "$WATCH_CANCELLED" = true ] && return 1
        local spinner="$(random_spinner)"
        gum spin --spinner "$spinner" --spinner.foreground="212" --title "$(get_random_chill)" -- sleep 1
    done

    echo ""
    # Phase 2: Antsy (orange, 5 seconds)
    gum style --foreground 214 --bold "Phase 2: Getting antsy (30-90s normally)"
    for i in 1 2 3 4 5; do
        [ "$WATCH_CANCELLED" = true ] && return 1
        local spinner="$(random_spinner)"
        gum spin --spinner "$spinner" --spinner.foreground="214" --title "$(get_random_antsy)" -- sleep 1
    done

    echo ""
    # Phase 3: Unhinged (red, 5 seconds)
    gum style --foreground 196 --bold "Phase 3: UNHINGED (90s+ normally)"
    for i in 1 2 3 4 5; do
        [ "$WATCH_CANCELLED" = true ] && return 1
        local spinner="$(random_spinner)"
        gum spin --spinner "$spinner" --spinner.foreground="196" --title "$(get_random_unhinged)" -- sleep 1
    done

    echo ""
    gum style --foreground 212 --bold --border double --border-foreground 212 --padding "1 3" --align center \
        "✨ DEMO COMPLETE ✨" \
        "" \
        "Now go impress someone"

    sleep 2
    return 0
}

# Editor scope picker (VSCode, PhpStorm, etc.)
run_editor_scope() {
    local selected_customer="$1"
    local editor_cmd="$2"
    local editor_name="$3"

    clear
    echo ""
    gum style --foreground 212 --bold "✨ OPEN IN $(echo "$editor_name" | tr '[:lower:]' '[:upper:]') ✨"
    gum style --foreground 82 "Selected: $selected_customer"
    gum style --foreground 250 "What to open?"
    echo ""

    # Get services for choice (use git repos for complete list)
    local services
    services=$(get_git_repos_for_customer "$selected_customer")

    # Build options: customer root + each service
    local options="📁 $selected_customer (project root)"
    while IFS= read -r svc; do
        options="${options}
📁 $selected_customer/$svc"
    done <<< "$services"
    options="${options}
← Back"

    local scope_choice
    scope_choice=$(echo "$options" | gum choose --cursor.foreground="212" --selected.foreground="212")

    if [ -z "$scope_choice" ] || [[ "$scope_choice" == "← Back"* ]]; then
        return 1
    fi

    local target_path
    if [[ "$scope_choice" == *"(project root)"* ]]; then
        target_path="$PROJECTS_DIR/$selected_customer"
    else
        local selected_service=$(echo "$scope_choice" | sed "s|📁 $selected_customer/||")
        target_path="$PROJECTS_DIR/$selected_customer/$selected_service"
    fi

    # Use eval to handle multi-word commands like "open -a PhpStorm"
    eval $editor_cmd '"$target_path"'

    gum style --foreground 82 "✓ Opened in $editor_name!"
    sleep 0.5
    return 0
}

# Run artisan schedule in background with notification
run_schedule_command() {
    local selected_customer="$1"
    local selected_service="$2"
    local selected_service_path="$3"

    clear
    echo ""
    gum style --foreground 212 --bold "✨ ARTISAN SCHEDULE ✨"
    local display_path="${selected_service_path/#$HOME/~}"
    display_path="${display_path/#~\/projects\//}"
    gum style --border rounded --border-foreground 250 --padding "0 2" --foreground 250 "📁 $display_path"

    # Check for .envrc - required for correct PHP version
    if [ ! -f "$selected_service_path/.envrc" ]; then
        echo ""
        gum style --foreground 196 --bold "⚠️  No .envrc found"
        gum style --foreground 214 "This project is missing its .envrc file."
        gum style --foreground 214 "PHP needs to know what version she's wearing today."
        gum style --foreground 250 --italic "Set up your .envrc first, bestie."
        echo ""
        gum style --foreground 250 "Press Enter to go back..."
        read -r
        return 1
    fi

    # Build a friendly project name for the notification
    local project_name="$selected_customer"
    if [ -n "$selected_service" ]; then
        project_name="$selected_customer/$selected_service"
    fi

    echo ""
    gum style --foreground 214 "Running schedule:run in background..."
    gum style --foreground 250 --italic "You'll get a ping when she's done 💅"
    echo ""

    # Run in background: source envrc, run schedule, then notify
    # Redirect all output to /dev/null so it doesn't pollute the UI
    (
        cd "$selected_service_path" && \
        source .envrc 2>/dev/null && \
        php artisan schedule:run && \
        ~/.claude/bin/notify-watch "Schedule complete: $project_name" "Slay"
    ) > /dev/null 2>&1 &

    gum style --foreground 82 "✓ Kicked off! You can close this or keep slaying."
    sleep 1.5
    return 0
}

# Run command (composer/npm install)
run_project_command() {
    local action_choice="$1"
    local selected_customer="$2"
    local selected_service="$3"
    local selected_service_path="$4"

    clear
    echo ""
    gum style --foreground 212 --bold "Run command in project"
    # Show truncated path
    local display_path="${selected_service_path/#$HOME/~}"
    display_path="${display_path/#~\/projects\//}"
    gum style --border rounded --border-foreground 250 --padding "0 2" --foreground 250 "📁 $display_path"

    # Check for .envrc - required for correct PHP/Node versions
    if [ ! -f "$selected_service_path/.envrc" ]; then
        echo ""
        gum style --foreground 196 --bold "⚠️  No .envrc found"
        gum style --foreground 214 "This project is missing its .envrc file."
        gum style --foreground 214 "Set it up first or composer/npm will use whatever version feels like showing up."
        gum style --foreground 250 --italic "The Frankenstein archaeology requires proper environment setup, bestie."
        echo ""
        gum style --foreground 250 "Press Enter to go back..."
        read -r
        return 1
    fi
    echo ""

    # Execute the action that was chosen
    case "$action_choice" in
        "Composer install")
            gum style --foreground 214 "Running composer install..."
            echo ""
            (cd "$selected_service_path" && source .envrc 2>/dev/null && composer install)
            ;;
        "npm install")
            gum style --foreground 214 "Running npm install..."
            echo ""
            (cd "$selected_service_path" && source .envrc 2>/dev/null && npm install)
            echo ""
            gum style --foreground 214 "Running npm run prod..."
            echo ""
            (cd "$selected_service_path" && source .envrc 2>/dev/null && npm run prod)
            ;;
    esac

    echo ""
    gum style --foreground 82 "✓ Done!"
    sleep 1
    return 0
}
