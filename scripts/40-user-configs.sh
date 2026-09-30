#!/bin/bash
# Step 40 — User configs: what /etc/skel and "omarchy finalize user" do on Arch (the Ubuntu-safe parts).
# Your current Hyprland config (~/.config/hypr) is moved to backups/; Omarchy uses hyprland.lua.
. "$(dirname "$0")/lib.sh"
[[ -d $OMARCHY_SYS/config ]] || die "run 30-checkout.sh first"
omarchy_env

say "Backing up existing configs → $BACKUPS/$BACKUP_TS"
# The first backup taken before Omarchy's configs exist is the one rollback restores.
if [[ ! -e $HOME/.config/omarchy && ! -e $BACKUPS/pre-omarchy ]]; then mkdir -p "$BACKUPS"; echo "$BACKUP_TS" > "$BACKUPS/pre-omarchy"; fi
for p in "${USER_CONFIG_PATHS[@]}"; do
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

say "Hyprland overrides (generic: layout and monitors follow the system)"
install -m644 "$KIT_DIR"/hypr/*.lua "$HOME/.config/hypr/"
ok "monitors.lua input.lua bindings.lua looknfeel.lua autostart.lua"

# Touchpad scrolling is a preference, not a fact about the machine: Omarchy ships traditional scrolling.
ask_yes_no KIT_NATURAL_SCROLL "Natural (inverted) touchpad scrolling?" no
[[ $KIT_NATURAL_SCROLL == yes ]] || sed -i 's/natural_scroll = true/natural_scroll = false/' "$HOME/.config/hypr/input.lua"
ok "touchpad: natural scrolling $KIT_NATURAL_SCROLL"

apply_machine_profiles
# Nothing on file for this hardware: offer to capture the monitors as they are wired right now.
if has_hyprland && [[ ${MACHINE_PROFILE_APPLIED:-0} != 1 ]]; then
  ask_yes_no KIT_MACHINE_PROFILE "Save the monitors connected right now as a profile for this machine?" no
  [[ $KIT_MACHINE_PROFILE == yes ]] && { generate_machine_profile && apply_machine_profiles; }
fi

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
if command -v google-chrome-stable >/dev/null; then
  sed 's/chromium.desktop/google-chrome.desktop/' "$OMARCHY_SYS/default/applications/mimeapps.list" >"$HOME/.config/mimeapps.list"
  env -u BROWSER xdg-settings set default-web-browser google-chrome.desktop 2>/dev/null ||
    warn "xdg-settings: default browser not set (no session); Chrome is in mimeapps.list anyway"
  ok "default browser: Google Chrome"
else
  cp "$OMARCHY_SYS/default/applications/mimeapps.list" "$HOME/.config/mimeapps.list"
  warn "no Chromium-family browser installed: web apps and the browser hotkeys will not work until you install one"
fi

# Omarchy's own default is foot; the others are offered when they are installed.
terminals=(foot); for t in kitty alacritty ghostty; do command -v "$t" >/dev/null && terminals+=("$t"); done
ask_choice KIT_TERMINAL "Default terminal?" foot "${terminals[@]}"
case $KIT_TERMINAL in
  kitty) echo "kitty.desktop" ;;
  alacritty) echo "Alacritty.desktop" ;;
  ghostty) echo "com.mitchellh.ghostty.desktop" ;;
  *) echo "foot.desktop" ;;
esac >"$HOME/.config/xdg-terminals.list"
ok "default terminal: $KIT_TERMINAL — change later with: omarchy-default-terminal <name>"

say "XCompose, branding, user directories"
git_name=$(git config --global user.name || true); git_email=$(git config --global user.email || true)
{ echo "include \"$OMARCHY_SYS/default/xcompose\""; [[ -n $git_name ]] && echo "<Multi_key> <space> <n> : \"$git_name\""; [[ -n $git_email ]] && echo "<Multi_key> <space> <e> : \"$git_email\""; } > "$HOME/.XCompose"
mkdir -p "$HOME/.config/omarchy/branding"
cp -n "$OMARCHY_SYS/logo.txt" "$HOME/.config/omarchy/branding/screensaver.txt" 2>/dev/null || true
cp -n "$OMARCHY_SYS/icon.txt" "$HOME/.config/omarchy/branding/about.txt" 2>/dev/null || true
# Omarchy's default-keyring.sh (a passwordless default keyring, for SDDM autologin) is not run: on Ubuntu, GDM's
# pam_gnome_keyring unlocks the encrypted login keyring, and a passwordless default would store every new secret
# unencrypted, in GNOME too. Where an earlier kit already created it, it is left in place on purpose: Chrome and the
# Secret portal read their keys through the "default" alias, so switching it back to login would make everything
# they encrypted since then unreadable. Only a plaintext Omarchy keyring next to an existing login keyring is flagged.
kd=$HOME/.local/share/keyrings
if [[ -f $kd/default && -f $kd/login.keyring && $(tr -d '[:space:]' <"$kd/default") == Default_keyring \
      && $(head -c 9 "$kd/Default_keyring.keyring" 2>/dev/null) == '[keyring]' ]]; then
  warn "the default keyring is Omarchy's unencrypted Default_keyring (earlier kit): new secrets are stored in clear."
  warn "Protect it with a password in Passwords and Keys (seahorse); do not just switch back to 'login' (Chrome would lose its key)."
fi
xdg-user-dirs-update; mkdir -p "$HOME/Pictures" "$HOME/Videos" "$HOME/Work"
if has_user_systemd; then gsettings set org.gnome.desktop.interface gtk-enable-primary-paste true 2>/dev/null || true; else skip "gsettings (no session)"; fi
ok "done"

say "Leftover user units from a previous desktop"
# A former Hyprland setup may leave enabled units that now fail (their job belongs to the Omarchy shell) and
# get reported at every login by uwsm's fumon ("Failed unit detected").
# Packaged units are masked whatever their state: a disabled unit still starts through D-Bus activation or a
# global enable in /etc/systemd/user. User-written units are backed up first.
for u in swaync mako dunst xfce4-notifyd waybar hypridle hyprpaper hyprsunset hyprlock ags swww ydotoold nwg-dock-hyprland; do
  f=$HOME/.config/systemd/user/$u.service
  # anything but an existing mask: regular files, symlinks into a dotfiles repo, dangling links
  if [[ -e $f || -L $f ]] && [[ $(readlink -f -- "$f") != /dev/null ]]; then user_systemctl disable --now "$u.service" 2>/dev/null || true; backup_path "$f"; fi
  if user_unit_shipped "$u.service"; then
    if has_user_systemd; then systemctl --user mask --now "$u.service" 2>/dev/null || true; else mkdir -p "${f%/*}"; ln -sfn /dev/null "$f"; fi
  fi
done
has_user_systemd && systemctl --user reset-failed 2>/dev/null || true
ok "checked"

say "Notifications: only the Omarchy shell owns org.freedesktop.Notifications"
# A packaged daemon's D-Bus activation file (swaync, mako, dunst…) starts it whenever the name is briefly unowned
# (login, shell restart, crash) and it then keeps the name. A user service file wins over every system one and
# makes activation fail, so only the shell can register.
mkdir -p "$HOME/.local/share/dbus-1/services"
printf '[D-BUS Service]\nName=org.freedesktop.Notifications\nExec=/bin/false\n' > "$HOME/.local/share/dbus-1/services/org.freedesktop.Notifications.service"
# dbus-daemon only watches service directories that existed when it started: reload a bus that is already running.
if has_user_systemd; then busctl --user call org.freedesktop.DBus /org/freedesktop/DBus org.freedesktop.DBus ReloadConfig >/dev/null 2>&1 || true; fi
ok "D-Bus activation of other notification daemons blocked"

say "Desktop helpers the shell replaces (uwsm autostart only; GNOME launches its own)"
# uwsm turns /etc/xdg/autostart entries into app-*@autostart.service units; GNOME starts the same entries itself
# (gnome-session scopes), so these masks only apply to Omarchy. update-notifier: its crash route opens apport
# dialogs (omarchy-crash-watch replaces them) and apt updates are announced by omarchy-update-available.
mkdir -p "$HOME/.config/systemd/user"
for d in blueman nm-tray-autostart update-notifier; do
  [[ -e /etc/xdg/autostart/$d.desktop ]] || continue
  unit="app-$(systemd-escape "$d")@autostart.service"
  if has_user_systemd; then systemctl --user mask --now "$unit" 2>/dev/null || true; else ln -sfn /dev/null "$HOME/.config/systemd/user/$unit"; fi
done
ok "blueman, nm-tray and update-notifier not started in Omarchy"

say "Apport crash UI: omarchy-crash-watch replaces it in Omarchy"
# update-notifier-crash.path runs in every session. The condition is on the service, not on the path unit: the
# path unit starts before uwsm exports XDG_CURRENT_DESKTOP. GNOME sessions keep Ubuntu's crash dialogs.
mkdir -p "$HOME/.config/systemd/user/update-notifier-crash.service.d"
printf '[Unit]\n# omarchy-ubuntu: in Omarchy, omarchy-crash-watch announces crashes\nConditionEnvironment=!XDG_CURRENT_DESKTOP=Hyprland\n' > "$HOME/.config/systemd/user/update-notifier-crash.service.d/10-omarchy.conf"
ok "done"

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
# The unit list comes from Omarchy's first-run script: a unit it enables but the kit did not install makes
# first-run fail under set -e, and then retry at every login (omarchy-migrate-notify.service did exactly that).
mkdir -p "$HOME/.config/systemd/user/app.slice.d"
omarchy_unit() { sed 's|/usr/bin/omarchy-|/usr/local/bin/omarchy-|g' "$OMARCHY_SYS/default/systemd/user/$1" > "$HOME/.config/systemd/user/$1"; }
mapfile -t user_units < <(grep -v '^[[:space:]]*#' "$OMARCHY_SYS/install/user/first-run/enable-user-units.sh" | grep -oE '[A-Za-z0-9@_.-]+\.(service|socket|timer|path)\b' | sort -u)
(( ${#user_units[@]} )) || die "no units found in install/user/first-run/enable-user-units.sh"
for u in "${user_units[@]}"; do
  if [[ -f $OMARCHY_SYS/default/systemd/user/$u ]]; then
    omarchy_unit "$u"
    if [[ $u != *.service ]]; then   # a .path/.timer/.socket is useless without the service it triggers
      t=$(sed -n 's/^Unit=//p' "$OMARCHY_SYS/default/systemd/user/$u" | head -1); t=${t:-${u%.*}.service}
      if [[ -f $OMARCHY_SYS/default/systemd/user/$t ]]; then omarchy_unit "$t"
      elif ! user_unit_shipped "$t"; then die "first-run enables $u, whose $t is shipped nowhere"; fi
    fi
  elif ! user_unit_shipped "$u"; then
    die "first-run enables $u, which neither default/systemd/user nor a package ships"
  fi
done
cp -f "$OMARCHY_SYS/default/systemd/user/app.slice.d/10-oomd.conf" "$HOME/.config/systemd/user/app.slice.d/"
if has_user_systemd; then
  systemctl --user daemon-reload
  systemctl --user enable "${user_units[@]}"
  # The Omarchy shell ships its own polkit agent; hyprpolkitagent is enabled globally by its package and
  # would register first ("An authentication agent already exists"), so mask it rather than disable it.
  systemctl --user mask --now hyprpolkitagent.service 2>/dev/null || true
  pkill -x hyprpolkitagent 2>/dev/null || true
  ok "${#user_units[@]} units enabled (start with the next session)"
else
  # No user manager here: enable through the wants/ symlinks, picked up at the first login.
  for u in "${user_units[@]}"; do
    [[ -f $HOME/.config/systemd/user/$u ]] || continue
    wb=$(sed -n 's/^WantedBy=//p' "$HOME/.config/systemd/user/$u" | head -1); [[ -n $wb ]] || continue
    mkdir -p "$HOME/.config/systemd/user/$wb.wants"; ln -sfn "../$u" "$HOME/.config/systemd/user/$wb.wants/$u"
  done
  ln -sfn /dev/null "$HOME/.config/systemd/user/hyprpolkitagent.service"   # masked: the shell has its own agent
  ok "${#user_units[@]} units enabled through wants/ symlinks (no user manager running)"
fi

say "Omarchy per-user setup (the parts of \"omarchy finalize user\" that suit Ubuntu)"
# At first login Omarchy runs omarchy-provision-user (install/user/all.sh) unless finalize-user is marked. The kit
# marks it and does the Ubuntu-safe parts here. Deliberately skipped: xdg-user-dirs --set DESKTOP/TEMPLATES/
# PUBLICSHARE $HOME and the English gtk bookmarks (they change GNOME's desktop and Files), the Dell XPS 13 text
# size (GNOME's text-scaling-factor), default-keyring.sh (see above), git.sh and xcompose.sh (identity handled
# above), chromium as default browser (Chrome is set above), `mise use -g node@latest` over a Node the user
# already has, and mise stubs over commands installed natively (Claude Code's ~/.local/bin/claude, apt's gh…).
export OMARCHY_INSTALL="$OMARCHY_SYS/install" OMARCHY_SETUP_CONTEXT=runtime
run_leaf() { bash -eE -c 'source "$1"' bash "$1" || warn "${1#"$OMARCHY_SYS"/} failed (not fatal)"; }
for d in "$HOME/.agents/skills" "$HOME/.claude/skills" "$HOME/.codex/skills" "$HOME/.pi/agent/skills" "$HOME/.hermes/skills"; do
  mkdir -p "$d"
  for sk in "$OMARCHY_SYS"/default/agents/skills/*/; do sk=${sk%/}; ln -sfn "$sk" "$d/${sk##*/}"; done
