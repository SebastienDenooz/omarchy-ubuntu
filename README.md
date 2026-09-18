# Omarchy 4.0.3 on Ubuntu 26.04 — installation kit

This folder reproduces the Omarchy configuration (Hyprland, Quickshell shell, themes, keybindings,
tools) on this ThinkPad P14s running Ubuntu 26.04. Each script is run by you, in order, after reading
it. The full analysis is in `REPORT.md`, the package-by-package detail in `MATRIX.md`.

## Principle

- The `basecamp/omarchy` repository (tag v4.0.3) is cloned into `~/omarchy` and exposed as
  `/usr/share/omarchy`, the path hardcoded across Omarchy. Its 444 `omarchy-*` commands are linked
  into `/usr/local/bin`.
- The scripts tied to pacman, Limine, Snapper and Plymouth are replaced by apt or no-op versions
  (`overrides/bin`), plus one QML fix, on a git branch `ubuntu` of the checkout: an Omarchy update is
  a merge of the new tag.
- Hyprland 0.56.2 and the whole hypr ecosystem come from the `cppiber/hyprland` PPA, which publishes
  for 26.04. The already-present Quickshell 0.3.1 is sufficient.
- Omarchy's own tools (omacalc, omacut, omawrite, tensaku, herdr, ttfx, cliamp, aether…) are installed
  from their official binaries or built under `~/.local`.
- Your current Hyprland config is backed up into `backups/`; `90-rollback.sh` restores it.

## One-shot install (fresh Ubuntu 26.04)

```
git clone <this kit> ~/omarchy-ubuntu && cd ~/omarchy-ubuntu
./install.sh                      # asks for sudo once; ~1 h 30 including builds
./install.sh --with-voxtype --with-pinta --ufw   # optional extras (--no-zsh to keep your own zsh config)
```

`install.sh` runs the steps below in order, logs to `logs/install-<timestamp>.log`, and remembers completed
steps in `logs/done/`: re-run it after fixing a failure and it resumes. `--from=30`, `--only=21` and
`--reset` are available. Step 21 (builds) fails when any build fails; retry just those with
`ONLY="ttfx tzupdate" ./install.sh --only=21`. Then log out and pick the "Omarchy (Hyprland uwsm)" session.

The installer is tested in a clean container with `test/docker-test.sh` (see "Testing").

## Execution order (step by step)

| Step | Script | sudo | Time | Purpose |
| --- | --- | --- | --- | --- |
| 0 | `scripts/00-preflight.sh` | no | 10 s | Machine state, nothing is changed |
| 1 | `scripts/10-ppa-hyprland.sh` | yes | 3 min | PPAs (cppiber/hyprland, avengemedia/danklinux) + Hyprland 0.56.2, hyprsunset, portal, uwsm, Quickshell |
| 2 | `scripts/11-apt.sh` | yes | 10 min | ~145 apt packages (tools, GUI, build dependencies) |
| 2b | `scripts/15-chrome.sh` | yes | 1 min | Google Chrome (skipped when present; `--skip` to opt out) |
| — | log out / log in (optional) | | | validates Hyprland 0.56 with your current config |
| 3 | `scripts/20-prebuilt.sh` | yes (deb) | 5 min | aether, localsend, obsidian, tensaku, herdr, cliamp, try, mise, fonts |
| 4 | `scripts/21-build.sh` | no | 20-40 min | omacalc/omacut/omawrite, ttfx, tzupdate, share picker, gpu-screen-recorder, Neovim LazyVim |
| 5 | `scripts/30-checkout.sh` | yes | 1 min | clone v4.0.3, `/usr/share/omarchy`, `/etc/omarchy.conf`, command links |
| 6 | `scripts/31-overrides.sh` | yes | 10 s | Ubuntu overrides + QML fix, committed on the `ubuntu` branch |
| 7 | `scripts/41-system.sh` | yes | 30 s | GDM session, uwsm, fonts, fcitx, systemd drop-ins, sudoers, lock-screen PAM |
| 8 | `scripts/40-user-configs.sh` | no | 30 s | Omarchy `~/.config`, AZERTY/monitor overrides, foot template, user services |
| 9 | `scripts/50-theme.sh` | no | 10 s | Tokyo Night theme and themed files |
| 9a | `scripts/55-hyprmoncfg.sh` | no | 2 min | hyprmoncfg multi-monitor manager: source build (`hyprmoncfg`, `hyprmoncfgd` daemon) and the Omarchy bar plugin `crmne.hyprmoncfg` (`--no-hyprmoncfg` to skip) |
| 9b | `scripts/25-voxtype.sh` (optional) | yes | 5 min | Voxtype AI dictation: official .deb, model by locale, CPU/GPU choice (or `--gpu`/`--cpu`), service |
| 10 | `scripts/60-zsh.sh` (automatic for zsh users) | no | 30 s | Omarchy aliases and functions for zsh (`ls` with eza icons, `lt`, `n`, `tdl`…), Starship prompt |
| — | log out → session "Omarchy (Hyprland uwsm)" | | | |

