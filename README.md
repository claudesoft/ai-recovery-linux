# AI Recovery Linux - Claude Code Edition

Ultra-kompakte Linux-Recovery-Distro basierend auf **Arch Linux x86-64** mit integriertem **Claude Code CLI**.

Bootfähige ISO (<500MB) für die Systemreparatur mit KI-Unterstützung.

## Features

- **Arch Linux Base** - Minimales System mit essentiellen Recovery-Tools
- **Claude Code Integration** - LLM-gestützte Diagnose und Reparatur
- **Auto-Login** - Keine Passwort-Eingabe beim Boot
- **Browser Auth** - Sichere Anthropic-Authentifizierung via Web-Browser
- **X11 + Surf** - Minimaler WebKit-Browser für OAuth-Flows
- **Recovery Tools** - parted, fsck, chroot, rsync, etc.
- **Netzwerk-Konfiguration** - Automatische DHCP auf allen Interfaces

## Requirements

**Build-System:**
- Arch Linux (oder Arch in VM/Container)
- archiso package
- ~500MB Speicherplatz für ISO
- Internet-Verbindung für Package Downloads

**Target-System:**
- x86-64 Prozessor
- Ethernet-Verbindung (für Claude Code)
- USB/SD-Karte oder CD für Boot
- 2GB RAM minimum

## Build

```bash
# 1. Auf Arch Linux System:
cd /path/to/ai_recovery_linux

# 2. Starte Build (dauert 10-20 Minuten):
chmod +x build.sh
./build.sh

# 3. ISO wird erstellt in: out/ai-recovery-linux-*.iso
```

### Build-Output

```
out/
├── ai-recovery-linux-YYYY.MM.DD-x86_64.iso  (400-480MB)
└── ai-recovery-linux-YYYY.MM.DD-x86_64.iso.md5
```

## Nutzung

### Vorbereitung

**Option 1: USB-Stick (Empfohlen)**
```bash
# Mit balena-etcher (GUI)
# - Datei: out/*.iso
# - Device: SD-Karte oder USB
# - Flash

# Oder mit dd:
sudo dd if=out/ai-recovery-linux-*.iso of=/dev/sdX bs=4M status=progress sync
# (Replace /dev/sdX with actual device: lsblk to find)
```

**Option 2: Virtuelle Maschine (QEMU)**
```bash
qemu-system-x86_64 \
  -cdrom out/ai-recovery-linux-*.iso \
  -m 2048 \
  -enable-kvm \
  -net nic \
  -net user
```

### Boot & Nutzung

1. **Boot** von USB/ISO
2. **Auto-Login** als `root` (kein Passwort)
3. **Automatische Init** - Netzwerk-Setup + Claude Code Start
4. **Browser-Fenster** - Öffnet sich für Anthropic Login
5. **Nach Auth** - Terminal mit Claude Code verfügbar

### Beispiel Recovery-Workflow

```bash
# Claude: "Check why /dev/sda1 won't mount"
mount /dev/sda1 /mnt
ls -la /mnt
# Claude can see output and help diagnose

# Claude: "Repair boot loader on /dev/sda"
arch-chroot /mnt
grub-install /dev/sda
exit

# Claude: "Verify system boots now"
reboot
```

## Projektstruktur

```
ai_recovery_linux/
├── build.sh                          # ISO-Build Script
├── README.md                         # Diese Datei
├── PLAN.md                           # Architektur-Dokumentation
└── archiso/
    ├── packages.x86_64               # Package-Liste
    ├── profiledef.sh                 # archiso Konfiguration
    ├── pacman.conf                   # Pacman Mirror-Config
    └── airootfs/                     # Root-Filesystem
        ├── root/
        │   ├── .bashrc               # Auto-start init script
        │   └── init-recovery.sh      # Haupt-Boot-Skript
        ├── etc/
        │   ├── hostname              # System-Name
        │   ├── systemd/system/getty@tty1.service.d/
        │   │   └── autologin.conf    # Auto-login Konfiguration
        │   └── sudoers.d/
        │       └── recovery-nopasswd # Passwortlose sudo
        └── usr/local/bin/
            └── setup-claude.sh       # Manuelle Claude-Installation
```

