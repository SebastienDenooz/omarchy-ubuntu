-- Raccourcis personnels et corrections AZERTY (kit omarchy-ubuntu).
-- Les défauts Omarchy restent actifs (voir « omarchy menu keybindings » / SUPER + K).
-- Pour les couper tous : omarchy_default_bindings = false dans hyprland.lua avant require("default.hypr.omarchy").

-- === Corrections pour le clavier belge ==========================================
-- Omarchy lie des keysyms US. En AZERTY belge, `, / et . demandent AltGr ou Shift :
-- les combinaisons SUPER + grave, SUPER + /, SUPER + CTRL + . sont donc injoignables.
-- On les double sur des keycodes physiques (indépendants de la disposition).

-- Scratchpad (SUPER + grave)  → touche ²/³ à gauche du 1 (code:49)
o.bind("SUPER + code:49",         "Toggle scratchpad",           hl.dsp.workspace.toggle_special("scratchpad"))
o.bind("SUPER + SHIFT + code:49", "Move window to scratchpad",   hl.dsp.window.move({ workspace = "special:scratchpad", follow = false }))

-- Échelle d'écran (SUPER + / et SUPER + ALT + /) → touche :/ (code:61)
o.bind("SUPER + code:61",         "Monitor scaling up",          "omarchy-hyprland-monitor-scaling up")
o.bind("SUPER + ALT + code:61",   "Monitor scaling down",        "omarchy-hyprland-monitor-scaling down")

-- Transcodage (SUPER + CTRL + .) → touche ;. (code:60)
o.bind("SUPER + CTRL + code:60",  "Transcode",                   "omarchy-transcode")

-- Rappel : SUPER + code:20/21 (« - » et « = » en US) tombent ici sur les touches )° et -_ ;
-- SUPER + ALT + code:34/35 (webcam) sur ^¨ et $* ; les workspaces (code:10-19) sont déjà corrects.

-- === Alt+Tab ======================================================================
-- Le comportement Omarchy est conservé : ALT + Tab / ALT + SHIFT + Tab cyclent les fenêtres
-- du workspace actif (hl.dsp.window.cycle_next) ; SUPER + ALT + Tab cycle dans un groupe ;
-- CTRL + ALT + Tab change d'écran. Rien à ajouter ici.

-- === Exemples de personnalisation ==================================================
-- o.rebind("SUPER + SHIFT + O", "Joplin", "joplin-desktop")          -- remplacer un défaut
-- hl.unbind("SUPER + SHIFT + E")                                     -- retirer un défaut (HEY Email)
-- o.bind("SUPER + SHIFT + Z", "Zed", { launch = "zed" })             -- ajouter une appli
