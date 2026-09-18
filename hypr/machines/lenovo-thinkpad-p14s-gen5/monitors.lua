-- ThinkPad P14s Gen 5 AMD: built-in 1920x1200 14" panel, Acer XV322QU P 32" on HDMI.
-- Applied by step 40 only on this machine (see the "match" file next to this one).
-- For layouts that follow the monitors you plug in, prefer hyprmoncfg (step 55) over this file.
local scale = 1   -- neither panel is retina-class, so Omarchy's default scale of 2 is too much

hl.monitor({ output = "eDP-1",    mode = "1920x1200@60",  position = "0x0",    scale = scale })
hl.monitor({ output = "HDMI-A-1", mode = "2560x1440@144", position = "1920x0", scale = scale })
hl.monitor({ output = "",         mode = "preferred",     position = "auto",   scale = "auto" })

-- Workspaces per monitor.
hl.workspace_rule({ workspace = "1", monitor = "eDP-1" })
hl.workspace_rule({ workspace = "2", monitor = "HDMI-A-1" })
hl.workspace_rule({ workspace = "3", monitor = "HDMI-A-1" })

hl.env("GDK_SCALE", "1")
