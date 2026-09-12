#!/bin/bash
# Étape 40 — Configs utilisateur : ce que /etc/skel et « omarchy finalize user » font sur Arch.
# Ta config Hyprland actuelle (~/.config/hypr) est déplacée dans backups/ ; Omarchy utilise hyprland.lua.
. "$(dirname "$0")/lib.sh"
[[ -d $OMARCHY_SYS/config ]] || die "lance d'abord 30-checkout.sh"
omarchy_env

say "Sauvegarde des configs existantes → $BACKUPS/$BACKUP_TS"
for p in hypr foot alacritty ghostty kitty btop tmux starship.toml lazygit omarchy fcitx5 imv obsidian opencode \
         xournalpp herdr chromium-flags.conf wireplumber hyprland-preview-share-picker autostart mimeapps.list xdg-terminals.list; do
  backup_path "$HOME/.config/$p"
done
backup_path "$HOME/.XCompose"

say "Copie de $OMARCHY_SYS/config → ~/.config"
( cd "$OMARCHY_SYS/config" && for item in *; do
    case $item in git|chromium) continue ;;   # git/config écraserait ton identité git ; chromium → Chrome ici
    esac
    cp -a "$item" "$HOME/.config/"
  done )
ok "configs Omarchy en place (hypr, foot, alacritty, ghostty, kitty, btop, tmux, starship, lazygit, omarchy, fcitx5, imv…)"

say "Surcharges Hyprland propres à cette machine (AZERTY belge, écrans, touchpad)"
install -m644 "$KIT_DIR"/hypr/*.lua "$HOME/.config/hypr/"
ok "monitors.lua input.lua bindings.lua looknfeel.lua autostart.lua"

say "État Omarchy (~/.local/state/omarchy)"
st="$HOME/.local/state/omarchy"
mkdir -p "$st"/{toggles/hypr,current,migrations,defaults,done,windows,indicators}
cp -f "$OMARCHY_SYS"/default/hypr/toggles/*.lua "$st/toggles/hypr/"
for m in "$OMARCHY_SYS"/migrations/*.sh; do touch "$st/migrations/$(basename "$m")"; done   # migrations Arch : marquées faites
mkdir -p "$HOME/.local/state/tensaku"; cp -n "$OMARCHY_SYS/default/tensaku/state.toml" "$HOME/.local/state/tensaku/" 2>/dev/null || true
ok "toggles, marqueurs de migration"

say "Web apps et icônes"
cp -f "$OMARCHY_SYS"/applications/*.desktop "$HOME/.local/share/applications/"
mkdir -p "$HOME/.local/share/icons/hicolor/256x256/apps" "$HOME/.local/share/icons/hicolor/scalable/apps"
cp -f "$OMARCHY_SYS"/applications/icons/*.png "$HOME/.local/share/icons/hicolor/256x256/apps/" 2>/dev/null || true
cp -f "$OMARCHY_SYS"/applications/icons/*.svg "$HOME/.local/share/icons/hicolor/scalable/apps/" 2>/dev/null || true
gtk-update-icon-cache -f -t "$HOME/.local/share/icons/hicolor" 2>/dev/null || true
mkdir -p "$HOME/.local/share/nautilus-python/extensions"
cp -f "$OMARCHY_SYS"/default/nautilus-python/extensions/*.py "$HOME/.local/share/nautilus-python/extensions/"
ok "$(ls "$OMARCHY_SYS"/applications/*.desktop | wc -l) lanceurs, extensions Nautilus (LocalSend, Transcode)"

say "Types de fichiers, navigateur et terminal par défaut"
sed 's/chromium.desktop/google-chrome.desktop/' "$OMARCHY_SYS/default/applications/mimeapps.list" > "$HOME/.config/mimeapps.list"
env -u BROWSER xdg-settings set default-web-browser google-chrome.desktop || true
echo "foot.desktop" > "$HOME/.config/xdg-terminals.list"
ok "Chrome par défaut (Chromium est un snap sur Ubuntu), terminal foot — change avec : omarchy-default-terminal kitty"

say "XCompose, branding, trousseau, dossiers utilisateur"
git_name=$(git config --global user.name || true); git_email=$(git config --global user.email || true)
{ echo "include \"$OMARCHY_SYS/default/xcompose\""; [[ -n $git_name ]] && echo "<Multi_key> <space> <n> : \"$git_name\""; [[ -n $git_email ]] && echo "<Multi_key> <space> <e> : \"$git_email\""; } > "$HOME/.XCompose"
mkdir -p "$HOME/.config/omarchy/branding"
cp -n "$OMARCHY_SYS/logo.txt" "$HOME/.config/omarchy/branding/screensaver.txt" 2>/dev/null || true
cp -n "$OMARCHY_SYS/icon.txt" "$HOME/.config/omarchy/branding/about.txt" 2>/dev/null || true
bash "$OMARCHY_SYS/install/user/default-keyring.sh"
xdg-user-dirs-update; mkdir -p "$HOME/Pictures" "$HOME/Videos" "$HOME/Work"
gsettings set org.gnome.desktop.interface gtk-enable-primary-paste true 2>/dev/null || true
ok "fait"

say "Services utilisateur"
mkdir -p "$HOME/.config/systemd/user/app.slice.d"
for u in bt-agent omarchy-recover-internal-monitor omarchy-sleep-lock omarchy-fcitx5 omarchy-crash-watch; do
  sed 's|/usr/bin/omarchy-|/usr/local/bin/omarchy-|g' "$OMARCHY_SYS/default/systemd/user/$u.service" > "$HOME/.config/systemd/user/$u.service"
done
cp -f "$OMARCHY_SYS/default/systemd/user/app.slice.d/10-oomd.conf" "$HOME/.config/systemd/user/app.slice.d/"
systemctl --user daemon-reload
systemctl --user enable bt-agent.service omarchy-recover-internal-monitor.service omarchy-sleep-lock.service omarchy-fcitx5.service omarchy-crash-watch.service
# Le shell Omarchy embarque son propre agent polkit : l'agent hyprpolkitagent ferait doublon.
systemctl --user disable --now hyprpolkitagent.service 2>/dev/null || true
ok "unités activées (démarrent à la prochaine session)"

say "Skill Omarchy pour les agents IA (Claude Code, Codex…)"
for d in "$HOME/.claude/skills" "$HOME/.codex/skills" "$HOME/.agents/skills"; do
  mkdir -p "$d"; ln -sfn "$OMARCHY_SYS/default/agents/skills/omarchy" "$d/omarchy"
done
ok "~/.claude/skills/omarchy → dépôt"

echo
info "Prochaine étape : ./41-system.sh (sudo), ./50-theme.sh, puis déconnexion et choix de la session « Omarchy (Hyprland uwsm) »."
info "Ton ancienne config est dans $BACKUPS/$BACKUP_TS. Alt+Tab est celui d'Omarchy ; ton ancien sélecteur (~/.config/quickshell/switcher) n'est plus lancé."
