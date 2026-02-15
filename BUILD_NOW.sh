#!/bin/bash
# AI Recovery Linux - Docker Build Script
# Copy-Paste ready - everything in one command

set -euo pipefail

cd ~/Desktop/ai_recovery_linux

echo "╔════════════════════════════════════════════════════╗"
echo "║  Building AI Recovery Linux ISO with Docker       ║"
echo "╚════════════════════════════════════════════════════╝"
echo

# Check Docker
if ! command -v docker &>/dev/null; then
    echo "ERROR: Docker not found!"
    exit 1
fi

echo "✓ Docker found: $(docker --version)"
echo

# Build Docker Image
echo "[Step 1/3] Building Docker image..."
echo "           This downloads Arch Linux and dependencies (~1-5 min)"
echo

# Enable BuildKit for macOS Docker Arch Linux compatibility
export DOCKER_BUILDKIT=1

docker build -t ai-recovery-builder . || {
    echo "ERROR: Docker build failed!"
    exit 1
}

echo
echo "[Step 2/3] Building ISO..."
echo "           Compressing filesystem and creating ISO (~15-25 min)"
echo "           This will download ~500MB of packages"
echo

docker run -v $(pwd)/out:/out ai-recovery-builder || {
    echo "ERROR: ISO build failed!"
    exit 1
}

echo
echo "[Step 3/3] Verifying result..."

if [ ! -f out/ai-recovery-linux-*.iso ]; then
    echo "ERROR: No ISO file created!"
    exit 1
fi

ISO_FILE=$(ls -1t out/ai-recovery-linux-*.iso | head -n1)
ISO_SIZE_MB=$(($(stat -c%s "$ISO_FILE" 2>/dev/null || stat -f%z "$ISO_FILE") / 1024 / 1024))

echo
echo "╔════════════════════════════════════════════════════╗"
echo "║  ✓ BUILD SUCCESSFUL!                               ║"
echo "╚════════════════════════════════════════════════════╝"
echo
echo "ISO File: $(basename "$ISO_FILE")"
echo "Location: $(pwd)/out/"
echo "Size: ${ISO_SIZE_MB} MB"
echo
if [ $ISO_SIZE_MB -gt 500 ]; then
    echo "⚠ WARNING: ISO is over 500MB target"
else
    echo "✓ ISO is under 500MB target!"
fi
echo
echo "Next: Flash to USB with balena-etcher or:"
echo "  sudo dd if='$ISO_FILE' of=/dev/sdX bs=4M status=progress sync"
echo
echo "✓ Done!"
