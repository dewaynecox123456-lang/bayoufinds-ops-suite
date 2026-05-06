source ./format.sh
source ./banner.sh
#!/usr/bin/env bash
print_banner
set -euo pipefail

echo "[INFO] BayouFinds System Health Check Toolkit"
echo "[INFO] Licensed Version"
echo

LICENSE_FILE="$HOME/.bayoufinds/license.key"

if [ ! -f "$LICENSE_FILE" ]; then
  echo "[ERROR] License key not found."
  exit 1
fi

LICENSE_KEY=$(tr -d '\r\n' < "$LICENSE_FILE")

VALID_KEYS=("BF-2026-001")

VALID=false
for key in "${VALID_KEYS[@]}"; do
  if [[ "$LICENSE_KEY" == "$key" ]]; then
    VALID=true
    break
  fi
done

if [ "$VALID" = false ]; then
  echo "[ERROR] Invalid license key."
  exit 1
fi

echo "[OK] License verified."
echo "[INFO] Running system scan..."
echo

OUTPUT_DIR="${1:-./output}"
mkdir -p "$OUTPUT_DIR"

REPORT="$OUTPUT_DIR/linux_health_$(date +%Y%m%d_%H%M%S).txt"

IS_OSTREE=false
if [ -f /run/ostree-booted ] || command -v rpm-ostree >/dev/null 2>&1; then
  IS_OSTREE=true
fi

if [ "$IS_OSTREE" = true ]; then
  CHECK_PATH="/var/home"
  PLATFORM="Fedora Silverblue / OSTree"
else
  CHECK_PATH="/"
  PLATFORM="Standard Linux"
fi

TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S %Z')"
HOSTNAME_FQDN="$(hostname -f 2>/dev/null || hostname)"
CURRENT_USER="$(whoami)"
DOMAIN_NAME="$(hostname -d 2>/dev/null || true)"

if command -v realm >/dev/null 2>&1; then
  REALM_INFO="$(realm list 2>/dev/null | awk -F: '/realm-name/ {gsub(/^[ \t]+/, "", $2); print $2; exit}')"
else
  REALM_INFO=""
fi

if [[ -n "${REALM_INFO:-}" ]]; then
  DOMAIN_CONTEXT="$REALM_INFO"
elif [[ -n "${DOMAIN_NAME:-}" ]]; then
  DOMAIN_CONTEXT="$DOMAIN_NAME"
else
  DOMAIN_CONTEXT="N/A"
fi

SCRIPT_VERSION="v1.9"

CRITICAL_COUNT=0
WARN_COUNT=0

DISK_USAGE=$(df "$CHECK_PATH" | awk 'NR==2 {print $5}' | tr -d '%')
UPTIME="$(uptime -p)"

{
  echo "🚨 SYSTEM HEALTH REPORT"
  echo "-----------------------"
  echo
  section "AUDIT METADATA"
  echo "- Generated: $TIMESTAMP"
  echo "- Hostname: $HOSTNAME_FQDN"
  echo "- User: $CURRENT_USER"
  echo "- Domain/Realm: $DOMAIN_CONTEXT"
  echo "- Platform: $PLATFORM"
  echo "- Check Path: $CHECK_PATH"
  echo "- Script Version: $SCRIPT_VERSION"
  echo
} > "$REPORT"

if (( DISK_USAGE > 90 )); then
  {
    echo "CRITICAL:"
    echo "- Disk usage above 90% on $CHECK_PATH ($DISK_USAGE%)"
    echo
  } >> "$REPORT"
  CRITICAL_COUNT=$((CRITICAL_COUNT + 1))
elif (( DISK_USAGE > 75 )); then
  {
    echo "WARN:"
    echo "- Disk usage above 75% on $CHECK_PATH ($DISK_USAGE%)"
    echo
  } >> "$REPORT"
  WARN_COUNT=$((WARN_COUNT + 1))
else
  {
    echo "INFO:"
    echo "- Disk usage normal on $CHECK_PATH ($DISK_USAGE%)"
    echo
  } >> "$REPORT"
fi

{
  echo "INFO:"
  echo "- Uptime: $UPTIME"
  echo
  section "DISK USAGE BREAKDOWN"
  echo "-----------------------"
} >> "$REPORT"

TOP_DIRS="$(
  du -xhd1 /var 2>/dev/null | sort -rh | head -n 6 || true
)"

if [[ -n "$TOP_DIRS" ]]; then
  echo "$TOP_DIRS" >> "$REPORT"
else
  echo "No /var breakdown data available." >> "$REPORT"
fi

TOP_LINE="$(printf '%s\n' "$TOP_DIRS" | sed '/^$/d' | head -n 1 || true)"
TOP_SIZE="$(printf '%s\n' "$TOP_LINE" | awk '{print $1}')"
TOP_PATH="$(printf '%s\n' "$TOP_LINE" | awk '{print $2}')"

{
  echo
  section "/var/lib BREAKDOWN"
  echo "--------------------"
} >> "$REPORT"

VARLIB_DIRS="$(
  du -xhd1 /var/lib 2>/dev/null | sort -rh | head -n 8 || true
)"

if [[ -n "$VARLIB_DIRS" ]]; then
  echo "$VARLIB_DIRS" >> "$REPORT"
else
  echo "No /var/lib breakdown data available." >> "$REPORT"
fi

