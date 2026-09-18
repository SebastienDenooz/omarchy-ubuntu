#!/bin/bash
# Step 60 (optional) — Equivalent of the omarchy-zsh package: Omarchy aliases, functions and options for zsh.
# Does not overwrite ~/.zshrc: appends one "source" line (backup made).
. "$(dirname "$0")/lib.sh"
need git zsh
ZSH_VER=1.5.0
dest="$HOME/.local/share/omarchy-zsh"

say "Sources: omarchy-zsh v$ZSH_VER + omadots (shared shell config)"
rm -rf "$BUILD/omarchy-zsh" "$BUILD/omadots"
git clone --depth 1 --branch "v$ZSH_VER" https://github.com/omacom-io/omarchy-zsh "$BUILD/omarchy-zsh"
git clone --depth 1 https://github.com/omacom-io/omadots "$BUILD/omadots"
rm -rf "$dest"; mkdir -p "$dest/shell" "$HOME/.local/share/zsh/site-functions"
cp -r "$BUILD/omadots/config/shell/." "$dest/shell/"
find "$dest/shell" -type f -exec sed -i -e "s|\"\$HOME\"/\.config/shell|$dest/shell|g" -e "s|\$HOME/\.config/shell|$dest/shell|g" {} +
cp "$BUILD/omarchy-zsh/shell/zoptions" "$dest/shell/"
cp "$BUILD/omarchy-zsh/shell/completions/"* "$HOME/.local/share/zsh/site-functions/" 2>/dev/null || true
sed -e "s|/usr/share/omarchy-zsh|$dest|g" "$BUILD/omarchy-zsh/templates/zshrc" > "$dest/zshrc"
ok "installed in $dest"

say "Hooking into ~/.zshrc"
# Frameworks such as oh-my-zsh define aliases (ga, gd…) with the same names as Omarchy's shell functions;
# zsh refuses to define a function over an alias, so those aliases are removed right before sourcing.
fns=$(grep -hoE '^[a-zA-Z_][a-zA-Z0-9_-]*\(\)' "$dest"/fns/* "$dest"/functions 2>/dev/null | tr -d '()' | sort -u | tr '\n' ' ')
cp -n "$HOME/.zshrc" "$BACKUPS/$BACKUP_TS-zshrc" 2>/dev/null || true
grep -q 'omarchy-zsh/zshrc' "$HOME/.zshrc" 2>/dev/null || cat >> "$HOME/.zshrc" <<EOZ

# Omarchy (ls/lt/ff/n/g… aliases, tdl/compress/… functions, starship, zoxide) — omarchy-ubuntu kit
fpath=(\$HOME/.local/share/zsh/site-functions \$fpath)
unalias $fns 2>/dev/null   # framework aliases that would collide with Omarchy's functions
[[ -f $dest/zshrc ]] && source $dest/zshrc
# Ubuntu ships fzf's zsh integration under /usr/share/doc/fzf/examples, not /usr/share/fzf (omadots' path)
for f in /usr/share/doc/fzf/examples/completion.zsh /usr/share/doc/fzf/examples/key-bindings.zsh; do [[ -f \$f ]] && source \$f; done
EOZ
ok "line added; open a new terminal. Recommended dependency: sudo apt install zsh-syntax-highlighting"
