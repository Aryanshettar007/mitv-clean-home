# Ad-free home screen for a Xiaomi Mi TV

My Xiaomi Mi TV (MiTV-AXSO2, Android TV 11) was slow and full of ads. Over wireless ADB I:

- **Backed up** every package and system setting before touching anything
- **Disabled 25 ad, telemetry and bloatware packages** one at a time, with an automatic crash check after each (rolls back on failure). Nothing is uninstalled.
- **Replaced the home screen** with a custom Apple TV-style launcher: a frosted-glass dock of favourite apps over rotating public-domain nature wallpapers, with **zero permissions**: no internet, no location, no tracking.
- **Wrote a one-command restore** (with a dry-run mode) that undoes every change

## Results

| | Before | After |
|---|---|---|
| Home screen memory | 125 MB (PatchWall) | ~38 MB |
| Used RAM | 1,131 MB | 1,008 MB |
| Google Assistant, Xiaomi analytics | running | off |
| Sponsored rows / promo banners | yes | none |

Kept on purpose: Xiaomi OTA (security updates), HDMI / Live TV inputs, Chromecast, and Google's Ambient Mode screensaver (Google Photos).

## Files

| File | What it does |
|---|---|
| `debloat.txt` | The package list, grouped and commented. Edit to taste. |
| `debloat.sh [--dry-run]` | Disables each package (`pm disable-user`), checks for crashes, rolls back if anything breaks, logs to `state/disabled.log` |
| `restore.sh [--dry-run]` | Re-enables everything in the log, restores the original launcher, uninstalls the custom one |
| `install-launcher.sh` | Builds the launcher and sets it as the default home screen |
| `launcher/` | The launcher (Java). Dock apps, hidden apps and wallpaper interval live in `app/src/main/res/values/config.xml` |

## Usage

On the TV: Settings → Device Preferences → About → press **Build** 7 times, then Developer options → turn on **ADB debugging**.

```bash
brew install android-platform-tools openjdk@17 gradle@8
brew install --cask android-commandlinetools
sdkmanager "platforms;android-34" "build-tools;34.0.0"

export ANDROID_SERIAL=<tv-ip>:5555
adb connect $ANDROID_SERIAL            # accept the prompt on the TV

mkdir -p backup/now && adb shell pm list packages -f > backup/now/packages_all.txt   # back up first
./debloat.sh --dry-run && ./debloat.sh
./install-launcher.sh

./restore.sh --dry-run                 # undo everything
```

The Google TV launcher (`com.google.android.tvlauncher`) has a higher HOME priority than any user app, so it has to be disabled for the custom launcher to stay default. It's in `debloat.txt` and `restore.sh` brings it back.

## Credits

- The launcher is adapted from [vishalsingh2972/Claude-TV](https://github.com/vishalsingh2972/Claude-TV) (MIT, see `launcher/LICENSE-claude-tv`). Changes: rotating wallpapers, frosted-glass dock, all permissions removed, 5-app dock.
- Wallpapers: public domain / CC0 from Wikimedia Commons, see `launcher/WALLPAPER-CREDITS.txt`.
- Font: Outfit (OFL, `launcher/FONT-LICENSE-OFL.txt`).
- Built with [Claude Code](https://claude.com/claude-code).
