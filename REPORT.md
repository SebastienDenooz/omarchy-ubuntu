# Reproducing Omarchy on Ubuntu 26.04 — feasibility analysis and outcome

Target machine: ThinkPad P14s Gen 5 AMD (Hawk Point), Ubuntu 26.04.1 LTS, Hyprland 0.53.3 (Ubuntu repository)
at the start, Quickshell 0.3.1, Belgian AZERTY keyboard, internal 1920x1200 display + Acer 2560x1440@144 on
HDMI-A-1, GDM. Reference analysed: `basecamp/omarchy` repository, tag **v4.0.3** (latest stable release as of
12 September 2026), compared with `master` (differences: 13 extra scripts, 3 keybinding lines, 22 QML files).
Arch packaging reference: the `omacom-io/omarchy-pkgs` repository.

Status on 13 September 2026: **installed and in daily use** through this kit. Section 12 lists what the
installation taught us; every point is already handled by the scripts.

## 1. Verdict

**Feasible, without compiling Hyprland.** The point I feared most, Hyprland 0.56.2 with its Lua
configuration, is available as Ubuntu 26.04 packages from the `cppiber/hyprland` PPA, together with the
whole hypr stack (guiutils, hyprsunset, hyprpicker, portal 1.4.1, hyprlock, hypridle). Quickshell 0.3.1,
already installed, has every module the Omarchy shell imports (Pipewire, UPower, Mpris, SystemTray, Polkit,
Pam, Notifications, Networking, Bluetooth, Hyprland, Wayland); Omarchy pins a slightly older git commit
(0.3.0+20), and in practice only one QML file needed a one-word patch.

What reproduces as is:

- The 22 themes and the whole theme system (`colors.toml` → templates → terminal, btop, Hyprland, Neovim,
  Chromium/Chrome, VS Code, Obsidian, shell). Pure bash, no Arch dependency.
- All keybindings (Lua files), with five fixes for Belgian AZERTY.
- The Quickshell shell: bar, audio/network/bluetooth/display/power/calendar panels, Omarchy menu,
  notifications, clipboard history, emoji, OSD, lock screen, polkit agent, screensaver.
- The 444 `omarchy-*` commands and the `omarchy` CLI, except the thirty or so tied to pacman, Limine,
  Snapper and Plymouth, replaced by apt or no-op versions.
- The foot terminal (and alacritty/ghostty/kitty), tmux, starship, the prompt, aliases and functions (bash
  originals, or zsh through `omarchy-zsh`), themed Neovim LazyVim, the TUIs (btop, lazygit, herdr, cliamp,
  try), the web apps, Voxtype dictation.
- Omarchy's own tools: omacalc, omacut, omawrite (Qt6, short build), tensaku, herdr, cliamp, aether, ttfx,
  tzupdate, hyprland-preview-share-picker, gpu-screen-recorder.

What does not port, by nature:

- The Arch life cycle: `pacman`/`yay`, migrations, the update guard, Snapper snapshots and boot-time
  rollback (Limine), the stable/rc/edge channels, the ISO and provisioning.
- Themed Plymouth and SDDM (Ubuntu keeps its Plymouth and GDM; SDDM remains possible later).
- Chromium: on Ubuntu it is a confined snap that breaks the native messaging hosts of the Omarchy extensions
  and the `--app` mode. Google Chrome (deb, already installed) replaces it; Omarchy supports it explicitly
  (web-app launcher, Copy URL and Download Video extensions, theme).
- The ufw-docker firewall, PAM faillock hardening, zram: optional or not applicable.

Actual effort: about 1 h 30 of scripts (20 to 40 min of builds), then one session of tweaks.
Everything is reversible with `90-rollback.sh`.

## 2. What Omarchy 4 is (architecture)

Omarchy is no longer a dotfiles collection but two Arch packages (`omarchy` and `omarchy-settings`) that
drop a full tree under `/usr/share/omarchy` and seeds into `/etc/skel`:

