-- Personal bindings and layout fixes (omarchy-ubuntu kit).
-- Omarchy's own bindings stay active (see "omarchy menu keybindings" / SUPER + K).
-- To drop them all: omarchy_default_bindings = false in hyprland.lua before require("default.hypr.omarchy").

-- === AZERTY fixes ================================================================
-- Omarchy binds US keysyms. On an AZERTY keyboard, `, / and . need AltGr or Shift, so SUPER + grave,
-- SUPER + / and SUPER + CTRL + . cannot be typed. Bind the physical keycodes as well, which are
-- independent of the layout. Applied only when the system layout is AZERTY.
local function system_layout()
  for _, path in ipairs({ "/etc/default/keyboard", "/etc/vconsole.conf" }) do
    local file = io.open(path, "r")
    if file then
      for line in file:lines() do
        local value = line:match('^%s*XKBLAYOUT%s*=%s*"?([^",#]*)"?')
        if value and value ~= "" then
          file:close()
          return value
        end
      end
      file:close()
    end
  end
  return "us"
end

local layout = system_layout()
if layout == "be" or layout == "fr" then
  -- Scratchpad (SUPER + grave) → the key left of 1 (² on be, ² on fr)
  o.bind("SUPER + code:49",         "Toggle scratchpad",         hl.dsp.workspace.toggle_special("scratchpad"))
  o.bind("SUPER + SHIFT + code:49", "Move window to scratchpad", hl.dsp.window.move({ workspace = "special:scratchpad", follow = false }))

  -- Monitor scaling (SUPER + / and SUPER + ALT + /) → the :/ key
  o.bind("SUPER + code:61",       "Monitor scaling up",   "omarchy-hyprland-monitor-scaling up")
  o.bind("SUPER + ALT + code:61", "Monitor scaling down", "omarchy-hyprland-monitor-scaling down")

  -- Transcode (SUPER + CTRL + .) → the ;. key
  o.bind("SUPER + CTRL + code:60", "Transcode", "omarchy-transcode")

  -- Note: the bindings Omarchy already expresses as keycodes work as they are, but land on the AZERTY
  -- keys: workspaces on code:10-19, window resizing on code:20/21, webcam size on code:34/35.
end

-- === Alt+Tab ======================================================================
-- Omarchy's behaviour is kept: ALT + Tab and ALT + SHIFT + Tab cycle the windows of the active
-- workspace, SUPER + ALT + Tab cycles within a group, CTRL + ALT + Tab switches monitors.

-- === Customization examples =======================================================
-- o.rebind("SUPER + SHIFT + O", "Joplin", "joplin-desktop")          -- replace a default
-- hl.unbind("SUPER + SHIFT + E")                                     -- remove a default (HEY Email)
-- o.bind("SUPER + SHIFT + Z", "Zed", { launch = "zed" })             -- add an application
