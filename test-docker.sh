#!/bin/bash
# werkroom Docker test script
# Tests the installer in a fresh Ubuntu container

set -e

# Colors
PINK='\033[95m'
GREEN='\033[92m'
YELLOW='\033[93m'
R='\033[0m'
B='\033[1m'

IMAGE_NAME="werkroom-test"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Parse args
USE_LOCAL=false
VERSION="master"
INTERACTIVE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -l|--local)
            USE_LOCAL=true
            shift
            ;;
        -i|--interactive)
            INTERACTIVE=true
            shift
            ;;
        -v|--version)
            VERSION="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: test-docker.sh [options]"
            echo ""
            echo "Test werkroom installer in a Docker container."
            echo ""
            echo "Options:"
            echo "  -l, --local        Mount local repo instead of pulling from GitHub"
            echo "  -i, --interactive  Drop into shell after install"
            echo "  -v, --version TAG  Test specific version (default: master)"
            echo "  -h, --help         Show this help"
            echo ""
            echo "Examples:"
            echo "  ./test-docker.sh                    # Test master from GitHub"
            echo "  ./test-docker.sh -l                 # Test local changes"
            echo "  ./test-docker.sh -v v1.0.5          # Test specific tag"
            echo "  ./test-docker.sh -l -i              # Test local + drop into shell"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

echo -e "${PINK}${B}werkroom${R} Docker test"
echo ""

# Check Docker is available
if ! command -v docker &>/dev/null; then
    echo -e "${YELLOW}Docker not found. Install it first.${R}"
    exit 1
fi

# Build test image if it doesn't exist
if ! docker image inspect "$IMAGE_NAME" &>/dev/null; then
    echo -e "Building test image (one-time setup)..."
    docker build -t "$IMAGE_NAME" - << 'EOF'
FROM ubuntu:latest
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y curl git fd-find gpg ca-certificates \
    && mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://repo.charm.sh/apt/gpg.key | gpg --dearmor -o /etc/apt/keyrings/charm.gpg \
    && echo 'deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *' > /etc/apt/sources.list.d/charm.list \
    && apt-get update && apt-get install -y gum \
    && rm -rf /var/lib/apt/lists/*
EOF
    echo -e "${GREEN}✓${R} Test image built"
    echo ""
fi

# Create dummy projects for testing slay's interactive menu
SETUP_PROJECTS='mkdir -p ~/projects/acme-corp/api ~/projects/acme-corp/frontend ~/projects/acme-corp/mobile ~/projects/personal/blog ~/projects/personal/dotfiles ~/projects/freelance/client-site && for dir in ~/projects/*/*; do git -C "$dir" init -q 2>/dev/null; done && echo "Created test projects in ~/projects"'

# Build the test command
if [ "$USE_LOCAL" = true ]; then
    echo -e "Testing ${B}local${R} repo..."

    # Copy local repo to ~/.werkroom (bypassing git clone) then link binaries
    TEST_CMD="$SETUP_PROJECTS && cp -r /werkroom ~/.werkroom && mkdir -p ~/bin && ln -sf ~/.werkroom/slay ~/bin/slay && ln -sf ~/.werkroom/hunty ~/bin/hunty && ln -sf ~/.werkroom/notify-watch ~/bin/notify-watch && echo 'Installed local werkroom'"
    DOCKER_ARGS="-v $SCRIPT_DIR:/werkroom:ro"
else
    echo -e "Testing ${B}$VERSION${R} from GitHub..."

    TEST_CMD="$SETUP_PROJECTS && curl -fsSL https://raw.githubusercontent.com/dblumenau/werkroom/$VERSION/install.sh | bash"
    DOCKER_ARGS=""
fi

# Add verification tests (PATH needs ~/bin added)
VERIFY_CMD='export PATH="$HOME/bin:$PATH" && echo "" && echo "=== Verification ===" && command -v slay && slay --version && echo "✓ slay works"'

if [ "$INTERACTIVE" = true ]; then
    # Interactive mode - run install, then drop into shell
    # Add PATH to .bashrc so it persists in the interactive shell
    echo ""
    docker run -it $DOCKER_ARGS "$IMAGE_NAME" bash -c "$TEST_CMD && $VERIFY_CMD && echo 'export PATH=\"\$HOME/bin:\$PATH\"' >> ~/.bashrc && echo '' && echo 'Dropping into shell... (type \"slay\" to test)' && exec bash"
else
    # Non-interactive - just run tests
    docker run --rm $DOCKER_ARGS "$IMAGE_NAME" bash -c "$TEST_CMD && $VERIFY_CMD"
    echo ""
    echo -e "${GREEN}${B}Tests passed!${R}"
fi
