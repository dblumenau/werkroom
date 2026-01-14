# werkroom

CLI tools that serve. Built with [gum](https://github.com/charmbracelet/gum) and questionable life choices.

## Tools

### slay
Interactive project runner for Laravel/Node projects. Handles:
- Git sync, composer/npm install, builds
- Artisan commands, queue workers, schedulers
- Watch mode with file monitoring
- Editor integration (Cursor, PHPStorm, VS Code)

```bash
slay              # Interactive mode
slay -w           # Watch mode
slay myproject    # Jump straight to a project
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

## Installation

### One-liner (recommended)

```bash
# Install slay
curl -fsSL https://raw.githubusercontent.com/dblumenau/werkroom/master/install.sh | bash

# Install specific tools
curl -fsSL ... | bash -s -- slay hunty

# Install everything
curl -fsSL ... | bash -s -- --all
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

If `~/bin` isn't already in your PATH, add this to your `~/.zshrc`:

```bash
export PATH="$HOME/bin:$PATH"
```

### Updating

```bash
slay update
```

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
