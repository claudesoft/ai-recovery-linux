#!/bin/bash

# AI Recovery Linux - ISO Builder
# Robust build script with detailed error handling and diagnostics

set -o pipefail
trap 'handle_error $? $LINENO' ERR

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging
LOG_FILE="build.log"

log() {
    local msg="$1"
    echo -e "$msg" | tee -a "$LOG_FILE"
}

log_section() {
    echo "" | tee -a "$LOG_FILE"
    log "╔════════════════════════════════════════════════════╗"
    log "║ $1"
    log "╚════════════════════════════════════════════════════╝"
}

handle_error() {
    local exit_code=$1
    local line_number=$2
    log "${RED}✗ Build failed at line $line_number with exit code $exit_code${NC}"
    log ""
    log "Debug information:"
    log "  - Script: ${BASH_SOURCE[1]}"
    log "  - Line: $line_number"
    log "  - Command exit code: $exit_code"
    log ""
    log "Check /tmp/archiso-debug for more details:"
    log "  tail -50 $LOG_FILE"
    exit $exit_code
}

# Start
log_section "AI Recovery Linux - ISO Builder v1.0"
log "${BLUE}Starting build process...${NC}"
log "Timestamp: $(date)"
log ""

# 1. Validate environment
log "Step 1/7: Validating environment..."

if ! command -v pacman &>/dev/null; then
    log "${RED}ERROR: pacman not found!${NC}"
    log "This script must run on Arch Linux (requires pacman and archiso)"
    log ""
    log "Options:"
    log "  1. Run on native Arch Linux system"
    log "  2. Use Arch Linux VM (VirtualBox, KVM, VMware)"
    log "  3. Use WSL2 with Arch Linux"
    log "  4. Use Docker: docker build -t ai-recovery . && docker run -v \$(pwd)/out:/out ai-recovery"
    exit 1
fi

log "  ✓ pacman found: $(pacman --version | head -1)"

# 2. Install dependencies
log ""
log "Step 2/7: Checking dependencies..."

MISSING_PACKAGES=()
for pkg in archiso; do
    if ! pacman -Q "$pkg" &>/dev/null; then
        MISSING_PACKAGES+=("$pkg")
    fi
done

