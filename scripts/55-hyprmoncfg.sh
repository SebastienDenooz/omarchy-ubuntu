#!/bin/bash
# Step 55 — hyprmoncfg multi-monitor manager: backend built from source (https://hyprmoncfg.dev/getting-started/)
# and the Omarchy bar plugin "hyprmoncfg: Multi-Monitor Manager for Omarchy" (crmne.hyprmoncfg).
# Run after 40 and 50 (Omarchy configs and shell in place). Option: --skip
. "$(dirname "$0")/lib.sh"
[[ " $* " == *" --skip "* ]] && { skip "hyprmoncfg (--skip)"; exit 0; }
omarchy_env
need git go jq

PLUGIN_ID=crmne.hyprmoncfg
PLUGIN_URL=https://github.com/crmne/omarchy-hyprmoncfg.git
PLUGIN_DIR="$HOME/.config/omarchy/plugins/$PLUGIN_ID"
installer="$OMARCHY_SYS/bin/omarchy-ubuntu-install-hyprmoncfg"
[[ -x $installer ]] || installer="$KIT_DIR/overrides/bin/omarchy-ubuntu-install-hyprmoncfg"

say "hyprmoncfg + hyprmoncfgd (source build)"
"$installer"
ok "$(hyprmoncfg version 2>/dev/null | head -1)"

say "Omarchy plugin $PLUGIN_ID"
shell_up=0
omarchy-shell -q shell ping >/dev/null 2>&1 && omarchy-shell shell ping >/dev/null 2>&1 && shell_up=1
if [[ -d $PLUGIN_DIR/.git ]]; then
  ok "already added ($(jq -r .version "$PLUGIN_DIR/manifest.json"))"
elif (( shell_up )); then
  omarchy-plugin-add "$PLUGIN_URL" --yes --enable
  ok "added and enabled"
else
  # No running shell (fresh install, container): omarchy-plugin-add needs the shell's IPC, so do what it
  # does by hand — clone, validate — and register the bar widget in shell.json for the first login.
  mkdir -p "$(dirname "$PLUGIN_DIR")"
  git clone --quiet "$PLUGIN_URL" "$PLUGIN_DIR"
  if ! omarchy-plugin-validate "$PLUGIN_DIR" >/dev/null; then rm -rf "$PLUGIN_DIR"; die "plugin validation failed"; fi
  ok "cloned and validated ($(jq -r .version "$PLUGIN_DIR/manifest.json"))"
fi

# Make sure the widget sits in the bar (next to the tray, where the plugin places itself by default).
cfg="$HOME/.config/omarchy/shell.json"
[[ -f $cfg ]] || cp "$OMARCHY_SYS/config/omarchy/shell.json" "$cfg"
if jq -e --arg id "$PLUGIN_ID" '[.bar.layout[][]?.id] | index($id)' "$cfg" >/dev/null; then
  ok "bar widget present in shell.json"
elif (( shell_up )); then
  omarchy-plugin-enable "$PLUGIN_ID" --section right && ok "bar widget enabled"
else
  tmp=$(mktemp)
  jq --arg id "$PLUGIN_ID" '
    .bar.layout.right |= (
      (map(.id) | index("omarchy.tray")) as $i
      | if $i == null then [{id: $id}] + . else .[:$i+1] + [{id: $id}] + .[$i+1:] end
    )' "$cfg" > "$tmp" && mv "$tmp" "$cfg"
  ok "bar widget registered in shell.json (after the tray)"
fi

say "Hyprland integration"
if has_hyprland; then
  report=$(hyprmoncfg doctor 2>&1 || true)
  if grep -q 'hyprmoncfg-monitors.* does not exist' <<<"$report" && [[ $(grep -c 'PROBLEM' <<<"$report") -le 1 ]]; then
    ok "hyprmoncfg doctor: no profile saved yet (expected on a fresh install)"
  else
    sed 's/^/    /' <<<"$report" | head -20
  fi
  omarchy-shell -q shell rescanPlugins >/dev/null 2>&1 || true
else
  skip "hyprmoncfg doctor (no Hyprland session): the daemon wires hyprmoncfg-monitors.lua into hyprland.lua on first apply"
fi
info "Open the bar widget, arrange your displays and save a profile; hyprmoncfgd applies it on hotplug, lid and resume."
info "Terminal UI: hyprmoncfg  ·  re-run this step after re-running 40 (it resets hyprland.lua)."
