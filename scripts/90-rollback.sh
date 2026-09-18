#!/bin/bash
# Rollback. Options: --purge-ppa (back to Ubuntu's Hyprland 0.53.3 via ppa-purge)
. "$(dirname "$0")/lib.sh"
need sudo
last=$(ls -1d "$BACKUPS"/20* 2>/dev/null | sort | tail -1 || true)

say "Omarchy session and system files"
sudo rm -f /usr/local/share/wayland-sessions/omarchy.desktop /usr/share/uwsm/env.d/10-omarchy \
  /etc/omarchy.conf /etc/profile.d/omarchy.sh /etc/sudoers.d/omarchy-tzupdate /etc/sudoers.d/omarchy-dns \
  /etc/pam.d/omarchy-lock-password /etc/pam.d/omarchy-lock-fingerprint \
  /etc/fonts/conf.d/50-omarchy.conf /usr/share/fontconfig/conf.avail/50-omarchy.conf \
  /usr/share/xdg-terminal-exec/hyprland-xdg-terminals.list /usr/lib/environment.d/10-omarchy-fcitx.conf \
  /etc/systemd/logind.conf.d/10-ignore-power-button.conf /etc/systemd/logind.conf.d/20-inhibit-delay.conf \
  /etc/sysctl.d/90-omarchy-file-watchers.conf /etc/fastfetch/config.jsonc /etc/xdg/kitty/kitty.conf /usr/share/pixmaps/omarchy.png
grep -qs 'omarchy-ubuntu kit' /etc/xdg/uwsm/env && sudo rm -f /etc/xdg/uwsm/env
sudo rm -rf /usr/share/fonts/omarchy; sudo fc-cache -f >/dev/null
sudo find /usr/local/bin -maxdepth 1 -type l -name 'omarchy*' -delete
[[ -L $OMARCHY_SYS ]] && sudo rm -f "$OMARCHY_SYS"
ok "removed (the $OMARCHY_CHECKOUT checkout is kept)"

say "User services"
systemctl --user disable --now bt-agent.service omarchy-recover-internal-monitor.service omarchy-sleep-lock.service omarchy-fcitx5.service omarchy-crash-watch.service voxtype.service 2>/dev/null || true
rm -f "$HOME"/.config/systemd/user/{bt-agent,omarchy-*,voxtype}.service; systemctl --user daemon-reload
systemctl --user enable hyprpolkitagent.service 2>/dev/null || true
ok "done"

say "User configs"
if [[ -n $last ]]; then
  info "latest backup: $last"
  for p in hypr foot alacritty ghostty kitty btop tmux starship.toml lazygit omarchy fcitx5 imv obsidian opencode xournalpp herdr chromium-flags.conf wireplumber hyprland-preview-share-picker autostart mimeapps.list xdg-terminals.list; do
    if [[ -e $last$HOME/.config/$p ]]; then rm -rf "$HOME/.config/$p"; cp -a "$last$HOME/.config/$p" "$HOME/.config/$p"; info "restored: ~/.config/$p"; fi
  done
  [[ -e $last$HOME/.XCompose ]] && cp -a "$last$HOME/.XCompose" "$HOME/.XCompose"
  [[ -e $last$HOME/.config/uwsm/env ]] && mkdir -p "$HOME/.config/uwsm" && cp -a "$last$HOME/.config/uwsm/env" "$HOME/.config/uwsm/env"
else
  warn "no backup found in $BACKUPS"
fi
ok "your personal Hyprland config (hyprland.conf) is active again"

if [[ " $* " == *" --purge-ppa "* ]]; then
  say "Back to Ubuntu's Hyprland 0.53.3"
  sudo ppa-purge -y ppa:cppiber/hyprland
fi
info "Log out and pick the classic \"Hyprland\" session."
