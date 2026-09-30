#!/bin/bash
# Rollback. Options: --purge-ppa (back to Ubuntu's Hyprland 0.53.3 via ppa-purge)
. "$(dirname "$0")/lib.sh"
need sudo
# The backup step 40 took before Omarchy's configs existed (recorded in backups/pre-omarchy). Kits older than that
# marker: the newest backup holding a step-40 path that is not a copy of Omarchy's own configs (a step-40 re-run
# backs up .config/omarchy; step 21 re-runs back up only nvim; font-fix and zshrc backups hold no .config tree).
last=""
if [[ -r $BACKUPS/pre-omarchy ]] && d=$BACKUPS/$(<"$BACKUPS/pre-omarchy") && [[ -d $d ]]; then last=$d; fi
if [[ -z $last ]]; then
  while IFS= read -r d; do
    [[ -e $d$HOME/.config/omarchy ]] && continue
    for p in "${USER_CONFIG_PATHS[@]}"; do [[ -e $d$HOME/.config/$p ]] && { last=$d; break 2; }; done
    [[ -e $d$HOME/.XCompose || -e $d$HOME/.config/uwsm/env ]] && { last=$d; break; }
  done < <(find "$BACKUPS" -mindepth 1 -maxdepth 1 -type d -name '20*' 2>/dev/null | sort -r)
fi

say "Omarchy session and system files"
sudo rm -f /usr/local/share/wayland-sessions/omarchy.desktop /usr/share/uwsm/env.d/10-omarchy \
  /etc/omarchy.conf /etc/profile.d/omarchy.sh /etc/sudoers.d/omarchy-tzupdate /etc/sudoers.d/omarchy-dns \
  /etc/pam.d/omarchy-lock-password /etc/pam.d/omarchy-lock-fingerprint \
  /etc/fonts/conf.d/50-omarchy.conf /usr/share/fontconfig/conf.avail/50-omarchy.conf \
  /usr/share/xdg-terminal-exec/hyprland-xdg-terminals.list /usr/lib/environment.d/10-omarchy-fcitx.conf \
  /etc/systemd/logind.conf.d/10-ignore-power-button.conf /etc/systemd/logind.conf.d/20-inhibit-delay.conf \
  /etc/sysctl.d/90-omarchy-file-watchers.conf /etc/fastfetch/config.jsonc /etc/xdg/kitty/kitty.conf /usr/share/pixmaps/omarchy.png
grep -qs 'omarchy-ubuntu kit' /etc/xdg/uwsm/env && sudo rm -f /etc/xdg/uwsm/env
# 09-omarchy-reject-webfonts.conf is kept on purpose: without it any Qt 6.10 app crashes again on Chrome's
# cache-12 placeholders. The greeter drop-ins (ConditionGroup=!gdm) are kept too: they only affect GDM.
sudo rm -rf /usr/share/fonts/omarchy; sudo fc-cache -f >/dev/null
sudo find /usr/local/bin -maxdepth 1 -type l -name 'omarchy*' -delete
[[ -L $OMARCHY_SYS ]] && sudo rm -f "$OMARCHY_SYS"
ok "removed (the $OMARCHY_CHECKOUT checkout is kept)"

say "User services"
# First-run's speaker tuning (laptops Omarchy ships one for): stop its unit, drop its PipeWire config, move the
# default sink back to the speakers. Run from the kept checkout: /usr/share/omarchy is gone by now.
if [[ -e $HOME/.config/systemd/user/omarchy-speaker-tuning.service || -e $HOME/.config/pipewire/omarchy-speaker-tuning.conf ]]; then
  OMARCHY_PATH="$OMARCHY_CHECKOUT" PATH="$OMARCHY_CHECKOUT/bin:$PATH" "$OMARCHY_CHECKOUT/bin/omarchy-audio-tuning" off || true
