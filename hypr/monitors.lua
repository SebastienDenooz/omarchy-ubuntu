-- Écrans de ce ThinkPad P14s Gen 5 (kit omarchy-ubuntu). Voir : hyprctl monitors all
-- Omarchy suppose un écran « retina » (scale 2) ; ici 1920x1200 14" et 2560x1440 32" → scale 1.
local omarchy_monitor_scale = 1

hl.monitor({ output = "eDP-1",    mode = "1920x1200@60",  position = "0x0",    scale = omarchy_monitor_scale })
hl.monitor({ output = "HDMI-A-1", mode = "2560x1440@144", position = "1920x0", scale = omarchy_monitor_scale })
hl.monitor({ output = "",         mode = "preferred",     position = "auto",   scale = "auto" })

-- Workspaces par écran (comme avant la migration).
hl.workspace_rule({ workspace = "1", monitor = "eDP-1" })
hl.workspace_rule({ workspace = "2", monitor = "HDMI-A-1" })
hl.workspace_rule({ workspace = "3", monitor = "HDMI-A-1" })

-- GTK ne connaît que des entiers ; 1 à scale 1 (Omarchy met 2 par défaut).
local omarchy_gdk_scale = 1
hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))
