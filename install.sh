#!/bin/bash

# werkroom installer
# Usage: curl -fsSL https://raw.githubusercontent.com/dblumenau/werkroom/master/install.sh | bash
#        curl ... | bash -s -- slay hunty    # install specific tools
#        curl ... | bash -s -- --all         # install all tools

set -e

# Colors
GREEN='\033[92m'
YELLOW='\033[93m'
PINK='\033[95m'
RED='\033[91m'
R='\033[0m'
B='\033[1m'

REPO_URL="https://github.com/dblumenau/werkroom.git"
INSTALL_DIR="$HOME/.werkroom"
BIN_DIR="$HOME/bin"

# Available tools
ALL_TOOLS=("slay" "hunty" "gum-showcase")

# Parse arguments - default to just slay
if [ $# -eq 0 ]; then
    TOOLS=("slay")
elif [ "$1" = "--all" ]; then
    TOOLS=("${ALL_TOOLS[@]}")
else
    TOOLS=("$@")
fi

echo -e "${PINK}${B}werkroom${R} installer"
echo ""

# Check dependencies
missing=()
if ! command -v gum &> /dev/null; then
    missing+=("gum")
fi
if ! command -v fd &> /dev/null; then
    missing+=("fd")
fi
if ! command -v git &> /dev/null; then
    missing+=("git")
fi

if [ ${#missing[@]} -gt 0 ]; then
    echo -e "${YELLOW}Missing dependencies: ${missing[*]}${R}"
    echo ""
    echo "Install them first:"
    echo -e "  ${B}brew install ${missing[*]}${R}"
    echo ""
    exit 1
fi

# Clone or update repo
if [ -d "$INSTALL_DIR" ]; then
    echo -e "Updating existing installation..."
    git -C "$INSTALL_DIR" pull origin master --quiet
else
    echo -e "Cloning werkroom..."
    git clone --quiet "$REPO_URL" "$INSTALL_DIR"
fi

# Ensure ~/bin exists
if [ ! -d "$BIN_DIR" ]; then
    echo -e "${YELLOW}Creating $BIN_DIR${R}"
    mkdir -p "$BIN_DIR"
fi

for tool in "${TOOLS[@]}"; do
    src="$INSTALL_DIR/$tool"
    dest="$BIN_DIR/$tool"

    if [ ! -f "$src" ]; then
        echo -e "${YELLOW}⚠ $tool not found, skipping${R}"
        continue
    fi

    # Remove existing symlink or file
    if [ -L "$dest" ] || [ -f "$dest" ]; then
        rm "$dest"
    fi

    # Create symlink
    ln -s "$src" "$dest"
    echo -e "${GREEN}✓${R} Linked ${B}$tool${R}"
done

echo ""
echo -e "${GREEN}${B}Done!${R}"
echo ""

# Check if ~/bin is in PATH
if [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
    echo -e "${YELLOW}~/bin is not in your PATH.${R} Add this to your ~/.zshrc:"
    echo ""
    echo -e '  export PATH="$HOME/bin:$PATH"'
    echo ""
    echo "Then run: source ~/.zshrc"
else
    echo "Run ${B}slay${R} to get started."
fi
