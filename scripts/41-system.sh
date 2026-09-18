#!/bin/bash
# Step 41 — System files (sudo): session, fonts, uwsm, fcitx, systemd drop-ins, sudoers, lock-screen PAM.
# Options: --ufw (Omarchy firewall policy: everything blocked except LocalSend)  --docker (Omarchy daemon.json)
. "$(dirname "$0")/lib.sh"
[[ -L $OMARCHY_SYS ]] || die "run 30-checkout.sh first"
need sudo

say "Wayland session \"Omarchy (Hyprland uwsm)\" for GDM"
sudo install -Dm644 "$OMARCHY_SYS/default/wayland-sessions/omarchy.desktop" /usr/local/share/wayland-sessions/omarchy.desktop
# Omarchy installs its session environment as /usr/share/uwsm/env.d/10-omarchy, but Ubuntu's uwsm 0.25 only
# sources "uwsm/env" (and "uwsm/env-<desktop>") from each XDG config/data dir, never an env.d/ directory.
# Keep Omarchy's file where it belongs and source it from /etc/xdg/uwsm/env, adding ~/.local/bin (the kit's
# tools) to the PATH. A user's ~/.config/uwsm/env still loads afterwards and wins.
sudo install -Dm644 "$OMARCHY_SYS/default/uwsm/env.d/10-omarchy" /usr/share/uwsm/env.d/10-omarchy
sudo install -d -m 0755 /etc/xdg/uwsm
sudo tee /etc/xdg/uwsm/env >/dev/null <<'UWSMENV'
# omarchy-ubuntu kit — Ubuntu's uwsm reads uwsm/env, not env.d/: load the Omarchy session environment here.
[ -r /usr/share/uwsm/env.d/10-omarchy ] && . /usr/share/uwsm/env.d/10-omarchy
# Tools built by the kit live in ~/.local/bin and ~/.cargo/bin.
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH" ;; esac
UWSMENV
ok "session + uwsm environment (OMARCHY_PATH, TERMINAL, EDITOR, PATH with ~/.local/bin)"

say "Fonts and fontconfig"
sudo install -Dm644 "$OMARCHY_SYS/default/fonts/omarchy/omarchy.ttf" /usr/share/fonts/omarchy/omarchy.ttf
sudo install -Dm644 "$OMARCHY_SYS/default/fontconfig/conf.avail/50-omarchy.conf" /usr/share/fontconfig/conf.avail/50-omarchy.conf
sudo ln -sfn /usr/share/fontconfig/conf.avail/50-omarchy.conf /etc/fonts/conf.d/50-omarchy.conf
sudo fc-cache -f >/dev/null
ok "omarchy.ttf (shell glyphs), monospace → JetBrainsMono Nerd Font"

say "Default terminal, input method, mimeapps"
sudo install -Dm644 "$OMARCHY_SYS/default/xdg-terminal-exec/hyprland-xdg-terminals.list" /usr/share/xdg-terminal-exec/hyprland-xdg-terminals.list
sudo install -Dm644 "$OMARCHY_SYS/default/environment.d/10-omarchy-fcitx.conf" /usr/lib/environment.d/10-omarchy-fcitx.conf
ok "xdg-terminal-exec (foot), fcitx5 (compose on CapsLock)"

say "fastfetch (About) and kitty (system defaults)"
sudo install -Dm644 "$OMARCHY_SYS/etc/fastfetch/config.jsonc" /etc/fastfetch/config.jsonc
sudo install -Dm644 "$OMARCHY_SYS/etc/xdg/kitty/kitty.conf" /etc/xdg/kitty/kitty.conf
sudo install -Dm644 "$OMARCHY_SYS/icon.png" /usr/share/pixmaps/omarchy.png
ok "done"

