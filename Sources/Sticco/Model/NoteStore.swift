import Foundation
import Combine

/// Owns notes and stages, persisted as one JSON file in Application Support.
@MainActor
final class NoteStore: ObservableObject {
    static let shared = NoteStore()

    @Published private(set) var notes: [Note] = []
    @Published private(set) var stages: [Stage] = Stage.defaults

    private struct Snapshot: Codable {
        var version = 1
        var notes: [Note]
        var stages: [Stage]
    }

    nonisolated static var supportDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("Sticco", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private var fileURL: URL { Self.supportDirectory.appendingPathComponent("notes.json") }
    private var saveWork: DispatchWorkItem?
    var readOnly = false

    func replaceAll(_ new: [Note]) { notes = new }

    private init() { load() }

    // MARK: Notes

    func note(_ id: UUID) -> Note? { notes.first { $0.id == id } }

    @discardableResult
    func createNote(stageID: String? = nil, color: NoteColor = .yellow) -> Note {
        var note = Note()
        note.stageID = stageID ?? stages.first?.id ?? "todo"
        note.color = color
        notes.insert(note, at: 0)
        scheduleSave()
        return note
    }

    func update(_ id: UUID, _ mutate: (inout Note) -> Void) {
        guard let i = notes.firstIndex(where: { $0.id == id }) else { return }
        var copy = notes[i]
        mutate(&copy)
        guard copy != notes[i] else { return }
        if copy.title != notes[i].title || copy.body != notes[i].body || copy.stageID != notes[i].stageID {
            copy.updatedAt = Date()
        }
        notes[i] = copy
        scheduleSave()
    }

    func delete(_ id: UUID) {
        notes.removeAll { $0.id == id }
        scheduleSave()
    }

    func toggleCheck(_ id: UUID, line: Int) {
        update(id) { $0.body = NoteLine.toggleCheck(at: line, in: $0.body) }
    }

    func cycleStage(_ id: UUID) {
        guard let note = note(id) else { return }
        let ids = stages.map(\.id)
        let next = ids.firstIndex(of: note.stageID).map { ids[($0 + 1) % ids.count] } ?? ids.first ?? "todo"
        update(id) { $0.stageID = next }
    }

    // MARK: Stages

    func stage(_ id: String) -> Stage { stages.first { $0.id == id } ?? stages.first ?? Stage.defaults[0] }

    func setStages(_ new: [Stage]) {
        guard !new.isEmpty else { return }
        stages = new
        let valid = Set(new.map(\.id))
        for i in notes.indices where !valid.contains(notes[i].stageID) { notes[i].stageID = new[0].id }
        scheduleSave()
    }

    // MARK: Persistence

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else {
            notes = Self.welcomeNotes()
            return
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let snap = try? decoder.decode(Snapshot.self, from: data) {
            notes = snap.notes
            stages = snap.stages.isEmpty ? Stage.defaults : snap.stages
        }
    }

    func scheduleSave() {
        saveWork?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.saveNow() }
        saveWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: work)
    }

    func saveNow() {
        guard !readOnly else { return }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(Snapshot(notes: notes, stages: stages)) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    private static func welcomeNotes() -> [Note] {
        var a = Note()
        a.title = "Welcome to Sticco"
        a.body = "[x] Open your first sticky\n[ ] Type [ ] for a checkbox\n[ ] Type - for a bullet\n- Click the stage label to move it along\nSet an alarm from the bell below."
        a.stageID = "doing"
        a.color = .yellow
        a.frame = CodableRect(CGRect(x: 160, y: 420, width: 300, height: 320))
        return [a]
    }
}
