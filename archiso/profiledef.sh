#!/usr/bin/env bash
# archiso profile definition

iso_name="ai-recovery-linux"
iso_label="AIRECOVERY_$(date +%Y%m)"
iso_publisher="Claude AI Recovery"
iso_application="AI Recovery Linux with Claude Code"
iso_version="$(date +%Y.%m.%d)"
install_dir="arch"
buildmodes=('iso')
bootmodes=('bios.syslinux' 'uefi.systemd-boot')
arch="x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'xz' '-Xbcj' 'x86' '-b' '1M' '-Xdict-size' '1M')

# File permissions for important scripts
file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/root"]="0:0:750"
  ["/root/init-recovery.sh"]="0:0:755"
  ["/usr/local/bin/setup-claude.sh"]="0:0:755"
)
