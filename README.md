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

Download the latest `Sticco-x.y.z.dmg` from [Releases](https://github.com/tail-s/sticco/releases) and drag Sticco to Applications.

## Build from source

```bash
scripts/fetch-fonts.sh        # optional: bundle the OFL fonts for the font themes
scripts/build-app.sh 0.1.0    # → build/Sticco.app (UNIVERSAL=1 for arm64 + x86_64)
scripts/make-dmg.sh 0.1.0     # → build/Sticco-0.1.0.dmg
```

`swift build && .build/debug/Sticco` runs a development build (notifications need the bundled `.app`).
`Sticco --snapshot <dir>` renders every theme to PNGs with sample notes.

For a notarized release, set `SIGN_IDENTITY="Developer ID Application: …"` before building, then run
`xcrun notarytool submit build/Sticco-0.1.0.dmg --wait` and `xcrun stapler staple build/Sticco-0.1.0.dmg`.

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

## License

MIT — see [LICENSE](LICENSE). Bundled fonts are licensed under the SIL Open Font License 1.1.
