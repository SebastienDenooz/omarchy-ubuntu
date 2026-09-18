-- Monitors (omarchy-ubuntu kit) — generic: every output uses its preferred mode, placed automatically.
-- See what you have with: hyprctl monitors all
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

-- GDK_SCALE is what sizes X11/XWayland windows; GTK only honors whole numbers.
-- Use 2 on a retina-class panel (Omarchy's own default), 1 otherwise.
local omarchy_gdk_scale = 1
hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))

-- Fixed layouts belong either in hypr/machines/<machine>/monitors.lua in the kit, applied when the DMI
-- identity matches, or in hyprmoncfg (step 55), which switches profiles on hotplug, lid and resume.
-- Example:
--   hl.monitor({ output = "DP-2", mode = "2560x1440@144", position = "0x0", scale = 1 })
--   hl.workspace_rule({ workspace = "1", monitor = "DP-2" })
