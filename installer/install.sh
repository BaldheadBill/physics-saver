#!/bin/bash
#
# Physics-Saver one-click installer for macOS and Linux.
# Designed, built, and copyrighted by VantEdge Intelligence, Atlanta, GA, USA.
# Open-sourced under the MIT License. https://vantedgeintelligence.com/
#
# Usage:
#   bash install.sh                    # install + interactive client setup
#   bash install.sh --claude           # also register with Claude Desktop
#   bash install.sh --gemini           # also register with Gemini CLI
#   bash install.sh --uninstall        # remove everything
#
set -euo pipefail

REPO="BaldheadBill/physics-saver"
APP_NAME="physics-saver"
APP_VERSION="3.0.0"
INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/bin}"

CLAUDE_CONFIG="$HOME/Library/Application Support/Claude/claude_desktop_config.json"
GEMINI_CONFIG="$HOME/.gemini/settings.json"

FLAG_CLAUDE=0
FLAG_GEMINI=0
FLAG_UNINSTALL=0
for arg in "$@"; do
    case "$arg" in
        --claude) FLAG_CLAUDE=1 ;;
        --gemini) FLAG_GEMINI=1 ;;
        --uninstall) FLAG_UNINSTALL=1 ;;
        *) echo "Unknown option: $arg" >&2; exit 1 ;;
    esac
done

echo ""
echo "  Physics-Saver v$APP_VERSION installer"
echo "  Designed, built, and copyrighted by VantEdge Intelligence, Atlanta, GA, USA"
echo "  Open-sourced under the MIT License. https://vantedgeintelligence.com/"
echo ""

uninstall_entry() {
    local config="$1"
    [ -f "$config" ] || return 0
    if command -v python3 >/dev/null 2>&1; then
        python3 - "$config" <<'PY'
import json, sys
path = sys.argv[1]
with open(path) as f:
    data = json.load(f)
servers = data.get("mcpServers", {})
if "physics-saver" in servers:
    del servers["physics-saver"]
    with open(path, "w") as f:
        json.dump(data, f, indent=2)
    print("    removed 'physics-saver' from", path)
PY
    else
        echo "    WARN: python3 not found; edit $config manually to remove the physics-saver entry."
    fi
}

if [ "$FLAG_UNINSTALL" = "1" ]; then
    echo "==> Uninstalling Physics-Saver"
    uninstall_entry "$CLAUDE_CONFIG"
    uninstall_entry "$GEMINI_CONFIG"
    rm -f "$INSTALL_DIR/$APP_NAME"
    echo "    removed $INSTALL_DIR/$APP_NAME"
    echo ""
    echo "Physics-Saver has been uninstalled."
    exit 0
fi

echo "==> 1. Locating the Physics-Saver binary"
if command -v "$APP_NAME" >/dev/null 2>&1; then
    EXE_PATH="$(command -v "$APP_NAME")"
    echo "    already installed at $EXE_PATH"
else
    ARCH="$(uname -m)"
    case "$ARCH" in
        x86_64|amd64) ASSET="physics-saver-linux-x86_64" ;;
        aarch64|arm64) ASSET="physics-saver-macos-arm64" ;;
        *) echo "    ERROR: unsupported architecture: $ARCH" >&2; exit 1 ;;
    esac
    if [ "$(uname -s)" = "Linux" ]; then
        case "$ARCH" in
            aarch64|arm64) ASSET="physics-saver-linux-arm64" ;;
        esac
    fi
    URL="https://github.com/$REPO/releases/latest/download/$ASSET"
    echo "    downloading $ASSET ..."
    mkdir -p "$INSTALL_DIR"
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL -o "$INSTALL_DIR/$APP_NAME" "$URL"
    elif command -v wget >/dev/null 2>&1; then
        wget -q -O "$INSTALL_DIR/$APP_NAME" "$URL"
    else
        echo "    ERROR: neither curl nor wget found." >&2
        exit 1
    fi
    chmod +x "$INSTALL_DIR/$APP_NAME"
    EXE_PATH="$INSTALL_DIR/$APP_NAME"
    echo "    installed to $EXE_PATH"
    echo "    NOTE: add $INSTALL_DIR to your PATH if the 'physics-saver' command is not found."
fi

echo "==> 2. Verifying the binary"
if "$EXE_PATH" help | grep -q "Physics-Saver"; then
    echo "    OK: binary responds"
else
    echo "    WARN: binary did not respond as expected"
fi

echo "==> 3. Registering with your AI assistants"
CLAUDE_NEEDED=0
GEMINI_NEEDED=0

if [ "$FLAG_CLAUDE" = "0" ] && [ "$FLAG_GEMINI" = "0" ]; then
    printf "    Register with Claude Desktop? [y/N] "
    read -r ans
    [ "$ans" = "y" ] || [ "$ans" = "Y" ] && CLAUDE_NEEDED=1
    printf "    Register with Gemini CLI? [y/N] "
    read -r ans
    [ "$ans" = "y" ] || [ "$ans" = "Y" ] && GEMINI_NEEDED=1
else
    [ "$FLAG_CLAUDE" = "1" ] && CLAUDE_NEEDED=1
    [ "$FLAG_GEMINI" = "1" ] && GEMINI_NEEDED=1
fi

STATE_FILE="$INSTALL_DIR/physics-saver-state.json"

register_entry() {
    local config="$1"
    local exe_path="$2"
    local state_file="$3"
    mkdir -p "$(dirname "$config")"
    if command -v python3 >/dev/null 2>&1; then
        python3 - "$config" "$exe_path" "$state_file" <<'PY'
import json, sys
path, exe, state = sys.argv[1], sys.argv[2], sys.argv[3]
data = {}
try:
    with open(path) as f:
        data = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    data = {}
data.setdefault("mcpServers", {})["physics-saver"] = {
    "command": exe,
    "args": ["mcp"],
    "env": {"PHYSICS_SAVER_STATE_FILE": state},
}
with open(path, "w") as f:
    json.dump(data, f, indent=2)
print("    OK: registered 'physics-saver' in", path)
print("    NOTE: fully quit and restart the AI app for the change to take effect.")
PY
    else
        echo "    WARN: python3 not found; add the physics-saver MCP entry manually."
    fi
}

[ "$CLAUDE_NEEDED" = "1" ] && register_entry "$CLAUDE_CONFIG" "$EXE_PATH" "$STATE_FILE"
[ "$CLAUDE_NEEDED" = "0" ] && echo "    Claude Desktop: skipped"
[ "$GEMINI_NEEDED" = "1" ] && register_entry "$GEMINI_CONFIG" "$EXE_PATH" "$STATE_FILE"
[ "$GEMINI_NEEDED" = "0" ] && echo "    Gemini CLI: skipped"

echo ""
echo "Done! Next steps:"
echo "  1. Fully quit and restart Claude Desktop / Gemini CLI."
echo "  2. Ask your assistant to use 'ingest_document' with a document path, then"
echo "     'search_documents' to retrieve only the relevant chunks - saving tokens."
echo "  3. Test the CLI any time:  $EXE_PATH help"
echo ""
echo "Need help or found a bug? https://github.com/$REPO/issues"
