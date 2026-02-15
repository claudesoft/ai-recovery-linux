# AI Recovery Linux - Ultra-Compact Arch ISO mit Claude Code

## Ziel
Eine bootfähige ISO (<500MB) basierend auf Arch Linux x86-64, die:
- Direkt ohne Login-Prompt startet (auto-login)
- Claude Code CLI automatisch initialisiert
- Browser nur für initiale Anthropic-Authentifizierung öffnet
- Danach Terminal-basiert dem LLM ermöglicht, gemountete Systeme zu reparieren

## Größen-Analyse

**Realistische Komponenten-Größen:**
- Arch Base (minimal): ~180-250MB
- Linux Kernel + initramfs: ~80-120MB
- Claude Code CLI (npm-basiert): ~60-80MB
- Minimal Browser (für Auth): ~40-80MB
- Recovery-Tools: ~30-50MB

**Geschätzt Total: 390-580MB** ⚠️ **Knapp am Limit!**

### Optimierungsstrategien:
1. **Kernel komprimieren** (xz statt gzip): -20MB
2. **Claude Code bei Boot downloaden** statt in ISO: -70MB
3. **Minimal Browser** (links-graphical oder surf): -40MB vs Firefox
4. **Nur essenzielle Arch packages**: base ohne empfohlene packages

**Revidierte Schätzung mit Optimierung: 280-420MB** ✓

## Architektur-Überblick

```
Boot (systemd-boot)
    ↓
Auto-login (getty@tty1 → recovery user)
    ↓
init-recovery.sh
  - Network setup (DHCP)
  - Download Claude Code (wenn nicht in ISO)
  - Start Claude Code CLI
    ↓
Claude Code öffnet Browser für Anthropic Login
    ↓
Zurück zum Terminal - Bereit für Reparatur-Befehle
```

## Implementierungsplan

### Phase 1: Projekt-Struktur erstellen

```
ai_recovery_linux/
├── build.sh                    # Haupt-Build-Script
├── README.md                   # Dokumentation
├── archiso/
│   ├── packages.x86_64         # Minimal package list
│   ├── profiledef.sh           # ISO profile definition
│   ├── pacman.conf             # Pacman config
│   └── airootfs/               # Root filesystem overlay
│       ├── root/
│       │   ├── .bashrc
│       │   └── init-recovery.sh    # Auto-start script
│       ├── etc/
│       │   ├── hostname
│       │   ├── systemd/system/
│       │   │   └── getty@tty1.service.d/
│       │   │       └── autologin.conf
│       │   └── sudoers.d/
│       │       └── recovery-nopasswd
│       └── usr/local/bin/
│           └── setup-claude.sh
```

### Phase 2: Kritische Dateien

#### `archiso/packages.x86_64`
Minimal package set für <500MB:
```
# Base System
base
linux
mkinitcpio
mkinitcpio-archiso

# Boot
syslinux
systemd

# Networking
dhcpcd
iwd
wpa_supplicant

# Node.js für Claude Code
nodejs
npm

# Minimal browser für Auth (OPTION 1: Text-based)
links

# Recovery Tools
parted
e2fsprogs
ntfs-3g
dosfstools
rsync
arch-install-scripts

# Optional: Minimal X + GUI browser (wenn links nicht funktioniert)
# xorg-server
# xorg-xinit
# xterm
# surf
```

**Alternative Browser-Optionen:**
1. **links** (~5MB): Text browser mit basic graphics - unsicher ob Claude Auth funktioniert
2. **surf + minimal X11** (~50-80MB): Minimal WebKit browser - sicherer für Auth
3. **Download beim Boot**: Browser gar nicht in ISO, bei Bedarf downloaden

**Empfehlung:** Surf + X11 für sichere Auth, auch wenn es 50-80MB kostet

#### `archiso/profiledef.sh`
```bash
#!/usr/bin/env bash
iso_name="ai-recovery-linux"
iso_label="AIRECOVERY_$(date +%Y%m)"
iso_publisher="Custom Recovery"
iso_application="AI Recovery Linux with Claude Code"
iso_version="$(date +%Y.%m.%d)"
install_dir="arch"
buildmodes=('iso')
bootmodes=('bios.syslinux.mbr' 'bios.syslinux.eltorito' 'uefi-x64.systemd-boot.esp' 'uefi-x64.systemd-boot.eltorito')
arch="x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'xz' '-Xbcj' 'x86' '-b' '1M' '-Xdict-size' '1M')
file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/root"]="0:0:750"
  ["/root/init-recovery.sh"]="0:0:755"
  ["/usr/local/bin/setup-claude.sh"]="0:0:755"
)
```

