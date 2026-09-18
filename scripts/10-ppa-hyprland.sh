#!/bin/bash
# Step 10 — Hyprland 0.56.2 stack from the cppiber/hyprland PPA (Ubuntu 26.04 "resolute").
# Replaces the Hyprland 0.53.3 shipped by Ubuntu. Revert with: sudo ppa-purge ppa:cppiber/hyprland
. "$(dirname "$0")/lib.sh"
need sudo apt-get

say "Adding the cppiber/hyprland PPA"
if grep -rqs 'cppiber/hyprland' /etc/apt/sources.list.d/; then
  ok "already present"
else
  apt_install software-properties-common
  sudo add-apt-repository -y ppa:cppiber/hyprland
fi

say "Adding the avengemedia/danklinux PPA (Quickshell 0.3.x, the engine of the Omarchy shell)"
if grep -rqs 'avengemedia/danklinux' /etc/apt/sources.list.d/; then
  ok "already present"
else
  sudo add-apt-repository -y ppa:avengemedia/danklinux
fi
sudo apt-get update

say "Known file conflicts between the PPA and Ubuntu (libhyprcursor, libudis86)"
# The PPA names libhyprcursor1 / libudis86.1 what Ubuntu names libhyprcursor0 / libudis86-0, with the
# same files and no Replaces field, so dpkg refuses to overwrite. Force the overwrite for these two
# packages only, then let apt settle the state.
force=()
dpkg_present libhyprcursor0 && force+=(libhyprcursor1)
dpkg_present libudis86-0    && force+=(libudis86.1)
if (( ${#force[@]} )); then
  sudo apt-get install -y --download-only "${force[@]}"
  debs=()
  for p in "${force[@]}"; do debs+=(/var/cache/apt/archives/"${p}"_*.deb); done
  sudo dpkg -i --force-overwrite "${debs[@]}"
  sudo apt-get -f install -y
  ok "${force[*]} installed over the Ubuntu versions"
fi

say "Installing / upgrading the Hyprland stack"
apt_install \
  hyprland hyprland-guiutils hyprland-protocols hyprwayland-scanner libhyprtoolkit6 \
  hyprsunset hyprpicker hyprlock hypridle hyprpaper hyprpolkitagent hyprsysteminfo \
  xdg-desktop-portal-hyprland xdg-desktop-portal-gtk \
  uwsm xdg-terminal-exec lua5.5 liblua5.5-0
# Quickshell: the kit accepts an already-built quickshell (e.g. from the Ubuntu-Hyprland installer).
if command -v quickshell >/dev/null; then ok "quickshell already present: $(quickshell --version 2>/dev/null | head -1)"; else apt_install quickshell; fi
command -v qs >/dev/null || sudo ln -sfn "$(command -v quickshell)" /usr/local/bin/qs

say "Resulting versions"
info "$(Hyprland --version 2>/dev/null | head -1)"
info "$(quickshell --version 2>/dev/null | head -1)"
for p in hyprland hyprland-guiutils hyprsunset xdg-desktop-portal-hyprland uwsm xdg-terminal-exec; do
  printf '    %-32s %s\n' "$p" "$(dpkg-query -W -f='${Version}' "$p" 2>/dev/null)"
done
echo
if has_hyprland; then
  warn "Hyprland changed version: log out and back in before testing."
  warn "Your current config (~/.config/hypr/hyprland.conf) still works with 0.56; the switch to Omarchy happens in script 40."
fi
