#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
[[ "$(uname -s)" == Darwin ]] || { echo 'Build on macOS to preserve app permissions.' >&2; exit 1; }
GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
"$GODOT" --version | grep -q '^4\.7\.2\.' || { echo 'Godot 4.7.2 required.' >&2; exit 1; }
OUT="$ROOT/desktop-pet/build/macos"
mkdir -p "$OUT"
# A fresh staging directory avoids accidentally shipping stale bundle contents.
STAGE="$(mktemp -d "$OUT/stage.XXXXXX")"
APP="$STAGE/WarmJade.app"
"$GODOT" --headless --editor --path "$ROOT/desktop-pet" --import
"$GODOT" --headless --path "$ROOT/desktop-pet" --export-release 'macOS' "$APP"
EXECUTABLE=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$APP/Contents/Info.plist")
chmod +x "$APP/Contents/MacOS/$EXECUTABLE"
"$GODOT" --headless --path "$ROOT/desktop-pet" --script res://tests/write_notices.gd
cp "$ROOT/desktop-pet/build/GODOT-LICENSE.txt" "$ROOT/desktop-pet/build/GODOT-THIRD-PARTY.json" "$APP/Contents/Resources/"
IDENTITY="${MACOS_SIGN_IDENTITY:--}"
if [[ "$IDENTITY" == '-' ]]; then
  /usr/bin/codesign --force --deep --sign - "$APP"
else
  /usr/bin/codesign --force --deep --options runtime --timestamp --sign "$IDENTITY" "$APP"
fi
/usr/bin/codesign --verify --deep --strict "$APP"
ZIP="$OUT/WarmJade-macOS.zip"
/usr/bin/ditto -c -k --sequesterRsrc --keepParent "$APP" "$ZIP"
if [[ -n "${MACOS_NOTARY_PROFILE:-}" ]]; then
  [[ "$IDENTITY" != '-' ]] || { echo 'Notarization requires Developer ID signing.' >&2; exit 1; }
  /usr/bin/xcrun notarytool submit "$ZIP" --keychain-profile "$MACOS_NOTARY_PROFILE" --wait
  /usr/bin/xcrun stapler staple "$APP"
  /usr/bin/xcrun stapler validate "$APP"
  /usr/sbin/spctl --assess --type execute --verbose "$APP"
  /usr/bin/ditto -c -k --sequesterRsrc --keepParent "$APP" "$ZIP"
fi
/usr/bin/shasum -a 256 "$ZIP"
echo "App: $APP"
echo "Share: $ZIP"