#### `airootfs/etc/systemd/system/getty@tty1.service.d/autologin.conf`
```ini
[Service]
ExecStart=
ExecStart=-/sbin/agetty -o '-p -f -- \\u' --noclear --autologin recovery %I $TERM
Type=idle
```

#### `airootfs/root/.bashrc`
```bash
#!/bin/bash
# Auto-start recovery init script on first login
if [[ -z "$RECOVERY_INIT_RAN" ]]; then
    export RECOVERY_INIT_RAN=1
    exec ~/init-recovery.sh
fi
```

#### `airootfs/root/init-recovery.sh`
```bash
#!/bin/bash

clear
cat << "EOF"
╔═══════════════════════════════════════════════════╗
║   AI Recovery Linux - Claude Code Integration    ║
╚═══════════════════════════════════════════════════╝
EOF
echo

# 1. Network Setup
echo "[1/4] Checking network connection..."
if ! ping -c 1 -W 2 8.8.8.8 &>/dev/null; then
    echo "  → Starting DHCP client..."
    systemctl start dhcpcd
    sleep 5

    if ! ping -c 1 -W 2 8.8.8.8 &>/dev/null; then
        echo "  ⚠ WARNING: No network connection!"
        echo "  Claude Code requires internet. Configure manually:"
        echo "  - Ethernet: systemctl start dhcpcd"
        echo "  - WiFi: iwctl (then run setup-claude.sh)"
        echo
        read -p "Press ENTER to continue..."
    fi
else
    echo "  ✓ Network connected"
fi

# 2. Claude Code Installation (if not in ISO)
echo "[2/4] Checking Claude Code installation..."
if ! command -v claude &>/dev/null; then
    echo "  → Installing Claude Code CLI..."
    npm install -g @anthropic-ai/claude-code 2>&1 | grep -v "npm WARN"
    if [ $? -eq 0 ]; then
        echo "  ✓ Claude Code installed"
    else
        echo "  ✗ Installation failed!"
        exit 1
    fi
else
    echo "  ✓ Claude Code already installed"
fi

# 3. Start X11 (if using GUI browser)
if command -v startx &>/dev/null; then
    echo "[3/4] Starting minimal X11 for browser auth..."
    # X11 wird im Hintergrund gestartet für Browser
fi

# 4. Start Claude Code
echo "[4/4] Starting Claude Code..."
echo
echo "┌────────────────────────────────────────────┐"
echo "│ Browser will open for Anthropic login     │"
echo "│ After login, you'll return to terminal    │"
echo "└────────────────────────────────────────────┘"
echo
sleep 2

# Claude Code starten
exec claude
```

#### `airootfs/usr/local/bin/setup-claude.sh`
```bash
#!/bin/bash
# Manueller Setup wenn auto-init fehlschlägt
echo "Setting up Claude Code manually..."
npm install -g @anthropic-ai/claude-code
claude
```

#### `build.sh`
```bash
#!/bin/bash
set -euo pipefail

echo "╔═══════════════════════════════════════════╗"
echo "║  AI Recovery Linux - ISO Builder          ║"
echo "╚═══════════════════════════════════════════╝"
echo

# Check if running on Arch Linux
if ! command -v pacman &>/dev/null; then
    echo "ERROR: This script must run on Arch Linux (needs pacman/archiso)"
    echo "       Use an Arch Linux VM or container to build"
    exit 1
fi

# Install archiso if needed
if ! command -v mkarchiso &>/dev/null; then
    echo "[*] Installing archiso..."
    sudo pacman -S --needed --noconfirm archiso
fi

# Setup directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR="$SCRIPT_DIR/work"
OUT_DIR="$SCRIPT_DIR/out"

echo "[*] Cleaning previous builds..."
sudo rm -rf "$WORK_DIR"
mkdir -p "$OUT_DIR"

# Build ISO
echo "[*] Building ISO (this may take 5-15 minutes)..."
sudo mkarchiso -v -w "$WORK_DIR" -o "$OUT_DIR" "$SCRIPT_DIR/archiso"

# Check result
if [ $? -ne 0 ]; then
    echo "✗ Build failed!"
    exit 1
fi

# Report size
ISO_FILE=$(ls -1 "$OUT_DIR"/*.iso | head -n1)
ISO_SIZE_BYTES=$(stat -f%z "$ISO_FILE" 2>/dev/null || stat -c%s "$ISO_FILE")
ISO_SIZE_MB=$((ISO_SIZE_BYTES / 1024 / 1024))

echo
echo "╔═══════════════════════════════════════════╗"
echo "║  Build Complete!                          ║"
echo "╚═══════════════════════════════════════════╝"
echo "ISO: $ISO_FILE"
echo "Size: ${ISO_SIZE_MB} MB"
echo

if [ $ISO_SIZE_MB -gt 500 ]; then
    echo "⚠ WARNING: ISO is ${ISO_SIZE_MB}MB (over 500MB target)"
    echo "   Consider removing packages or downloading Claude Code at boot"
else
    echo "✓ ISO is under 500MB target"
fi

echo
echo "Next steps:"
echo "  1. Test in VM:    qemu-system-x86_64 -cdrom $ISO_FILE -m 2G -enable-kvm"
echo "  2. Flash to USB:  sudo dd if=$ISO_FILE of=/dev/sdX bs=4M status=progress"
echo "  3. Boot and test Claude Code integration"
```

