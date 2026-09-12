#!/bin/bash
# Étape 10 — Pile Hyprland 0.56.2 depuis le PPA cppiber/hyprland (Ubuntu 26.04 « resolute »).
# Remplace le Hyprland 0.53.3 des dépôts Ubuntu. Réversible avec : sudo ppa-purge ppa:cppiber/hyprland
. "$(dirname "$0")/lib.sh"
need sudo apt-get

say "Ajout du PPA cppiber/hyprland"
if grep -rqs 'cppiber/hyprland' /etc/apt/sources.list.d/; then
  ok "déjà présent"
else
  apt_install software-properties-common
  sudo add-apt-repository -y ppa:cppiber/hyprland
fi
sudo apt-get update

say "Installation / mise à niveau de la pile Hyprland"
apt_install \
  hyprland hyprland-guiutils hyprland-protocols hyprwayland-scanner libhyprtoolkit6 \
  hyprsunset hyprpicker hyprlock hypridle hyprpaper hyprpolkitagent hyprsysteminfo \
  xdg-desktop-portal-hyprland xdg-desktop-portal-gtk \
  uwsm xdg-terminal-exec lua5.5 liblua5.5-0

say "Versions obtenues"
info "$(Hyprland --version | head -1)"
for p in hyprland hyprland-guiutils hyprsunset xdg-desktop-portal-hyprland uwsm xdg-terminal-exec; do
  printf '    %-32s %s\n' "$p" "$(dpkg-query -W -f='${Version}' "$p" 2>/dev/null)"
done
echo
warn "Hyprland a changé de version : ferme la session graphique et reconnecte-toi avant de tester."
warn "Ta config actuelle (~/.config/hypr/hyprland.conf) reste valable avec 0.56 ; le passage à Omarchy se fait au script 40."
