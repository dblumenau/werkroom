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

# Detect package manager
detect_package_manager() {
    # Check native Linux package managers first
    # (brew can be installed on Linux but is uncommon)
    if command -v apt-get &> /dev/null; then
        echo "apt"
    elif command -v dnf &> /dev/null; then
        echo "dnf"
    elif command -v yum &> /dev/null; then
        echo "yum"
    elif command -v pacman &> /dev/null; then
        echo "pacman"
    elif command -v brew &> /dev/null; then
        # macOS or Homebrew on Linux
        echo "brew"
    else
        echo "unknown"
    fi
}

# Available tools
ALL_TOOLS=("slay" "hunty" "gum-showcase" "notify-watch")

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
if ! command -v fd &>/dev/null && ! command -v fdfind &>/dev/null; then
    missing+=("fd")
fi
if ! command -v git &> /dev/null; then
    missing+=("git")
fi

if [ ${#missing[@]} -gt 0 ]; then
    echo -e "${YELLOW}Missing dependencies: ${missing[*]}${R}"
    echo ""
    echo "Install them first:"

    pkg_mgr=$(detect_package_manager)
    case "$pkg_mgr" in
        brew)
            echo -e "  ${B}brew install ${missing[*]}${R}"
            ;;
        apt)
            # Special case: fd is fd-find on Debian/Ubuntu
            apt_deps=()
            for dep in "${missing[@]}"; do
                if [ "$dep" = "fd" ]; then
                    apt_deps+=("fd-find")
                else
                    apt_deps+=("$dep")
                fi
            done
            echo -e "  ${B}sudo apt update && sudo apt install -y ${apt_deps[*]}${R}"
            ;;
        dnf|yum)
            # fd is fd-find on RHEL/Fedora too
            rpm_deps=()
            for dep in "${missing[@]}"; do
                if [ "$dep" = "fd" ]; then
                    rpm_deps+=("fd-find")
                else
                    rpm_deps+=("$dep")
                fi
            done
            echo -e "  ${B}sudo $pkg_mgr install -y ${rpm_deps[*]}${R}"
            ;;
        pacman)
            echo -e "  ${B}sudo pacman -S ${missing[*]}${R}"
            ;;
        *)
            # Unknown package manager - show all options
            echo -e "  ${B}brew install ${missing[*]}${R}  (macOS)"

            # Build apt command with fd-find special case
            apt_deps=()
            for dep in "${missing[@]}"; do
                [ "$dep" = "fd" ] && apt_deps+=("fd-find") || apt_deps+=("$dep")
            done
            echo -e "  ${B}sudo apt install ${apt_deps[*]}${R}  (Debian/Ubuntu)"
            echo -e "  ${B}sudo dnf install ${apt_deps[*]}${R}  (Fedora)"
            echo -e "  ${B}sudo pacman -S ${missing[*]}${R}  (Arch)"
            ;;
    esac

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
    # Detect shell and suggest appropriate config file
    shell_config=""
    shell_name=""
    if [ -n "$ZSH_VERSION" ]; then
        shell_config="~/.zshrc"
        shell_name="zsh"
    elif [ -n "$BASH_VERSION" ]; then
        shell_config="~/.bashrc"
        shell_name="bash"
    else
        # Fallback: check SHELL env var
        case "$SHELL" in
            */zsh)
                shell_config="~/.zshrc"
                shell_name="zsh"
                ;;
            */bash)
                shell_config="~/.bashrc"
                shell_name="bash"
                ;;
            *)
                shell_config="~/.profile"
                shell_name="your shell"
                ;;
        esac
    fi

    echo -e "${YELLOW}~/bin is not in your PATH.${R} Add this to your $shell_config:"
    echo ""
    echo -e '  export PATH="$HOME/bin:$PATH"'
    echo ""
    echo "Then run: source $shell_config"
else
    echo "Run ${B}slay${R} to get started."
fi
