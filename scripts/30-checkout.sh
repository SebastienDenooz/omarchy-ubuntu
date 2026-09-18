#!/bin/bash
# Step 30 — Omarchy v4.0.3 checkout in ~/omarchy, exposed as /usr/share/omarchy (the path expected everywhere).
. "$(dirname "$0")/lib.sh"
need git sudo

say "Cloning basecamp/omarchy ($OMARCHY_TAG)"
if [[ -d $OMARCHY_CHECKOUT/.git ]]; then
  ok "already cloned: $OMARCHY_CHECKOUT"
else
  git clone https://github.com/basecamp/omarchy.git "$OMARCHY_CHECKOUT"
fi
git -C "$OMARCHY_CHECKOUT" fetch --tags origin
if git -C "$OMARCHY_CHECKOUT" rev-parse --verify -q ubuntu >/dev/null; then
  ok "existing 'ubuntu' branch kept ($(git -C "$OMARCHY_CHECKOUT" describe --tags --always))"
else
  git -C "$OMARCHY_CHECKOUT" checkout -b ubuntu "$OMARCHY_TAG"
  ok "'ubuntu' branch created from $OMARCHY_TAG"
fi

say "System exposure"
sudo ln -sfn "$OMARCHY_CHECKOUT" "$OMARCHY_SYS";                       ok "$OMARCHY_SYS → $OMARCHY_CHECKOUT"
printf 'export OMARCHY_PATH="%s"\n' "$OMARCHY_SYS" | sudo tee /etc/omarchy.conf >/dev/null; ok "/etc/omarchy.conf"
sudo install -m644 "$OMARCHY_CHECKOUT/etc/profile.d/omarchy.sh" /etc/profile.d/omarchy.sh; ok "/etc/profile.d/omarchy.sh"
link_bins
info "Next: ./31-overrides.sh (Ubuntu adaptations), then 41 (system) and 40 (user configs)."
