#!/bin/bash
# Linux Precheck — collects system/storage/network snapshots into a dated text file

set -u
OUTDIR="${OUTDIR:-/home/devops}"
STAMP="$(date +'%d-%m-%Y_%H-%M-%S')"
OUT="${OUTDIR}/precheck_${STAMP}.txt"

mkdir -p "$OUTDIR"

sec () {
  # sec "Title" "command"
  echo -e "\n===== $1 =====" >> "$OUT"
  eval "$2" >> "$OUT" 2>&1
}

# 1) Time & FS
sec "Date & Time Information" "date"
sec "Mounted Filesystems" "df -Th"

# 2) Storage / LVM / Multipath
sec "Block IDs Information" "blkid || echo 'blkid not available'"
sec "Disks Information" "fdisk -l || echo 'fdisk not available'"
sec "Block Storage Information" "lsblk"
sec "Volume Groups Information" "command -v vgdisplay >/dev/null && vgdisplay || echo 'No LVM or vgdisplay missing'"
sec "Logical Volume Information" "command -v lvdisplay >/dev/null && lvdisplay || echo 'No LVM or lvdisplay missing'"
sec "Multipathing Information" "command -v multipath >/dev/null && multipath -ll || echo 'Multipath not configured or tool missing'"

# 3) Network
sec "Network Interfaces" "ifconfig -a 2>/dev/null || ip a"
sec "Routing Table Information" "route -n 2>/dev/null || ip route"

# 4) Memory / Processes / Utilization
sec "System Memory" "free -m"
sec "Processes Information" "ps -elf"
sec "Resource Utilization & Processes Details" "top -bn 1"

# 5) Bootloader (GRUB)
sec "GRUB Information" "cat /etc/grub2.cfg 2>/dev/null || cat /boot/grub2/grub.cfg 2>/dev/null || echo 'GRUB config not found'"

echo -e "\n---\nReport saved to: ${OUT}"
echo "Done."
