#!/usr/bin/env bash
# slay-lib/watch-loop.sh - Core polling and notification logic

# Requires globals: URL, TARGET_VERSION, INTERVAL, TIMEOUT_SECONDS, START_TIME,
#                   INITIAL_VERSION, CUSTOM_MESSAGE, INTERACTIVE_MODE, WATCH_CANCELLED,
#                   HAS_GUM, R, B, DIM, PINK, CYAN, YELLOW, GREEN, RED, WHITE, GRAY

check_timeout() {
    ELAPSED="$(( $(date +%s) - START_TIME ))"
    REMAINING="$(( (TIMEOUT_SECONDS - ELAPSED) / 60 ))"
    if [ "$ELAPSED" -ge "$TIMEOUT_SECONDS" ]; then
        echo ""
        if [ "$HAS_GUM" = true ]; then
            slay_error "TIMEOUT - 10 minutes elapsed, exiting to prevent zombie 💀"
        else
            echo -e "${RED}${B}TIMEOUT${R} - 10 minutes elapsed, exiting to prevent zombie 💀"
        fi
        exit 1
    fi
}

get_version() {
    curl -s "$URL" | grep -o '"version":"[^"]*"' | cut -d'"' -f4
}

animated_sleep() {
    local duration=$1
    local elapsed="$(( $(date +%s) - START_TIME ))"
    local message spinner color

    # Escalating energy based on elapsed time (random spinner, escalating color)
    spinner="$(random_spinner)"
    if [ "$elapsed" -lt 30 ]; then
        message="$(get_random_chill)"
        color="212"  # pink
    elif [ "$elapsed" -lt 90 ]; then
        message="$(get_random_antsy)"
        color="214"  # orange
    else
        message="$(get_random_unhinged)"
        color="196"  # red
    fi

    if [ "$HAS_GUM" = true ]; then
        gum spin --spinner "$spinner" --spinner.foreground="$color" --title "$message" -- sleep "$duration"
    else
        echo -e "${DIM}$message${R}"
        sleep "$duration"
    fi
}

animated_verify() {
    local duration=$1
    local message=$2
    if [ "$HAS_GUM" = true ]; then
        gum spin --spinner pulse --spinner.foreground="212" --title "$message" -- sleep "$duration"
    else
        echo -e "${YELLOW}$message${R}"
        sleep "$duration"
    fi
}

show_status() {
    local current=$1
    local target=$2
    local elapsed="$(( $(date +%s) - START_TIME ))"
    local mins="$(( elapsed / 60 ))"
    local secs="$(( elapsed % 60 ))"

    # Display friendly target for "any change" mode
    local display_target="$target"
    if [ "$target" = "__ANY_CHANGE__" ]; then
        display_target="≠ v$INITIAL_VERSION"
    fi

    if [ "$HAS_GUM" = true ]; then
        slay_status_line "$(date +%H:%M:%S)" "$current" "$display_target" "${mins}m ${secs}s"
    else
        echo -e "${GRAY}$(date +%H:%M:%S)${R} - Current: ${CYAN}$current${R} | Waiting for: ${YELLOW}$display_target${R}"
    fi
}

celebrate() {
    echo ""
    if [ "$HAS_GUM" = true ]; then
        slay_celebrate \
            "✨ SHE'S HERE ✨" \
            "" \
            "v$TARGET_VERSION is LIVE and STABLE" \
            "" \
            "💅 go test, queen 💅"
    else
        echo -e "${PINK}${B}✨ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✨${R}"
        echo -e "${PINK}${B}     SHE'S HERE - v$TARGET_VERSION is LIVE!     ${R}"
        echo -e "${PINK}${B}✨ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✨${R}"
    fi
    echo ""
}

