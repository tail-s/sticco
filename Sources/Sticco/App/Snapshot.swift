import AppKit
import SwiftUI

/// `Sticco --snapshot <dir>` renders every theme (light + dark) with sample notes to PNGs and quits.
/// Used for docs and visual checks; never touches the user's notes.
@MainActor
enum Snapshot {
    static func runIfRequested() -> Bool {
        let args = CommandLine.arguments
        guard let i = args.firstIndex(of: "--snapshot"), args.count > i + 1 else { return false }
        let dir = URL(fileURLWithPath: args[i + 1], isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let settings = AppSettings.shared
        let saved = (settings.themeID, settings.language, settings.appearance)
        NoteStore.shared.useSampleData()
        if let lang = args.firstIndex(of: "--lang").flatMap({ AppLanguage(rawValue: args[$0 + 1]) }) { settings.language = lang }
        for theme in ThemeStore.shared.themes {
            for dark in [false, true] {
                settings.themeID = theme.id
                NSApp.appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
                let name = "\(theme.id)-\(dark ? "dark" : "light")"
                render(SampleNotesBoard(), size: CGSize(width: 1040, height: 400), to: dir.appendingPathComponent("\(name)-notes.png"))
                render(DashboardView(), size: CGSize(width: 1100, height: 640), to: dir.appendingPathComponent("\(name)-dashboard.png"))
            }
        }
        render(SettingsView(), size: CGSize(width: 600, height: 520), to: dir.appendingPathComponent("settings.png"))
        (settings.themeID, settings.language, settings.appearance) = saved
        NSApp.terminate(nil)
        return true
    }

    private static func render<V: View>(_ view: V, size: CGSize, to url: URL) {
        let host = NSHostingView(rootView: view
            .environmentObject(NoteStore.shared).environmentObject(AppSettings.shared).environmentObject(ThemeStore.shared))
        let window = NSWindow(contentRect: CGRect(origin: .zero, size: size), styleMask: [.borderless], backing: .buffered, defer: false)
        window.contentView = host
        window.appearance = NSApp.appearance
        host.frame = CGRect(origin: .zero, size: size)
        host.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.4))
        guard let rep = host.bitmapImageRepForCachingDisplay(in: host.bounds) else { return }
        host.cacheDisplay(in: host.bounds, to: rep)
        try? rep.representation(using: .png, properties: [:])?.write(to: url)
    }
}

/// Three sample stickies side by side on a neutral desk.
private struct SampleNotesBoard: View {
    @EnvironmentObject var store: NoteStore
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        HStack(alignment: .top, spacing: 28) {
            ForEach(store.notes.prefix(3)) { note in
                NoteView(noteID: note.id).frame(width: 300, height: 330)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(scheme == .dark ? Color(white: 0.16) : Color(red: 0.86, green: 0.84, blue: 0.80))
    }
}

extension NoteStore {
    /// In-memory sample notes for snapshots (saving is disabled afterwards).
    func useSampleData() {
        readOnly = true
        func note(_ title: String, _ body: String, _ stage: String, _ color: NoteColor, alarm: Bool = false) -> Note {
            var n = Note(); n.title = title; n.body = body; n.stageID = stage; n.color = color; n.isOpen = false
            n.alarm.isOn = alarm
            return n
        }
        replaceAll([
            note("Launch checklist", "[x] Write release notes\n[x] Notarize the DMG\n[ ] Update the Homebrew cask\n[ ] Publish the GitHub release\nShip before Friday.", "doing", .yellow, alarm: true),
            note("Groceries", "- Oat milk\n- Eggs\n- Basil\n- Sourdough\nThe market closes at 2.", "todo", .mint),
            note("Design review", "Keep the stage label smaller than the subtitle.\n- Contrast checked in dark mode\n[x] Share notes with the team", "done", .lilac),
            note("Weekly 1:1", "[ ] Q4 roadmap\n[x] Hiring update\n- Bring the latency chart", "doing", .sky, alarm: true),
            note("Call the dentist", "Move the appointment to next week.\n[ ] Find the insurance card", "todo", .peach, alarm: true),
            note("Bug: alarm fires twice", "[x] Reproduce on macOS 26\n[x] Dedupe scheduled requests", "done", .graphite),
        ])
    }
}
