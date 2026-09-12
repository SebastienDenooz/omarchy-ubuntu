#!/bin/bash
# Étape 41 — Fichiers système (sudo) : session, polices, uwsm, fcitx, drop-ins systemd, sudoers.
# Options : --ufw (pare-feu Omarchy : tout bloqué sauf LocalSend)  --docker (daemon.json Omarchy)
. "$(dirname "$0")/lib.sh"
[[ -L $OMARCHY_SYS ]] || die "lance d'abord 30-checkout.sh"
need sudo

say "Session Wayland « Omarchy (Hyprland uwsm) » pour GDM"
sudo install -Dm644 "$OMARCHY_SYS/default/wayland-sessions/omarchy.desktop" /usr/local/share/wayland-sessions/omarchy.desktop
sudo install -Dm644 "$OMARCHY_SYS/default/uwsm/env.d/10-omarchy" /usr/share/uwsm/env.d/10-omarchy
ok "session + environnement uwsm (OMARCHY_PATH, TERMINAL, EDITOR)"

say "Polices et fontconfig"
sudo install -Dm644 "$OMARCHY_SYS/default/fonts/omarchy/omarchy.ttf" /usr/share/fonts/omarchy/omarchy.ttf
sudo install -Dm644 "$OMARCHY_SYS/default/fontconfig/conf.avail/50-omarchy.conf" /usr/share/fontconfig/conf.avail/50-omarchy.conf
sudo ln -sfn /usr/share/fontconfig/conf.avail/50-omarchy.conf /etc/fonts/conf.d/50-omarchy.conf
sudo fc-cache -f >/dev/null
ok "omarchy.ttf (glyphes du shell), monospace → JetBrainsMono Nerd Font"

say "Terminal par défaut, méthode de saisie, mimeapps"
sudo install -Dm644 "$OMARCHY_SYS/default/xdg-terminal-exec/hyprland-xdg-terminals.list" /usr/share/xdg-terminal-exec/hyprland-xdg-terminals.list
sudo install -Dm644 "$OMARCHY_SYS/default/environment.d/10-omarchy-fcitx.conf" /usr/lib/environment.d/10-omarchy-fcitx.conf
ok "xdg-terminal-exec (foot), fcitx5 (compose avec CapsLock)"

say "fastfetch (About) et kitty (défauts système)"
sudo install -Dm644 "$OMARCHY_SYS/etc/fastfetch/config.jsonc" /etc/fastfetch/config.jsonc
sudo install -Dm644 "$OMARCHY_SYS/etc/xdg/kitty/kitty.conf" /etc/xdg/kitty/kitty.conf
sudo install -Dm644 "$OMARCHY_SYS/icon.png" /usr/share/pixmaps/omarchy.png
ok "fait"

say "Drop-ins systemd / sysctl"
sudo install -Dm644 "$OMARCHY_SYS/etc/systemd/logind.conf.d/10-ignore-power-button.conf" /etc/systemd/logind.conf.d/10-ignore-power-button.conf
sudo install -Dm644 "$OMARCHY_SYS/etc/systemd/logind.conf.d/20-inhibit-delay.conf" /etc/systemd/logind.conf.d/20-inhibit-delay.conf
sudo install -Dm644 "$OMARCHY_SYS/etc/sysctl.d/90-omarchy-file-watchers.conf" /etc/sysctl.d/90-omarchy-file-watchers.conf
sudo sysctl -q --system >/dev/null 2>&1 || true
ok "bouton power → menu Omarchy ; inotify 524288 (le sysctl zram/swappiness d'Omarchy n'est pas repris)"

say "sudoers (fuseau horaire automatique, DNS depuis le menu)"
printf '%%sudo ALL=(root) NOPASSWD: /usr/bin/timedatectl ^set-timezone [A-Za-z0-9_+][A-Za-z0-9_+.-]*(/[A-Za-z0-9_+][A-Za-z0-9_+.-]*)*$\n' | sudo tee /etc/sudoers.d/omarchy-tzupdate >/dev/null
printf '%%sudo ALL=(root) NOPASSWD: /usr/local/bin/omarchy-dns Cloudflare, /usr/local/bin/omarchy-dns Google, /usr/local/bin/omarchy-dns DHCP\n' | sudo tee /etc/sudoers.d/omarchy-dns >/dev/null
sudo chmod 440 /etc/sudoers.d/omarchy-tzupdate /etc/sudoers.d/omarchy-dns
sudo visudo -c >/dev/null && ok "sudoers valides" || die "sudoers invalides : sudo rm /etc/sudoers.d/omarchy-*"

say "PAM de l'écran de verrouillage (shell Omarchy)"
[[ -x /usr/local/bin/omarchy-apply-lock ]] || die "lance d'abord 31-overrides.sh (surcharge omarchy-apply-lock)"
/usr/local/bin/omarchy-apply-lock
ok "/etc/pam.d/omarchy-lock-password (common-auth)"

say "Icônes d'action Nautilus (Yaru)"
sudo mkdir -p /usr/share/icons/Yaru/scalable/actions
for i in go-previous go-next; do sudo ln -snf "/usr/share/icons/Adwaita/symbolic/actions/$i-symbolic.svg" "/usr/share/icons/Yaru/scalable/actions/$i-symbolic.svg"; done
sudo gtk-update-icon-cache /usr/share/icons/Yaru >/dev/null 2>&1 || true
ok "fait"

if [[ " $* " == *" --ufw "* ]]; then
  say "Pare-feu (politique Omarchy)"
  sudo ufw default deny incoming; sudo ufw default allow outgoing
  sudo ufw allow 53317/udp; sudo ufw allow 53317/tcp   # LocalSend
  sudo ufw --force enable; ok "ufw actif (SSH entrant fermé, comme sur Omarchy)"
fi
if [[ " $* " == *" --docker "* ]]; then
  say "Docker : daemon.json Omarchy (DNS 172.17.0.1, rotation des logs)"
  sudo install -Dm644 "$OMARCHY_SYS/etc/docker/daemon.json" /etc/docker/daemon.json
  sudo install -Dm644 "$OMARCHY_SYS/etc/systemd/resolved.conf.d/20-docker-dns.conf" /etc/systemd/resolved.conf.d/20-docker-dns.conf
  sudo systemctl restart systemd-resolved docker; ok "docker reconfiguré"
fi
echo
info "Non repris volontairement : SDDM + thème Omarchy (GDM conservé), Plymouth, Limine, Snapper, faillock PAM, zram."
