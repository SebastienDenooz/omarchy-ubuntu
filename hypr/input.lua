-- Clavier belge AZERTY et touchpad (kit omarchy-ubuntu). Remplace les défauts Omarchy.
-- Omarchy lit /etc/vconsole.conf (XKBLAYOUT=be sur cette machine) ; on fixe quand même explicitement.
hl.config({
  input = {
    kb_layout = "be",
    kb_model = "pc105",
    -- CapsLock = touche compose (emoji et raccourcis ~/.XCompose), les deux Shift = verrouillage majuscules.
    kb_options = "compose:caps,shift:both_capslock_cancel",
    repeat_rate = 50,
    repeat_delay = 300,
    numlock_by_default = true,
    touchpad = {
      natural_scroll = true,          -- ta préférence ; Omarchy met false
      clickfinger_behavior = true,
      scroll_factor = 0.4,
      disable_while_typing = true,
    },
  },
})

-- Trois doigts horizontaux : changer de workspace.
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
