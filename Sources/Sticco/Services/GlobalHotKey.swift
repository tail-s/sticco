import Carbon

/// System-wide ⌥⌘N for a new sticky, even while another app is active.
enum GlobalHotKey {
    private static var ref: EventHotKeyRef?

    static func registerNewNote() {
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, _, _ in
            DispatchQueue.main.async { MainActor.assumeIsolated { NoteWindowManager.shared.newNote() } }
            return noErr
        }, 1, &spec, nil, nil)
        let id = EventHotKeyID(signature: OSType(0x5354_434F), id: 1) // "STCO"
        RegisterEventHotKey(UInt32(kVK_ANSI_N), UInt32(cmdKey | optionKey), id, GetApplicationEventTarget(), 0, &ref)
    }
}
