#!/usr/bin/env bash
set -euo pipefail

show_banner() {
cat <<'BAYOU'
=====================================================
        BayouFinds Ops Suite — Linux Launcher
=====================================================
BAYOU
echo
}

ensure_license() {
  local license_dir="$HOME/.bayoufinds"
  local license_file="$license_dir/license.key"

  mkdir -p "$license_dir"

  if [[ ! -f "$license_file" ]]; then
    echo "[INFO] No license key found."
    read -r -p "Enter your license key: " entered_key
    if [[ -z "${entered_key:-}" ]]; then
      echo "[ERROR] No license key entered."
      exit 1
    fi
    printf '%s\n' "$entered_key" > "$license_file"
  fi

  local key
  key="$(tr -d '\r\n' < "$license_file")"

  local valid=false
  for candidate in "BF-2026-001"; do
    if [[ "$key" == "$candidate" ]]; then
      valid=true
      break
    fi
  done

  if [[ "$valid" != true ]]; then
    echo "[ERROR] Invalid license key."
    exit 1
  fi

  echo "[OK] License verified."
  echo
}

run_tool() {
  local script_name="$1"

  if [[ ! -f "$script_name" ]]; then
    echo "[ERROR] Script not found: $script_name"
    read -r -p "Press Enter to continue..."
    return
  fi

  echo "[INFO] Running $script_name ..."
  echo
  bash "$script_name"
  echo
  read -r -p "Press Enter to return to menu..."
}

show_about() {
  echo
  echo "BayouFinds Ops Suite"
  echo
  echo "Cross-platform operations, audit, and access intelligence tooling."
  echo
  echo "Support: support@bayoufinds.com"
  echo "Website: https://bayoufinds.com"
  echo
  read -r -p "Press Enter to return to menu..."
}

show_banner
ensure_license

while true; do
  clear
  show_banner
  echo "[1] Linux Health Check"
  echo "[2] About / Support"
  echo "[0] Exit"
  echo

  read -r -p "Select an option: " choice

  case "$choice" in
    1) run_tool "Linux_Health_Check.sh" ;;
    2) show_about ;;
    0) break ;;
    *) echo "[WARN] Invalid selection."; read -r -p "Press Enter to continue..." ;;
  esac
done
