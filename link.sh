#!/bin/bash

# werkroom linker (for local/manual installs)
# Creates symlinks in ~/bin for all CLI tools

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/bin"

# Colors
GREEN='\033[92m'
YELLOW='\033[93m'
PINK='\033[95m'
R='\033[0m'
B='\033[1m'

echo -e "${PINK}${B}werkroom${R} installer"
echo ""

# Ensure ~/bin exists
if [ ! -d "$BIN_DIR" ]; then
    echo -e "${YELLOW}Creating $BIN_DIR${R}"
    mkdir -p "$BIN_DIR"
fi

# Tools to install
TOOLS=("slay" "hunty" "gum-showcase")

for tool in "${TOOLS[@]}"; do
    src="$SCRIPT_DIR/$tool"
    dest="$BIN_DIR/$tool"

    if [ ! -f "$src" ]; then
        echo -e "${YELLOW}⚠ $tool not found, skipping${R}"
        continue
    fi

    # Remove existing symlink or file
    if [ -L "$dest" ] || [ -f "$dest" ]; then
        echo -e "  Removing existing $dest"
        rm "$dest"
    fi

    # Create symlink
    ln -s "$src" "$dest"
    echo -e "${GREEN}✓${R} Linked ${B}$tool${R} → $dest"
done

echo ""
echo -e "${GREEN}${B}Done!${R} Make sure ~/bin is in your PATH."
echo ""
echo "Add this to your .zshrc if needed:"
echo '  export PATH="$HOME/bin:$PATH"'
