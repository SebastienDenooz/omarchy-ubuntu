#!/bin/bash
# Étape 30 — Dépôt Omarchy v4.0.3 dans ~/omarchy, exposé comme /usr/share/omarchy (chemin attendu partout).
. "$(dirname "$0")/lib.sh"
need git sudo

say "Clonage de basecamp/omarchy ($OMARCHY_TAG)"
if [[ -d $OMARCHY_CHECKOUT/.git ]]; then
  ok "déjà cloné : $OMARCHY_CHECKOUT"
else
  git clone https://github.com/basecamp/omarchy.git "$OMARCHY_CHECKOUT"
fi
git -C "$OMARCHY_CHECKOUT" fetch --tags origin
if git -C "$OMARCHY_CHECKOUT" rev-parse --verify -q ubuntu >/dev/null; then
  ok "branche 'ubuntu' existante conservée ($(git -C "$OMARCHY_CHECKOUT" describe --tags --always))"
else
  git -C "$OMARCHY_CHECKOUT" checkout -b ubuntu "$OMARCHY_TAG"
  ok "branche 'ubuntu' créée depuis $OMARCHY_TAG"
fi

say "Exposition système"
sudo ln -sfn "$OMARCHY_CHECKOUT" "$OMARCHY_SYS";                       ok "$OMARCHY_SYS → $OMARCHY_CHECKOUT"
printf 'export OMARCHY_PATH="%s"\n' "$OMARCHY_SYS" | sudo tee /etc/omarchy.conf >/dev/null; ok "/etc/omarchy.conf"
sudo install -m644 "$OMARCHY_CHECKOUT/etc/profile.d/omarchy.sh" /etc/profile.d/omarchy.sh; ok "/etc/profile.d/omarchy.sh"
link_bins
info "Suite : ./31-overrides.sh (adaptations Ubuntu), puis 41 (système) et 40 (configs utilisateur)."