done
ok "agent skills linked (~/.claude, ~/.codex, ~/.agents, ~/.pi, ~/.hermes)"
for f in "$OMARCHY_SYS"/install/user/hardware/*/*.sh "$OMARCHY_SYS"/install/user/hardware/*.sh; do
  case $f in */dell/xps13-text-scaling.sh)   # omarchy-display-text-size also sets GNOME's text-scaling-factor
    omarchy-hw-match DX13260 2>/dev/null && skip "XPS 13 text size (it changes GNOME's text scaling too): omarchy-display-text-size 11"
    continue ;;
  esac
  [[ -f $f ]] && run_leaf "$f"
done
ok "hardware quirks checked (ASUS ROG audio, Framework 13 AMD audio, nouveau cursor)"
omarchy-install-chromium-copy-url >/dev/null 2>&1 && omarchy-install-chromium-ytdlp >/dev/null 2>&1 && ok "browser helpers (copy URL, download video) registered" || warn "browser helpers not registered"
if command -v mise >/dev/null; then
  # install/user/mise-work.sh, without replacing a Node the user already has (a global mise pin, nvm, apt).
  mkdir -p "$HOME/Work/tries"
  [[ -f $HOME/Work/.mise.toml ]] || printf '[env]\n_.path = "{{ cwd }}/bin"\n' > "$HOME/Work/.mise.toml"
  mise trust -q "$HOME/Work/.mise.toml" >/dev/null 2>&1 || warn "mise trust ~/Work/.mise.toml failed"
  # Only a Node the Omarchy session can see counts (system bin dirs, then ~/.local/bin): nvm/fnm/volta exist only in
  # interactive shells, and the npm-based launchers (gemini, grok, ghui, playwright) run from menus and bindings.
  node_path=""
  for d in /usr/local/bin /usr/bin /bin /snap/bin "$HOME/.local/bin"; do
    if [[ -x $d/node && ! -d $d/node ]] && ! grep -qs 'exec mise x' "$d/node"; then node_path=$d/node; break; fi
  done
  if [[ -n $(cd "$HOME" && mise ls --global node 2>/dev/null) ]]; then ok "global mise Node kept"
  elif [[ -n $node_path ]]; then ok "Node kept ($node_path)"
  elif (cd "$HOME" && mise use -g node@lts >/dev/null); then
    ok "Node LTS (mise, global) for the npm-based launchers"
    other=$(command -v node 2>/dev/null) || other=""
    if [[ -n $other && $other != */mise/* ]]; then info "your Node at $other is not in the Omarchy session's PATH; in shells running 'mise activate' the mise Node now comes first (undo: mise unuse -g node)"; fi
  else warn "Node not installed (offline?): re-run this step to retry"; fi
  # Omarchy's AI/dev CLI launchers are mise stubs; never replace or shadow a command installed another way. Only
  # directories every session has count (not ~/.opencode/bin, nvm… that only an interactive rc adds).
  omarchy-mise-install() {
    local cmd=${2:-$1} d native="" stub=$HOME/.local/bin/${2:-$1}
    for d in /usr/local/bin /usr/bin /bin /snap/bin; do
      if [[ -x $d/$cmd && ! -d $d/$cmd ]] && ! grep -qs 'exec mise x' "$d/$cmd"; then native=$d/$cmd; break; fi
    done
    # a native launcher where the stub would go (Claude Code's installer links ~/.local/bin/claude)
    if [[ -z $native && -e $stub ]] && ! grep -qs 'exec mise x' "$stub"; then native=$stub; fi
    if [[ -n $native ]]; then
      if [[ $native != "$stub" ]] && grep -qs 'exec mise x' "$stub"; then rm -f "$stub"; echo "  removed the mise stub in ~/.local/bin for $cmd"; fi
      echo "  keeping $cmd ($native)"
      # a stub that already ran pinned the tool: its mise shim comes before $native in the session PATH
      if [[ -n $(cd "$HOME" && mise ls --global "$1" 2>/dev/null) ]]; then echo "  note: mise still pins $1 globally, so its shim wins in the Omarchy session (to use $native: mise unuse -g $1)"; fi
      return 0
    fi
    command omarchy-mise-install "$@"
  }
  export -f omarchy-mise-install
  run_leaf "$OMARCHY_SYS/install/user/mise.sh"
  unset -f omarchy-mise-install
  ok "mise launchers for the Omarchy AI/dev CLIs"
else
  skip "mise missing (step 20): no ~/Work mise setup, no CLI launchers"
fi
# Also what keeps provision-user from ever running (and re-running) on Ubuntu: see the comment above.
touch "$st/done/finalize-user"

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
