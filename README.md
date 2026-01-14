# werkroom

CLI tools that serve. Built with [gum](https://github.com/charmbracelet/gum) and questionable life choices.

## Tools

### slay
Project task runner and deployment watcher with dramatic personality. Features:
- Watch health endpoints for version deployments (with flicker protection)
- Git sync-to-master workflow (stash, switch, pull)
- Run composer install / npm install + build
- Run artisan schedule:run
- Open in VSCode or PhpStorm

```bash
slay                          # Interactive mode
slay <url> <version>          # Watch for specific version
slay -i 10 <url> <version>    # Custom polling interval (seconds)
```

### hunty
Search through Claude Code conversation transcripts.

```bash
hunty "search term"     # Search recent conversations
hunty -d 7 "pattern"    # Search last 7 days
hunty -p myproject      # Filter by project
```

### gum-showcase
Interactive demo of everything [gum](https://github.com/charmbracelet/gum) can do. Run it to see spinners, inputs, confirms, filters, and more.

```bash
gum-showcase            # Prepare to be obsessed
```

### notify-watch
Send push notifications to your phone/Apple Watch via [Pushover](https://pushover.net).

```bash
notify-watch "Build complete!"           # High priority (default)
notify-watch -q "FYI: logs rotated"      # Quiet - no sound
notify-watch -e "SERVER DOWN" "Alert"    # Emergency - repeats until acknowledged
```

**Setup:** Create `~/.config/notify-watch/credentials`:
```bash
PUSHOVER_USER="your-user-key"
PUSHOVER_TOKEN="your-api-token"
```

## Installation

### One-liner (recommended)

```bash
# Install slay (stable)
curl -fsSL https://raw.githubusercontent.com/dblumenau/werkroom/v1.0.0/install.sh | bash

# Install specific tools
curl -fsSL https://raw.githubusercontent.com/dblumenau/werkroom/v1.0.0/install.sh | bash -s -- slay hunty

# Install everything
curl -fsSL https://raw.githubusercontent.com/dblumenau/werkroom/v1.0.0/install.sh | bash -s -- --all

# Bleeding edge (master branch)
curl -fsSL https://raw.githubusercontent.com/dblumenau/werkroom/master/install.sh | bash
```

This clones to `~/.werkroom` and symlinks to `~/bin`.

### Manual

```bash
# Clone wherever you like
git clone git@github.com:dblumenau/werkroom.git ~/projects/werkroom

# Create symlinks
cd ~/projects/werkroom && ./link.sh
```

### PATH setup

If `~/bin` isn't already in your PATH, add this to your shell config:

```bash
# For zsh (macOS default)
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc

# For bash (Linux/WSL default)
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
```

The installer will detect your shell and tell you which one to use.

### Updating

```bash
slay update
```

### Versions

The installer uses semantic versioning:
- **v1.0.0** (current stable) - Recommended for production use
- **master** - Latest development version with newest features

Check [releases](https://github.com/dblumenau/werkroom/releases) for version history.

### What the installer does

> **Full disclosure**: I wrote this repo AND this security summary. The audacity. Feel free to read the 80-line `install.sh` yourself—it's not exactly obfuscated.

For the security-conscious, here's exactly what `install.sh` does:

1. **Checks for dependencies** (`gum`, `fd`, `git`) - exits if missing
2. **Clones this repo** to `~/.werkroom` (or `git pull` if it exists)
3. **Creates `~/bin`** if it doesn't exist
4. **Creates symlinks** in `~/bin` → `~/.werkroom`

**What it does NOT do:**
- No sudo/root required
- No system-wide changes (everything in `$HOME`)
- No modification of shell config (only prints PATH advice)
- No network calls other than git clone/pull
- No execution of downloaded code during install (symlinks only)

**Files touched:**
- `~/.werkroom/` - the cloned repo
- `~/bin/slay` - symlink (and `hunty`, `gum-showcase` if requested)

## Dependencies

Install these first:

```bash
brew install gum fd curl
```

- [gum](https://github.com/charmbracelet/gum) - gorgeous TUI components
- [fd](https://github.com/sharkdp/fd) - fast file finding
- curl - for health endpoint checks

## Structure

```
werkroom/
├── slay              # Main project runner
├── hunty             # Claude transcript search
├── gum-showcase      # Gum capabilities demo
├── slay-lib/         # Shared library
│   ├── colors.sh     # Color definitions
│   ├── interactive.sh # Menu/input helpers
│   ├── watch-loop.sh # File watching logic
│   └── ...
├── install.sh        # Remote installer (curl-able)
└── link.sh           # Local symlink creator
```

## From dotfiles

These scripts used to live in `dotfiles/common/bin/`. They've graduated to their own repo because they're fancy like that.
