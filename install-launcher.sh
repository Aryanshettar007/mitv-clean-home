#!/usr/bin/env bash
# Build the launcher and install it on the TV as the default home screen.
# Usage: ./install-launcher.sh [--no-build]
# Undo with ./restore.sh (re-selects the original launcher and uninstalls this one).
set -euo pipefail
cd "$(dirname "$0")"
: "${ANDROID_SERIAL:?set it to your TV address first, e.g. export ANDROID_SERIAL=<tv-ip>:5555}"; export ANDROID_SERIAL
export JAVA_HOME="${JAVA_HOME:-/opt/homebrew/opt/openjdk@17}"
GRADLE="${GRADLE:-gradle}"   # Gradle 8.x (brew install gradle@8)
APK=launcher/app/build/outputs/apk/debug/app-debug.apk
HOME_ACTIVITY=com.aryan.home/com.gathin.tvhome.MainActivity

if [ "${1:-}" != "--no-build" ]; then
  [ -f launcher/local.properties ] || echo "sdk.dir=$HOME/Library/Android/sdk" > launcher/local.properties
  (cd launcher && "$GRADLE" assembleDebug -q --console=plain)
fi

adb get-state >/dev/null 2>&1 || adb connect "$ANDROID_SERIAL" >/dev/null
adb install -r "$APK"
adb shell cmd package set-home-activity --user 0 "$HOME_ACTIVITY"
adb shell input keyevent KEYCODE_HOME
echo "Installed. Press Home on the remote to see it."
