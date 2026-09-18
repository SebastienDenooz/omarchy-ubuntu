# Omarchy 4.0.3 → Ubuntu 26.04 package matrix

Source: `install/omarchy-base.packages` (150 entries) plus the Arch packages required by `omarchy` itself.
Status: **apt** (Ubuntu repository or cppiber PPA), **deb** (official binary), **bin** (GitHub binary),
**build** (compiled by `21-build.sh`), **present** (already installed here), **flatpak**, **skip** (not
applicable on Ubuntu or not ported). Script = kit step that installs it.

## Compositor and hypr ecosystem

| Arch | Role | Ubuntu | Status | Script |
| --- | --- | --- | --- | --- |
| hyprland | compositor (Omarchy requires 0.56.2, Lua) | hyprland 0.56.2 (PPA) | apt | 10 |
| hyprland-guiutils | native Hyprland dialogs | hyprland-guiutils 0.2.2 (PPA) | apt | 10 |
| hyprland-preview-share-picker | screen-share picker with previews | cargo nightly | build | 21 |
| hyprpicker | color picker (SUPER+Print) | hyprpicker 0.4.7 (PPA) | apt | 10 |
| hyprsunset | night light (SUPER+CTRL+N) | hyprsunset 0.4.0 (PPA) | apt | 10 |
| xdg-desktop-portal-hyprland | portal (screen sharing) | 1.4.1 (PPA) | apt | 10 |
| xdg-desktop-portal-gtk | portal (file dialogs) | present | apt | 10 |
| quickshell | engine of the Omarchy shell | 0.3.1 present (danklinux PPA) | present | — |
| uwsm | systemd session management | uwsm 0.25.2 | apt | 10 |
| xdg-terminal-exec | default terminal (Omarchy: 0.14.3) | 0.14.0 (--app-id, --dir, --print-id ok) | apt | 10 |
| wireplumber / pipewire | audio | present | present | — |
| sddm | login manager | GDM kept (sddm available in apt) | skip | — |
| plymouth | themed boot screen | Ubuntu's Plymouth kept | skip | — |
| gnome-keyring, libsecret | keyring | gnome-keyring, libsecret-1-0 | apt | 11 |
| power-profiles-daemon | power profiles | same | apt | 11 |
| networkmanager | network | network-manager (present) | present | — |
| bluez, bluez-utils, bluez-tools | Bluetooth (+ bt-agent) | bluez, bluez-tools | apt | 11 |
| bolt | Thunderbolt | bolt | apt | 11 |
| brightnessctl, ddcutil, asdcontrol | internal / DDC / Apple brightness | brightnessctl, ddcutil; asdcontrol skip | apt | 11 |
| pamixer, alsa-utils | volume | pamixer, alsa-utils | apt | 11 |
| udiskie | auto-mount | udiskie | apt | 11 |
| fcitx5, fcitx5-gtk, fcitx5-qt | input method (CapsLock compose) | fcitx5, -frontend-gtk3, -frontend-qt6 | apt | 11 |
| gnome-themes-extra, yaru-icon-theme | GTK themes / icons | gnome-themes-extra, yaru-theme-icon | apt | 11 |
| noto-fonts (+cjk, emoji) | fonts | fonts-noto, -cjk, -color-emoji | apt | 11 |
| ttf-jetbrains-mono-nerd-basic | system/terminal font | Nerd Fonts 3.5.1 zip | bin | 20 |
| ttf-ia-writer | Omawrite font | iaolo/iA-Fonts TTF | bin | 20 |
| woff2-font-awesome | glyphs | fonts-font-awesome | apt | 11 |
| fontconfig | font config | present + 50-omarchy.conf | apt | 41 |

## Terminal, shell and CLI

