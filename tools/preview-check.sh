#!/usr/bin/env bash
# Isolated visual check; does not install or change the running Plasma desktop.
set -euo pipefail
cd "$(dirname "$0")/.."
TASK_TMP=$(mktemp -d /tmp/elklock-preview.XXXXXX)
Xvfb -displayfd 3 -screen 0 1100x800x24 3>"$TASK_TMP/display" >"$TASK_TMP/xvfb.log" 2>&1 &
XVFB_PID=$!
VIEWER_PID=""
trap 'if [[ -n "$VIEWER_PID" ]]; then kill "$VIEWER_PID" 2>/dev/null || true; fi; kill "$XVFB_PID" 2>/dev/null || true' EXIT
for attempt in {1..50}; do
    [[ -s "$TASK_TMP/display" ]] && break
    sleep 0.1
done
if [[ ! -s "$TASK_TMP/display" ]]; then cat "$TASK_TMP/xvfb.log"; exit 1; fi
export DISPLAY=":$(cat "$TASK_TMP/display")"
export QT_QPA_PLATFORM=xcb
export XDG_CONFIG_HOME="$TASK_TMP/config"
export XDG_CACHE_HOME="$TASK_TMP/cache"
export LANG="${ELKLOCK_PREVIEW_LANGUAGE:-en_US.UTF-8}"
export LC_ALL="$LANG"
export LANGUAGE="${LANG%%_*}"
export XDG_DATA_DIRS="$PWD/.local/stage/share:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
plasmoidviewer -a "$PWD/package" -s 460x560 >.local/preview.log 2>&1 &
VIEWER_PID=$!
sleep 8
import -window root docs/preview.png
xdotool mousemove 248 531 click 1
sleep 2
xdotool mousemove 250 282 click 1
xdotool type --clearmodifiers "Sun Tzu"
sleep 0.3
xdotool mousemove 142 360 click 1
sleep 0.3
import -window root docs/config-preview.png
xdotool mousemove 580 516 click 1
sleep 6
rg "^SelectedDays=Day of Sun Tzu$" "$XDG_CONFIG_HOME"
xdotool search --name 'plasmawindowed' >"$TASK_TMP/windows" || true
printf 'Screenshot: %s/docs/preview.png\n' "$PWD"
cat .local/preview.log
