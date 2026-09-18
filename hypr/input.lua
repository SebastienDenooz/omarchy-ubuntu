-- Keyboard, touchpad (omarchy-ubuntu kit). Replaces Omarchy's input defaults.
-- The layout follows the system: Ubuntu keeps it in /etc/default/keyboard, which Omarchy does not read
-- (it looks at /etc/vconsole.conf, absent on a plain Ubuntu). Change it with:
--   sudo dpkg-reconfigure keyboard-configuration
local function system_keyboard()
  local keyboard = { layout = "us", variant = "", model = "", options = "" }
  local keys = { XKBLAYOUT = "layout", XKBVARIANT = "variant", XKBMODEL = "model", XKBOPTIONS = "options" }
  for _, path in ipairs({ "/etc/default/keyboard", "/etc/vconsole.conf" }) do
    local file = io.open(path, "r")
    if file then
      for line in file:lines() do
        local key, value = line:match('^%s*([%w_]+)%s*=%s*"?([^"#]*)"?')
        if key and keys[key] and value and value ~= "" then
          keyboard[keys[key]] = (value:gsub("%s+$", ""))
        end
      end
      file:close()
      break
    end
  end
  return keyboard
end

local keyboard = system_keyboard()

hl.config({
  input = {
    kb_layout = keyboard.layout,
    kb_variant = keyboard.variant,
    kb_model = keyboard.model,
    -- CapsLock is Omarchy's compose key (emoji and ~/.XCompose shortcuts); both Shifts toggle Caps Lock.
    kb_options = "compose:caps,shift:both_capslock_cancel",
    repeat_rate = 50,
    repeat_delay = 300,
    numlock_by_default = true,
    touchpad = {
      natural_scroll = true,          -- asked by step 40; Omarchy's own default is false
      clickfinger_behavior = true,
      scroll_factor = 0.4,
      disable_while_typing = true,
    },
  },
})

-- Three fingers horizontally: switch workspace.
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
