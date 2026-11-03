#!/usr/bin/env bash
# Packages build/Sticco.app into build/Sticco-<version>.dmg (drag-to-Applications layout).
# Usage: scripts/make-dmg.sh [version]
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="${1:-0.1.0}"
[[ -d build/Sticco.app ]] || scripts/build-app.sh "$VERSION"

STAGE="$(mktemp -d)"
cp -R build/Sticco.app "$STAGE/"
ln -s /Applications "$STAGE/Applications"
DMG="build/Sticco-$VERSION.dmg"
rm -f "$DMG"
hdiutil create -volname "Sticco" -srcfolder "$STAGE" -ov -format UDZO "$DMG" > /dev/null
rm -rf "$STAGE"
[[ -n "${SIGN_IDENTITY:-}" ]] && codesign --sign "$SIGN_IDENTITY" "$DMG"
echo "Created $DMG"
