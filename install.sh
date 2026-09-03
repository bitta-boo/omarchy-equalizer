#!/bin/bash
# Install the Omarchy equalizer: CLI, PipeWire filter host, user service, and
# the bar widget. Safe to re-run; existing files are backed up once.
set -euo pipefail

SRC=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

need() { command -v "$1" >/dev/null || { echo "missing required command: $1" >&2; exit 1; }; }
need pipewire; need pw-cli; need python3

# Single source of truth for the id, so publishing under a different vendor is
# one edit in manifest.json rather than a hunt through the scripts.
PLUGIN_ID=$(python3 -c "import json;print(json.load(open('$SRC/manifest.json'))['id'])")
PLUGIN_DIR="$HOME/.config/omarchy/plugins/$PLUGIN_ID"

backup() { [[ -f $1 ]] && cp -n "$1" "$1.bak.$(date +%s)" || true; }

install -Dm755 "$SRC/bin/omarchy-eq"           "$HOME/.local/bin/omarchy-eq"
backup "$HOME/.config/pipewire/omarchy-eq.conf"
install -Dm644 "$SRC/pipewire/omarchy-eq.conf" "$HOME/.config/pipewire/omarchy-eq.conf"
install -Dm644 "$SRC/systemd/omarchy-eq.service" "$HOME/.config/systemd/user/omarchy-eq.service"

# `omarchy plugin add` clones this repo straight into the plugins directory and
# the widget is already where it belongs; only the DSP half is left to install.
if [[ $SRC == "$PLUGIN_DIR" ]]; then
  FROM_PLUGIN_ADD=1
else
  FROM_PLUGIN_ADD=0
  install -Dm644 "$SRC/manifest.json" "$PLUGIN_DIR/manifest.json"
  install -Dm644 "$SRC/Panel.qml"     "$PLUGIN_DIR/Panel.qml"
fi

mkdir -p "$HOME/.config/pipewire/omarchy-eq.conf.d"
"$HOME/.local/bin/omarchy-eq" apply >/dev/null

systemctl --user daemon-reload
systemctl --user enable --now omarchy-eq.service

if (( FROM_PLUGIN_ADD )); then
cat <<MSG

Installed the equalizer backend for $PLUGIN_ID.

  1. Enable the widget if you have not already:
       omarchy plugin enable $PLUGIN_ID right

  2. Select "Equalizer" as your audio output. The filter does nothing until
     audio routes through it.

  omarchy-eq status   shows the current curve
MSG
else
cat <<MSG

Installed.

  1. Add the widget to the bar and restart the shell so it registers:
       omarchy bar put $PLUGIN_ID right
       omarchy restart shell

  2. Select "Equalizer" as your audio output. The filter does nothing until
     audio routes through it.

  omarchy-eq status   shows the current curve
MSG
fi
