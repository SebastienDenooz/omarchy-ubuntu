-- Personal bindings and AZERTY fixes (omarchy-ubuntu kit).
-- The Omarchy defaults stay active (see "omarchy menu keybindings" / SUPER + K).
-- To drop them all: omarchy_default_bindings = false in hyprland.lua before require("default.hypr.omarchy").

-- === Belgian keyboard fixes ======================================================
-- Omarchy binds US keysyms. On Belgian AZERTY, `, / and . need AltGr or Shift, so
-- SUPER + grave, SUPER + / and SUPER + CTRL + . are unreachable. Duplicate them on
-- physical keycodes (independent of the layout).

-- Scratchpad (SUPER + grave)  → the ²/³ key left of 1 (code:49)
o.bind("SUPER + code:49",         "Toggle scratchpad",           hl.dsp.workspace.toggle_special("scratchpad"))
o.bind("SUPER + SHIFT + code:49", "Move window to scratchpad",   hl.dsp.window.move({ workspace = "special:scratchpad", follow = false }))

-- Monitor scaling (SUPER + / and SUPER + ALT + /) → the :/ key (code:61)
o.bind("SUPER + code:61",         "Monitor scaling up",          "omarchy-hyprland-monitor-scaling up")
o.bind("SUPER + ALT + code:61",   "Monitor scaling down",        "omarchy-hyprland-monitor-scaling down")

-- Transcode (SUPER + CTRL + .) → the ;. key (code:60)
o.bind("SUPER + CTRL + code:60",  "Transcode",                   "omarchy-transcode")

-- Note: SUPER + code:20/21 ("-" and "=" on US) land on the )° and -_ keys here;
-- SUPER + ALT + code:34/35 (webcam) on ^¨ and $*; workspaces (code:10-19) are already right.

-- === Alt+Tab ======================================================================
-- Omarchy behaviour is kept: ALT + Tab / ALT + SHIFT + Tab cycle the windows of the active
-- workspace (hl.dsp.window.cycle_next); SUPER + ALT + Tab cycles within a group;
-- CTRL + ALT + Tab switches monitors. Nothing to add here.

-- === Customization examples =======================================================
-- o.rebind("SUPER + SHIFT + O", "Joplin", "joplin-desktop")          -- replace a default
-- hl.unbind("SUPER + SHIFT + E")                                     -- remove a default (HEY Email)
-- o.bind("SUPER + SHIFT + Z", "Zed", { launch = "zed" })             -- add an application
