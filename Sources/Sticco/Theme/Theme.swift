import SwiftUI

/// A theme is pure data: the four built-ins and any user theme share this JSON format (see docs/THEMES.md).
struct ThemeManifest: Codable, Identifiable {
    var id: String
    var version: Int?
    var name: [String: String]
    var defaultFontTheme: String
    var note: NoteStyle
    var light: Palette
    var dark: Palette

    func displayName(_ lang: AppLanguage) -> String { name[lang.rawValue] ?? name["en"] ?? id }
    func palette(_ scheme: ColorScheme) -> Palette { scheme == .dark ? dark : light }
}

struct NoteStyle: Codable {
    enum Material: String, Codable { case solid, glass }
    enum Shadow: String, Codable { case soft, hard, lip, none }
    enum Titlebar: String, Codable { case strip, compact, bar, floating }
    enum StageStyle: String, Codable { case stamp, pill, bracket, stepper }
    enum CheckboxStyle: String, Codable { case inked, round, bracket, chunky }

    var cornerRadius: Double
    var borderWidth: Double = 0
    var material: Material = .solid
    var shadow: Shadow = .soft
    var titlebar: Titlebar
    var stage: StageStyle
    var checkbox: CheckboxStyle
    var bullet: String = "•"
    var lineNumbers: Bool = false
    var progressBar: Bool = false
    var titleSize: Double = 17
    var bodySize: Double = 14

    // Optional keys fall back to the defaults above, so theme.json files stay short.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        cornerRadius = try c.decode(Double.self, forKey: .cornerRadius)
        titlebar = try c.decode(Titlebar.self, forKey: .titlebar)
        stage = try c.decode(StageStyle.self, forKey: .stage)
        checkbox = try c.decode(CheckboxStyle.self, forKey: .checkbox)
        borderWidth = try c.decodeIfPresent(Double.self, forKey: .borderWidth) ?? 0
        material = try c.decodeIfPresent(Material.self, forKey: .material) ?? .solid
        shadow = try c.decodeIfPresent(Shadow.self, forKey: .shadow) ?? .soft
        bullet = try c.decodeIfPresent(String.self, forKey: .bullet) ?? "•"
        lineNumbers = try c.decodeIfPresent(Bool.self, forKey: .lineNumbers) ?? false
        progressBar = try c.decodeIfPresent(Bool.self, forKey: .progressBar) ?? false
        titleSize = try c.decodeIfPresent(Double.self, forKey: .titleSize) ?? 17
        bodySize = try c.decodeIfPresent(Double.self, forKey: .bodySize) ?? 14
    }
}

struct NoteColors: Codable {
    var bg: HexColor
    var ink: HexColor
    /// Small color chip (dashboard, Ink headers). Defaults to `bg`.
    var swatch: HexColor?
}

struct ChromeColors: Codable {
    var window: HexColor
    var sidebar: HexColor
    var card: HexColor
    var text: HexColor
    var secondary: HexColor
    var accent: HexColor
    var separator: HexColor
    var selection: HexColor
}

struct Palette: Codable {
    var notes: [String: NoteColors]
    var stages: [String: HexColor]
    var chrome: ChromeColors

    func note(_ c: NoteColor) -> NoteColors {
        notes[c.rawValue] ?? notes["yellow"] ?? NoteColors(bg: HexColor("#FFF1A8"), ink: HexColor("#222222"))
    }
    func stage(_ s: Stage) -> Color {
        (stages[s.id] ?? stages[s.tone.rawValue] ?? stages["custom"] ?? HexColor("#777777")).color
    }
}

/// "#RRGGBB" or "#RRGGBBAA" in JSON.
struct HexColor: Codable, Hashable {
    var hex: String
    init(_ hex: String) { self.hex = hex }
    init(from decoder: Decoder) throws { hex = try decoder.singleValueContainer().decode(String.self) }
    func encode(to encoder: Encoder) throws { var c = encoder.singleValueContainer(); try c.encode(hex) }

    var components: (r: Double, g: Double, b: Double, a: Double) {
        let s = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let v = UInt64(s, radix: 16) ?? 0
        if s.count == 8 {
            return (Double((v >> 24) & 0xFF) / 255, Double((v >> 16) & 0xFF) / 255, Double((v >> 8) & 0xFF) / 255, Double(v & 0xFF) / 255)
        }
        return (Double((v >> 16) & 0xFF) / 255, Double((v >> 8) & 0xFF) / 255, Double(v & 0xFF) / 255, 1)
    }
    var color: Color { let c = components; return Color(.sRGB, red: c.r, green: c.g, blue: c.b, opacity: c.a) }
    var opaque: Color { let c = components; return Color(.sRGB, red: c.r, green: c.g, blue: c.b, opacity: 1) }
    /// Darker (factor < 1) or lighter (> 1) opaque variant, used for Paper strips and Pop lips.
    func shaded(_ factor: Double) -> Color {
        let c = components
        let f = { (x: Double) in factor < 1 ? x * factor : x + (1 - x) * (factor - 1) }
        return Color(.sRGB, red: f(c.r), green: f(c.g), blue: f(c.b), opacity: 1)
    }
}

@MainActor
final class ThemeStore: ObservableObject {
    static let shared = ThemeStore()
    @Published private(set) var themes: [ThemeManifest] = []

    nonisolated static var userThemesDirectory: URL {
        let dir = NoteStore.supportDirectory.appendingPathComponent("Themes", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private init() { reload() }

    func reload() {
        let decoder = JSONDecoder()
        var list = BuiltinThemes.json.map { try! decoder.decode(ThemeManifest.self, from: Data($0.utf8)) }
        let fm = FileManager.default
        let folders = (try? fm.contentsOfDirectory(at: Self.userThemesDirectory, includingPropertiesForKeys: nil)) ?? []
        for folder in folders.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
            let file = folder.appendingPathComponent("theme.json")
            guard let data = try? Data(contentsOf: file),
                  let theme = try? decoder.decode(ThemeManifest.self, from: data) else { continue }
            list.removeAll { $0.id == theme.id }
            list.append(theme)
        }
        themes = list
    }

    func theme(_ id: String) -> ThemeManifest { themes.first { $0.id == id } ?? themes[0] }
}
