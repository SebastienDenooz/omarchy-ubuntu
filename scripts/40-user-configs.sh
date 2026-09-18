#!/bin/bash
# Step 40 — User configs: what /etc/skel and "omarchy finalize user" do on Arch.
# Your current Hyprland config (~/.config/hypr) is moved to backups/; Omarchy uses hyprland.lua.
. "$(dirname "$0")/lib.sh"
[[ -d $OMARCHY_SYS/config ]] || die "run 30-checkout.sh first"
omarchy_env

say "Backing up existing configs → $BACKUPS/$BACKUP_TS"
for p in hypr foot alacritty ghostty kitty btop tmux starship.toml lazygit omarchy fcitx5 imv obsidian opencode \
         xournalpp herdr chromium-flags.conf wireplumber hyprland-preview-share-picker autostart mimeapps.list xdg-terminals.list; do
  backup_path "$HOME/.config/$p"
done
backup_path "$HOME/.XCompose"
backup_path "$HOME/.config/uwsm/env"   # a pre-Omarchy uwsm env (GTK_THEME, cursor…) would override the Omarchy theme

say "Copying $OMARCHY_SYS/config → ~/.config"
( cd "$OMARCHY_SYS/config" && for item in *; do
    case $item in git|chromium) continue ;;   # git/config would overwrite your git identity; chromium → Chrome here
    esac
    cp -a "$item" "$HOME/.config/"
  done )
ok "Omarchy configs in place (hypr, foot, alacritty, ghostty, kitty, btop, tmux, starship, lazygit, omarchy, fcitx5, imv…)"

