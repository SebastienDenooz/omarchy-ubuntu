#!/bin/bash
# Étape 60 (optionnelle) — Équivalent du paquet omarchy-zsh : alias, fonctions et options Omarchy pour zsh.
# N'écrase pas ~/.zshrc : ajoute une ligne « source » (sauvegarde faite).
. "$(dirname "$0")/lib.sh"
need git zsh
ZSH_VER=1.5.0
dest="$HOME/.local/share/omarchy-zsh"

say "Sources : omarchy-zsh v$ZSH_VER + omadots (config partagée)"
rm -rf "$BUILD/omarchy-zsh" "$BUILD/omadots"
git clone --depth 1 --branch "v$ZSH_VER" https://github.com/omacom-io/omarchy-zsh "$BUILD/omarchy-zsh"
git clone --depth 1 https://github.com/omacom-io/omadots "$BUILD/omadots"
rm -rf "$dest"; mkdir -p "$dest/shell" "$HOME/.local/share/zsh/site-functions"
cp -r "$BUILD/omadots/config/shell/." "$dest/shell/"
find "$dest/shell" -type f -exec sed -i -e "s|\"\$HOME\"/\.config/shell|$dest/shell|g" -e "s|\$HOME/\.config/shell|$dest/shell|g" {} +
cp "$BUILD/omarchy-zsh/shell/zoptions" "$dest/shell/"
cp "$BUILD/omarchy-zsh/shell/completions/"* "$HOME/.local/share/zsh/site-functions/" 2>/dev/null || true
sed -e "s|/usr/share/omarchy-zsh|$dest|g" "$BUILD/omarchy-zsh/templates/zshrc" > "$dest/zshrc"
ok "installé dans $dest"

say "Branchement dans ~/.zshrc"
cp -n "$HOME/.zshrc" "$BACKUPS/$BACKUP_TS-zshrc" 2>/dev/null || true
grep -q 'omarchy-zsh/zshrc' "$HOME/.zshrc" 2>/dev/null || cat >> "$HOME/.zshrc" <<EOZ

# Omarchy (alias ls/lt/ff/n/g…, fonctions tdl/compress/…, starship, zoxide) — kit omarchy-ubuntu
fpath=(\$HOME/.local/share/zsh/site-functions \$fpath)
[[ -f $dest/zshrc ]] && source $dest/zshrc
EOZ
ok "ligne ajoutée ; ouvre un nouveau terminal. Dépendance conseillée : sudo apt install zsh-syntax-highlighting"
