#!/bin/bash

# This script runs INSIDE the xterm window in X11

echo "╔════════════════════════════════════════════════════╗"
echo "║   Claude Code Session                              ║"
echo "╚════════════════════════════════════════════════════╝"
echo

# Ensure we have internet before starting (double check)
if ! ping -c 1 8.8.8.8 &>/dev/null; then
    echo "⚠ Network check failed inside X11."
    echo "  Please check your connection."
fi

echo "Starting Claude..."
echo "If a browser opens, please authenticate there."
echo

# Run Claude
# If it's not in path for some reason (rare), try typical locations
if command -v claude &>/dev/null; then
    claude "$@"
else
    echo "⚠ 'claude' command not found. Trying to find it..."
    # npm global bin might not be in path
    export PATH=$PATH:$(npm get prefix)/bin
    claude "$@"
fi

echo
echo "Claude Code session ended."
echo "Starting a shell so you can continue working..."
echo "Type 'exit' to close this window and logout of graphical mode."
exec bash
