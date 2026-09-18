#!/bin/bash
# Pre-flight checks. Changes nothing.
. "$(dirname "$0")/lib.sh"

say "System"
(( IN_CONTAINER )) && info "container mode: session-dependent steps will be skipped"
info "$(lsb_release -ds 2>/dev/null || grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)  ·  kernel $(uname -r)  ·  $(uname -m)"
info "GPU: $(lspci 2>/dev/null | grep -iE 'vga|3d' | sed 's/.*: //' | head -1)"
info "Session: XDG_SESSION_TYPE=${XDG_SESSION_TYPE:-?}  display manager: $(basename "$(cat /etc/X11/default-display-manager 2>/dev/null)")"
info "Free space in /home: $(df -h "$HOME" | awk 'NR==2{print $4}')"

say "Hyprland stack"
info "Installed Hyprland: $(Hyprland --version 2>/dev/null | head -1 | cut -d' ' -f1-2)   (Omarchy $OMARCHY_TAG targets 0.56.2)"
if grep -rqs 'cppiber/hyprland' /etc/apt/sources.list.d/; then ok "PPA cppiber/hyprland present"; else warn "PPA cppiber/hyprland missing → script 10"; fi
for p in hyprland hyprland-guiutils hyprsunset hyprpicker hyprlock hypridle xdg-desktop-portal-hyprland uwsm xdg-terminal-exec foot alacritty kitty; do
  printf '    %-32s %s\n' "$p" "$(LC_ALL=C apt-cache policy "$p" 2>/dev/null | awk '/Candidate:/{c=$2} /Installed:/{i=$2} END{printf "candidate %s", c; if(i!="(none)"&&i!="") printf "  ·  installed %s", i}')"
done

say "Quickshell (the Omarchy shell runs on it)"
info "$(quickshell --version 2>/dev/null | head -1 || echo 'quickshell MISSING → script 10 installs it from the danklinux PPA')"
# Modules may be QML plugins on disk or compiled into the binary (danklinux PPA): check the binary's strings.
missing=()
if command -v quickshell >/dev/null; then
  mods=$(strings "$(command -v quickshell)" | grep -oE 'Quickshell\.(Services\.[A-Za-z]+|Hyprland|Wayland|Io|Networking|Bluetooth)' | sort -u)
  for m in Services.Pipewire Services.UPower Services.Mpris Services.SystemTray Services.Polkit Services.Pam Services.Notifications Networking Bluetooth Hyprland Wayland Io; do
    grep -qx "Quickshell.$m" <<<"$mods" || missing+=("$m")
  done
  if (( ${#missing[@]} )); then warn "missing Quickshell modules: ${missing[*]}"; else ok "all Quickshell modules imported by the Omarchy shell are present"; fi
fi
command -v quickshell >/dev/null && ok "'quickshell' binary present" || warn "'quickshell' binary missing (Omarchy calls it by that name)"

say "Build tools"
for t in git curl cargo rustup go ruby python3 uv cmake ninja meson qmake6 gcc; do
  printf '    %-8s %s\n' "$t" "$(command -v "$t" >/dev/null && echo present || echo MISSING)"
done

say "Omarchy checkout"
if [[ -d $OMARCHY_CHECKOUT/.git ]]; then ok "checkout: $OMARCHY_CHECKOUT ($(git -C "$OMARCHY_CHECKOUT" describe --tags --always 2>/dev/null))"; else info "not cloned yet → script 30"; fi
[[ -L $OMARCHY_SYS ]] && ok "$OMARCHY_SYS → $(readlink "$OMARCHY_SYS")" || info "$OMARCHY_SYS missing → script 30"

say "Keyboard"
info "$(grep XKBLAYOUT /etc/default/keyboard)  (Omarchy reads /etc/vconsole.conf: $( [[ -r /etc/vconsole.conf ]] && grep -o 'XKBLAYOUT=.*' /etc/vconsole.conf || echo missing))"
echo
info "Suggested order: 10 → 11 → (log out / log in) → 20 → 21 → 30 → 31 → 41 → 40 → 50 → (25, 60) → log out → session \"Omarchy (Hyprland uwsm)\""
