#!/usr/bin/env bash
# slay-lib/git-sync.sh - Sync to master/main workflow

# Requires: selected_customer, selected_service, selected_service_path (from interactive state)
# Uses: random_spinner(), random_rogue_branch_sass() from messages.sh

# Run the sync to master workflow
# Returns the next state via echo
run_sync_to_master() {
    local git_root="$selected_service_path"
    local display_path="${git_root/#$HOME/~}"
    display_path="${display_path/#~\/projects\//}"

    clear
    echo ""
    gum style --foreground 212 --bold "✨ SYNC TO MASTER ✨"
    gum style --foreground 82 "Project: $selected_customer / $selected_service"
    echo ""
    gum style --border rounded --border-foreground 250 --padding "0 2" --foreground 250 "📁 $display_path"
    echo ""

    # Fetch all (no spinner - git may prompt for credentials)
    gum style --foreground 212 "Fetching all the tea from remote..."
    git -C "$git_root" fetch --all --quiet
    gum style --foreground 82 "✓ Fetched"

    # Detect main branch name (master vs main)
    local main_branch="master"
    if git -C "$git_root" show-ref --verify --quiet refs/heads/main; then
        main_branch="main"
    fi

    # Get current branch
    local current_branch
    current_branch=$(git -C "$git_root" branch --show-current)

    if [ "$current_branch" != "$main_branch" ]; then
        # On a rogue branch - serve the drama
        echo ""
        gum style --foreground 214 --bold "Girl... you're on '$current_branch'"
        gum style --foreground 250 --italic "$(random_rogue_branch_sass)"
        echo ""

        # Check for uncommitted changes
        local has_changes=false
        if ! git -C "$git_root" diff --quiet 2>/dev/null || ! git -C "$git_root" diff --cached --quiet 2>/dev/null; then
            has_changes=true
            gum style --foreground 214 "You have uncommitted changes that need stashing."
            echo ""
        fi

        # Offer options based on whether there are changes
        local sync_choice
        if [ "$has_changes" = true ]; then
            sync_choice=$(gum choose --cursor.foreground="212" --selected.foreground="212" \
                "Stash everything and switch to $main_branch" \
                "← Back")
        else
            sync_choice=$(gum choose --cursor.foreground="212" --selected.foreground="212" \
                "Switch to $main_branch" \
                "← Back")
        fi

        if [ -z "$sync_choice" ] || [[ "$sync_choice" == "← Back"* ]]; then
            return
        fi

        if [[ "$sync_choice" == "Stash"* ]]; then
            # Get custom stash message
            local default_msg="WIP on $current_branch before hotfix $(date +%Y-%m-%d)"
            local stash_msg
            stash_msg=$(gum input --placeholder "$default_msg" --value "$default_msg" \
                --cursor.foreground="212" --prompt.foreground="212" --prompt "Stash message: ")

            if [ -z "$stash_msg" ]; then
                stash_msg="$default_msg"
            fi

            echo ""
            gum spin --spinner "$(random_spinner)" --spinner.foreground="212" --title "Stashing your future self's work..." -- \
                git -C "$git_root" stash push -m "$stash_msg"
            gum style --foreground 82 "✓ Stashed: $stash_msg"
        fi

        # Switch to master/main
        echo ""
        gum spin --spinner "$(random_spinner)" --spinner.foreground="212" --title "Switching to $main_branch..." -- \
            git -C "$git_root" checkout "$main_branch"
        gum style --foreground 82 "✓ Now on $main_branch"
    else
        gum style --foreground 82 "Already on $main_branch ✓"
    fi

    # Check if behind origin
    echo ""
    local behind_count
    behind_count=$(git -C "$git_root" rev-list --count HEAD..origin/$main_branch 2>/dev/null || echo "0")

    if [ "$behind_count" -gt 0 ]; then
        if [ "$behind_count" -gt 5 ]; then
            gum style --foreground 196 --bold "You're $behind_count commit(s) behind origin/$main_branch"
            gum style --foreground 250 --italic "$(random_very_behind_sass)"
        else
            gum style --foreground 214 "You're $behind_count commit(s) behind origin/$main_branch"
        fi
        echo ""

        local pull_choice
        pull_choice=$(gum choose --cursor.foreground="212" --selected.foreground="212" \
            "Pull latest" \
            "Skip pull")

        if [[ "$pull_choice" == "Pull"* ]]; then
            echo ""
            gum spin --spinner "$(random_spinner)" --spinner.foreground="212" --title "Pulling the latest looks..." -- \
                git -C "$git_root" pull
            gum style --foreground 82 "✓ Updated to latest $main_branch"
        fi
    else
        gum style --foreground 82 "✓ Already up to date with origin/$main_branch"
    fi

    echo ""
    gum style --foreground 212 --bold "$(random_hotfix_ready)"
    sleep 1.5
}
