#!/usr/bin/env bash
# slay-lib/colors.sh - ANSI fallbacks + Gum styling helpers

# ═══════════════════════════════════════════════════════════════
# ANSI FALLBACKS (for when gum isn't available)
# ═══════════════════════════════════════════════════════════════
R='\033[0m'
B='\033[1m'
DIM='\033[2m'
PINK='\033[95m'
CYAN='\033[96m'
YELLOW='\033[93m'
GREEN='\033[92m'
RED='\033[91m'
WHITE='\033[97m'
GRAY='\033[90m'

# ═══════════════════════════════════════════════════════════════
# GUM COLOR PALETTE (256-color / hex references)
# ═══════════════════════════════════════════════════════════════
# Pink vibes (brand color)
COLOR_PINK="212"
COLOR_PINK_LIGHT="219"
COLOR_PINK_HOT="199"

# Status colors
COLOR_SUCCESS="82"      # Bright green
COLOR_WARNING="214"     # Orange
COLOR_ERROR="196"       # Red
COLOR_INFO="51"         # Cyan

# Neutral tones
COLOR_MUTED="250"       # Light gray
COLOR_DIM="240"         # Dim gray
COLOR_WHITE="255"

# ═══════════════════════════════════════════════════════════════
# STYLING HELPERS (gum wrappers for consistent vibes)
# ═══════════════════════════════════════════════════════════════

# Header with sparkles
slay_header() {
    local title="$1"
    gum style --foreground "$COLOR_PINK" --bold "✨ $title ✨"
}

# Section header (no sparkles, just bold)
slay_section() {
    local title="$1"
    gum style --foreground "$COLOR_PINK" --bold "$title"
}

# Muted subtitle text
slay_muted() {
    gum style --foreground "$COLOR_MUTED" "$1"
}

# Dim/italic helper text
slay_dim() {
    gum style --foreground "$COLOR_DIM" --italic "$1"
}

# Success message with checkmark
slay_success() {
    gum style --foreground "$COLOR_SUCCESS" "✓ $1"
}

# Warning message
slay_warn() {
    gum style --foreground "$COLOR_WARNING" "⚠ $1"
}

# Error message
slay_error() {
    gum style --foreground "$COLOR_ERROR" "✗ $1"
}

# Info/highlight text (cyan)
slay_info() {
    gum style --foreground "$COLOR_INFO" "$1"
}

# Boxed content (rounded border)
slay_box() {
    local content="$1"
    local color="${2:-$COLOR_MUTED}"
    gum style --border rounded --border-foreground "$color" --padding "0 2" --foreground "$COLOR_MUTED" "$content"
}

# Fancy celebration box (double border, centered)
slay_celebrate() {
    gum style --foreground "$COLOR_PINK" --bold --border double --border-foreground "$COLOR_PINK" --padding "1 3" --align center "$@"
}

# Key-value display (consistent formatting)
slay_kv() {
    local key="$1"
    local value="$2"
    local value_color="${3:-$COLOR_INFO}"
    echo -e "$(gum style --foreground "$COLOR_WHITE" "$key") $(gum style --foreground "$value_color" "$value")"
}

# Status line with timestamp
slay_status_line() {
    local timestamp="$1"
    local current="$2"
    local target="$3"
    local elapsed="$4"
    gum join --horizontal \
        "$(gum style --foreground "$COLOR_DIM" "$timestamp")" \
        "$(gum style --foreground "$COLOR_DIM" " │ ")" \
        "$(gum style --foreground "$COLOR_WHITE" "Current: ")" \
        "$(gum style --foreground "$COLOR_INFO" "$current")" \
        "$(gum style --foreground "$COLOR_DIM" " │ ")" \
        "$(gum style --foreground "$COLOR_WHITE" "Target: ")" \
        "$(gum style --foreground "$COLOR_WARNING" "$target")" \
        "$(gum style --foreground "$COLOR_DIM" " │ $elapsed")"
}
