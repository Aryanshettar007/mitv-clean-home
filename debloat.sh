#!/usr/bin/env bash
# Disable (never uninstall) packages on the TV, one at a time, with crash checks.
# Usage: ./debloat.sh [--dry-run] [list-file]   (default list: debloat.txt)
# Every package actually disabled is appended to state/disabled.log for restore.sh.
set -uo pipefail
cd "$(dirname "$0")"
: "${ANDROID_SERIAL:?set it to your TV address first, e.g. export ANDROID_SERIAL=<tv-ip>:5555}"; export ANDROID_SERIAL

DRY=0
[ "${1:-}" = "--dry-run" ] && { DRY=1; shift; }
LIST="${1:-debloat.txt}"
LOG=state/disabled.log
mkdir -p state

# Processes that must stay alive after each disable, or we roll back.
CRITICAL="system_server com.android.systemui"

adb get-state >/dev/null 2>&1 || adb connect "$ANDROID_SERIAL" >/dev/null
[ "$(adb get-state 2>/dev/null)" = device ] || { echo "TV not connected"; exit 1; }

grep -vE '^\s*(#|$)' "$LIST" | awk '{print $1}' | while read -r pkg <&3; do
  if ! adb shell pm list packages "$pkg" | grep -qx "package:$pkg"; then
    echo "skip   $pkg (not installed)"; continue
  fi
  if adb shell pm list packages -d "$pkg" | grep -qx "package:$pkg"; then
    echo "skip   $pkg (already disabled)"; continue
  fi
  if [ $DRY = 1 ]; then echo "would  $pkg"; continue; fi

  adb logcat -b crash -c
  adb shell am force-stop "$pkg"
  if ! adb shell pm disable-user --user 0 "$pkg" | grep -q 'disabled-user'; then
    echo "FAIL   $pkg (pm refused)"; continue
  fi
  echo "$pkg" >> "$LOG"
  sleep 3

  bad=""
  for p in $CRITICAL; do adb shell pidof "$p" >/dev/null || bad="$bad $p died;"; done
  crashes=$(adb logcat -b crash -d | grep -E 'FATAL EXCEPTION|Process:' | grep -v "$pkg" | head -3)
  [ -n "$crashes" ] && bad="$bad crash: $crashes"

  if [ -n "$bad" ]; then
    adb shell pm enable "$pkg" >/dev/null
    sed -i '' "/^${pkg//./\\.}\$/d" "$LOG"
    echo "ROLLBK $pkg ->$bad"
  else
    echo "off    $pkg"
  fi
done 3<&0 </dev/null
