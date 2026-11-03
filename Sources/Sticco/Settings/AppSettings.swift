import AppKit
import ServiceManagement

enum AppearanceMode: String, CaseIterable, Identifiable {
    case auto, light, dark
    var id: String { rawValue }
}

/// User preferences, persisted in UserDefaults.
@MainActor
final class AppSettings: ObservableObject {
    static let shared = AppSettings()
    private let defaults = UserDefaults.standard

    @Published var language: AppLanguage { didSet { defaults.set(language.rawValue, forKey: "language") } }
    @Published var themeID: String { didSet { defaults.set(themeID, forKey: "themeID") } }
    /// nil = use the theme's default font theme.
    @Published var fontThemeID: String? { didSet { defaults.set(fontThemeID, forKey: "fontThemeID") } }
    @Published var appearance: AppearanceMode { didSet { defaults.set(appearance.rawValue, forKey: "appearance"); applyAppearance() } }
    @Published var alarmSound: Bool { didSet { defaults.set(alarmSound, forKey: "alarmSound") } }

    var strings: Strings { language.strings }

    private init() {
        language = AppLanguage(rawValue: defaults.string(forKey: "language") ?? "") ?? .en
        themeID = defaults.string(forKey: "themeID") ?? "glass"
        fontThemeID = defaults.string(forKey: "fontThemeID")
        appearance = AppearanceMode(rawValue: defaults.string(forKey: "appearance") ?? "") ?? .auto
        alarmSound = defaults.object(forKey: "alarmSound") as? Bool ?? true
    }

    func applyAppearance() {
        switch appearance {
        case .auto: NSApp.appearance = nil
        case .light: NSApp.appearance = NSAppearance(named: .aqua)
        case .dark: NSApp.appearance = NSAppearance(named: .darkAqua)
        }
    }

    var openAtLogin: Bool {
        get { SMAppService.mainApp.status == .enabled }
        set {
            objectWillChange.send()
            if newValue { try? SMAppService.mainApp.register() } else { try? SMAppService.mainApp.unregister() }
        }
    }
}
