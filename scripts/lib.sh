# shellcheck shell=bash
# Fonctions communes du kit « Omarchy sur Ubuntu ». Sourcé par chaque script.
set -euo pipefail

KIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OMARCHY_CHECKOUT="${OMARCHY_CHECKOUT:-$HOME/omarchy}"   # dépôt git basecamp/omarchy
OMARCHY_TAG="${OMARCHY_TAG:-v4.0.3}"                     # version stable ciblée
OMARCHY_SYS=/usr/share/omarchy                           # lien symbolique vers le dépôt
DL="$KIT_DIR/dl"; BUILD="$KIT_DIR/build"; LOGS="$KIT_DIR/logs"; BACKUPS="$KIT_DIR/backups"
mkdir -p "$DL" "$BUILD" "$LOGS" "$BACKUPS" "$HOME/.local/bin" "$HOME/.local/share/applications"
export BACKUP_TS="${BACKUP_TS:-$(date +%Y%m%d-%H%M%S)}"

say()  { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
info() { printf '    %s\n' "$*"; }
ok()   { printf '    \033[1;32m✔\033[0m %s\n' "$*"; }
warn() { printf '    \033[1;33m! %s\033[0m\n' "$*" >&2; }
die()  { printf '\033[1;31mERREUR : %s\033[0m\n' "$*" >&2; exit 1; }
need() { local c; for c in "$@"; do command -v "$c" >/dev/null 2>&1 || die "commande manquante : $c"; done; }
confirm() { local a; read -r -p "$1 [o/N] " a; [[ ${a,,} == o* || ${a,,} == y* ]]; }

fetch() { # fetch URL DESTINATION (reprise : ne retélécharge pas un fichier déjà complet)
  local url=$1 dest=$2
  if [[ -s $dest ]]; then info "déjà présent : $(basename "$dest")"; return 0; fi
  curl -fL --retry 3 --progress-bar -o "$dest.part" "$url" && mv "$dest.part" "$dest"
}
apt_install() { sudo apt-get install -y --no-install-recommends "$@"; }
dpkg_present() { dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q 'install ok installed'; }

backup_path() { # déplace un chemin dans $BACKUPS/<horodatage>/<chemin absolu>
  local p=$1
  [[ -e $p || -L $p ]] || return 0
  mkdir -p "$BACKUPS/$BACKUP_TS$(dirname "$p")"
  mv "$p" "$BACKUPS/$BACKUP_TS$p"
  info "sauvegardé : $p → $BACKUPS/$BACKUP_TS$p"
}

omarchy_env() { # charge OMARCHY_PATH + PATH comme dans une session Omarchy
  [[ -r /etc/omarchy.conf ]] && . /etc/omarchy.conf
  export OMARCHY_PATH="${OMARCHY_PATH:-$OMARCHY_SYS}"
  [[ -r "$OMARCHY_PATH/default/bash/env-bootstrap" ]] && . "$OMARCHY_PATH/default/bash/env-bootstrap"
  export PATH="$OMARCHY_PATH/bin:$PATH"
}

link_bins() { # expose bin/omarchy-* dans /usr/local/bin (équivalent des /usr/bin/omarchy-* du paquet Arch)
  local f
  say "Liens /usr/local/bin → $OMARCHY_SYS/bin"
  for f in "$OMARCHY_SYS"/bin/omarchy*; do
    sudo ln -sfn "$f" "/usr/local/bin/$(basename "$f")"
  done
  ok "$(ls "$OMARCHY_SYS"/bin | wc -l) commandes liées"
}
