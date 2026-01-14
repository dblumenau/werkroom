#!/usr/bin/env bash
# slay-lib/check-deps.sh - Dependency validation

# Requires: TEST_DEPS_MODE (global flag for testing)

check_dependencies() {
    local missing=()
    local install_cmds=()

    # Test mode - pretend everything is missing for demo purposes
    if [ "$TEST_DEPS_MODE" = true ]; then
        missing=("gum" "fd" "curl")
        install_cmds=(
            "  brew install gum  OR  apt install gum"
            "  brew install fd   OR  apt install fd-find"
            "  brew install curl OR  apt install curl"
        )
    else
        if ! command -v gum &> /dev/null; then
            missing+=("gum")
            install_cmds+=("  brew install gum  OR  apt install gum")
        fi
        if ! command -v fd &> /dev/null; then
            missing+=("fd")
            install_cmds+=("  brew install fd   OR  apt install fd-find")
        fi
        if ! command -v curl &> /dev/null; then
            missing+=("curl")
            install_cmds+=("  brew install curl OR  apt install curl")
        fi
    fi

    if [ ${#missing[@]} -gt 0 ]; then
        echo ""
        echo -e "\033[91m╔══════════════════════════════════════════════════════════════╗\033[0m"
        echo -e "\033[91m║  OH NO BABY WHAT IS YOU DOING                                ║\033[0m"
        echo -e "\033[91m╚══════════════════════════════════════════════════════════════╝\033[0m"
        echo ""
        echo -e "\033[93mMissing dependencies:\033[0m ${missing[*]}"
        echo ""
        echo -e "\033[93mInstall them like a civilized person:\033[0m"
        for cmd in "${install_cmds[@]}"; do
            echo -e "\033[96m$cmd\033[0m"
        done
        echo ""
        echo -e "\033[90mThis is a glow-up, not a glow-down. We have standards here. 💅\033[0m"
        echo ""
        exit 1
    fi
}
