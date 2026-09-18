#!/bin/bash
# Step 25 (optional) — Voxtype AI dictation, like Omarchy's "Install > AI > Dictation" but with the official .deb.
# Run after 30 and 41 (Omarchy in place). The hotkey is handled by Hyprland: hold F9, or SUPER + CTRL + X.
# Engine: asked at install time (GPU Vulkan offered by default when detected). Non-interactive: --gpu or --cpu.
. "$(dirname "$0")/lib.sh"
omarchy_env
VOXTYPE_VER=1.0.1
engine=""
case " $* " in *" --gpu "*) engine=gpu ;; *" --cpu "*) engine=cpu ;; esac

say "voxtype $VOXTYPE_VER package (official .deb)"
if dpkg_present voxtype; then ok "already installed: $(dpkg-query -W -f='${Version}' voxtype)"; else
  fetch "https://github.com/peteonrails/voxtype/releases/download/v$VOXTYPE_VER/voxtype_${VOXTYPE_VER}-1_amd64.deb" "$DL/voxtype.deb"
  sudo apt-get install -y "$DL/voxtype.deb"
fi
apt_install wtype wl-clipboard libvulkan1 mesa-vulkan-drivers vulkan-tools >/dev/null 2>&1 || true

say "Omarchy configuration (hotkey delegated to Hyprland, state file for the bar)"
mkdir -p "$HOME/.config/voxtype"
cp -f "$OMARCHY_SYS/default/voxtype/config.toml" "$HOME/.config/voxtype/config.toml"
ok "~/.config/voxtype/config.toml"

say "Speech model according to the system language"
# Omarchy ships base.en (English). For any other locale: multilingual "small" model (466 MB) and a fixed language.
lang=${LANG%%_*}; lang=${lang%%.*}
if [[ -z $lang || $lang == en || $lang == C || $lang == POSIX ]]; then model=base.en; lang=en; else model=small; fi
voxtype setup --download --model "$model" --no-post-install
sed -i -E "s/^model = \".*\"/model = \"$model\"/; s/^language = \".*\"/language = \"$lang\"/" "$HOME/.config/voxtype/config.toml"
ok "model $model, language $lang (change with: voxtype setup model, or ~/.config/voxtype/config.toml)"

say "Transcription engine: CPU or GPU"
gpu_name=$(lspci | grep -iE 'vga|3d' | sed 's/.*: //' | head -1)
cpu_flag=$(grep -o -wE 'avx512f|avx2' /proc/cpuinfo | sort -u | head -1)
if command -v omarchy-hw-vulkan >/dev/null && omarchy-hw-vulkan || vulkaninfo --summary 2>/dev/null | grep -q deviceName; then
  vulkan=1; info "Vulkan available: $gpu_name"
else
  vulkan=0; warn "no Vulkan detected ($gpu_name): CPU only"
fi
if [[ -z $engine ]]; then
  if (( vulkan )); then
    if command -v gum >/dev/null; then
      choice=$(gum choose --header "Voxtype engine?" "GPU Vulkan ($gpu_name) — recommended" "CPU ($cpu_flag)")
    else
      read -r -p "Engine: [G]PU Vulkan (recommended) or [c]pu? " choice
    fi
    [[ ${choice,,} == c* ]] && engine=cpu || engine=gpu
  else
    engine=cpu
  fi
fi
if [[ $engine == gpu ]]; then
  # Rewrites /usr/bin/voxtype to point at the Vulkan binary: sudo required.
  sudo voxtype setup gpu --enable && ok "GPU Vulkan engine enabled"
else
  sudo voxtype setup gpu --disable >/dev/null 2>&1 || true
  ok "CPU engine ($cpu_flag)"
fi
info "change later: sudo voxtype setup gpu --enable | --disable; status: voxtype setup gpu --status"

# The service must be (re)started after switching engines.
say "User service"
if has_user_systemd; then
  voxtype setup systemd
  systemctl --user restart voxtype.service 2>/dev/null || true; sleep 1
  systemctl --user is-active voxtype.service >/dev/null 2>&1 && ok "voxtype.service active" || warn "voxtype.service inactive: systemctl --user status voxtype"
else
  skip "voxtype systemd service (no user manager): run 'voxtype setup systemd' after the first login"
fi

say "Reloading Hyprland (bindings/voxtype.lua) and the shell"
hypr_reload
has_hyprland && omarchy-restart-shell >/dev/null 2>&1 || true
ok "hold F9, or SUPER + CTRL + X, to dictate · voxtype setup model to switch models"
