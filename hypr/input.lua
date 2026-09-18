-- Belgian AZERTY keyboard and touchpad (omarchy-ubuntu kit). Replaces the Omarchy defaults.
-- Omarchy reads /etc/vconsole.conf (XKBLAYOUT=be on this machine); set explicitly anyway.
hl.config({
  input = {
    kb_layout = "be",
    kb_model = "pc105",
    -- CapsLock is the compose key (emoji and ~/.XCompose shortcuts); both Shifts toggle Caps Lock.
    kb_options = "compose:caps,shift:both_capslock_cancel",
    repeat_rate = 50,
    repeat_delay = 300,
    numlock_by_default = true,
    touchpad = {
      natural_scroll = true,          -- your preference; Omarchy sets false
      clickfinger_behavior = true,
      scroll_factor = 0.4,
      disable_while_typing = true,
    },
  },
})

-- Three fingers horizontally: switch workspace.
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
