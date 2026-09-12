#!/bin/bash
# Étape 50 — Active le thème Tokyo Night (défaut Omarchy) et génère les fichiers thémés.
# Utilisable aussi plus tard : omarchy theme list · omarchy theme set "Catppuccin Latte"
. "$(dirname "$0")/lib.sh"
omarchy_env
need omarchy-theme-set
theme="${1:-Tokyo Night}"
say "Thème « $theme »"
mkdir -p "$HOME/.config/omarchy/themes" "$HOME/.local/state/omarchy/current"
OMARCHY_THEME_HEADLESS=1 omarchy-theme-set "$theme"
mkdir -p "$HOME/.config/btop/themes"
ln -snf "$HOME/.local/state/omarchy/current/theme/btop.theme" "$HOME/.config/btop/themes/current.theme"
ok "thème actif : $(cat "$HOME/.local/state/omarchy/current/theme.name" 2>/dev/null)"
info "fichiers générés : $(ls "$HOME/.local/state/omarchy/current/theme" | tr '\n' ' ')"
info "Thèmes clairs disponibles : Catppuccin Latte, Flexoki Light, Lupine, Rose Pine, White."
