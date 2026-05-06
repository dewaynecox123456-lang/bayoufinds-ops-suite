section() {
  local title="$1"
  echo "══════════════════════════════════════"
  echo "$title"
  echo "══════════════════════════════════════"
}

subsection() {
  local title="$1"
  echo
  echo "---- $title ----"
}

info() {
  echo "[INFO] $1"
}

warn() {
  echo "[WARN] $1"
}

critical() {
  echo "[CRITICAL] $1"
}
