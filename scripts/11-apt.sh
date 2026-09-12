#!/bin/bash
# Étape 11 — Paquets Ubuntu équivalents à la liste omarchy-base.packages (voir MATRICE.md).
. "$(dirname "$0")/lib.sh"
need sudo apt-get

# --- Outils shell et CLI ---------------------------------------------------
CLI=(
  bash-completion bat eza fd-find fzf ripgrep zoxide tmux starship gum jq git less man-db unzip whois
  btop fastfetch inxi inotify-tools socat plocate dosfstools exfatprogs
  yt-dlp wl-clipboard wtype grim slurp qrencode zbar-tools tesseract-ocr tesseract-ocr-eng tesseract-ocr-fra
  imagemagick libvips-tools ffmpegthumbnailer ffmpeg
  brightnessctl ddcutil pamixer wireplumber pipewire-pulse pipewire-alsa udiskie
  libnotify-bin xdg-user-dirs xdg-utils fuse3 libxkbcommon-tools systemd-coredump
  lazygit neovim python3-gi python3-poetry-core ruby lua5.1 luarocks tree-sitter-cli
  fcitx5 fcitx5-frontend-gtk3 fcitx5-frontend-qt6
  ppa-purge flatpak
)
# --- Bureau et applications graphiques --------------------------------------
GUI=(
  nautilus gnome-sushi python3-nautilus gvfs-backends gvfs-fuse evince imv mpv
  libreoffice obs-studio kdenlive xournalpp gnome-disk-utility gnome-keyring libsecret-1-0
  cups cups-filters system-config-printer avahi-daemon libnss-mdns
  bluez bluez-tools bolt power-profiles-daemon network-manager ufw
  docker.io docker-compose-v2 docker-buildx
  yaru-theme-icon gnome-themes-extra adwaita-icon-theme
  fonts-noto fonts-noto-cjk fonts-noto-color-emoji fonts-font-awesome fonts-liberation
  libgtk-4-1 libgtk4-layer-shell0 libadwaita-1-0 libwebkit2gtk-4.1-0 libqt6multimedia6 qt6-image-formats-plugins
)
# --- Dépendances de compilation (script 21) --------------------------------
BUILD_DEPS=(
  build-essential cmake ninja-build meson pkg-config scdoc
  qt6-base-dev qt6-base-dev-tools qt6-declarative-dev qt6-multimedia-dev qt6-svg-dev
  libgtk-4-dev libgtk4-layer-shell-dev libadwaita-1-dev libepoxy-dev
  golang-go
  libpipewire-0.3-dev libavcodec-dev libavformat-dev libavutil-dev libavfilter-dev libswresample-dev
  libva-dev libdrm-dev libgbm-dev libcap-dev libpulse-dev libwayland-dev libxrandr-dev libxcomposite-dev libxfixes-dev libxdamage-dev libxi-dev libxext-dev libxrender-dev libxcb1-dev libegl1-mesa-dev libgl-dev
)

say "Mise à jour des index"; sudo apt-get update
say "Outils CLI (${#CLI[@]} paquets)";        apt_install "${CLI[@]}"
say "Bureau et GUI (${#GUI[@]} paquets)";     apt_install "${GUI[@]}"
say "Dépendances de compilation (${#BUILD_DEPS[@]} paquets)"; apt_install "${BUILD_DEPS[@]}"

say "Noms de commandes attendus par Omarchy"
# Ubuntu renomme fd → fdfind et bat → batcat ; Omarchy (et ses alias) attendent fd et bat.
ln -sfn "$(command -v fdfind)" "$HOME/.local/bin/fd";  ok "fd → fdfind"
ln -sfn "$(command -v batcat)" "$HOME/.local/bin/bat"; ok "bat → batcat"
if ! command -v tldr >/dev/null; then
  if command -v uv >/dev/null; then uv tool install tldr >/dev/null && ok "tldr (via uv)"; else warn "tldr : installe-le avec 'uv tool install tldr' ou 'pipx install tldr'"; fi
fi

say "Flathub (pour gpu-screen-recorder / Pinta au besoin)"
flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo && ok "dépôt flathub (utilisateur)"

say "Services système"
sudo systemctl enable --now bluetooth.service power-profiles-daemon.service avahi-daemon.service cups.service 2>/dev/null || true
ok "terminé"