### Phase 3: Größen-Optimierungen

**Wenn ISO >500MB:**

1. **Claude Code nicht bundlen** (spart ~70MB):
   - Aus `packages.x86_64` entfernen: nodejs, npm
   - Bei jedem Boot downloaden (braucht Internet)
   - Oder: Als optionales "online mode"

2. **Firmware minimieren**:
   - Statt `linux-firmware`: nur `linux-firmware-minimal`
   - Nur Intel/AMD microcode, keine WiFi/Bluetooth firmware

3. **Kernel optimieren**:
   - Custom kernel config ohne unnötige Module
   - Oder: linux-lts statt linux (manchmal kleiner)

4. **Browser weglassen**:
   - Kein Browser in ISO
   - User muss Claude Code API key manuell eingeben
   - Alternative: SSH + Port forwarding für Auth von anderem Gerät

### Phase 4: Testing & Validation

**Test-Umgebung (QEMU):**
```bash
qemu-system-x86_64 \
    -cdrom out/ai-recovery-linux-*.iso \
    -m 2048 \
    -enable-kvm \
    -net nic \
    -net user
```

**Test-Checklist:**
- [ ] Bootet ohne Fehler (BIOS + UEFI)
- [ ] Auto-login funktioniert
- [ ] Netzwerk wird konfiguriert (DHCP)
- [ ] Claude Code startet
- [ ] Browser öffnet für Auth
- [ ] Nach Auth: Terminal-Zugriff
- [ ] Claude kann Befehle ausführen (mount, chroot, etc.)
- [ ] ISO-Größe unter 500MB

### Phase 5: Real-World Usage

**Typischer Workflow:**
```
1. Boot von USB/SD
2. System auto-startet → Claude Code Login
3. User loggt sich bei Anthropic ein
4. Terminal mit Claude Code aktiv

Claude-Befehle:
  "List all disks and partitions"
  "Mount /dev/sda2 and analyze why it won't boot"
  "Fix GRUB configuration on /dev/sda"
  "Chroot into mounted system and update packages"
  "Check systemd services that failed to start"
```

## Finalisierte Konfiguration (User-bestätigt)

### 1. Browser: Surf + minimal X11 ✓
- Surf WebKit browser (~15MB)
- Minimal X11 (xorg-server, xinit) (~50MB)
- Garantiert funktionierende Claude OAuth

### 2. Claude Code: In ISO gebundelt ✓
- Node.js LTS + npm (~50MB)
- @anthropic-ai/claude-code (~20MB)
- Funktioniert offline nach einmaliger Auth

### 3. Build-System: Native Arch Linux ✓
- Direkter archiso build
- Kein Docker-Overhead

### 4. Package Set: Standard Recovery Tools
- parted, e2fsprogs, ntfs-3g, dosfstools
- arch-install-scripts (chroot support)
- rsync, tar, gzip

**Finale Größenschätzung: 420-480MB** ✓ (unter 500MB Limit)

## Geschätzte Timeline

Keine Zeitangaben, aber Schritte:
1. Erstelle Projektstruktur und Files
2. Erste Test-Build auf Arch System
3. Größen-Messung und Optimierung
4. Claude Code Integration testen
5. Boot-Tests (QEMU + echte Hardware)
6. Dokumentation finalisieren

## Risiken & Mitigationen

| Risiko | Wahrscheinlichkeit | Mitigation |
|--------|-------------------|------------|
| ISO >500MB | Hoch | Claude Code download statt bundle |
| Browser Auth funktioniert nicht | Mittel | Fallback: API key manuell |
| Node.js zu groß | Mittel | Alternative: Claude API direkt (ohne CLI) |
| Build braucht Arch Linux | Sicher | Docker container mit Arch |

## Alternativen

**Alpine Linux statt Arch:**
- Vorteil: ~150MB base (100MB kleiner)
- Nachteil: User will Arch, apk statt pacman
- Bewertung: Nur wenn Arch nicht unter 500MB passt

**Minimal Custom Distro:**
- Buildroot oder Yocto
- Extrem klein (~50MB möglich)
- Aufwand: Sehr hoch, komplexe Konfiguration
