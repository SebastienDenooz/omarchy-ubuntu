# Reproduire Omarchy sur Ubuntu 26.04 — analyse de faisabilité

Machine cible : ThinkPad P14s Gen 5 AMD (Hawk Point), Ubuntu 26.04.1 LTS, Hyprland 0.53.3 (dépôt Ubuntu),
Quickshell 0.3.1, clavier belge AZERTY, écran interne 1920x1200 + Acer 2560x1440@144 sur HDMI-A-1, GDM.
Référence analysée : dépôt `basecamp/omarchy`, tag **v4.0.3** (dernière release stable au 12 septembre 2026),
comparé à `master` (écarts : 13 scripts en plus, 3 lignes de raccourcis, 22 fichiers QML retouchés).
Paquets Arch de référence : dépôt `omacom-io/omarchy-pkgs`.

## 1. Verdict

**Faisable, et sans compiler Hyprland.** Le point que je redoutais le plus, Hyprland 0.56.2 avec sa
configuration Lua, est disponible en paquets Ubuntu 26.04 via le PPA `cppiber/hyprland`, ainsi que
toute la pile hypr (guiutils, hyprsunset, hyprpicker, portail 1.4.1, hyprlock, hypridle). Quickshell
0.3.1, déjà installé, possède tous les modules que le shell Omarchy importe (Pipewire, UPower, Mpris,
SystemTray, Polkit, Pam, Notifications, Networking, Bluetooth, Hyprland, Wayland) ; Omarchy épingle un
commit git légèrement plus ancien (0.3.0+20), donc la compatibilité est très probable mais reste le
premier point à vérifier au premier démarrage.

Ce qui se reproduit tel quel :

- Les 22 thèmes et tout le système de thème (`colors.toml` → templates → terminal, btop, Hyprland,
  Neovim, Chromium/Chrome, VS Code, Obsidian, shell). C'est du bash pur, sans dépendance Arch.
- L'intégralité des raccourcis clavier (fichiers Lua), avec cinq corrections pour l'AZERTY belge.
- Le shell Quickshell : barre, panneaux audio/réseau/bluetooth/écran/énergie/calendrier, menu Omarchy,
  notifications, historique du presse-papiers, emoji, OSD, verrouillage, agent polkit, économiseur.
- Les 444 commandes `omarchy-*` et le CLI `omarchy`, à l'exception de la trentaine liée à pacman,
  Limine, Snapper et Plymouth, remplacées par des versions apt ou neutres.
- Le terminal foot (et alacritty/ghostty/kitty), tmux, starship, le prompt, les alias et fonctions
  (bash d'origine, ou zsh via `omarchy-zsh`), Neovim LazyVim thémé, les TUI (btop, lazygit, herdr,
  cliamp, try), les web apps.
- Les outils propres à Omarchy : omacalc, omacut, omawrite (Qt6, compilation courte), tensaku, herdr,
  cliamp, aether, ttfx, tzupdate, hyprland-preview-share-picker, gpu-screen-recorder.

Ce qui ne se porte pas, par nature :

- Le cycle de vie Arch : `pacman`/`yay`, les migrations, le garde-fou de mise à jour, les snapshots
  Snapper et le retour arrière au boot (Limine), les canaux stable/rc/edge, l'ISO et le provisioning.
- Plymouth et SDDM thémés (Ubuntu garde son Plymouth et GDM ; SDDM reste possible plus tard).
- Chromium : sur Ubuntu c'est un snap confiné qui casse les hôtes de messagerie native des extensions
  Omarchy et le mode `--app`. Google Chrome (deb, déjà installé) le remplace ; Omarchy le supporte
  explicitement (lanceur de web apps, extensions Copy URL et Download Video, thème).
- Le pare-feu ufw-docker, le durcissement PAM faillock, zram : optionnels ou sans objet.

Estimation : 1 h 30 de scripts (dont 20 à 40 min de compilation), puis une session de réglages.
Tout est réversible avec `90-rollback.sh`.

## 2. Ce qu'est Omarchy 4 (architecture)

Omarchy n'est plus une collection de dotfiles mais deux paquets Arch (`omarchy` et `omarchy-settings`)
qui déposent un arbre complet sous `/usr/share/omarchy` et des graines dans `/etc/skel` :

