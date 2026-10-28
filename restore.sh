#!/usr/bin/env bash
# Undo everything: re-enable every package debloat.sh disabled and restore the
# original home launcher. Usage: ./restore.sh [--dry-run]
set -uo pipefail
cd "$(dirname "$0")"
: "${ANDROID_SERIAL:?set it to your TV address first, e.g. export ANDROID_SERIAL=<tv-ip>:5555}"; export ANDROID_SERIAL

DRY=0
[ "${1:-}" = "--dry-run" ] && DRY=1
run() { if [ $DRY = 1 ]; then echo "would: adb $*"; else adb "$@"; fi; }

adb get-state >/dev/null 2>&1 || adb connect "$ANDROID_SERIAL" >/dev/null
[ "$(adb get-state 2>/dev/null)" = device ] || { echo "TV not connected"; exit 1; }

LOG=state/disabled.log
if [ -s "$LOG" ]; then
  for pkg in $(sort -u "$LOG"); do run shell pm enable "$pkg" </dev/null; done
  [ $DRY = 0 ] && : > "$LOG"
else
  echo "nothing to re-enable"
fi

# Put the original launcher back as default (recorded in the first backup).
ORIG=$(cat backup/*/home_launcher.txt 2>/dev/null | grep / | head -1)
[ -n "$ORIG" ] && run shell cmd package set-home-activity "$ORIG"
# Remove the custom launcher if it was installed (it's ours, not a system app).
if adb shell pm list packages com.aryan.home | grep -q .; then
  run uninstall com.aryan.home
fi
echo "done$([ $DRY = 1 ] && echo ' (dry run, nothing changed)')"
