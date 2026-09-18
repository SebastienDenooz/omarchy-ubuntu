#!/bin/bash
# Step 11 — Ubuntu packages equivalent to the omarchy-base.packages list (see MATRIX.md).
. "$(dirname "$0")/lib.sh"
need sudo apt-get

# --- Shell and CLI tools ----------------------------------------------------
CLI=(
  foot alacritty bash-completion bat eza fd-find fzf ripgrep zoxide tmux starship gum jq git less man-db unzip whois
  btop fastfetch inxi inotify-tools socat plocate dosfstools exfatprogs
  yt-dlp wl-clipboard wtype grim slurp qrencode zbar-tools tesseract-ocr tesseract-ocr-eng tesseract-ocr-fra
  imagemagick libvips-tools ffmpegthumbnailer ffmpeg
  brightnessctl ddcutil pamixer wireplumber pipewire-pulse pipewire-alsa udiskie
  libnotify-bin xdg-user-dirs xdg-utils fuse3 libxkbcommon-tools systemd-coredump
  lazygit neovim python3-gi python3-poetry-core ruby lua5.1 luarocks tree-sitter-cli
  fcitx5 fcitx5-frontend-gtk3 fcitx5-frontend-qt6
  ppa-purge flatpak pipx pciutils lsb-release gtk-update-icon-cache xdg-desktop-portal-gtk libcap2-bin zsh-syntax-highlighting
)
# --- Desktop and GUI applications -------------------------------------------
GUI=(
  nautilus gnome-sushi python3-nautilus gvfs-backends gvfs-fuse evince imv mpv
  libreoffice obs-studio kdenlive xournalpp gnome-disk-utility gnome-keyring libsecret-1-0
  cups cups-filters system-config-printer avahi-daemon libnss-mdns
  bluez bluez-tools bolt power-profiles-daemon network-manager ufw
  yaru-theme-icon gnome-themes-extra adwaita-icon-theme
  fonts-noto fonts-noto-cjk fonts-noto-color-emoji fonts-font-awesome fonts-liberation
  libgtk-4-1 libgtk4-layer-shell0 libadwaita-1-0 libwebkit2gtk-4.1-0 libqt6multimedia6 qt6-image-formats-plugins qt6-svg-plugins
)
# --- Build dependencies (script 21) ------------------------------------------
BUILD_DEPS=(
  build-essential cmake ninja-build meson pkg-config scdoc
  qt6-base-dev qt6-base-dev-tools qt6-declarative-dev qt6-multimedia-dev qt6-svg-dev
  libgtk-4-dev libgtk4-layer-shell-dev libadwaita-1-dev libepoxy-dev
  golang-go rustup
  libpipewire-0.3-dev libavcodec-dev libavformat-dev libavutil-dev libavfilter-dev libswresample-dev
  libva-dev libdrm-dev libgbm-dev libcap-dev libpulse-dev libwayland-dev libxrandr-dev libxcomposite-dev libxfixes-dev libxdamage-dev libxi-dev libxext-dev libxrender-dev libxcb1-dev libegl1-mesa-dev libgl-dev
)

# Docker: this machine already has docker-ce plus the compose/buildx plugins (Docker repository).
# Only install Ubuntu's docker.io / docker-compose-v2 / docker-buildx when no docker is present.
command -v docker >/dev/null || GUI+=(docker.io docker-compose-v2 docker-buildx)

say "Updating package index"; sudo apt-get update
say "CLI tools (${#CLI[@]} packages)";            apt_install "${CLI[@]}"
say "Desktop and GUI (${#GUI[@]} packages)";      apt_install "${GUI[@]}"
say "Build dependencies (${#BUILD_DEPS[@]} packages)"; apt_install "${BUILD_DEPS[@]}"

say "Command names Omarchy expects"
# Ubuntu renames fd → fdfind and bat → batcat; Omarchy (and its aliases) expect fd and bat.
ln -sfn "$(command -v fdfind)" "$HOME/.local/bin/fd";  ok "fd → fdfind"
ln -sfn "$(command -v batcat)" "$HOME/.local/bin/bat"; ok "bat → batcat"
if ! command -v tldr >/dev/null; then
  if command -v uv >/dev/null; then uv tool install tldr >/dev/null && ok "tldr (via uv)"; else pipx install tldr >/dev/null && ok "tldr (via pipx)"; fi
fi

say "Rust toolchain (rustup)"
# Ubuntu's rustup package ships no toolchain: install stable when cargo is missing.
if rust_ready; then ok "cargo usable: $(cargo --version)"; else warn "cargo unusable: run 'rustup default stable' by hand"; fi

say "Flathub (for gpu-screen-recorder / Pinta if needed)"
flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo && ok "flathub remote (user)"

say "System services"
if (( IN_CONTAINER )); then skip "systemctl enable (container)"; else
  sudo systemctl enable --now bluetooth.service power-profiles-daemon.service avahi-daemon.service cups.service 2>/dev/null || true
fi
ok "done"
