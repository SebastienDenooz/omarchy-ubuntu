#!/bin/bash
# Step 21 — Builds the Omarchy tools that have no Ubuntu package. Everything installs under ~/.local.
# Each block is independent: a failure does not stop the others (summary at the end).
# ONLY="ttfx nvim" restricts the run to the named steps (handy to retry a failure).
. "$(dirname "$0")/lib.sh"
rust_ready || die "cargo unusable (rustup default stable)"
need git cargo go qmake6 make

OMACALC_VER=0.2.2; OMACUT_VER=0.4.0; OMAWRITE_VER=0.5.0
TTFX_VER=0.3.2; TZUPDATE_VER=3.1.0; HPSP_VER=0.2.1
declare -A RESULT
run_step() { # run_step NAME function
  local name=$1 fn=$2
  say "$name"
  if "$fn" >"$LOGS/21-$name.log" 2>&1; then RESULT[$name]=OK; ok "$name (log: $LOGS/21-$name.log)"
  else RESULT[$name]=FAILED; warn "$name failed → $LOGS/21-$name.log"; fi
}
clone_tag() { # clone_tag URL TAG DIR
  rm -rf "$3"; git clone --depth 1 --recurse-submodules --branch "$2" "$1" "$3"
}

# omarchy-pkgs holds omacalc's .desktop/.svg and the omarchy-nvim overlay
[[ -d $BUILD/omarchy-pkgs ]] || git clone --depth 1 https://github.com/omacom-io/omarchy-pkgs "$BUILD/omarchy-pkgs"

build_oma() { # build_oma NAME VERSION  (Omarchy's Qt6 apps: ./bin/build → build/NAME)
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

step_ttfx()     { cargo +stable install --locked --root "$HOME/.local" --git https://github.com/omacom-io/ttfx --tag "v$TTFX_VER"; }
step_tzupdate() { cargo +stable install --locked --root "$HOME/.local" --git https://github.com/cdown/tzupdate --tag "$TZUPDATE_VER"; }

step_share_picker() { # screen-share picker with previews (xdph portal) — needs Rust nightly
  rustup toolchain install nightly --profile minimal
  clone_tag https://github.com/WhySoBad/hyprland-preview-share-picker "v$HPSP_VER" "$BUILD/hyprland-preview-share-picker"
  ( cd "$BUILD/hyprland-preview-share-picker" && cargo +nightly build --release --locked )
  install -Dm755 "$BUILD/hyprland-preview-share-picker/target/release/hyprland-preview-share-picker" "$HOME/.local/bin/hyprland-preview-share-picker"
  mkdir -p "$HOME/.local/share/hyprland-preview-share-picker"
  "$HOME/.local/bin/hyprland-preview-share-picker" schema > "$HOME/.local/share/hyprland-preview-share-picker/schema.json" || true
}

step_gpu_screen_recorder() { # screen recording (meson); gsr-kms-server needs cap_sys_admin (set by script 41)
  rm -rf "$BUILD/gpu-screen-recorder"
  git clone --depth 1 https://repo.dec05eba.com/gpu-screen-recorder "$BUILD/gpu-screen-recorder"
  ( cd "$BUILD/gpu-screen-recorder" && meson setup build --prefix="$HOME/.local" --buildtype=release && ninja -C build && ninja -C build install )
  sudo -n setcap cap_sys_admin+ep "$HOME/.local/bin/gsr-kms-server" 2>/dev/null || warn "setcap on gsr-kms-server deferred to script 41 (needs sudo)"
}

step_nvim() { # equivalent of the omarchy-nvim package: LazyVim + Omarchy overlay + dynamic theme
  local pk="$BUILD/omarchy-pkgs/pkgbuilds/omarchy-nvim"
  backup_path "$HOME/.config/nvim"; backup_path "$HOME/.local/share/nvim"; backup_path "$HOME/.local/state/nvim"; backup_path "$HOME/.cache/nvim"
  git clone --depth 1 https://github.com/LazyVim/starter "$HOME/.config/nvim"; rm -rf "$HOME/.config/nvim/.git"
  cp -a "$pk/lua" "$pk/plugin" "$pk/lazyvim.json" "$HOME/.config/nvim/"
  # Upstream still points at gthelding/monokai-pro.nvim, a repository that no longer exists (Lazy sync fails).
  sed -i 's|"gthelding/monokai-pro.nvim"|"loctvl842/monokai-pro.nvim"|' "$HOME/.config/nvim/lua/plugins/all-themes.lua"
  mkdir -p "$HOME/.config/nvim/lua/plugins"
  ln -sfn "$HOME/.local/state/omarchy/current/theme/neovim.lua" "$HOME/.config/nvim/lua/plugins/theme.lua"
  nvim --headless "+Lazy! sync" +qa || true
}

for s in ${ONLY:-omacalc omacut omawrite ttfx tzupdate share_picker gpu_screen_recorder nvim}; do
  run_step "$s" "step_$s"
done

say "Summary"
failures=0
for k in "${!RESULT[@]}"; do printf '    %-22s %s\n' "$k" "${RESULT[$k]}"; [[ ${RESULT[$k]} == FAILED ]] && failures=$((failures+1)); done
info "Not built (optional): usage (CLI completions), omarchy-emacs/fish. Voxtype: script 25."
if (( failures )); then
  warn "$failures build(s) failed: check the logs above, then retry only those with e.g. ONLY=\"ttfx tzupdate\" ./install.sh --only=21"
  exit 1
fi