say "Hyprland overrides for this machine (Belgian AZERTY, monitors, touchpad)"
install -m644 "$KIT_DIR"/hypr/*.lua "$HOME/.config/hypr/"
ok "monitors.lua input.lua bindings.lua looknfeel.lua autostart.lua"

say "Theme templates adapted to Ubuntu"
# foot 1.25 (Ubuntu) does not know [colors-dark]/[colors-light] (foot ≥ 1.26): user template takes priority.
mkdir -p "$HOME/.config/omarchy/themed"; cp -f "$KIT_DIR"/themed/*.tpl "$HOME/.config/omarchy/themed/"
ok "foot.ini.tpl ([colors] section)"

say "Omarchy state (~/.local/state/omarchy)"
st="$HOME/.local/state/omarchy"
mkdir -p "$st"/{toggles/hypr,current,migrations,defaults,done,windows,indicators}
# Only flags.lua is loaded by default (as omarchy-refresh-hyprland does); window-no-gaps.lua and
# single-window-aspect-ratio.lua are dropped in by their toggles (SUPER+SHIFT+Backspace…).
cp -f "$OMARCHY_SYS/default/hypr/toggles/flags.lua" "$st/toggles/hypr/"
rm -f "$st/toggles/hypr/window-no-gaps.lua" "$st/toggles/hypr/single-window-aspect-ratio.lua"
for m in "$OMARCHY_SYS"/migrations/*.sh; do touch "$st/migrations/$(basename "$m")"; done   # Arch migrations: marked as done
mkdir -p "$HOME/.local/state/tensaku"; cp -n "$OMARCHY_SYS/default/tensaku/state.toml" "$HOME/.local/state/tensaku/" 2>/dev/null || true
ok "toggles, migration markers"

say "Web apps and icons"
cp -f "$OMARCHY_SYS"/applications/*.desktop "$HOME/.local/share/applications/"
mkdir -p "$HOME/.local/share/icons/hicolor/256x256/apps" "$HOME/.local/share/icons/hicolor/scalable/apps"
cp -f "$OMARCHY_SYS"/applications/icons/*.png "$HOME/.local/share/icons/hicolor/256x256/apps/" 2>/dev/null || true
cp -f "$OMARCHY_SYS"/applications/icons/*.svg "$HOME/.local/share/icons/hicolor/scalable/apps/" 2>/dev/null || true
gtk-update-icon-cache -f -t "$HOME/.local/share/icons/hicolor" 2>/dev/null || true
mkdir -p "$HOME/.local/share/nautilus-python/extensions"
cp -f "$OMARCHY_SYS"/default/nautilus-python/extensions/*.py "$HOME/.local/share/nautilus-python/extensions/"
ok "$(ls "$OMARCHY_SYS"/applications/*.desktop | wc -l) launchers, Nautilus extensions (LocalSend, Transcode)"

say "File types, default browser and terminal"
sed 's/chromium.desktop/google-chrome.desktop/' "$OMARCHY_SYS/default/applications/mimeapps.list" > "$HOME/.config/mimeapps.list"
env -u BROWSER xdg-settings set default-web-browser google-chrome.desktop 2>/dev/null || warn "xdg-settings: default browser not set (no session); Chrome is in mimeapps.list anyway"
echo "foot.desktop" > "$HOME/.config/xdg-terminals.list"
ok "Chrome as default (Chromium is a snap on Ubuntu), terminal foot — change with: omarchy-default-terminal kitty"

say "XCompose, branding, keyring, user directories"
git_name=$(git config --global user.name || true); git_email=$(git config --global user.email || true)
{ echo "include \"$OMARCHY_SYS/default/xcompose\""; [[ -n $git_name ]] && echo "<Multi_key> <space> <n> : \"$git_name\""; [[ -n $git_email ]] && echo "<Multi_key> <space> <e> : \"$git_email\""; } > "$HOME/.XCompose"
mkdir -p "$HOME/.config/omarchy/branding"
cp -n "$OMARCHY_SYS/logo.txt" "$HOME/.config/omarchy/branding/screensaver.txt" 2>/dev/null || true
cp -n "$OMARCHY_SYS/icon.txt" "$HOME/.config/omarchy/branding/about.txt" 2>/dev/null || true
bash "$OMARCHY_SYS/install/user/default-keyring.sh"
xdg-user-dirs-update; mkdir -p "$HOME/Pictures" "$HOME/Videos" "$HOME/Work"
if has_user_systemd; then gsettings set org.gnome.desktop.interface gtk-enable-primary-paste true 2>/dev/null || true; else skip "gsettings (no session)"; fi
ok "done"

say "Leftover user units from a previous desktop"
# A former Hyprland setup may leave enabled units that now fail (their job belongs to the Omarchy shell) and
# get reported at every login by uwsm's fumon ("Failed unit detected").
for u in swaync waybar hypridle hyprpaper hyprsunset hyprlock ags swww ydotoold nwg-dock-hyprland; do
  # user-written units are backed up; packaged ones (e.g. hyprpaper.service from the PPA) are only disabled
  if [[ -f $HOME/.config/systemd/user/$u.service ]]; then
    user_systemctl disable --now "$u.service" 2>/dev/null || true
    backup_path "$HOME/.config/systemd/user/$u.service"
  elif has_user_systemd && systemctl --user list-unit-files --no-legend "$u.service" 2>/dev/null | grep -qE '^\S+\s+enabled'; then
    systemctl --user mask --now "$u.service" 2>/dev/null || true   # globally enabled by its package: only a mask stops it
  fi
done
has_user_systemd && systemctl --user reset-failed 2>/dev/null || true
ok "checked"

say "Fcitx5: hide the Wayland diagnose notice, keyboard profile = system layout"
# Fcitx cannot push the layout to Hyprland (expected: Hyprland owns the layout, Fcitx only serves the
# CapsLock compose key); this hides its recurring "Wayland diagnose" notification at login.
# Fcitx rewrites its config files when it stops, so make sure it is not running while we write them.
if has_user_systemd; then systemctl --user stop omarchy-fcitx5.service 2>/dev/null || true; fi
pkill -x fcitx5 2>/dev/null || true; sleep 1
mkdir -p "$HOME/.config/fcitx5/conf"
cat > "$HOME/.config/fcitx5/conf/notifications.conf" <<'FCITX'
[HiddenNotifications]
0=wayland-diagnose-other
FCITX
layout=$(grep -oE '^XKBLAYOUT="?[a-z]+' /etc/default/keyboard 2>/dev/null | grep -oE '[a-z]+$' || echo us)
if [[ -f $HOME/.config/fcitx5/profile ]]; then
  sed -i -E "s/^Default Layout=\w+/Default Layout=$layout/; s/^DefaultIM=keyboard-\w+/DefaultIM=keyboard-$layout/; s/^Name=keyboard-\w+/Name=keyboard-$layout/" "$HOME/.config/fcitx5/profile"
else
  printf '[Groups/0]\nName=Default\nDefault Layout=%s\nDefaultIM=keyboard-%s\n\n[Groups/0/Items/0]\nName=keyboard-%s\nLayout=\n\n[GroupOrder]\n0=Default\n' "$layout" "$layout" "$layout" > "$HOME/.config/fcitx5/profile"
fi
ok "fcitx5 profile: keyboard-$layout"

say "User services"
mkdir -p "$HOME/.config/systemd/user/app.slice.d"
for u in bt-agent omarchy-recover-internal-monitor omarchy-sleep-lock omarchy-fcitx5 omarchy-crash-watch; do
  sed 's|/usr/bin/omarchy-|/usr/local/bin/omarchy-|g' "$OMARCHY_SYS/default/systemd/user/$u.service" > "$HOME/.config/systemd/user/$u.service"
done
cp -f "$OMARCHY_SYS/default/systemd/user/app.slice.d/10-oomd.conf" "$HOME/.config/systemd/user/app.slice.d/"
if has_user_systemd; then
  systemctl --user daemon-reload
  systemctl --user enable bt-agent.service omarchy-recover-internal-monitor.service omarchy-sleep-lock.service omarchy-fcitx5.service omarchy-crash-watch.service
  # The Omarchy shell ships its own polkit agent; hyprpolkitagent is enabled globally by its package and
  # would register first ("An authentication agent already exists"), so mask it rather than disable it.
  systemctl --user mask --now hyprpolkitagent.service 2>/dev/null || true
  pkill -x hyprpolkitagent 2>/dev/null || true
  ok "units enabled (start with the next session)"
else
  # No user manager here: enable through the wants/ symlinks, picked up at the first login.
  mkdir -p "$HOME/.config/systemd/user/graphical-session.target.wants" "$HOME/.config/systemd/user/graphical-session-pre.target.wants"
  for u in bt-agent omarchy-sleep-lock omarchy-fcitx5 omarchy-crash-watch; do ln -sfn "../$u.service" "$HOME/.config/systemd/user/graphical-session.target.wants/$u.service"; done
  ln -sfn ../omarchy-recover-internal-monitor.service "$HOME/.config/systemd/user/graphical-session-pre.target.wants/omarchy-recover-internal-monitor.service"
  mkdir -p "$HOME/.config/systemd/user"; ln -sfn /dev/null "$HOME/.config/systemd/user/hyprpolkitagent.service"   # masked: the shell has its own agent
  ok "units enabled through wants/ symlinks (no user manager running)"
fi

say "Omarchy skill for AI agents (Claude Code, Codex…)"
for d in "$HOME/.claude/skills" "$HOME/.codex/skills" "$HOME/.agents/skills"; do
  mkdir -p "$d"; ln -sfn "$OMARCHY_SYS/default/agents/skills/omarchy" "$d/omarchy"
done
ok "~/.claude/skills/omarchy → checkout"

say "Validating the Hyprland Lua configuration"
if command -v Hyprland >/dev/null; then
  export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp/xdg-runtime-$UID}"; mkdir -p "$XDG_RUNTIME_DIR"; chmod 700 "$XDG_RUNTIME_DIR"
  if OMARCHY_PATH="$OMARCHY_SYS" Hyprland --verify-config 2>&1 | grep -q 'config ok'; then ok "Hyprland --verify-config: config ok"; else warn "Hyprland --verify-config reported errors: run it yourself to see them"; fi
else
  skip "Hyprland binary not found"
fi

echo
info "Next: ./41-system.sh (sudo) if not done yet, ./50-theme.sh, then log out and pick the \"Omarchy (Hyprland uwsm)\" session."
info "Your previous config is in $BACKUPS/$BACKUP_TS. Alt+Tab is Omarchy's; your old switcher (~/.config/quickshell/switcher) is no longer launched."
