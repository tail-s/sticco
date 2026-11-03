#!/usr/bin/env bash
# Builds build/Sticco.app. Usage: scripts/build-app.sh [version]
#   UNIVERSAL=1      build arm64 + x86_64
#   SIGN_IDENTITY=…  "Developer ID Application: Name (TEAMID)" (default: ad-hoc signature)
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="${1:-0.1.0}"
BUILD="$(git rev-list --count HEAD 2>/dev/null || echo 1)"
ARCHS=(--arch arm64)
[[ "${UNIVERSAL:-0}" == "1" ]] && ARCHS=(--arch arm64 --arch x86_64)

swift build -c release "${ARCHS[@]}"
BIN="$(swift build -c release "${ARCHS[@]}" --show-bin-path)/Sticco"

APP=build/Sticco.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/Sticco"
sed -e "s/__VERSION__/$VERSION/" -e "s/__BUILD__/$BUILD/" Resources/Info.plist > "$APP/Contents/Info.plist"
[[ -f Resources/AppIcon.icns ]] && cp Resources/AppIcon.icns "$APP/Contents/Resources/"
if compgen -G "Resources/Fonts/*.[ot]t[fc]" > /dev/null; then
  mkdir -p "$APP/Contents/Resources/Fonts"
  cp Resources/Fonts/*.[ot]t[fc] Resources/Fonts/*.txt "$APP/Contents/Resources/Fonts/" 2>/dev/null || true
fi

if [[ -n "${SIGN_IDENTITY:-}" ]]; then
  # Developer ID: hardened runtime + secure timestamp, both required for notarization
  codesign --force --options runtime --timestamp --sign "$SIGN_IDENTITY" "$APP"
else
  codesign --force --options runtime --sign - "$APP"   # ad-hoc, local use only
fi
echo "Built $APP ($VERSION)"
