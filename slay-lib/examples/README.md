# URL Discovery Scripts

These example scripts show how to auto-discover health endpoint URLs for different infrastructure setups.

## How It Works

1. Slay calls your discovery script when you select "Watch for new tag"
2. Your script outputs `project_group|url` pairs (one per line)
3. Slay shows discovered URLs as options alongside cached URLs

## Setup

```bash
# 1. Copy the script that matches your setup
cp discover-deployment-yaml.sh ~/.config/slay/discover-urls.sh

# 2. Make it executable
chmod +x ~/.config/slay/discover-urls.sh

# 3. Enable it in your config
mkdir -p ~/.config/slay
echo 'URL_DISCOVERY_SCRIPT="$HOME/.config/slay/discover-urls.sh"' >> ~/.config/slay/config
```

## Available Examples

| Script | Use Case |
|--------|----------|
| `discover-deployment-yaml.sh` | Kubernetes deployments with `APP_URL` env var |
| `discover-docker-compose.sh` | Docker Compose with `HEALTH_URL` or `APP_URL` |
| `discover-env-file.sh` | Laravel/Node `.env` files with `APP_URL` |

## Writing Your Own

Your script just needs to output `project_group|url` pairs:

```bash
#!/usr/bin/env bash
# Use PROJECTS_DIR from environment
PROJECTS_DIR="${PROJECTS_DIR:-$HOME/projects}"

# Your discovery logic here...
# Output format: project_group|url
echo "myproject|https://staging.example.com/health"
echo "other|https://api.example.com/healthz"
```

The `project_group` should match the top-level directory name under your projects folder.
