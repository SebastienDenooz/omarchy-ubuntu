#!/bin/bash
# Vérifications préalables. Ne modifie rien.
. "$(dirname "$0")/lib.sh"

say "Système"
info "$(lsb_release -ds 2>/dev/null)  ·  noyau $(uname -r)  ·  $(uname -m)"
info "GPU : $(lspci | grep -iE 'vga|3d' | sed 's/.*: //' | head -1)"
info "Session : XDG_SESSION_TYPE=${XDG_SESSION_TYPE:-?}  gestionnaire : $(basename "$(cat /etc/X11/default-display-manager 2>/dev/null)")"
info "Espace libre /home : $(df -h "$HOME" | awk 'NR==2{print $4}')"

say "Pile Hyprland"
info "Hyprland installé : $(Hyprland --version 2>/dev/null | head -1 | cut -d' ' -f1-2)   (Omarchy $OMARCHY_TAG vise 0.56.2)"
if grep -rqs 'cppiber/hyprland' /etc/apt/sources.list.d/; then ok "PPA cppiber/hyprland présent"; else warn "PPA cppiber/hyprland absent → script 10"; fi
for p in hyprland hyprland-guiutils hyprsunset hyprpicker hyprlock hypridle xdg-desktop-portal-hyprland uwsm xdg-terminal-exec foot alacritty kitty; do
  printf '    %-32s %s\n' "$p" "$(LC_ALL=C apt-cache policy "$p" 2>/dev/null | awk '/Candidate:/{c=$2} /Installed:/{i=$2} END{printf "candidat %s", c; if(i!="(none)"&&i!="") printf "  ·  installé %s", i}')"
done

say "Quickshell (le shell Omarchy tourne dessus)"
info "$(qs --version 2>/dev/null | head -1 || echo 'quickshell ABSENT')"
qml=$(dirname "$(find /usr /home/sebastien/Ubuntu-Hyprland -path '*Quickshell/qmldir' -print -quit 2>/dev/null)")
missing=()
for m in Services/Pipewire Services/UPower Services/Mpris Services/SystemTray Services/Polkit Services/Pam Services/Notifications Networking Bluetooth Hyprland Wayland Io; do
  [[ -f $qml/$m/qmldir ]] || missing+=("$m")
done
if (( ${#missing[@]} )); then warn "modules Quickshell manquants : ${missing[*]}"; else ok "tous les modules Quickshell requis par le shell Omarchy sont présents"; fi
command -v quickshell >/dev/null && ok "binaire 'quickshell' présent" || warn "binaire 'quickshell' absent (Omarchy l'appelle par ce nom)"

say "Outils de construction"
for t in git curl cargo rustup go ruby python3 uv cmake ninja meson qmake6 gcc; do
  printf '    %-8s %s\n' "$t" "$(command -v "$t" >/dev/null && echo présent || echo ABSENT)"
done

say "Dépôt Omarchy"
if [[ -d $OMARCHY_CHECKOUT/.git ]]; then ok "checkout : $OMARCHY_CHECKOUT ($(git -C "$OMARCHY_CHECKOUT" describe --tags --always 2>/dev/null))"; else info "pas encore cloné → script 30"; fi
[[ -L $OMARCHY_SYS ]] && ok "$OMARCHY_SYS → $(readlink "$OMARCHY_SYS")" || info "$OMARCHY_SYS absent → script 30"

say "Clavier"
info "$(grep XKBLAYOUT /etc/default/keyboard)  (Omarchy lit /etc/vconsole.conf : $( [[ -r /etc/vconsole.conf ]] && grep -o 'XKBLAYOUT=.*' /etc/vconsole.conf || echo absent))"
echo
info "Ordre conseillé : 10 → 11 → (déconnexion/reconnexion) → 20 → 21 → 30 → 31 → 41 → 40 → 50 → (60) → déconnexion → session « Omarchy (Hyprland uwsm) »"
