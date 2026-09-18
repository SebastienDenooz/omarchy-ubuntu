-- Monitors of this ThinkPad P14s Gen 5 (omarchy-ubuntu kit). See: hyprctl monitors all
-- Omarchy assumes a retina-class display (scale 2); here 1920x1200 14" and 2560x1440 32" → scale 1.
local omarchy_monitor_scale = 1

hl.monitor({ output = "eDP-1",    mode = "1920x1200@60",  position = "0x0",    scale = omarchy_monitor_scale })
hl.monitor({ output = "HDMI-A-1", mode = "2560x1440@144", position = "1920x0", scale = omarchy_monitor_scale })
hl.monitor({ output = "",         mode = "preferred",     position = "auto",   scale = "auto" })

-- Workspaces per monitor (as before the migration).
hl.workspace_rule({ workspace = "1", monitor = "eDP-1" })
hl.workspace_rule({ workspace = "2", monitor = "HDMI-A-1" })
hl.workspace_rule({ workspace = "3", monitor = "HDMI-A-1" })

-- GTK only honors integers; 1 at scale 1 (Omarchy defaults to 2).
local omarchy_gdk_scale = 1
hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))
