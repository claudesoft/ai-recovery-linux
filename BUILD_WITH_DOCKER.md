# Build ISO with Docker

Du brauchst dein Arch Linux zu reparieren? Kein Problem! Mit Docker kannst du die ISO von **jedem System** bauen.

## TL;DR - Schnell

```bash
cd ~/Desktop/ai_recovery_linux

# 1. Build Docker Image (1-2 min)
docker build -t ai-recovery-builder .

# 2. Baue ISO (15-25 min)
docker run -v $(pwd)/out:/out ai-recovery-builder

# 3. Fertig - ISO in out/
ls -lh out/*.iso
```

---

## Requirements

### Docker Installation

**macOS:**
```bash
# Option 1: Homebrew
brew install --cask docker

# Option 2: Docker Desktop
# https://www.docker.com/products/docker-desktop

# Oder: Colima (lightweight)
brew install colima
colima start
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt-get install docker.io
sudo usermod -aG docker $USER
newgrp docker
```

**Windows:**
- [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop)
- Oder: WSL2 + Docker

**Oder: Ohne Installation installiert - Online bauen!**
- GitHub Actions (siehe unten)
- Repl.it oder andere Online Docker Services

---

## Option 1: Lokales Docker

### Step 1: Build Docker Image

```bash
cd ~/Desktop/ai_recovery_linux

# Baue Arch Linux Container mit archiso
docker build -t ai-recovery-builder .
```

**Output während Build:**
```
Sending build context to Docker daemon
Step 1/X : FROM archlinux:base-...
Step 2/X : RUN pacman -Syu --noconfirm
  ... (mehrere Minuten - Downloads archiso und dependencies)
Step X/X : ENTRYPOINT
Successfully built xxxxx
Successfully tagged ai-recovery-builder:latest
```

### Step 2: Starte ISO-Build

```bash
docker run -v $(pwd)/out:/out ai-recovery-builder
```

**Was passiert:**
1. Container startet mit Arch Linux
2. archiso wird ausgeführt
3. ~500MB Packages werden heruntergeladen
4. ISO wird komprimiert
5. Resultat in `out/` speichern

**Output:**
```
╔════════════════════════════════════════════════════╗
║  AI Recovery Linux - Docker ISO Builder            ║
╚════════════════════════════════════════════════════╝

[1/2] Preparing build environment...
[2/2] Building ISO (takes 15-25 minutes)...

... (build output)

╔════════════════════════════════════════════════════╗
║  ✓ BUILD SUCCESSFUL
╚════════════════════════════════════════════════════╝

Output ISO: /out/ai-recovery-linux-2024.02.15-x86_64.iso
Size: 450 MB
✓ ISO is under 500MB target!
```

### Step 3: Check Output

```bash
ls -lh out/

# Output:
# -rw-r--r--  1 user  staff  450M Feb 15 10:45 ai-recovery-linux-2024.02.15-x86_64.iso
# -rw-r--r--  1 user  staff   65B Feb 15 10:45 ai-recovery-linux-2024.02.15-x86_64.iso.md5
```

---

## Option 2: GitHub Actions (kostenlos)

Wenn du GitHub hast, kannst du die ISO kostenlos bauen ohne Docker lokal zu haben!

### Setup

1. **Push dieses Repo zu GitHub:**
   ```bash
   cd ~/Desktop/ai_recovery_linux
   git init
   git add .
   git commit -m "Initial commit: AI Recovery Linux builder"
   git remote add origin https://github.com/YOUR_USERNAME/ai-recovery-linux.git
   git push -u origin main
   ```

2. **Erstelle `.github/workflows/build-iso.yml`:**
   ```yaml
   name: Build ISO

   on:
     push:
       branches: [main]
     workflow_dispatch:

   jobs:
     build:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v3

         - name: Build Docker Image
           run: docker build -t ai-recovery-builder .

         - name: Build ISO
           run: docker run -v $(pwd)/out:/out ai-recovery-builder

         - name: Upload ISO to Release
           uses: softprops/action-gh-release@v1
           if: startsWith(github.ref, 'refs/tags/')
           with:
             files: out/*.iso
           env:
             GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
   ```

3. **Push und GitHub Action startet automatisch:**
   ```bash
   git add .github/workflows/build-iso.yml
   git commit -m "Add GitHub Actions workflow"
   git push
   ```

4. **Check Status:**
   - https://github.com/YOUR_USERNAME/ai-recovery-linux/actions
   - Klick auf "Build ISO"
   - Download ISO nach erfolgreichem Build

---

## Option 3: Cloud-Basiert (keine Installation nötig)

### Repl.it / Replit (kostenlos)

1. Öffne https://replit.com
2. "New Repl" → "Docker"
3. Clone dein Repo:
   ```bash
   git clone https://github.com/YOUR_USERNAME/ai-recovery-linux.git
   cd ai-recovery-linux
   ```
4. Run:
   ```bash
   docker build -t ai-recovery-builder .
   docker run -v $(pwd)/out:/out ai-recovery-builder
   ```
5. Download ISO aus dem Files-Panel

### DigitalOcean / Linode (kostenpflichtig, ~$5)

1. Create new Droplet (Ubuntu 22.04)
2. SSH in droplet
3. Install Docker:
   ```bash
   sudo apt update && sudo apt install docker.io -y
   ```
