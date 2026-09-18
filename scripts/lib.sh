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

os_release() { # os_release KEY
  [[ -r /etc/os-release ]] && ( . /etc/os-release; printf '%s' "${!1:-}" )
}

require_ubuntu() { # the stack needs what only 26.04 LTS and later ship
  local id version
  id=$(os_release ID); version=$(os_release VERSION_ID)
  [[ $id == ubuntu ]] || die "this kit targets Ubuntu (found: ${id:-unknown}); on Arch, install Omarchy itself"
  # Hyprland 0.56 requires Lua 5.5 and the Omarchy shell a recent Qt 6: Ubuntu 24.04 LTS has neither
  # (no lua5.5, Qt 6.4), so 26.04 LTS is the floor.
  awk -v v="${version:-0}" 'BEGIN { split(v, a, "."); exit !(a[1] > 26 || (a[1] == 26 && a[2] >= 4)) }' ||
    die "Ubuntu $version is too old: this kit needs 26.04 LTS or later (Lua 5.5 and Qt 6.10)"
}

apply_machine_profiles() { # copy hypr/machines/<machine>/*.lua when the DMI identity matches
  local dir name pattern applied=0
  for dir in "$KIT_DIR"/hypr/machines/*/; do
    [[ -f $dir/match ]] || continue
    name=$(basename "$dir")
    while read -r pattern; do
      [[ -z $pattern || $pattern == \#* ]] && continue
      if grep -qi "$pattern" /sys/class/dmi/id/product_name /sys/class/dmi/id/product_family 2>/dev/null; then
        install -m644 "$dir"/*.lua "$HOME/.config/hypr/"
        ok "machine profile applied: $name ($pattern)"
        applied=1
        break
      fi
    done < "$dir/match"
  done
  (( applied )) || info "no machine profile matches this hardware, generic monitor settings kept"
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
