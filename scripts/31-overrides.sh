#!/bin/bash
# Step 31 — Replaces the Omarchy scripts tied to pacman/limine/snapper with apt or no-op versions, and
# patches the QML the Ubuntu Qt cannot parse, on the checkout's 'ubuntu' git branch (re-runnable after an update).
. "$(dirname "$0")/lib.sh"
[[ -d $OMARCHY_CHECKOUT/bin ]] || die "run 30-checkout.sh first"

say "Copying overrides into $OMARCHY_CHECKOUT/bin"
n=0
for f in "$KIT_DIR"/overrides/bin/*; do
  install -m755 "$f" "$OMARCHY_CHECKOUT/bin/$(basename "$f")"; n=$((n+1))
done
mkdir -p "$OMARCHY_CHECKOUT/ubuntu"
install -m644 "$KIT_DIR/overrides/pkgmap.txt" "$OMARCHY_CHECKOUT/ubuntu/pkgmap.txt"
ok "$n scripts + package name map"

say "QML fixes for Ubuntu's Qt 6.10"
# 'transient' is a reserved word for the Qt 6.10 QML parser: the notifications service refuses to load.
f="$OMARCHY_CHECKOUT/shell/plugins/notifications/Service.qml"
if grep -q 'var transient = false' "$f"; then
  sed -i -E 's/\bvar transient = false\b/var isTransient = false/; s/\btransient = !!\(/isTransient = !!(/; s/\{ transient = false \}/{ isTransient = false }/; s/return transient \|\|/return isTransient ||/' "$f"
  ok "notifications/Service.qml: 'transient' variable renamed"
else
  ok "notifications/Service.qml already fixed"
fi

say "foot 1.25 fixes (Ubuntu ships foot < 1.26)"
# foot 1.26 introduced [colors-dark]/[colors-light]; foot 1.25 rejects the section and the screensaver
# terminal shows the error instead of the animation.
for f in default/foot/screensaver.ini default/themed/foot.ini.tpl; do
  sed -i 's/^\[colors-dark\]/[colors]/' "$OMARCHY_CHECKOUT/$f"
done
ok "screensaver.ini and foot.ini.tpl use [colors]"

say "Lock service: act on the real session state"
# root.locked is a derived binding that has been seen stuck at true after an unlock; the lock IPC then
# answered "ok" without securing anything, so the hotkey, the idle timer and the pre-suspend hook all
# became silent no-ops. Decide on the Wayland session state instead.
f="$OMARCHY_CHECKOUT/shell/plugins/lock/Service.qml"
if grep -q 'if (!root.locked && !root.beginLock())' "$f"; then
  sed -i \
    -e 's|if (!root.locked \&\& !root.beginLock())|if (!sessionLock.secure \&\& !sessionLock.locked \&\& !root.beginLock())|' \
    -e 's|return root.locked ? "true" : "false"|return (sessionLock.secure \|\| sessionLock.locked \|\| root.lockRequested) ? "true" : "false"|' \
    "$f"
  ok "lock/Service.qml: lock() and isLocked() read the session lock directly"
else
  ok "lock/Service.qml already fixed"
fi

say "Commit on the ubuntu branch"
git -C "$OMARCHY_CHECKOUT" add -A
git -C "$OMARCHY_CHECKOUT" -c user.name=omarchy-ubuntu -c user.email=kit@localhost commit -qm "Ubuntu overrides (omarchy-ubuntu kit)" || info "nothing to commit"
link_bins
ok "done"
