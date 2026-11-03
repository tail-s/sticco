# Developing Sticco

## Build and run

Requires Xcode 16 or later (Swift 5.10+) on macOS 14+.

```bash
swift build && .build/debug/Sticco          # quick dev run (notifications need the bundled .app)
scripts/fetch-fonts.sh                      # optional: download the OFL fonts for the font themes
scripts/build-app.sh 0.1.0                  # → build/Sticco.app   (UNIVERSAL=1 for arm64 + x86_64)
scripts/make-dmg.sh 0.1.0                   # → build/Sticco-0.1.0.dmg
.build/debug/Sticco --snapshot /tmp/snap    # render every theme with sample notes to PNGs
swift scripts/make-icon.swift               # regenerate Resources/AppIcon.icns
```

## Project layout

```
Sources/Sticco/
  App/        app entry, menus, dashboard window, snapshot mode
  Model/      Note, Stage, line parser, JSON store (~/Library/Application Support/Sticco/notes.json)
  Settings/   preferences and UI strings (en / ko / ja)
  Theme/      theme manifest, built-in themes, font themes
  Views/      sticky note, dashboard, settings
  Windows/    one NSWindow per note
  Services/   alarms (UserNotifications), global ⌥⌘N hotkey
```

- **Add a UI language:** add a case to `AppLanguage` and a `Strings` table in `Settings/Strings.swift`.
- **Add a theme:** see [THEMES.md](THEMES.md). Built-ins live in `Theme/BuiltinThemes.swift` in the same JSON format.

## Releasing

Pushing a tag such as `v0.2.0` makes GitHub Actions build a universal DMG, sign it with Developer ID, notarize it,
and publish a GitHub release with generated notes. Signing and notarization run only when these repository secrets
exist (Settings → Secrets and variables → Actions):

| Secret | Value |
|---|---|
| `MACOS_CERT_P12` | Developer ID Application certificate + private key exported as .p12, then `base64 -i cert.p12` |
| `MACOS_CERT_PASSWORD` | the password chosen when exporting the .p12 |
| `NOTARY_KEY_P8` | App Store Connect API key (Users and Access → Integrations, role Developer), `base64 -i AuthKey_XXXX.p8` |
| `NOTARY_KEY_ID` | that key's ID |
| `NOTARY_ISSUER_ID` | the issuer ID shown above the keys list |

To sign and notarize locally instead:

```bash
xcrun notarytool store-credentials sticco   # once; asks for Apple ID, team ID, app-specific password
SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" scripts/make-dmg.sh 0.1.0
scripts/notarize.sh 0.1.0
```

### Opening a build that isn't notarized

Local builds and CI artifacts from branch pushes aren't notarized. Open one via **System Settings → Privacy & Security →
Open Anyway**, or run `xattr -dr com.apple.quarantine /Applications/Sticco.app`.
