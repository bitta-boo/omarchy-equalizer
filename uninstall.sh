#!/bin/bash
# Remove everything install.sh added. Backups (*.bak.*) are left in place.
set -uo pipefail
SRC=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PLUGIN_ID=$(python3 -c "import json;print(json.load(open('$SRC/manifest.json'))['id'])" 2>/dev/null || echo io.github.bitta-boo.equalizer)

systemctl --user disable --now omarchy-eq.service 2>/dev/null
rm -f "$HOME/.config/systemd/user/omarchy-eq.service"
systemctl --user daemon-reload 2>/dev/null

rm -f  "$HOME/.local/bin/omarchy-eq"
rm -f  "$HOME/.config/pipewire/omarchy-eq.conf"
rm -rf "$HOME/.config/pipewire/omarchy-eq.conf.d"
rm -rf "$HOME/.config/omarchy/plugins/$PLUGIN_ID"

echo "Removed. State kept at ~/.config/omarchy/eq.json (delete it to forget your curve)."
echo "If the EQ was your default output, pick a real device in the audio panel."
