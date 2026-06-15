#!/usr/bin/env bash
#
# Comprobot installer for macOS and Linux.
#
# Usage (must keep stdin attached for the interactive onboarding prompts):
#   bash <(curl -fsSL https://badluma.github.io/Comprobot-Website/install.sh)
#
# Do NOT pipe with `curl ... | bash` — the pipe steals stdin and the
# onboarding prompts will fail.

set -euo pipefail

DASHBOARD_REPO="badluma/Comprobot-Dashboard"

bold() { printf '\033[1m%s\033[0m\n' "$1"; }
info() { printf '\033[36m==>\033[0m %s\n' "$1"; }
warn() { printf '\033[33mwarning:\033[0m %s\n' "$1" >&2; }
die()  { printf '\033[31merror:\033[0m %s\n' "$1" >&2; exit 1; }

# --- locate the per-OS data directory (must match appdirs.user_data_dir) -----
data_dir() {
  case "$(uname -s)" in
    Darwin) printf '%s/Library/Application Support/Comprobot' "$HOME" ;;
    *)      printf '%s/Comprobot' "${XDG_DATA_HOME:-$HOME/.local/share}" ;;
  esac
}
DATA_DIR="$(data_dir)"

# --- make freshly installed tools usable in this same session ----------------
ensure_path() {
  export PATH="$HOME/.local/bin:$HOME/.bun/bin:$PATH"
}

# --- 1. uv: installs an isolated Python AND the bot CLI ----------------------
install_uv() {
  if command -v uv >/dev/null 2>&1; then
    info "uv already installed"
  else
    info "Installing uv (Python toolchain manager)"
    curl -LsSf https://astral.sh/uv/install.sh | sh
  fi
  ensure_path
  command -v uv >/dev/null 2>&1 || die "uv install failed — is ~/.local/bin on PATH?"
}

# --- 2. bun: the dashboard runtime -------------------------------------------
install_bun() {
  if command -v bun >/dev/null 2>&1; then
    info "bun already installed"
  else
    info "Installing bun (dashboard runtime)"
    curl -fsSL https://bun.sh/install | bash
  fi
  ensure_path
  command -v bun >/dev/null 2>&1 || die "bun install failed — is ~/.bun/bin on PATH?"
}

# --- 3. the bot itself -------------------------------------------------------
install_bot() {
  info "Installing Comprobot"
  uv tool install --force comprobot
  ensure_path
  command -v comprobot >/dev/null 2>&1 || die "comprobot not on PATH after install"
}

# --- 4. resolve which dashboard version this bot wants -----------------------
# Tags are v-prefixed (v1.0.2); the GitHub archive URL must match exactly.
# Normalise so a bare "1.0.2" still resolves.
normalize_tag() {
  case "$1" in
    v*) printf '%s' "$1" ;;
    ?*) printf 'v%s' "$1" ;;
    *)  printf '' ;;
  esac
}

resolve_dashboard_version() {
  local ver
  ver="$(comprobot --dashboard-version 2>/dev/null || true)"
  if [ -n "$ver" ]; then
    normalize_tag "$ver"
    return
  fi
  # Bot didn't pin one — fall back to the latest git tag. (Tags always exist;
  # GitHub Releases may not, so we don't rely on /releases/latest.)
  ver="$(curl -fsSL "https://api.github.com/repos/${DASHBOARD_REPO}/tags" \
          | grep -m1 '"name"' | cut -d'"' -f4 || true)"
  normalize_tag "$ver"
}

# --- 5. download + unpack the dashboard into the data dir --------------------
install_dashboard() {
  local ver url tmp
  ver="$(resolve_dashboard_version)"
  if [ -n "$ver" ]; then
    info "Installing dashboard ${ver}"
    url="https://github.com/${DASHBOARD_REPO}/archive/refs/tags/${ver}.tar.gz"
  else
    warn "No dashboard release found — using latest main"
    url="https://github.com/${DASHBOARD_REPO}/archive/refs/heads/main.tar.gz"
  fi

  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' RETURN
  curl -fsSL "$url" | tar -xz -C "$tmp"

  mkdir -p "$DATA_DIR"
  rm -rf "$DATA_DIR/dashboard"
  # the tarball extracts to a single top-level dir (repo-tag/)
  mv "$tmp"/*/ "$DATA_DIR/dashboard"
}

main() {
  bold "Installing Comprobot + dashboard"
  install_uv
  install_bun
  install_bot
  install_dashboard

  bold "Setup"
  info "Launching onboarding…"
  # onboard runs the interactive setup, then starts the bot (+ dashboard).
  comprobot onboard
}

main "$@"
