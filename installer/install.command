#!/bin/bash
#
# Physics-Saver macOS double-click installer.
# Designed, built, and copyrighted by VantEdge Intelligence, Atlanta, GA, USA.
# Open-sourced under the MIT License. https://vantedgeintelligence.com/
#
# Double-click this file to install. If macOS Gatekeeper blocks it the first
# time, right-click the file and choose "Open".
#
set -euo pipefail

cd "$(dirname "$0")"
echo "====================================================="
echo "  Physics-Saver installer (macOS)"
echo "  Designed, built, and copyrighted by"
echo "  VantEdge Intelligence, Atlanta, GA, USA"
echo "  Open-sourced under the MIT License."
echo "====================================================="
echo ""
echo "This installer will:"
echo "  1. Download the latest Physics-Saver release"
echo "  2. Install it to ~/.local/bin"
echo "  3. Optionally register it with Claude Desktop / Gemini CLI"
echo ""
read -r -p "Continue? [y/N] " answer
if [ "$answer" != "y" ] && [ "$answer" != "Y" ]; then
    echo "Installation cancelled."
    exit 0
fi

exec bash install.sh