run_watch_loop() {
    # Initialize wait messages now that TARGET_VERSION is set
    init_wait_messages

    # Header - display friendly target for "any change" mode
    DISPLAY_TARGET="v$TARGET_VERSION"
    if [ "$TARGET_VERSION" = "__ANY_CHANGE__" ]; then
        DISPLAY_TARGET="any change from v$INITIAL_VERSION"
    fi

    local cancel_hint="Ctrl+C to cancel"
    if [ "$INTERACTIVE_MODE" = true ]; then
        cancel_hint="Ctrl+C to go back"
    fi

    echo ""
    if [ "$HAS_GUM" = true ]; then
        slay_header "SLAY"
        slay_kv "Watching:" "$URL" "$COLOR_SUCCESS"
        slay_kv "Target:  " "$DISPLAY_TARGET" "$COLOR_WARNING"
        slay_dim "Interval: ${INTERVAL}s │ Timeout: 10 min │ $cancel_hint"
    else
        echo -e "${PINK}${B}✨ SLAY ✨${R}"
        echo -e "Watching ${GREEN}$URL${R} for ${YELLOW}$DISPLAY_TARGET${R}"
        echo -e "${DIM}Interval: ${INTERVAL}s | Timeout: 10 min | $cancel_hint${R}"
    fi
    echo ""

    while true; do
        # Check if cancelled by Ctrl+C
        if [ "$WATCH_CANCELLED" = true ]; then
            return 1
        fi

        check_timeout
        VERSION="$(get_version)"

        if [ -z "$VERSION" ]; then
            if [ "$HAS_GUM" = true ]; then
                echo "$(gum style --foreground "$COLOR_DIM" "$(date +%H:%M:%S)") $(gum style --foreground "$COLOR_ERROR" "Failed to fetch version (endpoint down?)")"
            else
                echo -e "${RED}$(date +%H:%M:%S)${R} - ${RED}Failed to fetch version (endpoint down?)${R}"
            fi
        else
            show_status "$VERSION" "$TARGET_VERSION"

            # Check for match - either specific version OR any change from initial
            version_matched=false
            if [ "$TARGET_VERSION" = "__ANY_CHANGE__" ]; then
                # Any change mode - check if different from initial
                if [ "$VERSION" != "$INITIAL_VERSION" ]; then
                    version_matched=true
                    CUSTOM_MESSAGE="${CUSTOM_MESSAGE} → v$VERSION"
                fi
            elif [ "$VERSION" = "$TARGET_VERSION" ]; then
                version_matched=true
            fi

            if [ "$version_matched" = true ]; then
                VERIFY_MSG="$(get_random_verify)"

                # Verify the version is stable (not mid-deploy flicker)
                while true; do
                    # Check if cancelled
                    if [ "$WATCH_CANCELLED" = true ]; then
                        return 1
                    fi

                    check_timeout
                    animated_verify 3 "$VERIFY_MSG"
                    VERIFY_VERSION="$(get_version)"

                    verify_matched=false
                    if [ "$TARGET_VERSION" = "__ANY_CHANGE__" ]; then
                        [ "$VERIFY_VERSION" != "$INITIAL_VERSION" ] && verify_matched=true
                    else
                        [ "$VERIFY_VERSION" = "$TARGET_VERSION" ] && verify_matched=true
                    fi

                    if [ "$verify_matched" = true ]; then
                        # Update TARGET_VERSION for celebrate display
                        [ "$TARGET_VERSION" = "__ANY_CHANGE__" ] && TARGET_VERSION="$VERIFY_VERSION"
                        celebrate
                        # Send notification if notify-watch is available (optional for WSL compatibility)
                        if command -v notify-watch &> /dev/null; then
                            notify-watch -e "$CUSTOM_MESSAGE" "Deployed"
                        fi
                        return 0
                    else
                        if [ "$HAS_GUM" = true ]; then
                            echo "$(gum style --foreground "$COLOR_DIM" "$(date +%H:%M:%S)") $(gum style --foreground "$COLOR_WARNING" "Oops, she flickered! Back to watching...")"
                        else
                            echo -e "${YELLOW}$(date +%H:%M:%S)${R} - ${YELLOW}Oops, she flickered! Back to watching...${R}"
                        fi
                        break
                    fi
                done
            fi
        fi

        animated_sleep "$INTERVAL"

        # Check again after sleep (Ctrl+C during sleep sets flag)
        if [ "$WATCH_CANCELLED" = true ]; then
            return 1
        fi
    done
}
