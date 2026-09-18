#!/bin/bash
# Step 20 — Omarchy software available as binaries or .deb (no compilation).
# Options: --with-pinta (flatpak).  SKIP_DEB=1 downloads the .deb files without installing them (no sudo).
. "$(dirname "$0")/lib.sh"
need curl tar

AETHER_VER=4.29.8      # theme builder GUI       (official deb)
LOCALSEND_VER=1.18.2   # file sharing            (official deb)
OBSIDIAN_VER=1.13.7    # notes                   (official deb; 1.13.8 has no Linux assets yet)
TENSAKU_VER=0.29.0     # screenshot annotation   (official tar.gz)
HERDR_VER=0.9.0        # terminal workspace mgr  (binary)
CLIAMP_VER=2.2.0       # TUI music player        (binary)
TRY_VER=1.8.1          # tobi/try                (ruby script)
NERD_VER=3.5.1         # JetBrainsMono Nerd Font

say ".deb packages (aether, localsend, obsidian)"
fetch "https://github.com/omacom/aether/releases/download/v$AETHER_VER/aether_${AETHER_VER}_amd64.deb" "$DL/aether.deb"
fetch "https://github.com/localsend/localsend/releases/download/v$LOCALSEND_VER/LocalSend-$LOCALSEND_VER-linux-x86-64.deb" "$DL/localsend.deb"
fetch "https://github.com/obsidianmd/obsidian-releases/releases/download/v$OBSIDIAN_VER/obsidian_${OBSIDIAN_VER}_amd64.deb" "$DL/obsidian.deb"
if [[ ${SKIP_DEB:-0} == 1 ]]; then
  warn "SKIP_DEB=1: the .deb files are in $DL; install them with: sudo apt-get install -y $DL/aether.deb $DL/localsend.deb $DL/obsidian.deb"
else
  sudo apt-get install -y "$DL/aether.deb" "$DL/localsend.deb" "$DL/obsidian.deb"
  ok "aether, localsend, obsidian"
fi

say "Tensaku (screenshot editor)"
fetch "https://github.com/jondkinney/tensaku/releases/download/v$TENSAKU_VER/tensaku-v$TENSAKU_VER-x86_64.tar.gz" "$DL/tensaku.tgz"
rm -rf "$BUILD/tensaku"; mkdir -p "$BUILD/tensaku"; tar xzf "$DL/tensaku.tgz" -C "$BUILD/tensaku"
[[ -d $BUILD/tensaku/bin ]]   && cp -a "$BUILD/tensaku/bin/."   "$HOME/.local/bin/"
[[ -d $BUILD/tensaku/share ]] && cp -a "$BUILD/tensaku/share/." "$HOME/.local/share/"
command -v tensaku >/dev/null && ok "tensaku $(tensaku --version 2>/dev/null | head -1)" || warn "tensaku: binary not found in the archive, check $BUILD/tensaku"

say "Herdr, Cliamp (static binaries)"
fetch "https://github.com/herdrdev/herdr/releases/download/v$HERDR_VER/herdr-linux-x86_64" "$DL/herdr"
fetch "https://github.com/bjarneo/cliamp/releases/download/v$CLIAMP_VER/cliamp-linux-amd64" "$DL/cliamp"
install -m755 "$DL/herdr" "$HOME/.local/bin/herdr"; install -m755 "$DL/cliamp" "$HOME/.local/bin/cliamp"
ok "herdr, cliamp"

say "try (tobi/try, ruby)"
mkdir -p "$HOME/.local/lib/tobi-try/lib"
for f in try.rb lib/tui.rb lib/fuzzy.rb; do
  fetch "https://raw.githubusercontent.com/tobi/try/v$TRY_VER/$f" "$DL/try-$(basename "$f")" || warn "try: $f not found at tag v$TRY_VER"
done
[[ -s $DL/try-try.rb ]] && { sed '1c#!/usr/bin/ruby' "$DL/try-try.rb" > "$HOME/.local/lib/tobi-try/try.rb"; chmod 755 "$HOME/.local/lib/tobi-try/try.rb"; }
for f in tui.rb fuzzy.rb; do [[ -s $DL/try-$f ]] && cp "$DL/try-$f" "$HOME/.local/lib/tobi-try/lib/$f"; done
ln -sfn "$HOME/.local/lib/tobi-try/try.rb" "$HOME/.local/bin/try"; ok "try"

say "mise (dev environments and AI CLI launchers)"
if command -v mise >/dev/null; then ok "already installed: $(mise --version)"; else
  curl -fsSL https://mise.run | MISE_INSTALL_PATH="$HOME/.local/bin/mise" sh; ok "mise"
fi

say "Fonts: JetBrainsMono Nerd Font, iA Writer Mono S"
mkdir -p "$HOME/.local/share/fonts/JetBrainsMonoNerd" "$HOME/.local/share/fonts/iAWriter"
fetch "https://github.com/ryanoasis/nerd-fonts/releases/download/v$NERD_VER/JetBrainsMono.zip" "$DL/JetBrainsMono.zip"
unzip -oq "$DL/JetBrainsMono.zip" -d "$HOME/.local/share/fonts/JetBrainsMonoNerd" -x '*.md' 'LICENSE*' 2>/dev/null || true
for w in Regular Bold Italic BoldItalic; do
  fetch "https://raw.githubusercontent.com/iaolo/iA-Fonts/master/iA%20Writer%20Mono/Static/iAWriterMonoS-$w.ttf" "$HOME/.local/share/fonts/iAWriter/iAWriterMonoS-$w.ttf" || true
done
fc-cache -f >/dev/null; ok "fonts installed ($(fc-list | grep -c 'JetBrainsMono Nerd') JetBrainsMono Nerd files)"

say "gpu-screen-recorder"
info "Omarchy uses it for screen recording. Two options:"
info "  a) native build (script 21, recommended: stop detection and gsr-kms-server work as intended)"
info "  b) flatpak: flatpak install --user flathub com.dec05eba.gpu_screen_recorder + a ~/.local/bin/gpu-screen-recorder wrapper"
info "     (limitation: Omarchy's stop shortcut looks for a process named gpu-screen-recorder)"

if [[ " $* " == *" --with-pinta "* ]]; then
  say "Pinta (flatpak)"; flatpak install --user -y flathub com.github.PintaProject.Pinta && ok "Pinta"
fi
# Voxtype (dictation): dedicated script 25-voxtype.sh, to run after 30 and 41.
ok "step 20 done"
