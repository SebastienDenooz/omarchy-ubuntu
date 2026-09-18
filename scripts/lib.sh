# shellcheck shell=bash
# Shared helpers for the "Omarchy on Ubuntu" kit. Sourced by every script.
set -euo pipefail

KIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OMARCHY_CHECKOUT="${OMARCHY_CHECKOUT:-$HOME/omarchy}"   # git checkout of basecamp/omarchy
OMARCHY_TAG="${OMARCHY_TAG:-v4.0.3}"                     # targeted stable release
OMARCHY_SYS=/usr/share/omarchy                           # symlink to the checkout (path hardcoded across Omarchy)
DL="$KIT_DIR/dl"; BUILD="$KIT_DIR/build"; LOGS="$KIT_DIR/logs"; BACKUPS="$KIT_DIR/backups"
mkdir -p "$DL" "$BUILD" "$LOGS" "$BACKUPS" "$HOME/.local/bin" "$HOME/.local/share/applications"
export BACKUP_TS="${BACKUP_TS:-$(date +%Y%m%d-%H%M%S)}"
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

# Environment detection. The kit also runs in a container (no systemd user session, no compositor):
# the steps that need a live session are skipped there and reported.
if [[ -f /.dockerenv || ! -d /run/systemd/system ]]; then IN_CONTAINER=1; else IN_CONTAINER=0; fi
has_user_systemd() { (( ! IN_CONTAINER )) && systemctl --user show-environment >/dev/null 2>&1; }
has_hyprland()     { [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]] && command -v hyprctl >/dev/null 2>&1; }

say()  { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
info() { printf '    %s\n' "$*"; }
ok()   { printf '    \033[1;32m✔\033[0m %s\n' "$*"; }
warn() { printf '    \033[1;33m! %s\033[0m\n' "$*" >&2; }
skip() { printf '    \033[1;35m↷ skipped:\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31mERROR: %s\033[0m\n' "$*" >&2; exit 1; }
need() { local c; for c in "$@"; do command -v "$c" >/dev/null 2>&1 || die "missing command: $c"; done; }

fetch() { # fetch URL DESTINATION (skips files already fully downloaded)
  local url=$1 dest=$2
  if [[ -s $dest ]]; then info "already present: $(basename "$dest")"; return 0; fi
  curl -fsSL --retry 3 -o "$dest.part" "$url" && mv "$dest.part" "$dest"
}
apt_install() { sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "$@"; }
dpkg_present() { dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q 'install ok installed'; }

user_systemctl() { # systemctl --user, only when a user manager is reachable
  if has_user_systemd; then systemctl --user "$@"; else skip "systemctl --user $*"; fi
}
hypr_reload() { if has_hyprland; then hyprctl reload >/dev/null 2>&1 || true; else skip "hyprctl reload (no Hyprland session)"; fi; }

backup_path() { # move a path into $BACKUPS/<timestamp>/<absolute path>
  local p=$1
  [[ -e $p || -L $p ]] || return 0
  mkdir -p "$BACKUPS/$BACKUP_TS$(dirname "$p")"
  mv "$p" "$BACKUPS/$BACKUP_TS$p"
  info "backed up: $p → $BACKUPS/$BACKUP_TS$p"
}

omarchy_env() { # load OMARCHY_PATH and PATH the way an Omarchy session does
  [[ -r /etc/omarchy.conf ]] && . /etc/omarchy.conf
  export OMARCHY_PATH="${OMARCHY_PATH:-$OMARCHY_SYS}"
  [[ -r "$OMARCHY_PATH/default/bash/env-bootstrap" ]] && . "$OMARCHY_PATH/default/bash/env-bootstrap"
  export PATH="$OMARCHY_PATH/bin:$PATH"
}

rust_ready() { # Ubuntu's rustup package ships proxies but no toolchain: ensure a stable toolchain exists
  command -v rustup >/dev/null 2>&1 || { cargo --version >/dev/null 2>&1; return; }
  rustup toolchain list 2>/dev/null | grep -q '^stable' || rustup toolchain install stable --profile minimal >/dev/null 2>&1 || return 1
  rustup show active-toolchain >/dev/null 2>&1 || rustup default stable >/dev/null 2>&1
  cargo +stable --version >/dev/null 2>&1
}

link_bins() { # expose bin/omarchy-* in /usr/local/bin (what the Arch package does with /usr/bin/omarchy-*)
  local f
  say "Linking /usr/local/bin → $OMARCHY_SYS/bin"
  for f in "$OMARCHY_SYS"/bin/omarchy*; do
    sudo ln -sfn "$f" "/usr/local/bin/$(basename "$f")"
  done
  ok "$(ls "$OMARCHY_SYS"/bin | wc -l) commands linked"
}
