#!/bin/bash
# Step 50 — Activates the Tokyo Night theme (Omarchy default) and renders the themed files.
# Also usable later: omarchy theme list · omarchy theme set "Catppuccin Latte"
. "$(dirname "$0")/lib.sh"
omarchy_env
need omarchy-theme-set
# Omarchy ships 22 themes; its own default is Tokyo Night. An argument still wins over the question.
if [[ -n ${1:-} ]]; then
  theme=$1
else
  mapfile -t themes < <(find "$OMARCHY_SYS/themes" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' |
    sed -E 's/(^|-)([a-z])/\1\u\2/g; s/-/ /g' | sort)
  ask_choice KIT_THEME "Which theme?" "Tokyo Night" "${themes[@]}"
  theme=$KIT_THEME
fi
say "Theme \"$theme\""
mkdir -p "$HOME/.config/omarchy/themes" "$HOME/.local/state/omarchy/current"
OMARCHY_THEME_HEADLESS=1 omarchy-theme-set "$theme" || die "omarchy-theme-set failed"
mkdir -p "$HOME/.config/btop/themes"
ln -snf "$HOME/.local/state/omarchy/current/theme/btop.theme" "$HOME/.config/btop/themes/current.theme"
ok "active theme: $(cat "$HOME/.local/state/omarchy/current/theme.name" 2>/dev/null)"
info "generated files: $(ls "$HOME/.local/state/omarchy/current/theme" | tr '\n' ' ')"
info "Light themes available: Catppuccin Latte, Flexoki Light, Lupine, Rose Pine, White."
