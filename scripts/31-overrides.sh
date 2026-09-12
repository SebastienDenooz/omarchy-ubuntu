#!/bin/bash
# Étape 31 — Remplace les scripts Omarchy liés à pacman/limine/snapper par des versions apt/no-op,
# sur la branche git 'ubuntu' du dépôt (rejouable après une mise à jour d'Omarchy).
. "$(dirname "$0")/lib.sh"
[[ -d $OMARCHY_CHECKOUT/bin ]] || die "lance d'abord 30-checkout.sh"

say "Copie des surcharges dans $OMARCHY_CHECKOUT/bin"
n=0
for f in "$KIT_DIR"/overrides/bin/*; do
  install -m755 "$f" "$OMARCHY_CHECKOUT/bin/$(basename "$f")"; n=$((n+1))
done
mkdir -p "$OMARCHY_CHECKOUT/ubuntu"
install -m644 "$KIT_DIR/overrides/pkgmap.txt" "$OMARCHY_CHECKOUT/ubuntu/pkgmap.txt"
ok "$n scripts + table de correspondance des paquets"

say "Commit sur la branche ubuntu"
git -C "$OMARCHY_CHECKOUT" add -A
git -C "$OMARCHY_CHECKOUT" -c user.name=omarchy-ubuntu -c user.email=kit@localhost commit -qm "Ubuntu overrides (kit omarchy-ubuntu)" || info "rien à committer"
link_bins
ok "terminé"