| Arch | Role | Ubuntu | Status | Script |
| --- | --- | --- | --- | --- |
| foot | default terminal | foot 1.25 (theme template adapted, see `themed/`) | apt | 11 |
| (alacritty, ghostty, kitty) | optional terminals | alacritty apt; ghostty, kitty present | apt/present | 11 |
| tmux | multiplexer (SUPER+ALT+Enter) | tmux 3.6 | apt | 11 |
| herdr | terminal workspace manager (SUPER+CTRL+Enter) | binary v0.9.0 | bin | 20 |
| starship | prompt | starship 1.22 | apt | 11 |
| bash-completion | completion | same | apt | 11 |
| bat, eza, fd, fzf, ripgrep, zoxide | shell tools | bat*, eza, fd-find*, fzf, ripgrep, zoxide (*fd/bat links created) | apt | 11 |
| btop | Activity (SUPER+CTRL+T) | btop 1.4 | apt | 11 |
| fastfetch | About | fastfetch 2.57 | apt | 11 |
| dua-cli | Disk Usage | not in apt → `cargo install dua-cli` | manual | — |
| tldr | short help | via `uv tool install tldr` | build | 11 |
| tobi-try | dated experiments (`try`) | ruby script v1.8.1 | bin | 20 |
| lazygit | git TUI | lazygit 0.57 | apt | 11 |
| lazydocker | docker TUI (SUPER+SHIFT+D) | not in apt → `go install github.com/jesseduffield/lazydocker@latest` | manual | — |
| docker, docker-buildx, docker-compose | containers | docker-ce + plugins already present (Docker repo) | present | 11 |
| ufw, ufw-docker | firewall | ufw; ufw-docker skip | apt (option --ufw) | 41 |
| git, jq, less, man-db, unzip, whois, socat, inotify-tools, inxi, plocate | base | same | apt | 11 |
| inetutils | ping etc. | inetutils-ping (optional) | skip | — |
| fakeroot, expac, pacman-contrib, yay, kernel-modules-hook | Arch tooling | not applicable | skip | — |
| mise-bin, usage | dev environments and AI CLIs | mise.run script; usage skip | bin | 20 |
| ruby, clang, llvm, lua51, luarocks, tree-sitter-cli, dotnet-runtime | runtimes (nvim, try, mise) | ruby, lua5.1, luarocks, tree-sitter-cli; clang/llvm/dotnet skip | apt | 11 |
| nvim + omarchy-nvim | themed Neovim LazyVim | neovim 0.11 + LazyVim starter + overlay | build | 21 |
| vi | historical vi | vim-tiny | apt | (pkgmap) |
| tzupdate | automatic timezone | cargo 3.1.0 + sudoers | build | 21, 41 |
| cliamp | TUI music player | binary v2.2.0 | bin | 20 |
| ttfx | text effects (screensaver) | cargo v0.3.2 | build | 21 |
| tensaku | screenshot annotation | tar.gz v0.29.0 | bin | 20 |
| gum | script dialogs | gum 0.17 | apt | 11 |
| tesseract, tesseract-data-eng, zbar, qrencode | OCR, QR (captures) | tesseract-ocr(+eng,+fra), zbar-tools, qrencode | apt | 11 |
| grim, slurp, wl-clipboard, wtype | captures, clipboard | same | apt | 11 |
| gpu-screen-recorder | screen recording | meson from repo.dec05eba.com (or flatpak) | build | 21 |
| imagemagick, libvips, ffmpegthumbnailer | transcoding, thumbnails | imagemagick, libvips-tools, ffmpegthumbnailer | apt | 11 |
| yt-dlp | video download | yt-dlp | apt | 11 |
| python-gobject, python-poetry-core | Omarchy Python scripts | python3-gi, python3-poetry-core | apt | 11 |
| libyaml, mariadb-libs, postgresql-libs | libs for mise/ruby | libyaml-0-2, libmariadb3, libpq5 | apt | (pkgmap) |
| qemu-user-static-binfmt | binfmt (multi-arch docker) | qemu-user-binfmt | apt | (pkgmap) |
| dosfstools, exfatprogs | USB stick formatting | same | apt | 11 |
| avahi, nss-mdns, cups, cups-filters, cups-pk-helper, system-config-printer | printing, mDNS | avahi-daemon, libnss-mdns, cups, cups-filters, system-config-printer | apt | 11 |
| wireless-regdb | Wi-Fi regulatory db | present (linux-firmware) | present | — |

