#!/bin/bash
# Étape 20 — Logiciels Omarchy disponibles en binaire/deb (pas de compilation).
# Options : --with-pinta (flatpak)   --with-voxtype (affiche les instructions)
. "$(dirname "$0")/lib.sh"
need curl tar

AETHER_VER=4.29.8      # théming GUI            (deb officiel)
LOCALSEND_VER=1.18.2   # partage de fichiers    (deb officiel)
OBSIDIAN_VER=1.13.8    # notes                  (deb officiel)
TENSAKU_VER=0.29.0     # annotation captures    (tar.gz officiel)
HERDR_VER=0.9.0        # gestionnaire terminal  (binaire)
CLIAMP_VER=2.2.0       # lecteur musique TUI    (binaire)
TRY_VER=1.8.1          # tobi/try               (script ruby)
NERD_VER=3.5.1         # JetBrainsMono Nerd Font

say "Paquets .deb"
fetch "https://github.com/omacom/aether/releases/download/v$AETHER_VER/aether_${AETHER_VER}_amd64.deb" "$DL/aether.deb"
fetch "https://github.com/localsend/localsend/releases/download/v$LOCALSEND_VER/LocalSend-$LOCALSEND_VER-linux-x86-64.deb" "$DL/localsend.deb"
fetch "https://github.com/obsidianmd/obsidian-releases/releases/download/v$OBSIDIAN_VER/obsidian_${OBSIDIAN_VER}_amd64.deb" "$DL/obsidian.deb"
sudo apt-get install -y "$DL/aether.deb" "$DL/localsend.deb" "$DL/obsidian.deb"
ok "aether, localsend, obsidian"

say "Tensaku (éditeur de captures d'écran)"
fetch "https://github.com/jondkinney/tensaku/releases/download/v$TENSAKU_VER/tensaku-v$TENSAKU_VER-x86_64.tar.gz" "$DL/tensaku.tgz"
rm -rf "$BUILD/tensaku"; mkdir -p "$BUILD/tensaku"; tar xzf "$DL/tensaku.tgz" -C "$BUILD/tensaku"
[[ -d $BUILD/tensaku/bin ]]   && cp -a "$BUILD/tensaku/bin/."   "$HOME/.local/bin/"
[[ -d $BUILD/tensaku/share ]] && cp -a "$BUILD/tensaku/share/." "$HOME/.local/share/"
command -v tensaku >/dev/null && ok "tensaku $(tensaku --version 2>/dev/null | head -1)" || warn "tensaku : binaire non trouvé dans l'archive, vérifie $BUILD/tensaku"

say "Herdr, Cliamp (binaires statiques)"
fetch "https://github.com/herdrdev/herdr/releases/download/v$HERDR_VER/herdr-linux-x86_64" "$DL/herdr"
fetch "https://github.com/bjarneo/cliamp/releases/download/v$CLIAMP_VER/cliamp-linux-amd64" "$DL/cliamp"
install -m755 "$DL/herdr" "$HOME/.local/bin/herdr"; install -m755 "$DL/cliamp" "$HOME/.local/bin/cliamp"
ok "herdr, cliamp"

say "try (tobi/try, ruby)"
mkdir -p "$HOME/.local/lib/tobi-try/lib"
for f in try.rb lib/tui.rb lib/fuzzy.rb; do
  fetch "https://raw.githubusercontent.com/tobi/try/v$TRY_VER/$f" "$DL/try-$(basename "$f")" || warn "try : $f introuvable au tag v$TRY_VER"
done
[[ -s $DL/try-try.rb ]] && { sed '1c#!/usr/bin/ruby' "$DL/try-try.rb" > "$HOME/.local/lib/tobi-try/try.rb"; chmod 755 "$HOME/.local/lib/tobi-try/try.rb"; }
for f in tui.rb fuzzy.rb; do [[ -s $DL/try-$f ]] && cp "$DL/try-$f" "$HOME/.local/lib/tobi-try/lib/$f"; done
ln -sfn "$HOME/.local/lib/tobi-try/try.rb" "$HOME/.local/bin/try"; ok "try"

say "mise (gestionnaire d'environnements et de CLI IA)"
if command -v mise >/dev/null; then ok "déjà installé : $(mise --version)"; else
  curl -fsSL https://mise.run | MISE_INSTALL_PATH="$HOME/.local/bin/mise" sh; ok "mise"
fi

say "Polices : JetBrainsMono Nerd Font, iA Writer Mono S"
mkdir -p "$HOME/.local/share/fonts/JetBrainsMonoNerd" "$HOME/.local/share/fonts/iAWriter"
fetch "https://github.com/ryanoasis/nerd-fonts/releases/download/v$NERD_VER/JetBrainsMono.zip" "$DL/JetBrainsMono.zip"
unzip -oq "$DL/JetBrainsMono.zip" -d "$HOME/.local/share/fonts/JetBrainsMonoNerd" -x '*.md' 'LICENSE*'
for w in Regular Bold Italic BoldItalic; do
  fetch "https://raw.githubusercontent.com/iaolo/iA-Fonts/master/iA%20Writer%20Mono/Static/iAWriterMonoS-$w.ttf" "$HOME/.local/share/fonts/iAWriter/iAWriterMonoS-$w.ttf" || true
done
fc-cache -f >/dev/null; ok "polices installées ($(fc-list | grep -c 'JetBrainsMono Nerd') fichiers JetBrainsMono Nerd)"

say "gpu-screen-recorder"
info "Omarchy l'utilise pour l'enregistrement d'écran. Deux voies :"
info "  a) compilation native (script 21, recommandée : détection d'arrêt et gsr-kms-server fonctionnels)"
info "  b) flatpak : flatpak install --user flathub com.dec05eba.gpu_screen_recorder  + wrapper ~/.local/bin/gpu-screen-recorder"
info "     (limite : le raccourci d'arrêt d'Omarchy cherche un processus nommé gpu-screen-recorder)"

if [[ " $* " == *" --with-pinta "* ]]; then
  say "Pinta (flatpak)"; flatpak install --user -y flathub com.github.PintaProject.Pinta && ok "Pinta"
fi
if [[ " $* " == *" --with-voxtype "* ]]; then
  say "Voxtype (dictée IA, optionnel)"
  info "Binaire fourni par https://voxtype.io ; Omarchy installe voxtype-<ver>-linux-x86_64-{avx2,vulkan} sous /usr/lib/voxtype"
  info "et un lanceur 'voxtype'. Installe-le à la main si tu en veux, puis 'voxtype setup model'."
fi
ok "étape 20 terminée"
