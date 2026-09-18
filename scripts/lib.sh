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

# --- Questions asked once, then remembered -----------------------------------
# Answers live in logs/answers.env, so a resumed or repeated run does not ask again. Without a terminal
# (install.sh piped to a log, a container, CI) every question takes its default. KIT_DEFAULTS=1 forces
# the defaults everywhere; delete logs/answers.env to be asked again.
KIT_ANSWERS="${KIT_ANSWERS:-$LOGS/answers.env}"
[[ -r $KIT_ANSWERS ]] && . "$KIT_ANSWERS"

tty_usable() { { : </dev/tty; } 2>/dev/null; }   # readable is not enough: it must open
prompt_fd() { tty_usable && echo /dev/tty || echo /dev/stdin; }
interactive() {
  [[ ${KIT_DEFAULTS:-0} == 1 ]] && return 1
  [[ ${KIT_FORCE_PROMPT:-0} == 1 ]] && return 0
  tty_usable && { [[ ${KIT_INTERACTIVE:-0} == 1 ]] || [[ -t 0 ]]; }
}
remember() { # remember NAME VALUE
  mkdir -p "$(dirname "$KIT_ANSWERS")"; touch "$KIT_ANSWERS"
  sed -i "/^$1=/d" "$KIT_ANSWERS"
  printf '%s=%q\n' "$1" "$2" >>"$KIT_ANSWERS"
  printf -v "$1" '%s' "$2"
}
ask_yes_no() { # ask_yes_no NAME "question" yes|no
  local name=$1 question=$2 default=${3:-no} reply
  [[ -n ${!name:-} ]] && return 0
  if ! interactive; then remember "$name" "$default"; info "$question → $default"; return 0; fi
  printf '    \033[1;36m?\033[0m %s [%s] ' "$question" "$([[ $default == yes ]] && echo Y/n || echo y/N)" >&2
  read -r reply <"$(prompt_fd)" || reply=""
  case ${reply,,} in y|yes|o|oui) reply=yes ;; n|no|non) reply=no ;; *) reply=$default ;; esac
  remember "$name" "$reply"
}
ask_choice() { # ask_choice NAME "question" default option...
  local name=$1 question=$2 default=$3; shift 3
  local options=("$@") reply i
  [[ -n ${!name:-} ]] && return 0
  if ! interactive; then remember "$name" "$default"; info "$question → $default"; return 0; fi
  printf '    \033[1;36m?\033[0m %s\n' "$question" >&2
  for i in "${!options[@]}"; do
    printf '      %2d) %s%s\n' $((i + 1)) "${options[i]}" "$([[ ${options[i]} == "$default" ]] && echo '  (default)')" >&2
  done
  printf '    choice [%s]: ' "$default" >&2
  read -r reply <"$(prompt_fd)" || reply=""
  if [[ $reply =~ ^[0-9]+$ ]] && (( reply >= 1 && reply <= ${#options[@]} )); then
    reply=${options[reply - 1]}
  elif [[ -z $reply ]] || ! printf '%s\n' "${options[@]}" | grep -qxF -- "$reply"; then
    reply=$default
  fi
  remember "$name" "$reply"
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
  export MACHINE_PROFILE_APPLIED=$applied
  (( applied )) || info "no machine profile matches this hardware, generic monitor settings kept"
}

generate_machine_profile() { # write hypr/machines/<machine>/ from the monitors currently connected
  local slug name family dir
  family=$(cat /sys/class/dmi/id/product_family 2>/dev/null || true)
  name=$(cat /sys/class/dmi/id/product_name 2>/dev/null || true)
  [[ -n ${family// } ]] || family=$name
  [[ -n ${family// } ]] || { warn "no DMI identity to match on"; return 1; }
  slug=$(tr 'A-Z ' 'a-z-' <<<"$family" | tr -cd 'a-z0-9-' | sed 's/--*/-/g; s/^-//; s/-$//')
  dir="$KIT_DIR/hypr/machines/$slug"
  mkdir -p "$dir"
  printf '# DMI patterns, one per line, matched against product_name and product_family.\n%s\n' "$family" >"$dir/match"
  {
    printf -- '-- %s: layout of the monitors connected when this profile was generated.\n' "$family"
    printf -- '-- Step 40 applies it only on a machine whose DMI identity matches "match" next to this file.\n'
    printf -- '-- Exact modes: hyprctl monitors all\n\n'
    hyprctl monitors -j | jq -r '.[] |
      "hl.monitor({ output = \"\(.name)\", mode = \"\(.width)x\(.height)@\(.refreshRate | round)\", position = \"\(.x)x\(.y)\", scale = \(.scale) })"'
    printf 'hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })\n'
  } >"$dir/monitors.lua"
  ok "machine profile written: hypr/machines/$slug"
  info "$(grep -c '^hl.monitor' "$dir/monitors.lua") monitor rules; add hl.workspace_rule lines there if you want fixed workspaces"
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