## Graphical applications

| Arch | Role | Ubuntu | Status | Script |
| --- | --- | --- | --- | --- |
| chromium | default browser, web apps | snap on Ubuntu → **Google Chrome** (deb, present) as default | present | 40 |
| nautilus, nautilus-python, sushi, gvfs-* | files (SUPER+SHIFT+F) | nautilus, python3-nautilus, gnome-sushi, gvfs-backends | apt | 11 |
| gnome-disk-utility | Disks | same | apt | 11 |
| evince | PDF | evince | apt | 11 |
| imv, mpv, mpv-mpris | images, video | imv, mpv (mpris built in) | apt | 11 |
| libreoffice-fresh | office suite | libreoffice | apt | 11 |
| obs-studio, kdenlive | capture, editing | obs-studio, kdenlive | apt | 11 |
| xournalpp | PDF annotation | xournalpp | apt | 11 |
| pinta | image editing | not in apt → flatpak (`--with-pinta`) | flatpak | 20 |
| obsidian | notes (SUPER+SHIFT+O) | deb 1.13.7 | deb | 20 |
| localsend | LAN sharing (SUPER+CTRL+S) | deb 1.18.2 | deb | 20 |
| aether | theme builder | deb 4.29.8 | deb | 20 |
| omacalc | calculator (SUPER+CTRL+Q) | Qt6, built | build | 21 |
| omacut | video trimmer | Qt6, built | build | 21 |
| omawrite | Markdown writing (SUPER+SHIFT+W) | Qt6, built | build | 21 |
| moonlight-qt | game streaming | not in apt (flatpak com.moonlight_stream.Moonlight) | skip | — |
| signal-desktop (optional install) | messaging (SUPER+SHIFT+G) | present (Signal repo) | present | — |
| spotify (optional install) | music (SUPER+SHIFT+M) | present (Spotify repo) | present | — |
| 1password (optional install) | passwords (SUPER+SHIFT+/) | 1Password deb repo if wanted | skip | — |
| hyprmoncfg-bin (Omarchy plugin backend) | multi-monitor profiles, hotplug/lid switching | built from source v1.18.3 + `hyprmoncfgd` user service; plugin `crmne.hyprmoncfg` | build | 55 |
| voxtype-bin (optional install) | dictation (F9) | official .deb 1.0.1, model by locale, CPU/GPU | deb | 25 |

## Hardware and system (omarchy-other.packages)

ISO concerns: kernel, firmware, NVIDIA/Intel/Apple/Tuxedo drivers, Limine, Snapper, zram, btrfs.
Nothing to carry over on this AMD ThinkPad under Ubuntu: `vulkan-radeon`, `pipewire-*`, `qt6-wayland`,
`gtk4-layer-shell`, `sof-firmware`, `thermald` are already provided by Ubuntu.

## The Omarchy packages themselves

| Package | Contents | Reproduction |
| --- | --- | --- |
| omarchy | bin/, install/, migrations/, themes/, shell/ | git checkout v4.0.3 → /usr/share/omarchy + /usr/local/bin links |
| omarchy-settings | /etc/skel, /etc drop-ins, fonts, session, plymouth, sddm | scripts 40 and 41 (without plymouth/sddm/limine/snapper) |
| omarchy-keyring | pacman keys | not applicable |
| omarchy-nvim | LazyVim + dynamic theme | script 21 |
| omarchy-zsh (optional) | aliases/functions for zsh | script 60 |
| omarchy-chromium-bin, omarchy-walker, elephant-* | v3 leftovers / optional | not applicable in v4 |
