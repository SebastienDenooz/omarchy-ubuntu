#!/bin/bash
# Retour arrière. Options : --purge-ppa (revient au Hyprland 0.53.3 d'Ubuntu via ppa-purge)
. "$(dirname "$0")/lib.sh"
need sudo
last=$(ls -1d "$BACKUPS"/20* 2>/dev/null | sort | tail -1 || true)

say "Session et fichiers système Omarchy"
sudo rm -f /usr/local/share/wayland-sessions/omarchy.desktop /usr/share/uwsm/env.d/10-omarchy \
  /etc/omarchy.conf /etc/profile.d/omarchy.sh /etc/sudoers.d/omarchy-tzupdate /etc/sudoers.d/omarchy-dns \
  /etc/fonts/conf.d/50-omarchy.conf /usr/share/fontconfig/conf.avail/50-omarchy.conf \
  /usr/share/xdg-terminal-exec/hyprland-xdg-terminals.list /usr/lib/environment.d/10-omarchy-fcitx.conf \
  /etc/systemd/logind.conf.d/10-ignore-power-button.conf /etc/systemd/logind.conf.d/20-inhibit-delay.conf \
  /etc/sysctl.d/90-omarchy-file-watchers.conf /etc/fastfetch/config.jsonc /etc/xdg/kitty/kitty.conf /usr/share/pixmaps/omarchy.png
sudo rm -rf /usr/share/fonts/omarchy; sudo fc-cache -f >/dev/null
sudo find /usr/local/bin -maxdepth 1 -type l -name 'omarchy*' -delete
[[ -L $OMARCHY_SYS ]] && sudo rm -f "$OMARCHY_SYS"
ok "supprimés (le dépôt $OMARCHY_CHECKOUT est conservé)"

say "Services utilisateur"
systemctl --user disable --now bt-agent.service omarchy-recover-internal-monitor.service omarchy-sleep-lock.service omarchy-fcitx5.service omarchy-crash-watch.service 2>/dev/null || true
rm -f "$HOME"/.config/systemd/user/{bt-agent,omarchy-*}.service; systemctl --user daemon-reload
systemctl --user enable hyprpolkitagent.service 2>/dev/null || true
ok "fait"

say "Configs utilisateur"
if [[ -n $last ]]; then
  info "dernière sauvegarde : $last"
  for p in hypr foot alacritty ghostty kitty btop tmux starship.toml lazygit omarchy fcitx5 imv obsidian opencode xournalpp herdr chromium-flags.conf wireplumber hyprland-preview-share-picker autostart mimeapps.list xdg-terminals.list; do
    if [[ -e $last$HOME/.config/$p ]]; then rm -rf "$HOME/.config/$p"; cp -a "$last$HOME/.config/$p" "$HOME/.config/$p"; info "restauré : ~/.config/$p"; fi
  done
  [[ -e $last$HOME/.XCompose ]] && cp -a "$last$HOME/.XCompose" "$HOME/.XCompose"
else
  warn "aucune sauvegarde trouvée dans $BACKUPS"
fi
ok "ta config Hyprland personnelle (hyprland.conf) est de nouveau active"

if [[ " $* " == *" --purge-ppa "* ]]; then
  say "Retour au Hyprland 0.53.3 d'Ubuntu"
  sudo ppa-purge -y ppa:cppiber/hyprland
fi
info "Déconnecte-toi et choisis la session « Hyprland » classique."