| Répertoire | Contenu | Taille |
| --- | --- | --- |
| `bin/` | 444 scripts (439 bash, 5 python) : `omarchy-<groupe>-<action>` | |
| `default/hypr/` | configuration Hyprland **en Lua** : `omarchy.lua`, `bindings/*.lua`, `apps/*.lua`, `looknfeel.lua`, `input.lua`, `envs.lua`, `windows.lua`, `qconsole.lua`, `toggles.lua` | |
| `config/` | fichiers copiés dans `~/.config` (hypr/*.lua de l'utilisateur, foot, alacritty, ghostty, kitty, btop, tmux, starship, lazygit, omarchy/shell.json, fcitx5, imv, xdph…) | |
| `shell/` | le bureau Quickshell : 104 fichiers QML, 18 plugins (bar, menu, notifications, osd, lock, polkit, clipboard, emojis, panels, background, reminders, agents, services idle/battery/media/nightlight) | 2,1 Mo |
| `themes/` | 22 thèmes : `colors.toml`, fonds d'écran, aperçus, `icons.theme`, parfois `hyprland.lua`, `btop.theme`, `chromium.theme` | 64 Mo |
| `default/themed/` | 19 templates `*.tpl` rendus à chaque changement de thème | |
| `default/` | bash (alias, fonctions), uwsm, systemd (units utilisateur), fontconfig, polices, xcompose, sddm, plymouth, limine, snapper, nautilus-python | |
| `etc/` | drop-ins système (logind, sysctl, sudoers, docker, fastfetch, kitty) | |
| `install/` | scripts d'installation ISO (paquets, matériel, config système, utilisateur) | |
| `migrations/` | 116 migrations shell, marquées par utilisateur | |
| `manual/` | 51 chapitres du manuel (lus intégralement pour cette analyse) | |

Points structurants pour un portage :

- **Tout passe par `$OMARCHY_PATH`** (`/usr/share/omarchy`), lu depuis `/etc/omarchy.conf` par
  `default/bash/env-bootstrap`, lui-même sourcé par `/etc/profile.d/omarchy.sh`, `.bashrc`, l'environnement
  uwsm et le Lua de Hyprland. Un lien symbolique `/usr/share/omarchy → ~/omarchy` suffit à satisfaire
  tous les chemins codés en dur.
- **Les commandes sont attendues dans le PATH** sous leur nom (`/usr/bin/omarchy-*` sur Arch). Le kit
  les lie dans `/usr/local/bin`.
- **La session est uwsm** : `omarchy.desktop` lance `uwsm start -g -1 -e -D Hyprland hyprland.desktop`.
  Ubuntu fournit uwsm 0.25.2 et GDM lit `/usr/local/share/wayland-sessions`.
- **Le shell est un seul processus Quickshell** (`quickshell -n -p /usr/share/omarchy/shell`) piloté par
  IPC (`omarchy-shell <cible> <méthode>`). Il gère aussi l'inactivité et le verrouillage : ni hypridle,
  ni hyprlock, ni waybar, ni swaync, ni polkit-agent externe.
- **Le Lua de Hyprland** : Omarchy utilise 39 fonctions `hl.*` (bind, unbind, config, monitor, env,
  window_rule, curve, animation, gesture, timer, on, get_config, get_active_window, dsp.*). Toutes existent
  déjà dans les stubs de 0.53.3, mais Omarchy vise 0.56.2 et huit scripts appellent `hyprctl eval`
  (absent en 0.53). Passer en 0.56.2 n'est donc pas négociable, et le PPA le permet.

## 3. Inventaire des composants

Le détail des 150 paquets de `omarchy-base.packages` est dans `MATRICE.md`. En résumé :

| Famille | Nombre | apt | deb/binaire | à compiler | présent | sans objet |
| --- | --- | --- | --- | --- | --- | --- |
| Pile Hyprland / session | 12 | 10 (PPA + Ubuntu) | — | 1 (share-picker) | 1 (quickshell) | — |
| Terminaux, shell, CLI | 55 | 44 | 4 (herdr, cliamp, try, mise) | 3 (ttfx, tzupdate, nvim) | 2 | 5 (outillage Arch) |
| GUI | 20 | 12 | 3 (aether, localsend, obsidian) | 3 (omacalc, omacut, omawrite) | 3 (Chrome, Signal, Spotify) | 2 (pinta → flatpak, moonlight) |
| Système et matériel | 60 | déjà couverts par Ubuntu | | | | 60 (ISO) |

Versions notables obtenues : Hyprland 0.56.2, hyprland-guiutils 0.2.2, hyprsunset 0.4.0,
xdg-desktop-portal-hyprland 1.4.1, uwsm 0.25.2, xdg-terminal-exec 0.14.0 (Omarchy : 0.14.3, les options
utilisées `--app-id`, `--dir`, `--print-id`, `--title` existent en 0.14.0), foot 1.25, neovim 0.11.6,
Lua 5.5 (exigé par Hyprland 0.56).

## 4. Raccourcis clavier

Omarchy définit ses raccourcis dans `default/hypr/bindings/{applications,tiling,utilities,media,
clipboard,voxtype}.lua` avec l'aide `o.bind(touches, description, action)`. Ils sont tous repris. Les
utilisateurs ajoutent ou remplacent dans `~/.config/hypr/bindings.lua` (`o.bind`, `o.rebind`,
`hl.unbind`). Vue d'ensemble :

| Famille | Exemples | Dépend de |
| --- | --- | --- |
| Applications | SUPER+Entrée terminal · SUPER+SHIFT+Entrée navigateur · SUPER+SHIFT+F fichiers · SUPER+SHIFT+N éditeur · SUPER+ALT+Entrée tmux · SUPER+CTRL+Entrée herdr | xdg-terminal-exec, uwsm-app, `omarchy-launch-*` |
| Web apps et pré-installés | SUPER+SHIFT+A ChatGPT · +E/+C HEY · +Y YouTube · +G Signal · +M Spotify · +O Obsidian · +W Omawrite · +/ 1Password | Chrome `--app`, apps installées ; désactivables via `omarchy_preinstalled_bindings = false` |
| Fenêtres et tiling | SUPER+W/Q fermer · J split · T flottant · F/ALT+F/CTRL+F plein écran · O pop · L layout scrolling · flèches focus/swap · code:20/21 redimensionner · G groupes · S/grave scratchpad | dispatchers Hyprland, `omarchy-hyprland-window-*` |
| Workspaces | SUPER+1..0 (keycodes) · SHIFT déplacer · SHIFT+ALT déplacer sans suivre · Tab suivant · molette | Hyprland |
| Menu et panneaux | SUPER+Espace menu · SUPER+ALT+Espace apps · SUPER+Échap système · SUPER+K raccourcis · SUPER+CTRL+A/B/W/D/P panneaux · SUPER+CTRL+1..9 | shell Quickshell |
| Captures | Impr écran · ALT+Impr enregistrement · SUPER+Impr pipette · SUPER+CTRL+Impr OCR · SUPER+CTRL+C menu | grim, slurp, tensaku, gpu-screen-recorder, tesseract, hyprpicker |
| Presse-papiers universel | SUPER+C/X/V partout (Ctrl+Insert / Shift+Insert dans un terminal) · SUPER+CTRL+V historique | `hl.dsp.send_key_state`, shell |
| Notifications, rappels, notices | SUPER+, · SUPER+CTRL+R rappel · SUPER+CTRL+ALT+T/B/W heure, batterie, météo | shell |
| Toggles | SUPER+CTRL+N nuit · +I veille · SUPER+SHIFT+Espace barre · SUPER+Backspace transparence · SUPER+CTRL+Delete écran interne | hyprsunset, `omarchy-toggle-*` |
| Multimédia | touches XF86 volume/luminosité/média, Shift pour min/max, Alt pour pas de 1 % | `omarchy-audio-*`, `omarchy-brightness-*` (brightnessctl, ddcutil, wpctl) |
| Style | SUPER+CTRL+SHIFT+Espace thème · SUPER+CTRL+Espace fond | shell |
| Capot | fermeture → écran interne éteint si un externe est branché | `omarchy-system-lid-close`, `omarchy-hyprland-monitor-clamshell` |

Adaptation à l'AZERTY belge (analyse keysym par keysym, appliquée dans `hypr/bindings.lua`) :

- Les chiffres et les touches `-`, `=`, `[`, `]` sont liés par **keycode** (`code:10..21`, `code:34/35`) :
  ils fonctionnent, mais tombent sur `&é"'(§è!çà`, `)°`, `-_`, `^¨`, `$*`.
- `SUPER + grave` (scratchpad) est injoignable : `grave` demande AltGr. Ajout de `SUPER + code:49`
  (touche `²/³`). L'alternative `SUPER + S` existe déjà.
- `SUPER + /` et `SUPER + ALT + /` (échelle d'écran) demandent Shift : doublés sur `code:61` (touche `:/`).
- `SUPER + CTRL + .` (transcodage) demande Shift : doublé sur `code:60` (touche `;.`).
- `SUPER + ,` (notifications) et `SUPER + SHIFT + /` (1Password) fonctionnent tels quels.
- La disposition `be` est lue par Omarchy dans `/etc/vconsole.conf`, présent sur ce Ubuntu ; le kit la
  fixe quand même dans `input.lua`. CapsLock devient la touche compose (emoji, nom, e-mail) : c'est le
  choix Omarchy, modifiable via `kb_options`.
- Alt+Tab est celui d'Omarchy : `ALT + Tab` cycle les fenêtres du workspace actif, `SUPER + ALT + Tab`
  celles d'un groupe, `CTRL + ALT + Tab` les écrans. Ton ancien sélecteur Quickshell n'est pas repris.

## 5. Thèmes

Le mécanisme (`omarchy-theme-set`, bash) est entièrement portable :

1. copie du thème `themes/<nom>/` dans `~/.local/state/omarchy/current/next-theme`, surcouche
   `~/.config/omarchy/themes/<nom>/` ;
2. rendu des templates `default/themed/*.tpl` à partir de `colors.toml` (alacritty, foot, ghostty, kitty,
   btop, chromium, hyprland.lua, neovim.lua, vscode, obsidian, helix, shell.toml, claude.json…) ;
3. bascule atomique vers `current/theme`, choix du fond d'écran, notification du shell, hook `theme-set`,
   puis re-teinte en parallèle des applications ouvertes (terminaux, Hyprland, btop, navigateur, éditeurs).

Les 22 thèmes (17 sombres, 5 clairs : Catppuccin Latte, Flexoki Light, Lupine, Rose Pine, White) sont
livrés avec 2 à 9 fonds chacun et un jeu d'icônes Yaru assorti (Ubuntu fournit `yaru-theme-icon` avec
toutes les variantes). Les applications thémées non installées sont simplement ignorées. Chrome reçoit
le thème par politique d'entreprise (`omarchy-theme-set-browser`, sudo demandé la première fois).

## 6. Points de friction Ubuntu et réponses

| Sujet | Sur Arch | Réponse du kit |
| --- | --- | --- |
| Hyprland 0.56.2 + Lua 5.5 | paquet omarchy | PPA cppiber (0.56.2-1ppa2, resolute) + `lua5.5` Ubuntu |
| Chemin `/usr/share/omarchy` | paquet | lien symbolique vers `~/omarchy` (branche git `ubuntu` sur v4.0.3) |
| `/usr/bin/omarchy-*` | paquet | liens dans `/usr/local/bin` (`omarchy-ubuntu-link-bins`) |
| `/etc/skel` | `useradd -m` | script 40 copie `config/`, sauvegarde l'existant |
| pacman / yay (35 scripts) | natif | 26 surcharges : apt + table `pkgmap.txt` (Arch → apt), AUR refusé proprement |
| `omarchy update` / migrations | pacman + migrations | fusion git du nouveau tag + `apt upgrade` ; migrations désactivées (marquées faites) |
| Snapper / Limine / Plymouth (22 scripts) | natif | no-op ; `omarchy-snapshot` renvoie déjà 127 sans snapper |
| SDDM + thème | natif | GDM conservé, session `omarchy.desktop` ajoutée |
| Chromium | paquet | Google Chrome, `mimeapps.list` réécrit, `xdg-settings` |
| Écran de verrouillage PAM | `omarchy-lock-password` inclut `system-local-login` | surcharge `omarchy-apply-lock` : `common-auth` / `common-account` |
| sudoers `%wheel` | Arch | réécrits avec `%sudo` et `/usr/local/bin` |
| units systemd `/usr/bin/omarchy-*` | paquet | copiées dans `~/.config/systemd/user` avec le chemin corrigé |
| hyprpolkitagent (activé ici) | absent | désactivé : le shell Omarchy a son agent polkit |
| `GDK_SCALE=2`, `natural_scroll=false` par défaut | écran retina | `monitors.lua` (scale 1, GDK 1), `input.lua` (natural_scroll true) |
| fd / bat renommés (`fdfind`, `batcat`) | — | liens dans `~/.local/bin` |
| `xdg-terminal-exec` 0.14.0 vs 0.14.3 | — | options utilisées présentes ; à surveiller |
| Polices (JetBrainsMono Nerd, iA Writer, omarchy.ttf) | paquets | téléchargées ; `omarchy.ttf` installé système avec `50-omarchy.conf` |
| gpu-screen-recorder | paquet | compilé (meson) ou flatpak (détection d'arrêt dégradée) |

## 7. Stratégie retenue et contenu du kit

Voir `README.md` pour l'ordre et les durées. Les choix :

- **Canal « dev » sans le dire** : Omarchy prévoit qu'un checkout git remplace le paquet
  (`omarchy-dev-link`). Le kit garde `OMARCHY_PATH=/usr/share/omarchy` (lien symbolique) pour que tous
  les chemins codés en dur restent vrais, et met les surcharges sur une branche `ubuntu` : la prochaine
  release se fusionne, les surcharges se rejouent (`31-overrides.sh`).
- **Rien dans `/usr/share` sauf ce qui est indispensable** : polices, fontconfig, session, uwsm env,
  xdg-terminal-exec, fcitx, fastfetch, kitty, deux drop-ins logind, un sysctl, deux sudoers.
- **Tout le reste sous `~/.local`** (binaires, applications, icônes) et `~/.config`.
- **Ta config Hyprland actuelle est sauvegardée**, pas supprimée : `backups/<horodatage>/`.

## 8. Ce qui restera différent d'un vrai Omarchy

- Pas de snapshot avant mise à jour ni de retour arrière au boot.
- `omarchy update` ne suit pas le miroir Arch « un mois en retard » : c'est `apt upgrade`.
- Les menus *Install > Package/AUR* et *Remove > Package* parlent apt ; les entrées *Install > …*
  qui nomment des paquets Arch échouent si `pkgmap.txt` n'a pas la correspondance (message explicite).
- Écran de démarrage Ubuntu, écran de connexion GDM, pas de « Unlock » thémé au déchiffrement.
- Docker sans le durcissement ufw-docker (option `--ufw` pour la politique de base).
- Dictée (voxtype), Tailscale, Dropbox, 1Password, jeux : à installer à la main si voulus.
- Le shell zsh n'est pas le bash d'Omarchy : `60-zsh.sh` reprend alias et fonctions via `omarchy-zsh`.

## 9. Risques et inconnues

1. **Shell Quickshell vs 0.3.1** : Omarchy compile quickshell à un commit précis (0.3.0+20). Si un
   composant QML refuse de charger, `journalctl --user -t omarchy-shell` le dira ; le remède est de
   compiler le commit épinglé (script `Ubuntu-Hyprland/install-scripts/quickshell.sh` comme modèle).
2. **PPA cppiber** : bibliothèques hypr dans des versions parallèles à celles d'Ubuntu (soname distincts,
   coexistence normale). Vérifier après le script 10 que `Hyprland --version` affiche 0.56.2 et que ta
   config actuelle démarre encore avant de continuer.
3. **`./bin/build` d'omacalc/omacut/omawrite** : scripts qmake6 non testés ici ; journaux dans `logs/`.
4. **hyprland-preview-share-picker** demande Rust nightly ; en cas d'échec, le portail retombe sur le
   sélecteur standard (`hyprland-share-picker`, présent).
5. **Extensions Chrome** (Copy URL, Download Video) : `omarchy-install-chromium-copy-url` sait écrire dans
   `~/.config/google-chrome` ; à lancer une fois Chrome fermé.
6. **Deux Hyprland dans apt** : `apt upgrade` gardera la version PPA tant que le PPA est présent ;
   `ppa-purge` remet 0.53.3.

## 10. Liste de contrôle après la première session Omarchy

- `omarchy-shell shell ping` répond ; la barre est visible ; `SUPER + Espace` ouvre le menu.
- `SUPER + K` liste les raccourcis (lit `xkbcli`, paquet `libxkbcommon-tools`).
- `SUPER + CTRL + L` verrouille et le mot de passe déverrouille (PAM `omarchy-lock-password`).
- `Impr écran` prend une capture, la notification ouvre Tensaku.
- `SUPER + CTRL + N` teinte l'écran (hyprsunset 0.4 piloté par `hyprctl hyprsunset`).
- `omarchy theme set "Catppuccin Latte"` re-teinte terminal, Neovim, Chrome, shell.
- `omarchy version`, `omarchy update` (test à blanc), `omarchy debug`.
- Bluetooth et Wi-Fi depuis les panneaux (`SUPER + CTRL + B / W`).
- Fermeture du capot avec l'Acer branché : écran interne éteint, rallumé à l'ouverture.

## 11. Références

- Dépôt : https://github.com/basecamp/omarchy (tag v4.0.3) · manuel : `manual/` (miroir learn.omacom.io)
- Paquets Arch : https://github.com/omacom-io/omarchy-pkgs (`pkgbuilds/`), dépôt binaire pkgs.omarchy.org
- PPA Hyprland pour Ubuntu : https://launchpad.net/~cppiber/+archive/ubuntu/hyprland
- Outils : omacom-io/{omacalc,omacut,omawrite,ttfx,omarchy-zsh,omadots}, jondkinney/tensaku,
  herdrdev/herdr, bjarneo/cliamp, omacom/aether, tobi/try, WhySoBad/hyprland-preview-share-picker,
  repo.dec05eba.com/gpu-screen-recorder, cdown/tzupdate, LazyVim/starter