Options: `41-system.sh --ufw --docker` (Omarchy-style firewall and Docker), `20-prebuilt.sh --with-pinta`.
When a script needs sudo and you drive it from Claude Code, run it with the `!` prefix.

## Testing

```
test/docker-test.sh            # fresh ubuntu:26.04 container, unprivileged sudo user, full ./install.sh
test/docker-test.sh --resume   # re-run in the same container (completed steps skipped)
test/docker-test.sh --shell    # inspect
test/docker-test.sh --rm       # clean up
```

Inside a container the scripts detect the missing session and skip what needs one (systemd user units are
enabled through `wants/` symlinks instead, no `hyprctl reload`, no `gsettings`). Everything else, from the
PPAs to the theme rendering, runs for real.

## After the installation

- `SUPER + Space` opens the Omarchy menu, `SUPER + K` lists the keybindings.
- `omarchy` in a terminal gives the full CLI; `omarchy update` merges the next release and runs
  `apt upgrade`.
- Your files: `~/.config/hypr/{monitors,input,bindings,looknfeel,autostart}.lua`,
  `~/.config/omarchy/shell.json`. The defaults live in `/usr/share/omarchy/default`, do not edit them.
- Rollback: `scripts/90-rollback.sh` (add `--purge-ppa` to go back to Hyprland 0.53.3).

## Lessons learned while installing (already handled by the scripts)

- PPA packages `libhyprcursor1` and `libudis86.1` clash with Ubuntu's `libhyprcursor0` / `libudis86-0`
  (same files, no `Replaces`): script 10 force-overwrites those two.
- Ubuntu's sudo has no regex rules: the timezone sudoers uses a wildcard.
- Ubuntu's Docker packages conflict with docker-ce plugins: script 11 skips them when docker exists.
- Qt 6.10's QML parser reserves `transient`: the notifications service is patched by script 31.
- `qt6-svg-plugins` is required for the panel icons.
- foot 1.25 lacks `[colors-dark]`: script 31 patches the screensaver config and the theme template, plus a user template in `themed/`.
- Only `flags.lua` may be seeded in `~/.local/state/omarchy/toggles/hypr/`, otherwise gaps and borders vanish.
- Ubuntu's `rustup` package ships no toolchain: the scripts run `rustup default stable` when `cargo` is unusable.
- The PPA Quickshell embeds its QML modules in the binary; the preflight checks the binary, not the filesystem.
- The hyprmoncfg plugin installs its backend from the AUR; on Ubuntu the kit builds it from source, and its "Install hyprmoncfg" button is routed to that build through the `omarchy-pkg-aur-add` override.
- The shell's lock IPC can get stuck reporting the session as locked after an unlock, which silently disables locking; step 31 patches the lock service and `omarchy-system-lock` verifies the session really secured.
- Omarchy's shell aliases live in bash by default; zsh users need `60-zsh.sh` (now automatic) or `ls` shows no icons.
- `hyprpolkitagent.service` must be masked (globally enabled by the PPA), or the Omarchy shell's own polkit agent cannot register.
- Leftover user units of a previous desktop (swaync, ydotoold…) are disabled, otherwise uwsm's fumon reports them at login; Fcitx's "Wayland diagnose" notice is hidden.
- Ubuntu's uwsm reads `uwsm/env`, not `env.d/`: script 41 installs `/etc/xdg/uwsm/env` (Omarchy env + `~/.local/bin` in PATH).

## Contents

```
README.md            this file
REPORT.md            full feasibility analysis
MATRIX.md            the 150 Omarchy packages and their Ubuntu equivalent
install.sh           one-shot, resumable installer
scripts/             steps 00 → 90 (+ shared lib.sh)
test/docker-test.sh  clean-container test of install.sh
overrides/bin/       28 omarchy-* scripts rewritten for apt / no-op, plus the Ubuntu lock-screen PAM
overrides/pkgmap.txt Arch → apt package name map
hypr/                monitors, input, bindings (AZERTY fixes), looknfeel, autostart for this machine
themed/              theme templates adapted to Ubuntu (foot 1.25)
dl/ build/ logs/     downloads, builds, logs (created on use)
backups/             your replaced configs, timestamped
```
