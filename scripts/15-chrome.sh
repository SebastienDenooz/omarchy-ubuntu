#!/bin/bash
# Step 15 — Google Chrome (Omarchy's browser role; Ubuntu's Chromium is a confined snap that breaks the
# Omarchy web apps and extensions). Skipped when Chrome is already installed. Option: --skip
. "$(dirname "$0")/lib.sh"
[[ " $* " == *" --skip "* ]] && { skip "Google Chrome (--skip)"; exit 0; }
if command -v google-chrome-stable >/dev/null; then ok "Google Chrome already installed: $(google-chrome-stable --version 2>/dev/null)"; exit 0; fi
# Omarchy's browser role wants a Chromium-family browser: its web apps use --app windows and its two
# extensions need native messaging, both of which Ubuntu's confined Chromium snap breaks.
ask_choice KIT_BROWSER "Install a browser for Omarchy's web apps and hotkeys?" google-chrome google-chrome none
[[ $KIT_BROWSER == none ]] && { skip "browser install (answer: none); Omarchy menu → Install → Browser offers others"; exit 0; }
need sudo curl
say "Google Chrome repository"
sudo install -d -m 0755 /etc/apt/keyrings
curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor -o /etc/apt/keyrings/google-chrome.gpg --yes
printf 'deb [arch=amd64 signed-by=/etc/apt/keyrings/google-chrome.gpg] https://dl.google.com/linux/chrome/deb/ stable main\n' | sudo tee /etc/apt/sources.list.d/google-chrome.list >/dev/null
sudo apt-get update
apt_install google-chrome-stable
ok "$(google-chrome-stable --version)"