fi
systemctl --user disable --now bt-agent.service omarchy-recover-internal-monitor.service omarchy-sleep-lock.service omarchy-migrate-notify.service omarchy-fcitx5.service omarchy-crash-watch.service voxtype.service 2>/dev/null || true
rm -f "$HOME"/.config/systemd/user/{bt-agent,omarchy-*,voxtype}.service "$HOME"/.config/systemd/user/omarchy-*.{path,timer,socket}
find "$HOME/.config/systemd/user" -mindepth 2 -maxdepth 2 -path '*.wants/*' \( -name 'omarchy-*' -o -name bt-agent.service \) -xtype l -delete 2>/dev/null || true
# Undo the masks of step 40 (a plain enable cannot override a mask) and the step-41 global mask.
for u in swaync mako dunst xfce4-notifyd waybar hypridle hyprpaper hyprsunset hyprlock ags swww ydotoold nwg-dock-hyprland hyprpolkitagent; do
  if [[ $(readlink "$HOME/.config/systemd/user/$u.service" 2>/dev/null) == /dev/null ]]; then systemctl --user unmask "$u.service" 2>/dev/null || rm -f "$HOME/.config/systemd/user/$u.service"; fi
done
systemctl --user unmask 'app-blueman@autostart.service' 'app-nm\x2dtray\x2dautostart@autostart.service' 'app-update\x2dnotifier@autostart.service' 2>/dev/null || true
# Unmasked, not re-enabled: enabled globally it segfaults in GDM's greeter, and enabled per user it starts (and
# crashes) in GNOME, which has its own agent. A classic Hyprland config starts it with exec-once.
sudo systemctl --global unmask hyprpolkitagent.service 2>/dev/null || true
rm -f "$HOME/.local/share/dbus-1/services/org.freedesktop.Notifications.service"
rm -rf "$HOME/.config/systemd/user/update-notifier-crash.service.d"
systemctl --user daemon-reload 2>/dev/null || true
ok "done"
info "hyprpolkitagent, hyprpaper, hyprsunset and hypridle stay disabled (they crashed or failed in the GDM greeter"
info "and GNOME): start them from your Hyprland config (exec-once), or systemctl --user enable <unit> if you want."

say "User configs"
if [[ -n $last ]]; then
  info "pre-Omarchy backup: $last"
  for p in "${USER_CONFIG_PATHS[@]}"; do
    if [[ -e $last$HOME/.config/$p ]]; then rm -rf "$HOME/.config/$p"; cp -a "$last$HOME/.config/$p" "$HOME/.config/$p"; info "restored: ~/.config/$p"; fi
  done
  [[ -e $last$HOME/.XCompose ]] && cp -a "$last$HOME/.XCompose" "$HOME/.XCompose"
  [[ -e $last$HOME/.config/uwsm/env ]] && mkdir -p "$HOME/.config/uwsm" && cp -a "$last$HOME/.config/uwsm/env" "$HOME/.config/uwsm/env"
  # Leave no Omarchy tree behind, so a later reinstall records a fresh pre-Omarchy backup (step 40 keys on
  # ~/.config/omarchy); the rollback's own backup holds .config/omarchy, so the fallback above skips it.
  backup_path "$HOME/.config/omarchy"
  rm -f "$BACKUPS/pre-omarchy"
  ok "your previous configs from ${last##*/} are restored"
else
  warn "no pre-Omarchy backup found in $BACKUPS: ~/.config left unchanged"
fi

say "Omarchy links outside ~/.config"
# Agent skills and browser native-messaging hosts point into the removed /usr/share/omarchy.
for d in "$HOME/.agents/skills" "$HOME/.claude/skills" "$HOME/.codex/skills" "$HOME/.pi/agent/skills" "$HOME/.hermes/skills"; do
  for l in "$d"/*; do
    if [[ -L $l && $(readlink "$l") == "$OMARCHY_SYS"/* ]]; then rm -f "$l"; fi
  done
done
rm -f "$HOME"/.config/{chromium,google-chrome,google-chrome-beta,google-chrome-unstable,microsoft-edge,microsoft-edge-dev,BraveSoftware/Brave-Browser,BraveSoftware/Brave-Browser-Beta,BraveSoftware/Brave-Browser-Nightly}/NativeMessagingHosts/com.omarchy.{copy_url,ytdlp}.json
ok "agent skill links and browser helpers removed"
info "The mise launchers in ~/.local/bin (codex, gemini, pi…) are kept: they run through mise, not Omarchy."

if [[ " $* " == *" --purge-ppa "* ]]; then
  say "Back to Ubuntu's Hyprland 0.53.3"
  sudo ppa-purge -y ppa:cppiber/hyprland
fi
info "Log out and pick the classic \"Hyprland\" session."