| Directory | Contents | Size |
| --- | --- | --- |
| `bin/` | 444 scripts (439 bash, 5 python): `omarchy-<group>-<action>` | |
| `default/hypr/` | Hyprland configuration **in Lua**: `omarchy.lua`, `bindings/*.lua`, `apps/*.lua`, `looknfeel.lua`, `input.lua`, `envs.lua`, `windows.lua`, `qconsole.lua`, `toggles.lua` | |
| `config/` | files copied into `~/.config` (user hypr/*.lua, foot, alacritty, ghostty, kitty, btop, tmux, starship, lazygit, omarchy/shell.json, fcitx5, imv, xdph…) | |
| `shell/` | the Quickshell desktop: 104 QML files, 18 plugins (bar, menu, notifications, osd, lock, polkit, clipboard, emojis, panels, background, reminders, agents, idle/battery/media/nightlight services) | 2.1 MB |
| `themes/` | 22 themes: `colors.toml`, backgrounds, previews, `icons.theme`, sometimes `hyprland.lua`, `btop.theme`, `chromium.theme` | 64 MB |
| `default/themed/` | 19 `*.tpl` templates rendered at every theme change | |
| `default/` | bash (aliases, functions), uwsm, systemd (user units), fontconfig, fonts, xcompose, sddm, plymouth, limine, snapper, nautilus-python | |
| `etc/` | system drop-ins (logind, sysctl, sudoers, docker, fastfetch, kitty) | |
| `install/` | ISO install scripts (packages, hardware, system config, user) | |
| `migrations/` | 116 shell migrations, marked per user | |
| `manual/` | 51 chapters of the manual (read in full for this analysis) | |

Structural points for a port:

- **Everything goes through `$OMARCHY_PATH`** (`/usr/share/omarchy`), read from `/etc/omarchy.conf` by
  `default/bash/env-bootstrap`, itself sourced by `/etc/profile.d/omarchy.sh`, `.bashrc`, the uwsm
  environment and Hyprland's Lua. A symlink `/usr/share/omarchy → ~/omarchy` satisfies every hardcoded path.
- **Commands are expected on the PATH** under their name (`/usr/bin/omarchy-*` on Arch). The kit links them
  into `/usr/local/bin`.
- **The session is uwsm**: `omarchy.desktop` runs `uwsm start -g -1 -e -D Hyprland hyprland.desktop`.
  Ubuntu ships uwsm 0.25.2 and GDM reads `/usr/local/share/wayland-sessions`.
- **The shell is a single Quickshell process** (`quickshell -n -p /usr/share/omarchy/shell`) driven over IPC
  (`omarchy-shell <target> <method>`). It also owns idle and locking: no hypridle, hyprlock, waybar, swaync
  or external polkit agent.
- **Hyprland's Lua**: Omarchy uses 39 `hl.*` functions (bind, unbind, config, monitor, env, window_rule,
  curve, animation, gesture, timer, on, get_config, get_active_window, dsp.*). All already exist in the
  0.53.3 stubs, but Omarchy targets 0.56.2 and eight scripts call `hyprctl eval` (absent in 0.53). Moving to
  0.56.2 is therefore mandatory, and the PPA makes it possible. Hyprland 0.56 loads `hyprland.lua` in
  preference to `hyprland.conf` when both exist.

## 2b. Portability: what is generic and what is not

The kit is written for any Ubuntu 26.04 LTS machine, not for the ThinkPad it was built on:

| Setting | How it is decided |
| --- | --- |
| Ubuntu release | `require_ubuntu` in `lib.sh` stops below 26.04 LTS: Hyprland 0.56 needs Lua 5.5 and the shell a recent Qt 6, and 24.04 LTS ships neither (no `lua5.5`, Qt 6.4.2); the danklinux PPA also publishes Quickshell for 26.04 but not for 24.04 |
| Keyboard layout | read from `/etc/default/keyboard`, falling back to `/etc/vconsole.conf` then `us`; Omarchy alone reads only the latter, which a plain Ubuntu does not have |
| AZERTY keycode fixes | added by `hypr/bindings.lua` only when that layout is `be` or `fr` |
| Monitors | generic `preferred`/`auto`; fixed layouts live in `hypr/machines/<machine>/`, untracked, applied by step 40 only when `/sys/class/dmi/id/product_name` or `product_family` matches the profile's `match` file, and step 40 offers to generate one from the connected monitors; per-setup layouts are hyprmoncfg's job (step 55) |
| OCR language | `tesseract-ocr-<lang>` derived from `$LANG`, on top of English |
| Dictation model | `base.en` in English, the multilingual `small` model otherwise (step 25) |
| Transcription engine | GPU when Vulkan is detected, CPU otherwise, asked at install time |
| Shell integration | step 60 runs automatically when `$SHELL` is zsh |
| Touchpad scrolling, terminal, browser, theme | asked at install time, defaulting to Omarchy's own choices (traditional scrolling, foot, Chrome for the web apps, Tokyo Night); answers kept in `logs/answers.env`, `--defaults` skips the questions |
| Session-only steps | skipped when no user systemd manager or compositor is present, as in a container |

No machine profile ships with the kit: the repository holds only the mechanism and its documentation, and
a profile is generated on the machine that needs one.

## 3. Component inventory

The detail of the 150 packages of `omarchy-base.packages` is in `MATRIX.md`. In short:

| Family | Count | apt | deb/binary | built | present | not applicable |
| --- | --- | --- | --- | --- | --- | --- |
| Hyprland stack / session | 12 | 10 (PPA + Ubuntu) | — | 1 (share-picker) | 1 (quickshell) | — |
| Terminals, shell, CLI | 55 | 44 | 4 (herdr, cliamp, try, mise) | 3 (ttfx, tzupdate, nvim) | 2 | 5 (Arch tooling) |
| GUI | 20 | 12 | 4 (aether, localsend, obsidian, voxtype) | 3 (omacalc, omacut, omawrite) | 3 (Chrome, Signal, Spotify) | 2 (pinta → flatpak, moonlight) |
| System and hardware | 60 | already covered by Ubuntu | | | | 60 (ISO) |

Notable versions obtained: Hyprland 0.56.2, hyprland-guiutils 0.2.2, hyprsunset 0.4.0,
xdg-desktop-portal-hyprland 1.4.1, uwsm 0.25.2, xdg-terminal-exec 0.14.0 (Omarchy: 0.14.3; the options used,
`--app-id`, `--dir`, `--print-id`, `--title`, exist in 0.14.0), foot 1.25, neovim 0.11.6, Lua 5.5 (required by
Hyprland 0.56).

## 4. Keybindings

Omarchy defines its keybindings in `default/hypr/bindings/{applications,tiling,utilities,media,clipboard,
voxtype}.lua` through the helper `o.bind(keys, description, action)`. All of them are carried over. Users add
or replace in `~/.config/hypr/bindings.lua` (`o.bind`, `o.rebind`, `hl.unbind`). Overview:

| Family | Examples | Depends on |
| --- | --- | --- |
| Applications | SUPER+Enter terminal · SUPER+SHIFT+Enter browser · SUPER+SHIFT+F files · SUPER+SHIFT+N editor · SUPER+ALT+Enter tmux · SUPER+CTRL+Enter herdr | xdg-terminal-exec, uwsm-app, `omarchy-launch-*` |
| Web apps and preinstalls | SUPER+SHIFT+A ChatGPT · +E/+C HEY · +Y YouTube · +G Signal · +M Spotify · +O Obsidian · +W Omawrite · +/ 1Password | Chrome `--app`, installed apps; can be disabled with `omarchy_preinstalled_bindings = false` |
| Windows and tiling | SUPER+W/Q close · J split · T float · F/ALT+F/CTRL+F fullscreen · O pop · L scrolling layout · arrows focus/swap · code:20/21 resize · G groups · S/grave scratchpad | Hyprland dispatchers, `omarchy-hyprland-window-*` |
| Workspaces | SUPER+1..0 (keycodes) · SHIFT move · SHIFT+ALT move silently · Tab next · scroll wheel | Hyprland |
| Menu and panels | SUPER+Space menu · SUPER+ALT+Space apps · SUPER+Esc system · SUPER+K keybindings · SUPER+CTRL+A/B/W/D/P panels · SUPER+CTRL+1..9 | Quickshell shell |
| Capture | Print screenshot · ALT+Print recording · SUPER+Print color picker · SUPER+CTRL+Print OCR · SUPER+CTRL+C menu | grim, slurp, tensaku, gpu-screen-recorder, tesseract, hyprpicker |
| Universal clipboard | SUPER+C/X/V everywhere (Ctrl+Insert / Shift+Insert in a terminal) · SUPER+CTRL+V history | `hl.dsp.send_key_state`, shell |
| Notifications, reminders, notices | SUPER+, · SUPER+CTRL+R reminder · SUPER+CTRL+ALT+T/B/W time, battery, weather | shell |
| Toggles | SUPER+CTRL+N night light · +I idle · SUPER+SHIFT+Space bar · SUPER+Backspace transparency · SUPER+CTRL+Delete internal display | hyprsunset, `omarchy-toggle-*` |
| Media | XF86 volume/brightness/media keys, Shift for min/max, Alt for 1 % steps | `omarchy-audio-*`, `omarchy-brightness-*` (brightnessctl, ddcutil, wpctl) |
| Style | SUPER+CTRL+SHIFT+Space theme · SUPER+CTRL+Space background | shell |
| Lid | closing → internal display off when an external one is connected | `omarchy-system-lid-close`, `omarchy-hyprland-monitor-clamshell` |
| Dictation | hold F9 · SUPER+CTRL+X toggle | voxtype (script 25) |

Belgian AZERTY adaptation (keysym by keysym analysis, applied in `hypr/bindings.lua`):

- Digits and the `-`, `=`, `[`, `]` keys are bound by **keycode** (`code:10..21`, `code:34/35`): they work but
  land on `&é"'(§è!çà`, `)°`, `-_`, `^¨`, `$*`.
- `SUPER + grave` (scratchpad) is unreachable: `grave` needs AltGr. `SUPER + code:49` (the `²/³` key) is added.
  The `SUPER + S` alternative already exists.
- `SUPER + /` and `SUPER + ALT + /` (monitor scaling) need Shift: duplicated on `code:61` (the `:/` key).
- `SUPER + CTRL + .` (transcode) needs Shift: duplicated on `code:60` (the `;.` key).
- `SUPER + ,` (notifications) and `SUPER + SHIFT + /` (1Password) work as they are.
- The `be` layout is read by Omarchy from `/etc/vconsole.conf`, present on this Ubuntu; the kit sets it in
  `input.lua` anyway. CapsLock becomes the compose key (emoji, name, e-mail): Omarchy's choice, changeable
  through `kb_options`.
- Alt+Tab is Omarchy's: `ALT + Tab` cycles the windows of the active workspace, `SUPER + ALT + Tab` those of
  a group, `CTRL + ALT + Tab` the monitors. The previous Quickshell switcher is not carried over.

## 5. Themes

The mechanism (`omarchy-theme-set`, bash) is fully portable:

1. copy of `themes/<name>/` into `~/.local/state/omarchy/current/next-theme`, overlaid with
   `~/.config/omarchy/themes/<name>/`;
2. rendering of the `default/themed/*.tpl` templates from `colors.toml` (alacritty, foot, ghostty, kitty,
   btop, chromium, hyprland.lua, neovim.lua, vscode, obsidian, helix, shell.toml, claude.json…); user templates
   in `~/.config/omarchy/themed/` take priority (the kit uses that for foot);
3. atomic switch to `current/theme`, background choice, shell notification, `theme-set` hook, then parallel
   retint of the running applications (terminals, Hyprland, btop, browser, editors).

The 22 themes (17 dark, 5 light: Catppuccin Latte, Flexoki Light, Lupine, Rose Pine, White) ship with 2 to 9
backgrounds each and a matching Yaru icon set (Ubuntu ships `yaru-theme-icon` with every variant). Themed
applications that are not installed are simply ignored. Chrome receives the theme through an enterprise
policy (`omarchy-theme-set-browser`, sudo asked the first time).

## 6. Ubuntu friction points and answers

| Topic | On Arch | Kit answer |
| --- | --- | --- |
| Hyprland 0.56.2 + Lua 5.5 | omarchy package | cppiber PPA (0.56.2-1ppa2, resolute) + Ubuntu `lua5.5` |
| `/usr/share/omarchy` path | package | symlink to `~/omarchy` (git branch `ubuntu` on v4.0.3) |
| `/usr/bin/omarchy-*` | package | links in `/usr/local/bin` (`omarchy-ubuntu-link-bins`) |
| `/etc/skel` | `useradd -m` | script 40 copies `config/`, backs up the existing files |
| pacman / yay (35 scripts) | native | 28 overrides: apt + `pkgmap.txt` (Arch → apt) table, AUR refused cleanly |
| `omarchy update` / migrations | pacman + migrations | git merge of the new tag + `apt upgrade`; migrations disabled (marked done) |
| Snapper / Limine / Plymouth (22 scripts) | native | no-op; `omarchy-snapshot` already returns 127 without snapper |
| SDDM + theme | native | GDM kept, `omarchy.desktop` session added |
| Chromium | package | Google Chrome, `mimeapps.list` rewritten, `xdg-settings` |
| Lock-screen PAM | `omarchy-lock-password` includes `system-local-login` | `omarchy-apply-lock` override: `common-auth` / `common-account`, fingerprint kept |
| sudoers `%wheel` and regex rules | Arch | rewritten with `%sudo`, `/usr/local/bin`, and a wildcard (Ubuntu's sudo has no regex support) |
| systemd units `/usr/bin/omarchy-*` | package | copied into `~/.config/systemd/user` with the corrected path |
| hyprpolkitagent (enabled here) | absent | not installed; masked per user and globally: the Omarchy shell has its own polkit agent |
| `GDK_SCALE=2`, `natural_scroll=false` defaults | retina display | `monitors.lua` (scale 1, GDK 1), `input.lua` (natural_scroll true) |
| fd / bat renamed (`fdfind`, `batcat`) | — | links in `~/.local/bin` |
| `xdg-terminal-exec` 0.14.0 vs 0.14.3 | — | options used are present; watch it |
| Fonts (JetBrainsMono Nerd, iA Writer, omarchy.ttf) | packages | downloaded; `omarchy.ttf` installed system-wide with `50-omarchy.conf` |
| gpu-screen-recorder | package | built (meson) or flatpak (degraded stop detection) |
| Hyprland toggles (`toggles/hypr/`) | `/etc/skel` ships only `flags.lua` | script 40: `flags.lua` only; `window-no-gaps.lua` and `single-window-aspect-ratio.lua` are dropped in by their toggles, otherwise gaps and borders disappear |
| foot 1.26 (`[colors-dark]`) | package | Ubuntu has foot 1.25: script 31 rewrites `default/foot/screensaver.ini` and `default/themed/foot.ini.tpl` with `[colors]`; user template in `themed/` as a belt-and-braces |
| QML reserved word `transient` (Qt 6.10) | Arch Qt | `shell/plugins/notifications/Service.qml` patched by script 31 |
| Qt SVG image plugin | package | `qt6-svg-plugins` (panel icons) |
| PPA vs Ubuntu library names | — | `libhyprcursor1`/`libudis86.1` force-overwrite `libhyprcursor0`/`libudis86-0` (script 10) |
| Docker | docker package | docker-ce from the Docker repository kept; Ubuntu's docker.io skipped |

## 7. Chosen strategy and kit layout

See `README.md` for the order and durations. The choices:

- **The "dev channel", unspoken**: Omarchy foresees a git checkout replacing the package (`omarchy-dev-link`).
  The kit keeps `OMARCHY_PATH=/usr/share/omarchy` (symlink) so every hardcoded path stays true, and puts the
  overrides on an `ubuntu` branch: the next release is merged, the overrides are replayed (`31-overrides.sh`).
- **Nothing in `/usr/share` beyond the essentials**: fonts, fontconfig, session, uwsm env, xdg-terminal-exec,
  fcitx, fastfetch, kitty, two logind drop-ins, one sysctl, two sudoers files, the lock-screen PAM.
- **Everything else under `~/.local`** (binaries, applications, icons) and `~/.config`.
- **Your current Hyprland config is backed up**, not deleted: `backups/<timestamp>/`.

## 8. What stays different from a real Omarchy

- No snapshot before an update and no boot-time rollback.
- `omarchy update` does not follow the Arch mirror "one month behind": it is `apt upgrade`.
- The *Install > Package/AUR* and *Remove > Package* menus speak apt; *Install > …* entries naming Arch
  packages fail when `pkgmap.txt` has no mapping (explicit message).
- Ubuntu boot screen, GDM login screen, no themed "Unlock" at disk decryption.
- Docker without the ufw-docker hardening (option `--ufw` for the base policy).
- Tailscale, Dropbox, 1Password, gaming: to install by hand if wanted.
- The zsh shell is not Omarchy's bash: `60-zsh.sh` brings aliases and functions through `omarchy-zsh`.

## 9. Risks and unknowns

1. **Quickshell shell vs 0.3.1**: tested on 12 September, the shell starts and answers on Quickshell 0.3.1.
   One discrepancy found: Qt 6.10's QML parser reserves the word `transient`, used as a variable in
   `plugins/notifications/Service.qml`; `31-overrides.sh` renames the variable. The Qt SVG plugin
   (`qt6-svg-plugins`) is also required for the panel icons. For any new stubborn component:
   `journalctl --user -t omarchy-shell`.
2. **cppiber PPA**: hypr libraries in versions parallel to Ubuntu's (distinct sonames, normal coexistence).
   Check after script 10 that `Hyprland --version` shows 0.56.2 and that your current config still starts
   before going on.
3. **`./bin/build` of omacalc/omacut/omawrite**: qmake6 scripts; logs in `logs/` (all three built fine here).
4. **hyprland-preview-share-picker** needs Rust nightly; on failure the portal falls back to the standard
   picker (`hyprland-share-picker`, present).
5. **Chrome extensions** (Copy URL, Download Video): `omarchy-install-chromium-copy-url` knows how to write
   into `~/.config/google-chrome`; run it once with Chrome closed.
6. **Two Hyprlands in apt**: `apt upgrade` keeps the PPA version as long as the PPA is present;
   `ppa-purge` brings 0.53.3 back.
7. **Qt 6.10 font fallback bug (latent)**: any font pattern without a charset crashes every Qt 6.10 app on
   its first fallback glyph (§13). The web-font rule removes the only known source (Chrome ≥ 154's cache-12
   placeholders). Flatpak Qt apps do not read `/etc/fonts`, so keep `.woff`/`.woff2` files out of
   `~/.local/share/fonts`. Worth reporting: Qt (backport of 80ddc8dee6 to 6.10 / Ubuntu's qt6-base) and
   fontconfig (2.17 accepting another writer's cache-12 content through the version-9 name).

## 10. Checklist after the first Omarchy session

- `omarchy-shell shell ping` answers; the bar is visible; `SUPER + Space` opens the menu.
- `SUPER + K` lists the keybindings (reads `xkbcli`, package `libxkbcommon-tools`).
- `SUPER + CTRL + L` locks and the password unlocks (PAM `omarchy-lock-password`).
- `Print` takes a screenshot, the notification opens Tensaku.
- `SUPER + CTRL + N` tints the screen (hyprsunset 0.4 driven by `hyprctl hyprsunset`).
- `omarchy theme set "Catppuccin Latte"` retints terminal, Neovim, Chrome, shell.
- `omarchy version`, `omarchy update` (dry run), `omarchy debug`.
- Bluetooth and Wi-Fi from the panels (`SUPER + CTRL + B / W`).
- Closing the lid with the Acer connected: internal display off, back on when opened.
- Hold `F9` and speak: the dictation lands in the focused field (Voxtype, GPU Vulkan engine).
- `test/health.sh` passes (fonts, notification owner, first-run, greeter units, no shell crash since login).

## 11. References

- Repository: https://github.com/basecamp/omarchy (tag v4.0.3) · manual: `manual/` (mirror learn.omacom.io)
- Arch packages: https://github.com/omacom-io/omarchy-pkgs (`pkgbuilds/`), binary repository pkgs.omarchy.org
- Hyprland PPA for Ubuntu: https://launchpad.net/~cppiber/+archive/ubuntu/hyprland
- Tools: omacom-io/{omacalc,omacut,omawrite,ttfx,omarchy-zsh,omadots}, jondkinney/tensaku,
  herdrdev/herdr, bjarneo/cliamp, omacom/aether, tobi/try, WhySoBad/hyprland-preview-share-picker,
  repo.dec05eba.com/gpu-screen-recorder, cdown/tzupdate, LazyVim/starter, peteonrails/voxtype

## 12. Clean-container test of the one-shot installer (13 September 2026)

`test/docker-test.sh` runs `install.sh` as an unprivileged sudo user in a fresh `ubuntu:26.04` container.
First pass: all eleven steps completed in about six minutes (apt cache warm), with two silent build failures
that the second pass fixed:

| Finding | Cause | Fix |
| --- | --- | --- |
| `ttfx` and `tzupdate` builds failed | Ubuntu's `rustup` package installs `cargo`/`rustc` proxies but no toolchain, so `command -v cargo` lied | `rust_ready` helper: `rustup default stable` when `cargo --version` fails; stable pinned for those two crates, nightly only for the share picker |
| Quickshell modules reported missing | the danklinux PPA compiles the QML modules into the binary (no `qmldir` on disk) | preflight inspects the binary's strings instead of the filesystem |
| `unshare: Operation not permitted` during step 20 | Obsidian's post-install probes the Chrome sandbox inside the container | harmless, container only |
| no `XDG_RUNTIME_DIR` for `Hyprland --verify-config` | no session in the container | step 40 sets a private runtime dir and validates the Lua config anyway |

Steps that need a live session (user systemd units, gsettings, `hyprctl reload`, the shell restart) are
detected and skipped, and the unit enablement falls back to `wants/` symlinks picked up at first login.

## 13. Lessons from the actual installation (12–13 September 2026)

| Symptom | Cause | Fix (now in the kit) |
| --- | --- | --- |
| dpkg refused `libhyprcursor1` and `libudis86.1` | same files as Ubuntu's `libhyprcursor0` / `libudis86-0`, no `Replaces` | script 10 force-overwrites those two then runs `apt -f install` |
| script 11 stopped halfway | Ubuntu `docker.io`/`docker-compose-v2` conflict with docker-ce plugins; foot missing from the list | Docker packages only when no docker exists; foot and alacritty added |
| `visudo: regular expressions are not supported` | Ubuntu's sudo built without regex | wildcard rule for `timedatectl set-timezone` |
| notifications plugin failed to load | `transient` reserved by Qt 6.10 QML | variable renamed by script 31 |
| `claude.svg: Unsupported image format` | Qt SVG plugin missing | `qt6-svg-plugins` in script 11 |
| foot: `[colors-dark]: invalid section name` | foot 1.25 < 1.26 | user template with `[colors]` (`themed/`) |
| screensaver shows only repeated foot config errors | `default/foot/screensaver.ini` also uses `[colors-dark]` | script 31 patches `screensaver.ini` and `foot.ini.tpl` on the `ubuntu` branch |
| windows without gaps or borders | toggle files seeded by mistake | script 40 seeds `flags.lua` only |
| `voxtype: command not found` | optional Arch binary package | script 25: official .deb, model by locale, CPU/GPU choice |
| Obsidian 1.13.8 deb 404 | no Linux assets yet for that release | pinned to 1.13.7 |
| screensaver/tools: `ttfx: command not found` from Hyprland, no `OMARCHY_PATH`/`TERMINAL` in the session | Ubuntu's uwsm 0.25 ignores `env.d/` directories (only `uwsm/env`); Omarchy ships `/usr/share/uwsm/env.d/10-omarchy` | script 41 writes `/etc/xdg/uwsm/env` sourcing Omarchy's file and adding `~/.local/bin` to PATH; a pre-Omarchy `~/.config/uwsm/env` (GTK_THEME, cursor) is backed up by script 40 |
| "Failed unit detected: ydotoold.service" at every login | leftover user units from the previous desktop (swaync, ydotoold) fail and uwsm's `fumon` reports them | script 40 backs up user-written leftover units and **masks** packaged ones (swaync, mako, dunst, waybar, hypridle, hyprpaper, hyprsunset, ags…): a disabled unit still starts through D-Bus activation or a global enable |
| "Wayland diagnose" notification from Fcitx at login | Fcitx cannot push the layout to Hyprland (by design) | script 40 hides the notice in `fcitx5/conf/notifications.conf` and sets the Fcitx profile to the system layout |
| shell polkit agent: "An authentication agent already exists" | `hyprpolkitagent.service` is enabled globally by the PPA package; a user-scope disable does not stop it | script 40 masks it for the user; script 41 also disables and masks it globally (a user mask never reaches the GDM greeter, see below); script 10 no longer installs it |
| top bar gone | the `bar-off` toggle (SUPER + SHIFT + Space) was set | `omarchy-toggle-bar` (or *Trigger > Toggle > Menu Bar*) brings it back; not a kit issue |
| hyprmoncfg plugin inactive, "Install hyprmoncfg" failed | the plugin installs `hyprmoncfg-bin` from the AUR, which Ubuntu does not have | step 55 builds hyprmoncfg 1.18.3 from source (version stamped so the plugin's minimum-version check passes), installs the `hyprmoncfgd` user service and the plugin; `omarchy-pkg-aur-add` routes the panel's install button to the same build |
| `SUPER + CTRL + L` did nothing, and suspend warned "Screen did not lock before suspend" | the shell's lock service kept its derived `locked` flag true after an unlock, so the lock IPC answered `ok` without securing the session; every path (hotkey, idle, lid, pre-suspend) became a silent no-op until the shell was restarted | script 31 patches `shell/plugins/lock/Service.qml` so `lock()` and `isLocked()` read the Wayland session lock directly; the `omarchy-system-lock` override waits for the session to secure and restarts the shell once as a last resort |
| `ls` without icons in the terminal | the user shell is zsh; Omarchy's aliases (`eza --icons`) are bash-only unless `omarchy-zsh` is installed | `install.sh` runs `60-zsh.sh` automatically when `$SHELL` is zsh |
| Neovim: `monokai-pro.nvim` fails to clone | omarchy-nvim's `all-themes.lua` points at a deleted repository (`gthelding/…`) | step 21 rewrites it to the maintained `loctvl842/monokai-pro.nvim` |
| Quickshell SIGSEGV ×6 at login, then "Giving up on the Omarchy shell": no bar, no notifications (30 September 2026) | three defects in a chain. (1) Google Chrome ≥ 154 bundles fontconfig 2.18.3 (cache format 12, Fontations indexer); it writes `~/.cache/fontconfig/*-le64.cache-12` and symlinks the `-9/-10/-11` names to them. For `.woff`/`.woff2` files these caches hold placeholder patterns (file + `fontwrapper`, no family, no charset). (2) Ubuntu's fontconfig 2.17.1 accepts them for directories whose mtime has zero nanoseconds, and a pattern with nothing to mismatch wins every `FcFontMatch()` (here `VictorMono-Bold.woff` for any family). (3) Qt 6.10.2's `QFontEngineMultiFontConfig::shouldLoadFontEngineForCharacter()` ignores the failed `FcPatternGetCharSet()` and passes an uninitialised pointer (0xfefefefe, Qt's own `trivial_auto_var_init_pattern`) to `FcCharSetHasChar()`; the first fallback glyph (the audio icon U+EEE8) crashes. Qt fixed it upstream in 80ddc8dee6, not picked to 6.10 | `overrides/fontconfig/09-omarchy-reject-webfonts.conf`, installed by script 41, rejects WOFF/WOFF2 files and `fontwrapper` placeholders whichever cache they come from; script 41 also drops Chrome's compat links and rebuilds the user cache. A Chrome wrapper (dpkg-divert) is not enough: Playwright, Puppeteer and chrome-devtools-mcp run `/opt/google/chrome/chrome` directly |
| notifications shown by swaync (KoolDots style), or the shell logs "Could not register notification server" | swaync's D-Bus activation file starts it whenever `org.freedesktop.Notifications` is briefly unowned (login, shell restart, crash), and it keeps the name; disabling its unit does not stop activation | script 40 writes `~/.local/share/dbus-1/services/org.freedesktop.Notifications.service` with `Exec=/bin/false`: a user service file wins over every system one, so only the shell can take the name |
| "System program problem detected" (apport) at login; hyprpolkitagent crashed ×5 and hyprsunset failed ×5 per greeter start | the PPA enables hyprpolkitagent, hyprpaper and hyprsunset in `/etc/systemd/user`, which also applies to GDM's dynamic greeter users; the greeter crashes leave root-owned reports in `/var/crash` | script 41 disables them globally, masks hyprpolkitagent globally, adds `ConditionGroup=!gdm` drop-ins for fumon, foot-server (service and socket) and the ghostty unit, and, in case a package reinstall re-enables them globally, for hyprpolkitagent, hyprpaper, hyprsunset and hypridle; it also removes the stale greeter reports |
| "Learn Keybindings" / "Update System" at every login, `~/.XCompose` identity blanked, `~/.local/bin` mise wrappers rewritten | Omarchy 4 (since v4.0.0) enables `omarchy-migrate-notify.service` in first-run (`install/user/first-run/enable-user-units.sh`); the kit's hard-coded unit list never included it, so first-run failed and retried at every login from the first install, re-running `omarchy-provision-user` (which also aborted on `chromium.desktop`) | script 40 reads the unit list (services, paths, timers, sockets) from `enable-user-units.sh`, does the Ubuntu-safe parts of `omarchy-provision-user` itself (agent skills, hardware quirks, browser helpers, `~/Work` mise setup and a Node LTS only when the session has none, mise launchers that are never written over or in front of a native command; a global mise pin left by an earlier stub run still wins until `mise unuse -g <tool>`) and marks `finalize-user`, so the parts that would change GNOME (Desktop folder = `$HOME`, English bookmarks, the XPS 13 text scaling) never run; the `omarchy-migrate` stub answers `--pending` like upstream; script 31 makes the browser step non-fatal and falls back to the git identity for XCompose; script 41 installs the speaker-tuning LV2 limiter on laptops Omarchy ships a tuning for (otherwise that first-run step fails and loops too) |
| apport dialogs and the blueman / nm-tray tray icons in Omarchy | Ubuntu's `update-notifier-crash` path unit runs in every session, and uwsm starts every XDG autostart entry (blueman, nm-tray, update-notifier with its own `/var/crash` route) as `app-*@autostart.service` | script 40 adds `ConditionEnvironment=!XDG_CURRENT_DESKTOP=Hyprland` to `update-notifier-crash.service` (omarchy-crash-watch announces crashes instead) and masks the three autostart units, which only exist in uwsm sessions; pending apt upgrades and a pending reboot show as the bar's update icon (`omarchy-update-available`). GNOME is unchanged: it launches the same entries itself and keeps Ubuntu's crash dialogs (the per-user `show-apport-crashes` key is not touched) |
| a passwordless "Default_keyring" became GNOME's default keyring: new secrets (browser safe storage, git credentials…) stored unencrypted | earlier kits ran Omarchy's `default-keyring.sh`, written for SDDM autologin | script 40 no longer runs it. An existing Default_keyring is left as the default on purpose (Chrome and the Secret portal read their keys through the `default` alias; switching back to `login` would make what they encrypted since unreadable): script 40 and `test/health.sh` warn, and the fix is to give it a password in seahorse |
| the bar's update icon always shown | the Ubuntu `omarchy-update-available` override always exited 0 | it follows upstream's contract (exit 1 when nothing is pending) and also reports phased-aware apt upgrades and `/run/reboot-required` |
| hyprmoncfgd logging every few seconds in GNOME | upstream unit is `WantedBy=default.target` | the installer scopes it to `graphical-session.target` with `ConditionEnvironment=HYPRLAND_INSTANCE_SIGNATURE` |
