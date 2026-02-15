#!/bin/bash

# Manual setup script for Claude Code

set -e

echo "╔════════════════════════════════════════════════════╗"
echo "║   Claude Code Manual Setup                         ║"
echo "╚════════════════════════════════════════════════════╝"
echo

# Check network
if ! ping -c 1 -W 2 8.8.8.8 &>/dev/null; then
    echo "⚠ No internet connection detected"
    echo "Attempting to start DHCP..."
    systemctl start dhcpcd || dhcpcd -B &
    sleep 3
fi

# Install/update Claude Code
echo "Installing/updating Claude Code CLI..."
npm install -g @anthropic-ai/claude-code

echo
echo "✓ Claude Code setup complete"
echo
echo "Starting Claude Code..."
sleep 1

# Launch Claude
claude "$@"
