# Omarchy 4.0.3 sur Ubuntu 26.04 — kit d'installation

Ce dossier reproduit la configuration Omarchy (Hyprland, shell Quickshell, thèmes, raccourcis,
outils) sur ce ThinkPad P14s sous Ubuntu 26.04. Rien n'a été exécuté : chaque script est à lancer
par toi, dans l'ordre, après lecture. L'analyse complète est dans `RAPPORT.md`, le détail paquet
par paquet dans `MATRICE.md`.

## Principe

- Le dépôt `basecamp/omarchy` (tag v4.0.3) est cloné dans `~/omarchy` et exposé en
  `/usr/share/omarchy`, le chemin codé en dur partout dans Omarchy. Ses 444 commandes `omarchy-*`
  sont liées dans `/usr/local/bin`.
- Les scripts liés à pacman, Limine, Snapper et Plymouth sont remplacés par des versions apt ou
  neutres (`overrides/bin`), sur une branche git `ubuntu` du dépôt : une mise à jour d'Omarchy se
  fait par fusion du nouveau tag.
- Hyprland 0.56.2 et tout l'écosystème hypr viennent du PPA `cppiber/hyprland`, qui publie pour
  26.04. Quickshell 0.3.1 déjà présent convient.
- Les outils propres à Omarchy (omacalc, omacut, omawrite, tensaku, herdr, ttfx, cliamp, aether…)
  sont installés depuis leurs binaires officiels ou compilés sous `~/.local`.
- Ta config Hyprland actuelle est sauvegardée dans `backups/` ; le script `90-rollback.sh` la remet.

## Ordre d'exécution

| Étape | Script | sudo | Durée | Rôle |
| --- | --- | --- | --- | --- |
| 0 | `scripts/00-preflight.sh` | non | 10 s | État de la machine, rien n'est modifié |
| 1 | `scripts/10-ppa-hyprland.sh` | oui | 3 min | PPA + Hyprland 0.56.2, hyprsunset, portail, uwsm |
| 2 | `scripts/11-apt.sh` | oui | 10 min | ~130 paquets apt (outils, GUI, dépendances de build) |
| — | déconnexion / reconnexion | | | valide Hyprland 0.56 avec ta config actuelle |
| 3 | `scripts/20-prebuilt.sh` | oui (deb) | 5 min | aether, localsend, obsidian, tensaku, herdr, cliamp, try, mise, polices |
| 4 | `scripts/21-build.sh` | non | 20-40 min | omacalc/omacut/omawrite, ttfx, tzupdate, share-picker, gpu-screen-recorder, Neovim LazyVim |
| 5 | `scripts/30-checkout.sh` | oui | 1 min | clone v4.0.3, `/usr/share/omarchy`, `/etc/omarchy.conf`, liens des commandes |
| 6 | `scripts/31-overrides.sh` | oui | 10 s | surcharges Ubuntu + commit sur la branche `ubuntu` |
| 7 | `scripts/41-system.sh` | oui | 30 s | session GDM, uwsm, polices, fcitx, drop-ins systemd, sudoers |
| 8 | `scripts/40-user-configs.sh` | non | 30 s | `~/.config` Omarchy, surcharges AZERTY/écrans, services utilisateur |
| 9 | `scripts/50-theme.sh` | non | 10 s | thème Tokyo Night et fichiers thémés |
| 10 | `scripts/60-zsh.sh` (optionnel) | non | 30 s | alias et fonctions Omarchy pour zsh |
| — | déconnexion → session « Omarchy (Hyprland uwsm) » | | | |

Options : `41-system.sh --ufw --docker` (pare-feu et Docker façon Omarchy),
`20-prebuilt.sh --with-pinta --with-voxtype`.

## Après l'installation

- `SUPER + Espace` ouvre le menu Omarchy, `SUPER + K` liste les raccourcis.
- `omarchy` en terminal donne le CLI complet ; `omarchy update` fusionne la prochaine release et
  fait `apt upgrade`.
- Les fichiers à toi : `~/.config/hypr/{monitors,input,bindings,looknfeel,autostart}.lua`,
  `~/.config/omarchy/shell.json`. Les défauts sont dans `/usr/share/omarchy/default`, à ne pas éditer.
- Retour arrière : `scripts/90-rollback.sh` (ajoute `--purge-ppa` pour revenir à Hyprland 0.53.3).

## Contenu

```
README.md            ce fichier
RAPPORT.md           analyse de faisabilité complète
MATRICE.md           les 150 paquets Omarchy et leur équivalent Ubuntu
scripts/             étapes 00 → 90 (+ lib.sh commun)
overrides/bin/       26 scripts omarchy-* réécrits pour apt / no-op
overrides/pkgmap.txt correspondance des noms de paquets Arch → apt
hypr/                monitors, input, bindings (corrections AZERTY), looknfeel, autostart pour cette machine
dl/ build/ logs/     téléchargements, compilations, journaux (créés à l'usage)
backups/             tes configs remplacées, horodatées
```
