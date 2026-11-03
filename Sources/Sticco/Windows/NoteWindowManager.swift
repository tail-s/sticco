import AppKit
import SwiftUI
import Combine

final class NoteWindow: NSWindow {
    var noteID = UUID()
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

/// Each note lives in its own borderless-looking window. This keeps them in sync with the store.
@MainActor
final class NoteWindowManager: NSObject, NSWindowDelegate {
    static let shared = NoteWindowManager()
    private var windows: [UUID: NoteWindow] = [:]
    private var bag = Set<AnyCancellable>()
    private let store = NoteStore.shared
    private let settings = AppSettings.shared

    func start() {
        for note in store.notes where note.isOpen { open(note.id, activate: false) }
        settings.$themeID.dropFirst().receive(on: RunLoop.main)
            .sink { [weak self] _ in DispatchQueue.main.async { self?.refreshStyles() } }
            .store(in: &bag)
        store.$notes.receive(on: RunLoop.main)
            .sink { [weak self] notes in self?.reconcile(notes) }
            .store(in: &bag)
    }

    func open(_ id: UUID, activate: Bool = true) {
        if let w = windows[id] {
            w.makeKeyAndOrderFront(nil)
            if activate { NSApp.activate(ignoringOtherApps: true) }
            return
        }
        guard let note = store.note(id) else { return }
        let frame = note.frame?.rect ?? cascadeFrame()
        let w = NoteWindow(contentRect: frame, styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
                           backing: .buffered, defer: false)
        w.noteID = id
        w.titlebarAppearsTransparent = true
        w.titleVisibility = .hidden
        for b in [NSWindow.ButtonType.closeButton, .miniaturizeButton, .zoomButton] { w.standardWindowButton(b)?.isHidden = true }
        w.isOpaque = false
        w.backgroundColor = .clear
        w.isMovableByWindowBackground = true
        w.isReleasedWhenClosed = false
        w.tabbingMode = .disallowed
        w.minSize = NSSize(width: 220, height: 150)
        w.collectionBehavior = [.fullScreenAuxiliary]
        w.delegate = self
        let host = NSHostingView(rootView: NoteView(noteID: id)
            .environmentObject(store).environmentObject(settings).environmentObject(ThemeStore.shared))
        host.sizingOptions = []
        w.contentView = host
        w.setFrame(frame, display: false)
        windows[id] = w
        apply(note, to: w)
        if !note.isOpen { store.update(id) { $0.isOpen = true } }
        w.makeKeyAndOrderFront(nil)
        if activate { NSApp.activate(ignoringOtherApps: true) }
    }

    /// Hides the sticky from the desktop; the note stays in the dashboard.
    func close(_ id: UUID) {
        store.update(id) { $0.isOpen = false }
        windows[id]?.close()
    }

    func newNote() {
        let note = store.createNote()
        open(note.id)
    }

    func showAll() { for n in store.notes { open(n.id, activate: false) }; NSApp.activate(ignoringOtherApps: true) }
    func hideAll() { for id in Array(windows.keys) { close(id) } }

    func refreshStyles() {
        for (id, w) in windows { if let n = store.note(id) { apply(n, to: w) }; w.invalidateShadow() }
    }

    private func apply(_ note: Note, to w: NoteWindow) {
        w.level = note.keepOnTop ? .floating : .normal
        let style = ThemeStore.shared.theme(settings.themeID).note
        w.hasShadow = style.shadow == .soft
    }

    private func reconcile(_ notes: [Note]) {
        let byID = Dictionary(uniqueKeysWithValues: notes.map { ($0.id, $0) })
        for (id, w) in windows {
            guard let n = byID[id] else { windows[id] = nil; w.close(); continue }
            if !n.isOpen { windows[id] = nil; w.close(); continue }
            let level: NSWindow.Level = n.keepOnTop ? .floating : .normal
            if w.level != level { w.level = level }
        }
        for n in notes where n.isOpen && windows[n.id] == nil { open(n.id, activate: false) }
    }

    private func cascadeFrame() -> CGRect {
        let screen = NSScreen.main?.visibleFrame ?? CGRect(x: 0, y: 0, width: 1440, height: 900)
        let offset = CGFloat(windows.count % 8) * 28
        return CGRect(x: screen.midX - 150 + offset, y: screen.midY - 60 - offset, width: 300, height: 300)
    }

    // MARK: NSWindowDelegate

    func windowWillClose(_ notification: Notification) {
        guard let w = notification.object as? NoteWindow else { return }
        let id = w.noteID
        if windows[id] != nil {
            windows[id] = nil
            store.update(id) { $0.isOpen = false }
        }
    }

    func windowDidMove(_ notification: Notification) { saveFrame(notification) }
    func windowDidEndLiveResize(_ notification: Notification) { saveFrame(notification) }

    private func saveFrame(_ notification: Notification) {
        guard let w = notification.object as? NoteWindow else { return }
        let rect = CodableRect(w.frame)
        store.update(w.noteID) { $0.frame = rect }
    }
}
