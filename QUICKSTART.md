# Quick Start - Build ISO

## TL;DR (Kurz)

Du brauchst ein **Arch Linux System** mit internet. Dann:

```bash
cd ~/Desktop/ai_recovery_linux
chmod +x build.sh
./build.sh
```

Die ISO wird dann in `out/` erstellt. Fertig!

---

## Schritt für Schritt

### 1. Vorbereitung: Arch Linux System

**Lokales Arch Linux:**
```bash
# Check ob Arch:
pacman --version

# Falls nicht: https://wiki.archlinux.org/title/Installation_guide
```

**Oder: Arch in VM (schneller für Test):**
```bash
# VirtualBox / KVM / VMware
# Download: https://archlinux.org/download/
# Installiere minimal-ISO (kannst skip bei setup)
```

**Oder: Docker (wenn kein Arch vorhanden):**
```bash
cd ~/Desktop/ai_recovery_linux

# Build Container
docker build -t ai-recovery-builder .

# Run Build
docker run -v $(pwd)/out:/out ai-recovery-builder
```

### 2. Build

```bash
cd ~/Desktop/ai_recovery_linux

# Mach Script executable
chmod +x build.sh

# Starte Build
./build.sh

# Dann einfach warten... (10-30 Minuten)
```

**Was build.sh macht:**
- ✓ Prüft Arch Linux
- ✓ Installiert archiso (wenn nötig)
- ✓ Validiert alle Dateien
- ✓ Baut ISO mit mkarchiso
- ✓ Prüft Größe
- ✓ Speichert alles in `out/*.iso`

### 3. Output

```
out/
├── ai-recovery-linux-2024.02.15-x86_64.iso  (~400-480MB)
└── ai-recovery-linux-2024.02.15-x86_64.iso.md5
```

Falls erfolgreich: **Größe sollte <500MB sein** ✓

### 4. Testen

**In QEMU (schnell, ohne Hardware):**
```bash
qemu-system-x86_64 \
    -cdrom out/ai-recovery-linux-*.iso \
    -m 2048 \
    -enable-kvm \
    -net nic \
    -net user
```

**Oder: Flash auf USB/SD**
```bash
# Mit balena-etcher (GUI - empfohlen)
# 1. https://www.balena.io/etcher/
# 2. Select: out/*.iso
# 3. Select: USB/SD Device
# 4. Flash

# Oder mit dd:
sudo dd if=out/ai-recovery-linux-*.iso of=/dev/sdX bs=4M status=progress sync
# (Find device: lsblk)
```

---

## Troubleshooting

### Build schlägt fehl: "pacman: command not found"

**Problem:** Du bist nicht auf Arch Linux

**Lösung:**
```bash
# Check System:
uname -a
cat /etc/os-release

# Falls nicht Arch:
# Option 1: In Arch VM bauen
# Option 2: Mit Docker bauen (siehe unten)
```

### Build schlägt fehl: "mkarchiso: command not found"

**Problem:** archiso nicht installiert

**Lösung:**
```bash
sudo pacman -S archiso
./build.sh
```

### Build schlägt fehl: "No space left on device"

**Problem:** Zu wenig Disk-Platz

**Lösung:**
```bash
# Braucht: ~2GB freier Platz
df -h

# Cleanup falls nötig:
sudo pacman -Sc  # Cache leeren
rm -rf ~/Desktop/ai_recovery_linux/work
# Disk-Platz freimachen, dann retry
```

### Build schlägt fehl: Network/Download Fehler

**Problem:** Internet-Verbindung oder Arch-Mirror Problem

**Lösung:**
```bash
# Check Netzwerk:
ping 8.8.8.8

# Besseren Mirror wählen:
sudo pacman-mirrors --geoip
sudo pacman -Syy

# Retry build:
./build.sh
```

### ISO zu groß (>500MB)

**Mögliche Ursachen:**
- Zu viele Packages im image
- Node.js/npm ist groß (~70MB)
- X11 + Browser ist groß (~70MB)

**Lösungen:**

1. **Packages entfernen** (einfach):
   ```bash
   # Edit: archiso/packages.x86_64
   # Entferne z.B.:
   #  - git (spart ~30MB)
   #  - vim, nano (nutze nur einen)
   #  - gparted (parted genügt)

   # Dann neu bauen:
   ./build.sh
   ```

2. **Claude Code nicht bundlen** (spart ~70MB):
   ```bash
   # Edit: archiso/packages.x86_64
   # Entferne:
   #  - nodejs-lts
   #  - npm

   # Edit: archiso/airootfs/root/init-recovery.sh
   # Ändere zu: wget + npm install global

   ./build.sh
   ```

3. **Browser entfernen** (spart ~70MB):
   ```bash
   # Edit: archiso/packages.x86_64
   # Entferne:
   #  - xorg-server
   #  - xorg-xinit
   #  - xterm
   #  - surf

   # Dann Claude per API-Key starten (weniger komfortable)
   ./build.sh
   ```

---

## Mit Docker bauen (Cross-Platform)

Falls kein Arch Linux lokal vorhanden:

```bash
cd ~/Desktop/ai_recovery_linux

# 1. Build Docker Image
docker build -t ai-recovery-builder .

# 2. Run Build (ISO wird in out/ erstellt)
docker run -v $(pwd)/out:/out ai-recovery-builder

# 3. Check Output
ls -lh out/*.iso
```

**Requirements:** Docker installiert (macOS/Linux/Windows)

---

## Wenn alles funktioniert

ISO ist fertig in `out/ai-recovery-linux-*.iso`

**Was jetzt:**

1. **USB-Stick:** Mit balena-etcher oder dd flashen
2. **Boot:** Von USB booten (F12/F2/DEL beim Starten)
3. **Auto-Login:** Root-Zugang sofort
4. **Claude Code:** Startet automatisch
5. **Browser:** Öffnet sich für Anthropic-Login

**Tipps:**
- Ethernet-Verbindung für Claude Code nötig
- Erste Boot dauert länger (DHCP + Browser)
- Nach Auth: `claude` Kommandos im Terminal

---

## Debug-Infos für mich sammeln

Falls was schiefgeht und du Hilfe brauchst:

```bash
# 1. Vollständiger Output speichern:
./build.sh 2>&1 | tee full-build.log

# 2. Diese Dateien für Debugging:
tail -100 build.log
tail -100 full-build.log
lsblk  # Disk info
df -h  # Freier Platz
uname -a  # System info
cat /etc/os-release  # Distribution

# 3. Share output mit mir und ich debugge
```

---

## Weitere Hilfe

- **Arch Wiki:** https://wiki.archlinux.org/title/archiso
- **Archiso Docs:** `man mkarchiso`
- **Claude Code Docs:** https://claude.com/claude-code
- **Mein Code:** Alle Dateien gut dokumentiert, gerne anpassen
