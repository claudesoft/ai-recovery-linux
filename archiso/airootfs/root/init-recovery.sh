#!/bin/bash

clear
cat << "EOF"
╔════════════════════════════════════════════════════╗
║   🤖 AI Recovery Linux - Claude Code Edition     ║
║                                                    ║
║   Powered by Anthropic Claude & Arch Linux       ║
╚════════════════════════════════════════════════════╝

EOF
echo "Initializing recovery environment..."
echo

# 1. Network setup
echo "[1/4] Configuring network..."
if ! timeout 3 ping -c 1 8.8.8.8 &>/dev/null 2>&1; then
    echo "  → Starting DHCP on all interfaces..."
    systemctl start dhcpcd.service 2>/dev/null || dhcpcd -B &>/dev/null &
    sleep 3

    if ! timeout 3 ping -c 1 8.8.8.8 &>/dev/null 2>&1; then
        echo "  ⚠ No network connection detected"
        echo "  Options:"
        echo "    - Ethernet: Wait 10 seconds or run: systemctl restart dhcpcd"
        echo "    - WiFi: Use 'iwctl' to connect"
        echo "    - Manual: Use 'ip addr' and 'ip route' to configure"
        echo
        read -p "Press ENTER to continue..." -t 10
    else
        echo "  ✓ Network connected"
    fi
else
    echo "  ✓ Network already connected"
fi

# 2. Claude Code installation (if not already installed)
echo
echo "[2/4] Checking Claude Code installation..."
if command -v claude &>/dev/null; then
    echo "  ✓ Claude Code already installed"
else
    echo "  → Installing Claude Code CLI..."
    if npm install -g @anthropic-ai/claude-code 2>&1 | grep -q "added.*packages"; then
        echo "  ✓ Claude Code installed successfully"
    else
        echo "  ✗ Installation failed - check internet connection"
        echo "  Try manually: npm install -g @anthropic-ai/claude-code"
        echo
        read -p "Press ENTER to continue..."
    fi
fi

# 3. Setup X11 if needed
echo
echo "[3/4] Preparing browser environment..."
if [ -x "/usr/bin/startx" ]; then
    echo "  ✓ X11 is available for browser auth"
else
    echo "  ⚠ X11 not available - browser auth may not work"
fi

# 4. Launch Claude Code
echo
echo "[4/4] Starting Claude Code..."
echo
cat << "EOF"
╔════════════════════════════════════════════════════╗
║                                                    ║
║  🌐 Browser will open for Anthropic login        ║
║                                                    ║
║  After successful authentication, you'll be       ║
║  returned to this terminal to recover/repair      ║
║  your system.                                      ║
║                                                    ║
║  Available tools:                                  ║
║  • parted, fdisk, lsblk - Disk management         ║
║  • fsck, e2fsck - Filesystem repair               ║
║  • chroot, arch-chroot - System repair            ║
║  • mount, umount - Mount operations                ║
║  • rsync - Backup/restore                         ║
║                                                    ║
╚════════════════════════════════════════════════════╝
EOF
echo
sleep 2

# Start Claude Code with proper environment
export DISPLAY=${DISPLAY:-:0}
export XAUTHORITY=${XAUTHORITY:-$HOME/.Xauthority}

# Launch Claude Code
exec claude "$@"
