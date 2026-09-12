# Matrice des paquets Omarchy 4.0.3 → Ubuntu 26.04

Source : `install/omarchy-base.packages` (150 entrées) + paquets Arch requis par `omarchy` lui-même.
Statut : **apt** (dépôt Ubuntu ou PPA cppiber), **deb** (binaire officiel), **bin** (binaire GitHub),
**build** (compilé par `21-build.sh`), **présent** (déjà installé ici), **flatpak**, **skip** (sans objet
sur Ubuntu ou non porté). Script = étape du kit qui l'installe.

## Compositeur et écosystème Hypr

| Arch | Rôle | Ubuntu | Statut | Script |
| --- | --- | --- | --- | --- |
| hyprland | compositeur (Omarchy exige 0.56.2, Lua) | hyprland 0.56.2 (PPA) | apt | 10 |
| hyprland-guiutils | dialogues natifs Hyprland | hyprland-guiutils 0.2.2 (PPA) | apt | 10 |
| hyprland-preview-share-picker | sélecteur de partage d'écran avec aperçus | cargo nightly | build | 21 |
| hyprpicker | pipette couleur (SUPER+Print) | hyprpicker 0.4.7 (PPA) | apt | 10 |
| hyprsunset | lumière de nuit (SUPER+CTRL+N) | hyprsunset 0.4.0 (PPA) | apt | 10 |
| xdg-desktop-portal-hyprland | portail (partage d'écran) | 1.4.1 (PPA) | apt | 10 |
| xdg-desktop-portal-gtk | portail (fichiers) | présent | apt | 10 |
| quickshell | moteur du shell Omarchy | 0.3.1 présent (PPA danklinux) | présent | — |
| uwsm | gestion de session systemd | uwsm 0.25.2 | apt | 10 |
| xdg-terminal-exec | terminal par défaut (0.14.3 chez Omarchy) | 0.14.0 (--app-id, --dir, --print-id ok) | apt | 10 |
| wireplumber / pipewire | audio | présents | présent | — |
| sddm | gestionnaire de connexion | GDM conservé (sddm dispo en apt) | skip | — |
| plymouth | écran de boot thémé | Plymouth Ubuntu conservé | skip | — |
| gnome-keyring, libsecret | trousseau | gnome-keyring, libsecret-1-0 | apt | 11 |
| power-profiles-daemon | profils énergie | idem | apt | 11 |
| networkmanager | réseau | network-manager (présent) | présent | — |
| bluez, bluez-utils, bluez-tools | Bluetooth (+ bt-agent) | bluez, bluez-tools | apt | 11 |
| bolt | Thunderbolt | bolt | apt | 11 |
| brightnessctl, ddcutil, asdcontrol | luminosité écran interne / DDC / Apple | brightnessctl, ddcutil ; asdcontrol skip | apt | 11 |
| pamixer, alsa-utils | volume | pamixer, alsa-utils | apt | 11 |
| udiskie | montage auto | udiskie | apt | 11 |
| fcitx5, fcitx5-gtk, fcitx5-qt | méthode de saisie (compose CapsLock) | fcitx5, -frontend-gtk3, -frontend-qt6 | apt | 11 |
| gnome-themes-extra, yaru-icon-theme | thèmes GTK / icônes | gnome-themes-extra, yaru-theme-icon | apt | 11 |
| noto-fonts (+cjk, emoji) | polices | fonts-noto, -cjk, -color-emoji | apt | 11 |
| ttf-jetbrains-mono-nerd-basic | police système/terminal | zip Nerd Fonts 3.5.1 | bin | 20 |
| ttf-ia-writer | police Omawrite | TTF iaolo/iA-Fonts | bin | 20 |
| woff2-font-awesome | glyphes | fonts-font-awesome | apt | 11 |
| fontconfig | config polices | présent + 50-omarchy.conf | apt | 41 |

## Terminal, shell et CLI

| Arch | Rôle | Ubuntu | Statut | Script |
| --- | --- | --- | --- | --- |
| foot | terminal par défaut | foot 1.25 | apt | 11 |
| (alacritty, ghostty, kitty) | terminaux optionnels | alacritty apt ; ghostty, kitty présents | apt/présent | 11 |
| tmux | multiplexeur (SUPER+ALT+Entrée) | tmux 3.6 | apt | 11 |
| herdr | gestionnaire de terminal (SUPER+CTRL+Entrée) | binaire v0.9.0 | bin | 20 |
| starship | prompt | starship 1.22 | apt | 11 |
| bash-completion | complétion | idem | apt | 11 |
| bat, eza, fd, fzf, ripgrep, zoxide | outils shell | bat*, eza, fd-find*, fzf, ripgrep, zoxide (*liens fd/bat créés) | apt | 11 |
| btop | Activity (SUPER+CTRL+T) | btop 1.4 | apt | 11 |
| fastfetch | About | fastfetch 2.57 | apt | 11 |
| dua-cli | Disk Usage | dua-cli absent d'apt → `cargo install dua-cli` | manuel | — |
| tldr | aide courte | via `uv tool install tldr` | build | 11 |
| tobi-try | expériences datées (`try`) | script ruby v1.8.1 | bin | 20 |
| lazygit | TUI git | lazygit 0.57 | apt | 11 |
| lazydocker | TUI docker (SUPER+SHIFT+D) | absent d'apt → `go install github.com/jesseduffield/lazydocker@latest` | manuel | — |
| docker, docker-buildx, docker-compose | conteneurs | docker.io, docker-buildx, docker-compose-v2 (présents) | apt | 11 |
| ufw, ufw-docker | pare-feu | ufw ; ufw-docker skip | apt (option --ufw) | 41 |
| git, jq, less, man-db, unzip, whois, socat, inotify-tools, inxi, plocate | base | idem | apt | 11 |
| inetutils | ping etc. | inetutils-ping (facultatif) | skip | — |
| fakeroot, expac, pacman-contrib, yay, kernel-modules-hook | outillage Arch | sans objet | skip | — |
| mise-bin, usage | environnements de dev et CLI IA | script mise.run ; usage skip | bin | 20 |
| ruby, clang, llvm, lua51, luarocks, tree-sitter-cli, dotnet-runtime | runtimes (nvim, try, mise) | ruby, lua5.1, luarocks, tree-sitter-cli ; clang/llvm/dotnet skip | apt | 11 |
| nvim + omarchy-nvim | Neovim LazyVim thémé | neovim 0.11 + LazyVim starter + surcouche | build | 21 |
| vi | vi historique | vim-tiny | apt | (pkgmap) |
| tzupdate | fuseau horaire auto | cargo 3.1.0 + sudoers | build | 21, 41 |
| cliamp | lecteur musique TUI | binaire v2.2.0 | bin | 20 |
| ttfx | effets texte (screensaver) | cargo v0.3.2 | build | 21 |
| tensaku | annotation de captures | tar.gz v0.29.0 | bin | 20 |
| gum | dialogues des scripts | gum 0.17 | apt | 11 |
| tesseract, tesseract-data-eng, zbar, qrencode | OCR, QR (captures) | tesseract-ocr(+eng,+fra), zbar-tools, qrencode | apt | 11 |
| grim, slurp, wl-clipboard, wtype | captures, presse-papiers | idem | apt | 11 |
| gpu-screen-recorder | enregistrement d'écran | meson depuis repo.dec05eba.com (ou flatpak) | build | 21 |
| imagemagick, libvips, ffmpegthumbnailer | transcodage, vignettes | imagemagick, libvips-tools, ffmpegthumbnailer | apt | 11 |
| yt-dlp | téléchargement vidéo | yt-dlp | apt | 11 |
| python-gobject, python-poetry-core | scripts Python d'Omarchy | python3-gi, python3-poetry-core | apt | 11 |
| libyaml, mariadb-libs, postgresql-libs | libs pour mise/ruby | libyaml-0-2, libmariadb3, libpq5 | apt | (pkgmap) |
| qemu-user-static-binfmt | binfmt (docker multi-arch) | qemu-user-binfmt | apt | (pkgmap) |
| dosfstools, exfatprogs | formatage clés USB | idem | apt | 11 |
| avahi, nss-mdns, cups, cups-filters, cups-pk-helper, system-config-printer | impression, mDNS | avahi-daemon, libnss-mdns, cups, cups-filters, system-config-printer | apt | 11 |
| wireless-regdb | régulation Wi-Fi | présent (linux-firmware) | présent | — |

## Applications graphiques

| Arch | Rôle | Ubuntu | Statut | Script |
| --- | --- | --- | --- | --- |
| chromium | navigateur par défaut, web apps | snap sur Ubuntu → **Google Chrome** (deb, présent) pris comme défaut | présent | 40 |
| nautilus, nautilus-python, sushi, gvfs-* | fichiers (SUPER+SHIFT+F) | nautilus, python3-nautilus, gnome-sushi, gvfs-backends | apt | 11 |
| gnome-disk-utility | Disks | idem | apt | 11 |
| evince | PDF | evince | apt | 11 |
| imv, mpv, mpv-mpris | images, vidéo | imv, mpv (mpris intégré) | apt | 11 |
| libreoffice-fresh | bureautique | libreoffice | apt | 11 |
| obs-studio, kdenlive | capture, montage | obs-studio, kdenlive | apt | 11 |
| xournalpp | annotation PDF | xournalpp | apt | 11 |
| pinta | retouche image | absent d'apt → flatpak (`--with-pinta`) | flatpak | 20 |
| obsidian | notes (SUPER+SHIFT+O) | deb 1.13.8 | deb | 20 |
| localsend | partage réseau (SUPER+CTRL+S) | deb 1.18.2 | deb | 20 |
| aether | création de thèmes | deb 4.29.8 | deb | 20 |
| omacalc | calculatrice (SUPER+CTRL+Q) | Qt6, compilé | build | 21 |
| omacut | découpe vidéo | Qt6, compilé | build | 21 |
| omawrite | écriture Markdown (SUPER+SHIFT+W) | Qt6, compilé | build | 21 |
| moonlight-qt | streaming de jeux | absent d'apt (flatpak com.moonlight_stream.Moonlight) | skip | — |
| signal-desktop (install optionnel) | messagerie (SUPER+SHIFT+G) | présent (dépôt Signal) | présent | — |
| spotify (install optionnel) | musique (SUPER+SHIFT+M) | présent (dépôt Spotify) | présent | — |
| 1password (install optionnel) | mots de passe (SUPER+SHIFT+/) | dépôt deb 1Password si voulu | skip | — |
| voxtype-bin (install optionnel) | dictée (F9) | binaire voxtype.io | skip (`--with-voxtype`) | 20 |

## Matériel et système (omarchy-other.packages)

Concerne l'ISO : noyau, firmware, pilotes NVIDIA/Intel/Apple/Tuxedo, Limine, Snapper, zram, btrfs.
Rien à reprendre sur ce ThinkPad AMD sous Ubuntu : `vulkan-radeon`, `pipewire-*`, `qt6-wayland`,
`gtk4-layer-shell`, `sof-firmware`, `thermald` sont déjà fournis par Ubuntu.

## Paquets Omarchy eux-mêmes

| Paquet | Contenu | Reproduction |
| --- | --- | --- |
| omarchy | bin/, install/, migrations/, themes/, shell/ | dépôt git v4.0.3 → /usr/share/omarchy + liens /usr/local/bin |
| omarchy-settings | /etc/skel, /etc drop-ins, polices, session, plymouth, sddm | scripts 40 et 41 (sans plymouth/sddm/limine/snapper) |
| omarchy-keyring | clés pacman | sans objet |
| omarchy-nvim | LazyVim + thème dynamique | script 21 |
| omarchy-zsh (optionnel) | alias/fonctions pour zsh | script 60 |
| omarchy-chromium-bin, omarchy-walker, elephant-* | reliquats v3 / optionnels | sans objet en v4 |
