#!/bin/bash
# Étape 21 — Compilation des outils Omarchy sans paquet Ubuntu. Tout s'installe sous ~/.local.
# Chaque bloc est indépendant : un échec n'arrête pas les autres (résumé à la fin).
. "$(dirname "$0")/lib.sh"
need git cargo go qmake6 make

OMACALC_VER=0.2.2; OMACUT_VER=0.4.0; OMAWRITE_VER=0.5.0
TTFX_VER=0.3.2; TZUPDATE_VER=3.1.0; HPSP_VER=0.2.1
declare -A RESULT
run_step() { # run_step NOM fonction
  local name=$1 fn=$2
  say "$name"
  if "$fn" >"$LOGS/21-$name.log" 2>&1; then RESULT[$name]=OK; ok "$name (journal : $LOGS/21-$name.log)"
  else RESULT[$name]=ÉCHEC; warn "$name a échoué → $LOGS/21-$name.log"; fi
}
clone_tag() { # clone_tag URL TAG DIR
  rm -rf "$3"; git clone --depth 1 --recurse-submodules --branch "$2" "$1" "$3"
}

# omarchy-pkgs contient les .desktop/.svg d'omacalc et la surcouche omarchy-nvim
[[ -d $BUILD/omarchy-pkgs ]] || git clone --depth 1 https://github.com/omacom-io/omarchy-pkgs "$BUILD/omarchy-pkgs"

build_oma() { # build_oma NOM VERSION  (apps Qt6 de l'équipe Omarchy : ./bin/build → build/NOM)
  local name=$1 ver=$2
  clone_tag "https://github.com/omacom-io/$name" "v$ver" "$BUILD/$name"
  ( cd "$BUILD/$name" && ./bin/build )
  install -Dm755 "$BUILD/$name/build/$name" "$HOME/.local/bin/$name"
  local desk svg
  desk=$(find "$BUILD/$name/pkgbuild" "$BUILD/omarchy-pkgs/pkgbuilds/$name" -name "$name.desktop" 2>/dev/null | head -1)
  svg=$(find "$BUILD/$name/pkgbuild" "$BUILD/omarchy-pkgs/pkgbuilds/$name" -name "$name.svg" 2>/dev/null | head -1)
  [[ -n $desk ]] && install -Dm644 "$desk" "$HOME/.local/share/applications/$name.desktop"
  [[ -n $svg ]]  && install -Dm644 "$svg"  "$HOME/.local/share/icons/hicolor/scalable/apps/$name.svg"
}
step_omacalc()  { build_oma omacalc  "$OMACALC_VER"; }
step_omacut()   { build_oma omacut   "$OMACUT_VER"; }
step_omawrite() { build_oma omawrite "$OMAWRITE_VER"; }

step_ttfx()     { cargo install --locked --root "$HOME/.local" --git https://github.com/omacom-io/ttfx --tag "v$TTFX_VER"; }
step_tzupdate() { cargo install --locked --root "$HOME/.local" --git https://github.com/cdown/tzupdate --tag "$TZUPDATE_VER"; }

step_share_picker() { # sélecteur de partage d'écran avec aperçus (portail xdph) — Rust nightly requis
  rustup toolchain install nightly --profile minimal
  clone_tag https://github.com/WhySoBad/hyprland-preview-share-picker "v$HPSP_VER" "$BUILD/hyprland-preview-share-picker"
  ( cd "$BUILD/hyprland-preview-share-picker" && cargo +nightly build --release --locked )
  install -Dm755 "$BUILD/hyprland-preview-share-picker/target/release/hyprland-preview-share-picker" "$HOME/.local/bin/hyprland-preview-share-picker"
  mkdir -p "$HOME/.local/share/hyprland-preview-share-picker"
  "$HOME/.local/bin/hyprland-preview-share-picker" schema > "$HOME/.local/share/hyprland-preview-share-picker/schema.json" || true
}

step_gpu_screen_recorder() { # enregistrement d'écran (meson) ; gsr-kms-server a besoin de cap_sys_admin
  rm -rf "$BUILD/gpu-screen-recorder"
  git clone --depth 1 https://repo.dec05eba.com/gpu-screen-recorder "$BUILD/gpu-screen-recorder"
  ( cd "$BUILD/gpu-screen-recorder" && meson setup build --prefix="$HOME/.local" --buildtype=release && ninja -C build && ninja -C build install )
  sudo setcap cap_sys_admin+ep "$HOME/.local/bin/gsr-kms-server" || warn "setcap sur gsr-kms-server : à refaire avec sudo"
}

step_nvim() { # équivalent du paquet omarchy-nvim : LazyVim + surcouche Omarchy + thème dynamique
  local pk="$BUILD/omarchy-pkgs/pkgbuilds/omarchy-nvim"
  backup_path "$HOME/.config/nvim"; backup_path "$HOME/.local/share/nvim"; backup_path "$HOME/.local/state/nvim"; backup_path "$HOME/.cache/nvim"
  git clone --depth 1 https://github.com/LazyVim/starter "$HOME/.config/nvim"; rm -rf "$HOME/.config/nvim/.git"
  cp -a "$pk/lua" "$pk/plugin" "$pk/lazyvim.json" "$HOME/.config/nvim/"
  mkdir -p "$HOME/.config/nvim/lua/plugins"
  ln -sfn "$HOME/.local/state/omarchy/current/theme/neovim.lua" "$HOME/.config/nvim/lua/plugins/theme.lua"
  nvim --headless "+Lazy! sync" +qa || true
}

for s in omacalc omacut omawrite ttfx tzupdate share_picker gpu_screen_recorder nvim; do
  run_step "$s" "step_$s"
done

say "Résumé"
for k in "${!RESULT[@]}"; do printf '    %-22s %s\n' "$k" "${RESULT[$k]}"; done
info "Non compilés (optionnels) : voxtype (dictée), usage (complétions CLI), omarchy-emacs/fish."
