import SwiftUI
import AppKit

@main
struct SticcoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @ObservedObject private var settings = AppSettings.shared

    var body: some Scene {
        Settings {
            SettingsView()
                .environmentObject(AppSettings.shared)
                .environmentObject(ThemeStore.shared)
                .environmentObject(NoteStore.shared)
        }
        .commands { SticcoCommands(settings: settings) }

        MenuBarExtra("Sticco", systemImage: "note.text") {
            let s = settings.strings
            Button(s.newNote) { NoteWindowManager.shared.newNote() }
            Button(s.dashboard) { AppActions.openDashboard() }
            Divider()
            Button(s.showAllNotes) { NoteWindowManager.shared.showAll() }
            Button(s.hideAllNotes) { NoteWindowManager.shared.hideAll() }
            Divider()
            SettingsLink { Text(s.settings) }
            Button("Quit Sticco") { NSApp.terminate(nil) }
        }
    }
}

struct SticcoCommands: Commands {
    @ObservedObject var settings: AppSettings

    var body: some Commands {
        let s = settings.strings
        CommandGroup(replacing: .newItem) {
            Button(s.newNote) { NoteWindowManager.shared.newNote() }.keyboardShortcut("n")
            Button(s.dashboard) { AppActions.openDashboard() }.keyboardShortcut("0")
        }
        CommandGroup(after: .windowArrangement) {
            Button(s.showAllNotes) { NoteWindowManager.shared.showAll() }
            Button(s.hideAllNotes) { NoteWindowManager.shared.hideAll() }
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        MainActor.assumeIsolated {
            FontKit.registerUserFonts()
            if Snapshot.runIfRequested() { return }
            AppSettings.shared.applyAppearance()
            NoteWindowManager.shared.start()
            AlarmScheduler.shared.start()
            GlobalHotKey.registerNewNote()
            if !NoteStore.shared.notes.contains(where: \.isOpen) { AppActions.openDashboard() }
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        MainActor.assumeIsolated { AppActions.openDashboard() }
        return true
    }

    func applicationWillTerminate(_ notification: Notification) {
        MainActor.assumeIsolated { NoteStore.shared.saveNow() }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
}

@MainActor
enum AppActions {
    private static var dashboard: NSWindow?

    static func openDashboard() {
        if dashboard == nil {
            let w = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1080, height: 680),
                             styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                             backing: .buffered, defer: false)
            w.isReleasedWhenClosed = false
            w.title = "Sticco"
            w.contentView = NSHostingView(rootView: DashboardView()
                .environmentObject(NoteStore.shared)
                .environmentObject(AppSettings.shared)
                .environmentObject(ThemeStore.shared))
            w.center()
            w.setFrameAutosaveName("SticcoDashboard")
            dashboard = w
        }
        dashboard?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