if [ ${#MISSING_PACKAGES[@]} -gt 0 ]; then
    log "  → Installing missing packages: ${MISSING_PACKAGES[*]}"
    if ! sudo pacman -S --needed --noconfirm "${MISSING_PACKAGES[@]}" 2>&1 | tee -a "$LOG_FILE"; then
        log "${RED}Failed to install packages${NC}"
        exit 1
    fi
    log "  ✓ Dependencies installed"
else
    log "  ✓ All dependencies present"
fi

# 3. Setup directories
log ""
log "Step 3/7: Setting up directories..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR="$SCRIPT_DIR/work"
OUT_DIR="$SCRIPT_DIR/out"

log "  Script dir: $SCRIPT_DIR"
log "  Work dir: $WORK_DIR"
log "  Output dir: $OUT_DIR"

if [ ! -d "$SCRIPT_DIR/archiso" ]; then
    log "${RED}ERROR: archiso directory not found in $SCRIPT_DIR${NC}"
    exit 1
fi

# Clean old builds
if [ -d "$WORK_DIR" ]; then
    log "  → Cleaning previous work directory..."
    sudo rm -rf "$WORK_DIR" 2>&1 | tee -a "$LOG_FILE"
fi

mkdir -p "$OUT_DIR"
log "  ✓ Directories ready"

# 4. Validate project files
log ""
log "Step 4/7: Validating project files..."

REQUIRED_FILES=(
    "$SCRIPT_DIR/archiso/profiledef.sh"
    "$SCRIPT_DIR/archiso/packages.x86_64"
    "$SCRIPT_DIR/archiso/pacman.conf"
    "$SCRIPT_DIR/archiso/airootfs/root/init-recovery.sh"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        log "${RED}ERROR: Required file not found: $file${NC}"
        exit 1
    fi
done

log "  ✓ All required files present"

# 5. Fix permissions
log ""
log "Step 5/7: Setting up file permissions..."

chmod +x "$SCRIPT_DIR/archiso/profiledef.sh"
chmod +x "$SCRIPT_DIR/archiso/airootfs/root/init-recovery.sh" 2>/dev/null || true
chmod +x "$SCRIPT_DIR/archiso/airootfs/usr/local/bin/setup-claude.sh" 2>/dev/null || true

log "  ✓ Permissions set"

# 6. Build ISO
log ""
log "Step 6/7: Building ISO..."
log "${BLUE}This may take 10-30 minutes (downloads ~500MB of packages)${NC}"
log ""

if ! sudo mkarchiso -v -w "$WORK_DIR" -o "$OUT_DIR" "$SCRIPT_DIR/archiso" 2>&1 | tee -a "$LOG_FILE"; then
    log ""
    log "${RED}ISO build failed!${NC}"
    log ""
    log "Common issues and solutions:"
    log "  • Disk space: Ensure 2GB free in $WORK_DIR"
    log "  • Network: Check internet connection for package downloads"
    log "  • Permissions: May need sudo; check systemd-resolved for DNS"
    log ""
    log "Debug:"
    log "  - See build.log for full output"
    log "  - Check /tmp for archiso temp files"
    exit 1
fi

log "  ✓ ISO build complete"

# 7. Verify result
log ""
log "Step 7/7: Verifying ISO..."

ISO_FILE=$(ls -1t "$OUT_DIR"/*.iso 2>/dev/null | head -n1)

if [ -z "$ISO_FILE" ]; then
    log "${RED}ERROR: No ISO file found in $OUT_DIR${NC}"
    exit 1
fi

# Get file size (cross-platform compatible)
if command -v stat &>/dev/null; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        ISO_SIZE_BYTES=$(stat -f%z "$ISO_FILE")
    else
        ISO_SIZE_BYTES=$(stat -c%s "$ISO_FILE")
    fi
else
    ISO_SIZE_BYTES=$(ls -l "$ISO_FILE" | awk '{print $5}')
fi

ISO_SIZE_MB=$((ISO_SIZE_BYTES / 1024 / 1024))

log "  ISO file: $(basename "$ISO_FILE")"
log "  Size: ${ISO_SIZE_MB} MB"

# Final report
log_section "✓ BUILD SUCCESSFUL"

log ""
log "${GREEN}ISO created successfully!${NC}"
log ""
log "File: $ISO_FILE"
log "Size: ${ISO_SIZE_MB} MB"
log ""

if [ $ISO_SIZE_MB -gt 500 ]; then
    log "${YELLOW}⚠ WARNING: ISO is ${ISO_SIZE_MB}MB (target was <500MB)${NC}"
    log ""
    log "Options to reduce size:"
    log "  1. Remove packages: Edit archiso/packages.x86_64"
    log "  2. Don't bundle Claude Code (download at boot)"
    log "  3. Remove GUI: Remove xorg-server, xorg-xinit, surf"
    log "  4. Minimal firmware: use linux-firmware-minimal"
    log ""
else
    log "${GREEN}✓ ISO is under 500MB target (${ISO_SIZE_MB}MB)${NC}"
fi

log ""
log "═════════════════════════════════════════════════════"
log "Next steps:"
log "═════════════════════════════════════════════════════"
log ""
log "1. Test in QEMU (optional):"
log "   qemu-system-x86_64 -cdrom '$ISO_FILE' -m 2048 -enable-kvm -net nic -net user"
log ""
log "2. Flash to USB/SD Card (with balena-etcher or dd):"
log "   sudo dd if='$ISO_FILE' of=/dev/sdX bs=4M status=progress sync"
log "   (Replace /dev/sdX with: lsblk)"
log ""
log "3. Boot from USB and:"
log "   - Auto-login as root (no password)"
log "   - Network starts automatically"
log "   - Claude Code launches"
log "   - Browser opens for Anthropic login"
log ""
log "═════════════════════════════════════════════════════"
log ""

# Create checksum
if command -v md5sum &>/dev/null; then
    md5sum "$ISO_FILE" > "${ISO_FILE}.md5"
    log "Checksum: $(cat "${ISO_FILE}.md5")"
fi

log ""
log "Log saved to: $LOG_FILE"
log "${GREEN}✓ Done!${NC}"