say "systemd / sysctl drop-ins"
sudo install -Dm644 "$OMARCHY_SYS/etc/systemd/logind.conf.d/10-ignore-power-button.conf" /etc/systemd/logind.conf.d/10-ignore-power-button.conf
sudo install -Dm644 "$OMARCHY_SYS/etc/systemd/logind.conf.d/20-inhibit-delay.conf" /etc/systemd/logind.conf.d/20-inhibit-delay.conf
sudo install -Dm644 "$OMARCHY_SYS/etc/sysctl.d/90-omarchy-file-watchers.conf" /etc/sysctl.d/90-omarchy-file-watchers.conf
(( IN_CONTAINER )) || sudo sysctl -q --system >/dev/null 2>&1 || true
ok "power button → Omarchy menu; inotify 524288 (Omarchy's zram/swappiness sysctl is not carried over)"

say "sudoers (automatic timezone, DNS from the menu)"
# Ubuntu's sudo is built without regex rules: wildcard instead of Omarchy's regular expression.
printf '%%sudo ALL=(root) NOPASSWD: /usr/bin/timedatectl set-timezone *\n' | sudo tee /etc/sudoers.d/omarchy-tzupdate >/dev/null
printf '%%sudo ALL=(root) NOPASSWD: /usr/local/bin/omarchy-dns Cloudflare, /usr/local/bin/omarchy-dns Google, /usr/local/bin/omarchy-dns DHCP\n' | sudo tee /etc/sudoers.d/omarchy-dns >/dev/null
sudo chmod 440 /etc/sudoers.d/omarchy-tzupdate /etc/sudoers.d/omarchy-dns
sudo visudo -c >/dev/null && ok "sudoers valid" || die "invalid sudoers: sudo rm /etc/sudoers.d/omarchy-*"

say "Lock-screen PAM (Omarchy shell)"
[[ -x /usr/local/bin/omarchy-apply-lock ]] || die "run 31-overrides.sh first (omarchy-apply-lock override)"
/usr/local/bin/omarchy-apply-lock
ok "/etc/pam.d/omarchy-lock-password (common-auth)"

say "Nautilus action icons (Yaru)"
sudo mkdir -p /usr/share/icons/Yaru/scalable/actions
for i in go-previous go-next; do sudo ln -snf "/usr/share/icons/Adwaita/symbolic/actions/$i-symbolic.svg" "/usr/share/icons/Yaru/scalable/actions/$i-symbolic.svg"; done
sudo gtk-update-icon-cache /usr/share/icons/Yaru >/dev/null 2>&1 || true
ok "done"

say "gpu-screen-recorder: capability for gsr-kms-server"
if [[ -x $HOME/.local/bin/gsr-kms-server ]]; then sudo setcap cap_sys_admin+ep "$HOME/.local/bin/gsr-kms-server" && ok "cap_sys_admin on gsr-kms-server"; else info "gsr-kms-server missing (script 21 not run)"; fi

if [[ " $* " == *" --ufw "* ]]; then
  say "Firewall (Omarchy policy)"
  sudo ufw default deny incoming; sudo ufw default allow outgoing
  sudo ufw allow 53317/udp; sudo ufw allow 53317/tcp   # LocalSend
  sudo ufw --force enable; ok "ufw active (incoming SSH closed, as on Omarchy)"
fi
if [[ " $* " == *" --docker "* ]]; then
  say "Docker: Omarchy daemon.json (DNS 172.17.0.1, log rotation)"
  sudo install -Dm644 "$OMARCHY_SYS/etc/docker/daemon.json" /etc/docker/daemon.json
  sudo install -Dm644 "$OMARCHY_SYS/etc/systemd/resolved.conf.d/20-docker-dns.conf" /etc/systemd/resolved.conf.d/20-docker-dns.conf
  sudo systemctl restart systemd-resolved docker; ok "docker reconfigured"
fi
echo
info "Deliberately not carried over: SDDM + Omarchy theme (GDM kept), Plymouth, Limine, Snapper, PAM faillock, zram."