## Größen-Optimierung

**Aktuelle Größenschätzung: 420-480MB**

Falls ISO >500MB:

1. **Claude Code nicht bundeln** (spart ~70MB):
   - Aus `packages.x86_64` entfernen: `nodejs-lts npm`
   - Wird dann beim Boot heruntergeladen

2. **Minimal Browser** entfernen (spart ~70MB):
   - Aus `packages.x86_64` entfernen: `xorg-server xorg-xinit surf`
   - Nur wenn API-Key manuell eingegeben wird

3. **Firmware minimieren** (spart ~30MB):
   - `linux-firmware-minimal` statt volles linux-firmware

### Package-Liste Optimieren

In `archiso/packages.x86_64`:

```bash
# Unnötige Packages entfernen:
# - git (braucht ~30MB dependencies)
# - vim (nano ist kleiner)
# - gparted (parted command-line reicht)
```

## Troubleshooting

### "No network connection"

```bash
# Manuell Netzwerk starten:
systemctl start dhcpcd

# Oder WiFi:
iwctl
[iwctl]# device list
[iwctl]# station wlan0 scan
[iwctl]# station wlan0 get-networks
[iwctl]# station wlan0 connect SSID
[iwctl]# exit

# Internet prüfen:
ping 8.8.8.8
```

### Claude Code nicht gefunden

```bash
# Manuell neu installieren:
/usr/local/bin/setup-claude.sh

# Oder direkt:
npm install -g @anthropic-ai/claude-code
claude
```

### Browser öffnet nicht

```bash
# Manuell X11 starten:
startx -- -keeptty

# Oder Claude Code ohne Browser:
# - Manuell API-Key eingeben wenn gefragt
# - Oder: ANTHROPIC_API_KEY=your_key_here claude
```

## Claude Code Commands

Übliche Recovery-Befehle:

```bash
# Disk & Partition Info
lsblk
lsblk -fs
parted -l

# Mount & Inspect
mount /dev/sda1 /mnt
ls -la /mnt

# Chroot in zerrissenes System
arch-chroot /mnt /bin/bash

# Filesystem Check
fsck.ext4 /dev/sda1

# Bootloader Repair
arch-chroot /mnt
grub-install /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg

# Package Management
pacman -S package_name
pacman -Syu

# System Logs
journalctl -xe
systemctl status unit_name
```

## Sicherheit

⚠️ **Warning**: Diese ISO startet automatisch als `root` ohne Passwort!

**Nicht für Produktiv-Einsatz geeignet**, nur für:
- Lokale Recovery an heimischen Systemen
- Sichere, vertrauenswürdige Netzwerk-Umgebungen
- Fehlerdiagnose und Reparatur

Für Multi-User-Systeme: Boot-Parameter anpassen oder Passwort in autologin.conf setzen.

## Performance

**Typische Boot-Zeit:** 20-30 Sekunden
**Claude Code Startup:** 5-10 Sekunden
**Browser Auth:** 30-60 Sekunden

## Tipps & Tricks

### Persistent Recovery Boot

1. ISO permanent auf USB installieren (nicht nur dd):
   ```bash
   # Mit Persistent Home:
   mkfs.ext4 /dev/sdX1  # Partition 1
   mkdir /mnt/usb
   mount /dev/sdX1 /mnt/usb
   # ... copy ISO contents
   ```

2. Network Boot (PXE):
   ```bash
   # ISO als NFS Share mounten
   # Boot mit IPXE
   ```

### Automation

```bash
# Recovery Script für Claude:
#!/bin/bash
mount /dev/sda1 /mnt
arch-chroot /mnt pacman -Syu
arch-chroot /mnt grub-install /dev/sda
umount /mnt
```

## Contributing

Verbesserungen willkommen:
- Weitere Recovery-Tools
- Kleinere Package-Dependencies
- Better Error Handling
- Multilingual Support

## License

- **Arch Linux Base**: GPL v2+
- **Claude Code Integration**: Custom (Anthropic)
- **Recovery Scripts**: MIT

## Author

Custom AI-powered Recovery Distro
Built with Arch Linux + Claude AI

---

**Letzte Aktualisierung:** 2026-02-15
