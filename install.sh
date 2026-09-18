#!/bin/bash
# Omarchy on Ubuntu 26.04 LTS or later — one-shot installer. Runs the kit steps in order, resumable.
#
#   ./install.sh                 full install (asks for sudo when needed)
#   ./install.sh --with-voxtype --with-pinta      (zsh users get step 60 automatically; --no-zsh to skip)
#   ./install.sh --no-hyprmoncfg                  skip the multi-monitor manager (step 55)
#   ./install.sh --from 30       resume at step 30 (completed steps are also skipped automatically)
#   ./install.sh --only 21       run a single step
#   ./install.sh --defaults      never ask, take every default
#   ./install.sh --reset         forget completed steps and remembered answers
#
# Each step logs to logs/install-<timestamp>.log and marks logs/done/<step> on success.
set -euo pipefail
KIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$KIT_DIR"
mkdir -p logs/done
LOG="logs/install-$(date +%Y%m%d-%H%M%S).log"

STEPS=(00-preflight 10-ppa-hyprland 11-apt 15-chrome 20-prebuilt 21-build 30-checkout 31-overrides 41-system 40-user-configs 50-theme 55-hyprmoncfg)
from=""; only=""; extra_args=()
with_voxtype=0; with_zsh=0; no_zsh=0; no_hyprmoncfg=0
for a in "$@"; do
  case $a in
    --from=*) from=${a#*=} ;;
    --only=*) only=${a#*=} ;;
    --with-voxtype) with_voxtype=1 ;;
    --with-zsh) with_zsh=1 ;;
    --no-zsh) no_zsh=1 ;;
    --no-hyprmoncfg) no_hyprmoncfg=1 ;;
    --with-pinta) extra_args+=(--with-pinta) ;;
    --ufw|--docker) extra_args+=("$a") ;;
    --gpu|--cpu) extra_args+=("$a") ;;
    --defaults) export KIT_DEFAULTS=1 ;;
    --reset) rm -f logs/done/* logs/answers.env; echo "completed-step markers and remembered answers cleared" ;;
    -h|--help) sed -n '2,13p' "$0"; exit 0 ;;
    *) echo "unknown option: $a" >&2; exit 2 ;;
  esac
done
if (( no_hyprmoncfg )); then
  kept=(); for s in "${STEPS[@]}"; do [[ $s == 55-hyprmoncfg ]] || kept+=("$s"); done; STEPS=("${kept[@]}")
fi
(( with_voxtype )) && STEPS+=(25-voxtype)
# zsh users get Omarchy's aliases/functions (eza icons for ls, tdl, n…) automatically; --no-zsh opts out.
[[ ${SHELL##*/} == zsh && $no_zsh -eq 0 ]] && with_zsh=1
(( with_zsh )) && STEPS+=(60-zsh)

step_args() { # options forwarded to a given step
  local s=$1 out=()
  for a in "${extra_args[@]}"; do
    case "$s:$a" in
      20-prebuilt:--with-pinta|41-system:--ufw|41-system:--docker|25-voxtype:--gpu|25-voxtype:--cpu) out+=("$a") ;;
    esac
  done
  printf '%s\n' "${out[@]}"
}

# Steps are piped into tee, so their stdout is not a terminal: tell them a user is watching, and they
# will ask their questions on /dev/tty. Answers are remembered in logs/answers.env.
[[ -t 0 && -t 1 ]] && export KIT_INTERACTIVE=1

echo "Omarchy on Ubuntu — installer · log: $LOG"
[[ $EUID -eq 0 ]] && { echo "Run as your normal user (sudo is requested when needed)." >&2; exit 1; }
sudo -v 2>/dev/null || true   # ask for the password once, up front

started=0; failed=""
for s in "${STEPS[@]}"; do
  n=${s%%-*}
  if [[ -n $only ]]; then [[ $n == "$only" ]] || continue; fi
  if [[ -n $from && $started -eq 0 ]]; then [[ $n == "$from" ]] && started=1 || continue; fi
  if [[ -z $only && -f logs/done/$s ]]; then printf '\033[1;35m↷ %s already done\033[0m\n' "$s"; continue; fi
  mapfile -t args < <(step_args "$s")
  printf '\n\033[1;36m######## %s ########\033[0m\n' "$s" | tee -a "$LOG"
  if bash "scripts/$s.sh" "${args[@]}" 2>&1 | tee -a "$LOG"; then
    touch "logs/done/$s"
  else
    failed=$s; break
  fi
done

echo
if [[ -n $failed ]]; then
  printf '\033[1;31mStep %s failed. Fix the cause, then re-run ./install.sh (completed steps are skipped).\033[0m\n' "$failed"
  exit 1
fi
printf '\033[1;32mAll steps done.\033[0m\n'
if [[ -f /.dockerenv || ! -d /run/systemd/system ]]; then
  echo "Container run: session-dependent steps were skipped (services, gsettings, Hyprland reload)."
else
  echo "Log out and pick the \"Omarchy (Hyprland uwsm)\" session in GDM. Then: SUPER + Space (menu), SUPER + K (keys)."
fi
