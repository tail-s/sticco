# Sticco

Little notes that stick around — a free, open-source sticky-notes app for macOS.

![Sticco themes](docs/screenshots/themes.png)

- **Every note is its own window.** Float it on the desktop, pin it on top, close it to the dashboard.
- **Subtitle + stage** at the top of each note (Not started → In progress → Done, fully customizable).
- **Plain-text checklists.** `[ ]` checkbox, `- ` bullet, or plain text — mix them freely, click to tick.
- **Alarms per note.** One-off, daily, weekdays or weekly, delivered as macOS notifications.
- **Dashboard** with board (by stage) and list views, filters, search.
- **4 themes** — Glass, Paper, Ink, Pop — plus your own via a `theme.json` ([docs/THEMES.md](docs/THEMES.md)).
- **6 font themes** built on free OFL fonts, with macOS fallbacks.
- **English, 한국어, 日本語**, switchable live in Settings.

Requires macOS 14 Sonoma or later.

## Install

1. Download the latest `Sticco-x.y.z.dmg` from [Releases](https://github.com/tail-s/sticco/releases).
2. Open it and drag **Sticco** into **Applications**.
3. Launch Sticco. Release builds are signed with a Developer ID and notarized by Apple, so they open normally.

### Opening a build that isn't notarized

Builds you make yourself, and the `Sticco-dmg` artifacts from CI runs, are not notarized. The first time you open one,
macOS says it can't verify the developer. To open it anyway:

1. Try to open Sticco once, then click **Done** on the warning.
2. Go to **System Settings → Privacy & Security**, scroll down, and click **Open Anyway** next to the Sticco message.
3. Confirm with your password. From then on Sticco opens like any other app.

Or, in Terminal: `xattr -dr com.apple.quarantine /Applications/Sticco.app`

## Build from source

```bash
scripts/fetch-fonts.sh        # optional: bundle the OFL fonts for the font themes
scripts/build-app.sh 0.1.0    # → build/Sticco.app (UNIVERSAL=1 for arm64 + x86_64)
scripts/make-dmg.sh 0.1.0     # → build/Sticco-0.1.0.dmg
```

`swift build && .build/debug/Sticco` runs a development build (notifications need the bundled `.app`).
`Sticco --snapshot <dir>` renders every theme to PNGs with sample notes.

## Releasing (maintainers)

Pushing a tag such as `v0.1.0` builds a universal DMG and publishes a GitHub release. It is signed and notarized
when these repository secrets exist (Settings → Secrets and variables → Actions):

| Secret | Value |
|---|---|
| `MACOS_CERT_P12` | Developer ID Application certificate + private key, exported as .p12, then `base64 -i cert.p12` |
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

## Project layout

```
Sources/Sticco/
  App/        app entry, menus, dashboard window, snapshot mode
  Model/      Note, Stage, line parser, JSON store (~/Library/Application Support/Sticco/notes.json)
  Settings/   preferences and UI strings (en / ko / ja)
  Theme/      theme manifest, built-in themes, font themes
  Views/      sticky note, dashboard, settings
  Windows/    one NSWindow per note
  Services/   alarm scheduling (UserNotifications)
```

Adding a UI language: add a case to `AppLanguage` and a `Strings` table in `Settings/Strings.swift`.

---

## 한국어

Sticco는 macOS 전용 무료 오픈소스 스티커 메모 앱입니다. 메모마다 독립된 창으로 바탕화면에 띄우고, 소제목과 진행 단계(시작 전 → 진행 중 → 완료)를 표시합니다. 본문에서는 `[ ]` 체크박스, `- ` 글머리 기호, 일반 텍스트를 섞어 쓸 수 있고, 메모별로 알림을 켤 수 있습니다. 대시보드(보드/목록), 테마 4종(Glass, Paper, Ink, Pop)과 사용자 테마(`theme.json`), 무료 글꼴 테마 6종, 영어·한국어·일본어를 지원합니다.

**설치:** [Releases](https://github.com/tail-s/sticco/releases)에서 `Sticco-x.y.z.dmg`를 받아 열고, Sticco를 응용 프로그램 폴더로 끌어다 놓으세요. 정식 릴리스는 Apple 공증을 받아 바로 열립니다.

**공증받지 않은 빌드를 열 때** (직접 빌드했거나 CI 결과물): 한 번 실행해 경고가 뜨면 **완료**를 누르고, **시스템 설정 → 개인정보 보호 및 보안**에서 Sticco 옆의 **그래도 열기**를 누르세요. 터미널에서는 `xattr -dr com.apple.quarantine /Applications/Sticco.app`로도 됩니다.

## License

MIT — see [LICENSE](LICENSE). Bundled fonts are licensed under the SIL Open Font License 1.1.
