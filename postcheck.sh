#!/bin/bash
# Linux Postcheck — verifies system/services/network health after changes

set -u
OUTDIR="/home/john"
STAMP="$(date +'%d-%m-%Y_%H-%M-%S')"
OUT="${OUTDIR}/postcheck_${STAMP}.txt"
mkdir -p "$OUTDIR"

# You can override these with env vars:
SERVICES="${SERVICES:-sshd crond network firewalld}"
HOSTS="${HOSTS:-8.8.8.8 1.1.1.1}"
PORTS="${PORTS:-22 80 443}"

sec () {
  echo -e "\n===== $1 =====" >> "$OUT"
  eval "$2" >> "$OUT" 2>&1
}

header () {
  echo "Postcheck started at: $(date)" > "$OUT"
  echo "User: $(whoami)" >> "$OUT"
  echo "Hostname: $(hostname -f 2>/dev/null || hostname)" >> "$OUT"
  echo "Kernel: $(uname -r)" >> "$OUT"
  echo "Services: ${SERVICES}" >> "$OUT"
  echo "Hosts to ping: ${HOSTS}" >> "$OUT"
  echo "Ports to test: ${PORTS}" >> "$OUT"
}

header

# 1) Basic system status
sec "Uptime" "uptime"
sec "Time Sync Status" "timedatectl status 2>/dev/null || chronyc tracking 2>/dev/null || ntpq -p 2>/dev/null || echo 'No time tool found'"
sec "SELinux Status" "getenforce 2>/dev/null || echo 'SELinux tool not found'"
sec "Firewall Status" "systemctl is-active firewalld && firewall-cmd --list-all || { echo 'firewalld inactive or missing; dumping iptables'; iptables-save 2>/dev/null || nft list ruleset 2>/dev/null; }"

# 2) Services health
sec "Systemd Failed Units" "systemctl --failed || true"

{
  echo -e '\n--- Service Status Summary ---'
  for s in $SERVICES; do
    if systemctl list-unit-files | grep -q \"${s}.service\"; then
      echo -e "\n[$s]"
      systemctl is-enabled ${s} || true
      systemctl is-active ${s} || true
      systemctl status ${s} --no-pager -l | sed -n '1,25p'
      journalctl -u ${s} --since '1 hour ago' --no-pager -n 50 2>/dev/null || true
    else
      echo "Service ${s} not found (unit file missing?)"
    fi
  done
} >> "$OUT" 2>&1

# 3) Network checks
sec "Interfaces (ip a)" "ip a"
sec "Routing (ip route)" "ip route"
{
  echo -e '\n--- Ping Tests ---'
  for h in $HOSTS; do
    echo -e "\nPinging $h"
    ping -c 4 -W 2 $h || echo "Ping to $h failed"
  done
  echo -e '\n--- DNS Resolution Test (A records) ---'
  getent hosts google.com || host google.com 2>/dev/null || nslookup google.com 2>/dev/null || echo 'DNS tools not found'
} >> "$OUT" 2>&1

# 4) Ports & listeners
sec "Listening Sockets" "ss -tulpn 2>/dev/null || netstat -tulpn 2>/dev/null || echo 'ss/netstat not available'"
{
  echo -e '\n--- Local Port Connectivity ---'
  for p in $PORTS; do
    echo -n "Port $p: "
    (echo >/dev/tcp/127.0.0.1/$p) >/dev/null 2>&1 && echo "OPEN" || echo "CLOSED"
  done
} >> "$OUT" 2>&1

# 5) Storage quick health
sec "Filesystem Usage (df -Th)" "df -Th"
sec "Block Devices (lsblk)" "lsblk"
sec "LVM Summary" "vgdisplay 2>/dev/null || true; lvdisplay 2>/dev/null || true; pvs 2>/dev/null || true"
sec "Multipath" "multipath -ll 2>/dev/null || echo 'Multipath not configured or tool missing'"
sec "RAID (mdadm)" "cat /proc/mdstat 2>/dev/null || echo '/proc/mdstat not present'"

# 6) Package state
sec "Pending Updates (DNF/APT/Zypper)" "dnf -q check-update 2>/dev/null || apt-get -s upgrade 2>/dev/null || zypper lu 2>/dev/null || echo 'No package manager detected'"
sec "Recently Changed Packages (last 24h)" "rpm -qa --last 2>/dev/null | head -n 50 || grep ' install ' /var/log/dpkg.log 2>/dev/null | tail -n 50 || echo 'Package history not available'"

# 7) Logs & errors
sec "Kernel Ring Buffer (last 200 lines)" "dmesg | tail -n 200"
sec "System Journal Errors (last 1h)" "journalctl -p 3 --since '1 hour ago' --no-pager 2>/dev/null || echo 'journalctl not available'"

# 8) Security quick checks
sec "Users Currently Logged In" "who"
sec "Last Logins" "last -n 10 2>/dev/null || lastlog -b 0 2>/dev/null || echo 'last/lastlog not available'"

echo -e "\n---\nReport saved to: ${OUT}" | tee -a "$OUT"
echo "Done."
