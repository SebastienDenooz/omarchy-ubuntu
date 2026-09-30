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
# Chrome >= 154 bundles fontconfig 2.18.3 (cache format 12, Fontations): it symlinks *-le64.cache-{9,10,11} to its
# cache-12 files, whose .woff/.woff2 entries have no family and no charset. fontconfig 2.17 accepts them, and
# Qt 6.10 (upstream fix 80ddc8dee6 not picked to 6.10) crashes on the first glyph fallback. See REPORT.md §13.
sudo install -Dm644 "$KIT_DIR/overrides/fontconfig/09-omarchy-reject-webfonts.conf" /usr/share/fontconfig/conf.avail/09-omarchy-reject-webfonts.conf
sudo ln -sfn /usr/share/fontconfig/conf.avail/09-omarchy-reject-webfonts.conf /etc/fonts/conf.d/09-omarchy-reject-webfonts.conf
sudo fc-cache -f >/dev/null
# Drop Chrome's compat links so the user cache is rebuilt in Ubuntu's own format (Chrome recreates them; the rule
# above is what keeps them harmless).
find "$HOME/.cache/fontconfig" -maxdepth 1 -type l -name '*-le64.cache-*' -delete 2>/dev/null || true
fc-cache >/dev/null 2>&1 || true
ok "omarchy.ttf (shell glyphs), monospace → JetBrainsMono Nerd Font; WOFF/WOFF2 web-font containers rejected"

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

say "Global user units: nothing Hyprland-only in the GDM greeter"
# PPA packages enable their units in /etc/systemd/user, which also applies to GDM's dynamic greeter users:
# hyprpolkitagent segfaulted 5x per greeter start (root crash reports → apport dialogs), hyprsunset failed 5x.
# A per-user mask never reaches the greeter. Omarchy runs none of these as units (the shell is the polkit agent
# and draws the background; night light starts hyprsunset on demand).
for u in hyprpolkitagent hyprpaper hyprsunset hypridle; do sudo systemctl --global disable "$u.service" >/dev/null 2>&1 || true; done
# Masked even when absent: a later install of the package (a hyprland-* dependency) must not re-enable it.
sudo systemctl --global mask hyprpolkitagent.service >/dev/null 2>&1 || true
# The guard also covers the helpers above, should a package reinstall or a rollback enable them globally again.
for u in fumon.service foot-server.service foot-server.socket app-com.mitchellh.ghostty.service \
         hyprpolkitagent.service hyprpaper.service hyprsunset.service hypridle.service; do
  sudo mkdir -p "/etc/systemd/user/$u.d"
  printf '[Unit]\n# omarchy-ubuntu: enabled globally by its package; not in the GDM greeter\nConditionGroup=!gdm\n' | sudo tee "/etc/systemd/user/$u.d/10-omarchy-no-greeter.conf" >/dev/null
done
sudo sh -c 'rm -f /var/crash/_usr_libexec_hyprpolkitagent.*.crash'
ok "hyprpolkitagent masked, hyprpaper/hyprsunset/hypridle disabled globally; greeter guard on fumon/foot/ghostty and the hypr helpers"

say "Speaker tuning dependencies (laptops Omarchy ships a tuning for)"
# Omarchy's first-run applies the speaker tuning; on a matching laptop it fails without the LV2 limiter, and a
# failed first-run step makes first-run retry at every login.
if OMARCHY_PATH="$OMARCHY_SYS" "$OMARCHY_SYS/bin/omarchy-audio-tuning" match >/dev/null 2>&1; then
  # lsp-plugins-lv2: the limiter; libspa-0.2-modules-extra: PipeWire's LV2 filter-graph loader on Ubuntu.
  apt_install lsp-plugins-lv2 libspa-0.2-modules-extra >/dev/null
  ok "lsp-plugins-lv2 + libspa-0.2-modules-extra installed"
else
  skip "no speaker tuning for this machine"
fi

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
