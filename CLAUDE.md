# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

werkroom is a collection of CLI tools built with [gum](https://github.com/charmbracelet/gum) for gorgeous terminal UIs. The tools have a consistent "Kardashian-style" personality with sassy messages and escalating urgency states.

## Tools

- **slay** - Interactive project runner for Laravel/Node projects. Monitors health endpoints for deployments, runs git sync workflows, composer/npm install, artisan schedule commands, and opens editors.
- **hunty** - Searches through Claude Code conversation transcripts (~/.claude/projects). Uses fd, rg, jq, fzf for fast searching with fzf preview.
- **gum-showcase** - Interactive demo of all gum capabilities.

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/dblumenau/werkroom/v1.0.0/install.sh | bash
```

## Dependencies

- gum (required for TUI components)
- fd (required for fast file finding)
- curl (required for health endpoint checks in slay)
- rg, jq, fzf (required for hunty)
- bat (optional, hunty falls back to less for pager)

## Architecture

### slay Modular Library (`slay-lib/`)

slay uses a state machine architecture with modular library files:

| File | Purpose |
|------|---------|
| `colors.sh` | ANSI fallbacks + gum styling helpers (`slay_header`, `slay_success`, `slay_error`, `slay_box`, etc.) |
| `messages.sh` | Randomized messages (greetings, spinners, wait messages) with 3 escalating phases: chill (0-30s), antsy (30-90s), unhinged (90s+) |
| `project-cache.sh` | Project discovery via fd, caches git repos to `~/.cache/slay-projects` |
| `interactive.sh` | State machine for project picker (`select_customer` → `choose_action` → action-specific states) |
| `actions.sh` | Action handlers: editor scope picker, schedule runner, composer/npm commands |
| `git-sync.sh` | Git sync-to-master workflow (stash, switch branch, pull) |
| `watch-loop.sh` | Core polling loop with timeout (10min), version verification (3s delay to avoid flicker) |
| `check-deps.sh` | Dependency validation with sassy error messages |

### State Machine Flow

The interactive mode in `slay` follows this state flow:
```
select_customer → choose_action → [action-specific states] → back to choose_action
```

### Configuration

slay supports optional config at `~/.config/slay/config`:
- `SLAY_PROJECTS_DIR` - Override projects directory (default: `~/projects`)
- `URL_DISCOVERY_SCRIPT` - Custom script path for auto-discovering health endpoints

### URL Discovery

slay can auto-discover health endpoint URLs via a custom discovery script. Create one in `slay-lib/examples/` - it should output `project_group|url` lines.

### hunty Transcript Search

hunty searches JSONL transcripts in `~/.claude/projects/`. Key features:
- Project paths are encoded in directory names (dashes replace slashes)
- Can detect and offer to resume parent sessions for subagent conversations
- Preview panel shows parsed user/assistant messages around matches
- Animated spinner with 60+ rotating sassy messages (changes every 5s)
- Match count shows "X match(es) across Y conversation(s)" for clarity

#### CLI Options

| Flag | Description |
|------|-------------|
| `-d <n>` | Search last N days (default: 1) |
| `-a` | Search all time |
| `-p <project>` | Filter by project name |
| `-C <n>` | Show N lines of context |

#### Action Menu

After selecting a search result:
- **View in pager** - Full conversation in bat/less
- **Resume session** - Launch `claude --resume` (detects subagents → offers parent)
- **Open in VSCode** - Raw JSONL transcript
- **Copy session ID** - UUID to clipboard
- **← Back to results** - Return to fzf picker

## Key Patterns

- All tools resolve symlinks to find their real location for sourcing library files
- gum is optional for basic operation (ANSI fallbacks exist) but required for interactive mode
- Random spinner selection via `random_spinner()` for variety
- Watch loop uses verification delay (3 seconds) to catch deployment flickering
- Ctrl+C returns to project picker in interactive mode, exits in direct mode

## Testing

```bash
# slay
slay --test-deps    # Test dependency check display (pretends deps are missing)
slay -r             # Force refresh project cache

# hunty
hunty "pattern"     # Search today's conversations
hunty -d 7 "api"    # Search last 7 days
hunty -a "bug"      # Search all time
hunty               # Interactive mode (prompts for pattern and time range)
```
