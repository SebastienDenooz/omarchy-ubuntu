#!/bin/bash
# Step 50 — Activates the Tokyo Night theme (Omarchy default) and renders the themed files.
# Also usable later: omarchy theme list · omarchy theme set "Catppuccin Latte"
. "$(dirname "$0")/lib.sh"
omarchy_env
need omarchy-theme-set
theme="${1:-Tokyo Night}"
say "Theme \"$theme\""
mkdir -p "$HOME/.config/omarchy/themes" "$HOME/.local/state/omarchy/current"
OMARCHY_THEME_HEADLESS=1 omarchy-theme-set "$theme" || die "omarchy-theme-set failed"
mkdir -p "$HOME/.config/btop/themes"
ln -snf "$HOME/.local/state/omarchy/current/theme/btop.theme" "$HOME/.config/btop/themes/current.theme"
ok "active theme: $(cat "$HOME/.local/state/omarchy/current/theme.name" 2>/dev/null)"
info "generated files: $(ls "$HOME/.local/state/omarchy/current/theme" | tr '\n' ' ')"
info "Light themes available: Catppuccin Latte, Flexoki Light, Lupine, Rose Pine, White."
