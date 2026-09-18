# Machine profiles

Fixed monitor layouts, applied by step 40 only on the machine they were written for. Everything else in
the kit is generic: without a matching profile, each output simply uses its preferred mode.

A profile is a directory holding:

- `match` — DMI patterns, one per line, compared (case-insensitively, as substrings) against
  `/sys/class/dmi/id/product_name` and `/sys/class/dmi/id/product_family`
- one or more `.lua` files copied over `~/.config/hypr/`, usually `monitors.lua`

```
hypr/machines/my-laptop/match          →  XPS 13 9350
hypr/machines/my-laptop/monitors.lua   →  hl.monitor / hl.workspace_rule rules
```

The easiest way to create one is to let the installer do it: with a Hyprland session running and no
profile matching your hardware, step 40 offers to save the monitors as they are currently wired. You can
also call `generate_machine_profile` from `scripts/lib.sh` directly.

Profiles are ignored by git (see `.gitignore`), since they describe one person's desk. Remove the ignore
rule if you want to version yours.

For layouts that should follow whatever you plug in, rather than the machine, use hyprmoncfg (step 55):
it stores a profile per setup and applies it on hotplug, lid and resume.