VARLIB_TOP_LINE="$(printf '%s\n' "$VARLIB_DIRS" | sed '/^$/d' | head -n 1 || true)"
VARLIB_TOP_SIZE="$(printf '%s\n' "$VARLIB_TOP_LINE" | awk '{print $1}')"
VARLIB_TOP_PATH="$(printf '%s\n' "$VARLIB_TOP_LINE" | awk '{print $2}')"

{
  echo
  section "LARGEST FILES (/var/lib)"
  echo "------------------------------"
} >> "$REPORT"

LARGEST_FILES="$(
  find /var/lib -xdev -type f -printf '%s %p\n' 2>/dev/null | sort -nr | head -n 5 | awk '{
    size=$1;
    $1="";
    path=substr($0,2);
    if (size>1073741824)      human=sprintf("%.1fG", size/1073741824);
    else if (size>1048576)    human=sprintf("%.1fM", size/1048576);
    else if (size>1024)       human=sprintf("%.1fK", size/1024);
    else                      human=sprintf("%dB", size);
    print human "\t" path
  }' || true
)"

if [[ -n "$LARGEST_FILES" ]]; then
  echo "$LARGEST_FILES" >> "$REPORT"
else
  echo "No large file data available." >> "$REPORT"
fi

TMP_SIZE="$(du -sh /tmp 2>/dev/null | awk '{print $1}' || true)"
LOG_SIZE="$(du -sh /var/log 2>/dev/null | awk '{print $1}' || true)"

JOURNAL_SIZE="unknown"
if command -v journalctl >/dev/null 2>&1; then
  JOURNAL_SIZE="$(journalctl --disk-usage 2>/dev/null | sed 's/Archived and active journals take up //; s/ in the file system\.//' || true)"
  [[ -z "$JOURNAL_SIZE" ]] && JOURNAL_SIZE="unknown"
fi

{
  echo
  section "TOP SPACE CONSUMER"
} >> "$REPORT"

if [[ -n "${TOP_PATH:-}" && -n "${TOP_SIZE:-}" ]]; then
  echo "$TOP_PATH → $TOP_SIZE" >> "$REPORT"
else
  echo "Unable to determine top space consumer." >> "$REPORT"
fi

{
  echo
  echo "🚨 TOP /var/lib CONSUMER:"
} >> "$REPORT"

if [[ -n "${VARLIB_TOP_PATH:-}" && -n "${VARLIB_TOP_SIZE:-}" ]]; then
  echo "$VARLIB_TOP_PATH → $VARLIB_TOP_SIZE" >> "$REPORT"
else
  echo "Unable to determine top /var/lib consumer." >> "$REPORT"
fi

{
  echo
  section "POTENTIAL CLEANUP TARGETS"
  echo "- /tmp → ${TMP_SIZE:-unknown}"
  echo "- /var/log → ${LOG_SIZE:-unknown}"
  echo "- journald → ${JOURNAL_SIZE:-unknown}"
  echo
  section "CLEANUP INSIGHT"
} >> "$REPORT"

if [[ "${VARLIB_TOP_PATH:-}" == *"/containers"* ]]; then
  echo "Container storage appears to be the biggest consumer. Review podman/docker images, layers, and volumes." >> "$REPORT"
elif [[ "${VARLIB_TOP_PATH:-}" == *"/flatpak"* ]]; then
  echo "Flatpak storage appears large. Review unused runtimes and applications." >> "$REPORT"
elif [[ "${VARLIB_TOP_PATH:-}" == *"/libvirt"* ]]; then
  echo "Virtual machine storage appears large. Review VM disks and snapshots." >> "$REPORT"
elif [[ "${TOP_PATH:-}" == *"/var/log"* ]]; then
  echo "Logs are consuming notable space. Check rotation and old log retention." >> "$REPORT"
elif [[ -n "${VARLIB_TOP_PATH:-}" ]]; then
  echo "Review ${VARLIB_TOP_PATH} for stale data, caches, or oversized application content." >> "$REPORT"
else
  echo "No cleanup insight available from current scan." >> "$REPORT"
fi

{
  echo
  section "TOP ISSUE"
} >> "$REPORT"

if (( CRITICAL_COUNT > 0 )); then
  echo "Disk capacity is critically high" >> "$REPORT"
elif (( WARN_COUNT > 0 )); then
  echo "System nearing disk limits" >> "$REPORT"
elif [[ -n "${VARLIB_TOP_PATH:-}" ]]; then
  echo "Largest storage concentration identified under /var/lib" >> "$REPORT"
else
  echo "No critical issues detected" >> "$REPORT"
fi

{
  echo
  section "RECOMMENDATION"
} >> "$REPORT"

if (( DISK_USAGE > 90 )); then
  echo "Clean files or expand storage immediately." >> "$REPORT"
elif (( DISK_USAGE > 75 )); then
  echo "Monitor disk usage and schedule cleanup." >> "$REPORT"
elif [[ -n "${VARLIB_TOP_PATH:-}" ]]; then
  echo "Investigate ${VARLIB_TOP_PATH} and the largest files listed above before performing cleanup." >> "$REPORT"
else
  echo "System operating normally." >> "$REPORT"
fi

echo >> "$REPORT"
echo "Health check complete: $REPORT" >> "$REPORT"
printf '%s\n' "Health check complete: $REPORT"

# --- Support Footer ---
{
  echo
  section "SUPPORT"
  echo "Support: support@bayoufinds.com"
  echo "Website: https://bayoufinds.com"
} >> "$REPORT"
