import Foundation

enum NoteColor: String, Codable, CaseIterable, Identifiable {
    case yellow, peach, mint, sky, lilac, graphite
    var id: String { rawValue }
}

enum RepeatRule: String, Codable, CaseIterable, Identifiable {
    case never, daily, weekdays, weekly
    var id: String { rawValue }
}

struct Alarm: Codable, Equatable {
    var isOn: Bool = false
    /// For `.never` the full date matters; for repeating rules only the time (and weekday for `.weekly`).
    var date: Date = Alarm.nextFullHour()
    var repeatRule: RepeatRule = .never

    static func nextFullHour() -> Date {
        let cal = Calendar.current
        let next = cal.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        return cal.date(bySetting: .minute, value: 0, of: next) ?? next
    }
}

/// A progress stage such as "Not started". Built-in stages are localized by id; renamed or custom ones carry `customName`.
struct Stage: Codable, Identifiable, Equatable {
    enum Tone: String, Codable { case todo, doing, done, custom }
    var id: String
    var customName: String?
    var tone: Tone

    static let defaults: [Stage] = [
        Stage(id: "todo", customName: nil, tone: .todo),
        Stage(id: "doing", customName: nil, tone: .doing),
        Stage(id: "done", customName: nil, tone: .done),
    ]
}

struct CodableRect: Codable, Equatable {
    var x: Double, y: Double, width: Double, height: Double
    init(_ r: CGRect) { x = r.origin.x; y = r.origin.y; width = r.size.width; height = r.size.height }
    var rect: CGRect { CGRect(x: x, y: y, width: width, height: height) }
}

struct Note: Codable, Identifiable, Equatable {
    var id = UUID()
    var title = ""
    var body = ""
    var stageID = "todo"
    var color: NoteColor = .yellow
    var alarm = Alarm()
    var isOpen = true
    var keepOnTop = false
    var frame: CodableRect?
    var createdAt = Date()
    var updatedAt = Date()

    var lines: [NoteLine] { NoteLine.parse(body) }

    var checklist: (done: Int, total: Int) {
        lines.reduce(into: (0, 0)) { acc, line in
            if case .check(let done) = line.kind { acc.1 += 1; if done { acc.0 += 1 } }
        }
    }
}

/// One line of a note body. Syntax: "[ ]" / "[]" / "[x]" checkbox, "- " (or "• ", "* ") bullet, anything else plain text.
struct NoteLine: Identifiable, Equatable {
    enum Kind: Equatable { case check(Bool), bullet, text }
    let id: Int
    var kind: Kind
    var text: String

    static func parse(_ body: String) -> [NoteLine] {
        body.components(separatedBy: "\n").enumerated().map { i, raw in
            let trimmed = raw.drop(while: { $0 == " " || $0 == "\t" })
            if trimmed.hasPrefix("[") , let close = trimmed.firstIndex(of: "]") {
                let inside = trimmed[trimmed.index(after: trimmed.startIndex)..<close]
                if inside.isEmpty || inside == " " || inside == "x" || inside == "X" {
                    let rest = trimmed[trimmed.index(after: close)...].drop(while: { $0 == " " })
                    return NoteLine(id: i, kind: .check(inside == "x" || inside == "X"), text: String(rest))
                }
            }
            for marker in ["- ", "• ", "* "] where trimmed.hasPrefix(marker) {
                return NoteLine(id: i, kind: .bullet, text: String(trimmed.dropFirst(marker.count)))
            }
            return NoteLine(id: i, kind: .text, text: raw)
        }
    }

    /// Flips the checkbox on line `index`, normalizing "[]" to "[ ]".
    static func toggleCheck(at index: Int, in body: String) -> String {
        var rows = body.components(separatedBy: "\n")
        guard rows.indices.contains(index) else { return body }
        let lines = parse(body)
        guard case .check(let done) = lines[index].kind else { return body }
        let indent = rows[index].prefix(while: { $0 == " " || $0 == "\t" })
        rows[index] = indent + (done ? "[ ] " : "[x] ") + lines[index].text
        return rows.joined(separator: "\n")
    }
}