4. Clone repo und build:
   ```bash
   git clone https://github.com/YOUR_USERNAME/ai-recovery-linux.git
   cd ai-recovery-linux
   docker build -t ai-recovery-builder .
   docker run -v $(pwd)/out:/out ai-recovery-builder
   ```
5. SCP ISO back:
   ```bash
   scp -r root@YOUR_IP:/root/ai-recovery-linux/out .
   ```

---

## Troubleshooting

### Error: "docker: command not found"

```bash
# Check Docker installation
docker --version

# Falls nicht installiert:
# macOS: brew install --cask docker
# Linux: sudo apt install docker.io
# Windows: Download Docker Desktop
```

### Error: "Cannot connect to Docker daemon"

```bash
# Start Docker daemon
sudo systemctl start docker  # Linux
open /Applications/Docker.app  # macOS

# Oder mit Colima
colima start
```

### Error: "permission denied while trying to connect to Docker daemon"

```bash
# Linux: Add your user to docker group
sudo usermod -aG docker $USER
newgrp docker

# macOS: Usually works with Docker Desktop - restart if needed
```

### Build fails: "Package download failed"

```bash
# Retry build (network issue)
docker run -v $(pwd)/out:/out ai-recovery-builder

# Oder: Rebuild image without cache
docker build --no-cache -t ai-recovery-builder .
docker run -v $(pwd)/out:/out ai-recovery-builder
```

### ISO too large (>500MB)

**Lösung:** Siehe `QUICKSTART.md` → "Troubleshooting" → "ISO zu groß"

**Schnell:**
```bash
# Edit archiso/packages.x86_64
# Entferne Zeilen die du nicht brauchst:
#   - git (spart ~30MB)
#   - nano (wenn vim reicht)
#   - xterm (wenn nur surf)

# Rebuild
docker build --no-cache -t ai-recovery-builder .
docker run -v $(pwd)/out:/out ai-recovery-builder
```

---

## Performance & Timing

| Schritt | Zeit | Bemerkung |
|---------|------|----------|
| Docker Image bauen | 5-10 min | Erste Mal: Downloads Arch + archiso |
| ISO bauen | 15-25 min | Downloads ~500MB Packages |
| Gesamt (erstes Mal) | 20-35 min | Abhängig von Internet |
| Gesamt (Rebuild) | 10-15 min | Cache hilft |

---

## Nach dem Build

### 1. Verify ISO

```bash
# Check size
ls -lh out/*.iso

# Check checksum
cat out/*.iso.md5
md5sum -c out/*.iso.md5
```

### 2. Test in QEMU

```bash
# Wenn QEMU installiert
qemu-system-x86_64 -cdrom out/ai-recovery-linux-*.iso -m 2048 -enable-kvm
```

### 3. Flash zu USB/SD

```bash
# macOS:
diskutil list
sudo dd if=out/ai-recovery-linux-*.iso of=/dev/rdiskX bs=4m
diskutil eject /dev/diskX

# Linux:
lsblk
sudo dd if=out/ai-recovery-linux-*.iso of=/dev/sdX bs=4M status=progress sync

# Windows:
# Nutze Balena Etcher: https://www.balena.io/etcher/
```

### 4. Boot & Recover

1. Insert USB in Arch-System das repariert werden soll
2. Boot (F12/F2/DEL)
3. Wähle USB
4. Auto-login + Claude Code startet
5. Browser öffnet für Auth
6. Terminal ready für Reparatur-Befehle

---

## Pro-Tipps

### Rebuild ohne Docker Cache

```bash
docker build --no-cache -t ai-recovery-builder .
```

### Build Progress anzeigen

```bash
docker build --progress=plain -t ai-recovery-builder .
```

### Mit Custom Packages bauen

```bash
# Edit archiso/packages.x86_64
nano archiso/packages.x86_64

# Rebuild
docker build --no-cache -t ai-recovery-builder .
docker run -v $(pwd)/out:/out ai-recovery-builder
```

### Multiple Architektur-Builds

```bash
# Wenn du auch ARM oder andere Archs brauchst
# (sehr advanced - braucht Cross-Compile)
# Siehe: https://wiki.archlinux.org/title/Archiso
```

---

## Häufig gestellte Fragen

**Q: Brauche ich Arch Linux zum Bauen?**
A: Nein! Docker containerisiert Arch. Du kannst auf macOS/Windows/Linux bauen.

**Q: Geht es schneller auf echtem Arch?**
A: Ja, ca 10-15% schneller (no Docker-Overhead). Aber Docker ist praktischer.

**Q: Kann ich die ISO modifizieren?**
A: Ja! Edit `archiso/packages.x86_64` oder Scripts, dann rebuild.

**Q: Funktioniert Docker auf ARM (Apple Silicon)?**
A: Ja, Docker Desktop und Colima unterstützen M1/M2. Beachte aber dass `archiso` x86-64 only ist.

**Q: Kann ich den Build offline machen?**
A: Teilweise. Packages müssen einmal heruntergeladen werden, aber Docker kann cache verwenden.

---

## Noch Fragen?

Alle Dateien sind gut dokumentiert:
- `README.md` - Allgemeine Doku
- `QUICKSTART.md` - Schneller Start
- `VALIDATION_REPORT.md` - Technische Details
- `PLAN.md` - Architektur-Übersicht

**Gib mir einfach Bescheid wenn was nicht funktioniert!**
