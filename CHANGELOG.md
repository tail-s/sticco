# Changelog

All notable changes to Sticco are listed here, newest first.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow [Semantic Versioning](https://semver.org).

## [0.1.1] - 2026-11-04

### Added
- **Default** theme: clean, opaque and calm. It is now the theme new installs start with.
- Settings now live inside the dashboard: pick General, Appearance, Stages or About from the bottom of the sidebar.
  ⌘, and the menu bar's Settings open them there.
- New app icon.

### Changed
- **Glass** is now truly see-through: your desktop shows through the notes (Liquid Glass on macOS 26 and later).
- The dashboard has three columns: sidebar filters, a note list and an inspector where you can edit the selected
  note's title, stage, checklist, alarm, color and pin. Search, list/board view and New Note sit at the top.
- Settings are reorganized into grouped sections with live previews of themes and font styles.

### Fixed
- Notes couldn't be moved: drag a note by its top bar or any empty area.
- A note stayed in editing mode after clicking elsewhere. Editing now ends when you click another window or app,
  an empty part of the note, or press Esc.

## [0.1.0] - 2026-11-03

First release.

- Every note is its own window: float it on the desktop or pin it on top.
- Subtitle and stage on each note (Not started → In progress → Done, customizable).
- `[ ]` checkboxes, `- ` bullets and plain text in one note.
- Per-note alarms: once, daily, weekdays or weekly.
- Dashboard with board and list views, filters and search.
- Glass, Paper, Ink and Pop themes, custom themes via `theme.json`, and six font styles.
- English, 한국어 and 日本語.

[0.1.1]: https://github.com/tail-s/sticco/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/tail-s/sticco/releases/tag/v0.1.0
