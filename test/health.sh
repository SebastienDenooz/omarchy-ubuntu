#!/bin/bash
# Login-path health check for Omarchy on Ubuntu. Run it inside the Omarchy session.
# No sudo, no side effects. Exit 1 on any failure.
set -uo pipefail
rc=0
ok() { printf '  ok    %s\n' "$*"; }
ko() { printf '  FAIL  %s\n' "$*"; rc=1; }
nb() { printf '  note  %s\n' "$*"; }
chk() { local what=$1; shift; if "$@" >/dev/null 2>&1; then ok "$what"; else ko "$what"; fi; }
OMARCHY_SYS=${OMARCHY_PATH:-/usr/share/omarchy}

echo fonts
conflist=$(fc-conflist 2>/dev/null)   # captured: grep -q closing the pipe would fail the test under pipefail
if grep -q '^+ /etc/fonts/conf.d/09-omarchy-reject-webfonts.conf' <<<"$conflist"; then ok "web-font reject rule loaded (system)"
elif grep -q '^+ .*/09-omarchy-reject-webfonts.conf' <<<"$conflist"; then nb "web-font reject rule loaded from the user config only: run scripts/41-system.sh"
else ko "web-font reject rule not loaded (scripts/41-system.sh)"; fi
n=$(fc-list -f '%{?charset{}{x\n}}' 2>/dev/null | grep -c x)
if (( n == 0 )); then ok "no charset-less font patterns"; else ko "$n charset-less font patterns (Qt 6.10 crashes on them)"; fi
chk "fallback matching returns real fonts" sh -c "! fc-match -f '%{file}' 'Noto Naskh Arabic' | grep -qi woff"
n=$(find ~/.local/share/fonts ~/.fonts \( -iname '*.woff' -o -iname '*.woff2' \) 2>/dev/null | wc -l)
(( n == 0 )) || nb "$n web fonts in user font dirs (Flatpak Qt apps do not read the system rule)"
n=$(find ~/.cache/fontconfig -maxdepth 1 -type l 2>/dev/null | wc -l)
(( n == 0 )) || nb "$n Chrome compat cache links (harmless with the rule)"

echo notifications
chk "D-Bus activation shadow in place" test -f ~/.local/share/dbus-1/services/org.freedesktop.Notifications.service
shell_pid=$(pgrep -of "quickshell -n -p $OMARCHY_SYS/shell" || true)
if [[ -n $shell_pid ]]; then
  chk "shell owns org.freedesktop.Notifications" sh -c "busctl --user status org.freedesktop.Notifications | grep -qx Comm=quickshell"
else
  ko "Omarchy shell not running (omarchy-restart-shell)"
fi

echo first-run
chk "omarchy-migrate --pending reports nothing" sh -c '! omarchy-migrate --pending'
for u in $(grep -v '^[[:space:]]*#' "$OMARCHY_SYS/install/user/first-run/enable-user-units.sh" | grep -oE '[A-Za-z0-9@_.-]+\.(service|socket|timer|path)\b' | sort -u); do
  chk "unit $u installed" systemctl --user cat "$u"
done
chk "finalize-user marked" omarchy-done check finalize-user
if omarchy-done check first-run-user; then ok "first-run complete"; else nb "first-run not complete yet (runs at the next login)"; fi

echo "greeter and dialogs"
chk "hyprpolkitagent masked globally" sh -c '[ "$(systemctl --global is-enabled hyprpolkitagent.service 2>/dev/null)" = masked ]'
for u in hyprpaper hyprsunset hypridle; do chk "$u not enabled globally" sh -c "! systemctl --global is-enabled -q $u.service"; done
for u in fumon.service foot-server.service foot-server.socket app-com.mitchellh.ghostty.service hyprpolkitagent.service hyprpaper.service hyprsunset.service hypridle.service; do
  chk "$u skips the GDM greeter" test -f "/etc/systemd/user/$u.d/10-omarchy-no-greeter.conf"
done
kd=~/.local/share/keyrings
if [[ -f $kd/default && $(tr -d '[:space:]' <"$kd/default") == Default_keyring && $(head -c 9 "$kd/Default_keyring.keyring" 2>/dev/null) == '[keyring]' ]]; then
  nb "default keyring is Omarchy's unencrypted Default_keyring: protect it with a password in seahorse (do not switch back to login)"
fi
chk "apport UI skipped under Hyprland" test -f ~/.config/systemd/user/update-notifier-crash.service.d/10-omarchy.conf
for u in 'app-blueman@autostart.service' 'app-nm\x2dtray\x2dautostart@autostart.service' 'app-update\x2dnotifier@autostart.service'; do
  [[ -e /etc/xdg/autostart/$(systemd-escape -u "${u#app-}" | sed 's/@autostart.service$//').desktop ]] || continue
  chk "$u masked" sh -c "[ \"\$(systemctl --user is-enabled '$u' 2>/dev/null)\" = masked ]"
done
n=$(systemctl --user --failed --no-legend 2>/dev/null | wc -l)
if (( n == 0 )); then ok "no failed user units"; else ko "$n failed user units: systemctl --user --failed"; fi

echo "this login"
since=$(systemctl --user show -p ActiveEnterTimestamp --value 'wayland-wm@*.service' 2>/dev/null | awk 'NF{print $2" "$3; exit}')
if [[ -z $since ]]; then
  nb "no uwsm compositor unit found: crash history not checked"
else
  lines=$(journalctl --user -t omarchy-shell -S "$since" -o short-unix 2>/dev/null | grep -E 'has crashed|exited with status|Giving up')
  n=$(grep -c . <<<"$lines")
  if (( n == 0 )); then
    ok "no shell crash since login ($since)"
  else
    last=$(tail -1 <<<"$lines" | cut -d' ' -f1 | cut -d. -f1)
    started=0; [[ -n $shell_pid ]] && started=$(( $(date +%s) - $(ps -o etimes= -p "$shell_pid") ))
    if (( started > last )); then nb "$n shell crash lines earlier in this login; the running shell started after them"
    else ko "$n shell crash lines since login: journalctl --user -t omarchy-shell -S '$since'"; fi
  fi
fi
exit $rc
