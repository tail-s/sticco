import AppKit
import SwiftUI

/// A font theme maps each script to a list of candidate families, first installed one wins.
/// "@system", "@rounded", "@serif", "@mono" mean the matching San Francisco / New York design.
struct FontTheme: Identifiable {
    var id: String
    var latin: [String]
    var korean: [String]
    var japanese: [String]

    static let all: [FontTheme] = [
        FontTheme(id: "system", latin: ["@system"], korean: ["Apple SD Gothic Neo"], japanese: ["Hiragino Sans"]),
        FontTheme(id: "plex", latin: ["IBM Plex Sans", "@system"], korean: ["IBM Plex Sans KR", "Apple SD Gothic Neo"], japanese: ["IBM Plex Sans JP", "Hiragino Sans"]),
        FontTheme(id: "rounded", latin: ["Nunito", "@rounded"], korean: ["Gowun Dodum", "Apple SD Gothic Neo"], japanese: ["Zen Maru Gothic", "Hiragino Maru Gothic ProN"]),
        FontTheme(id: "hand", latin: ["Patrick Hand", "Noteworthy"], korean: ["Gaegu", "Nanum Pen Script", "Apple SD Gothic Neo"], japanese: ["Yomogi", "Klee", "Hiragino Maru Gothic ProN"]),
        FontTheme(id: "serif", latin: ["Lora", "@serif"], korean: ["Gowun Batang", "AppleMyungjo"], japanese: ["Shippori Mincho", "Hiragino Mincho ProN"]),
        FontTheme(id: "mono", latin: ["JetBrains Mono", "@mono"], korean: ["Nanum Gothic Coding", "Apple SD Gothic Neo"], japanese: ["M PLUS 1 Code", "Osaka", "Hiragino Sans"]),
    ]

    static func find(_ id: String) -> FontTheme { all.first { $0.id == id } ?? all[0] }
}

enum FontKit {
    static var userFontsDirectory: URL {
        let dir = NoteStore.supportDirectory.appendingPathComponent("Fonts", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    /// Bundled fonts load via ATSApplicationFontsPath; fonts dropped into the user folder are registered here.
    static func registerUserFonts() {
        let urls = (try? FileManager.default.contentsOfDirectory(at: userFontsDirectory, includingPropertiesForKeys: nil)) ?? []
        for url in urls where ["ttf", "otf", "ttc"].contains(url.pathExtension.lowercased()) {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }

    private static let installed = Set(NSFontManager.shared.availableFontFamilies)

    private static func baseFont(_ candidates: [String], size: CGFloat, weight: NSFont.Weight) -> NSFont? {
        for name in candidates {
            switch name {
            case "@system": return .systemFont(ofSize: size, weight: weight)
            case "@mono": return .monospacedSystemFont(ofSize: size, weight: weight)
            case "@rounded", "@serif":
                let design: NSFontDescriptor.SystemDesign = name == "@rounded" ? .rounded : .serif
                let d = NSFont.systemFont(ofSize: size, weight: weight).fontDescriptor.withDesign(design)
                return d.flatMap { NSFont(descriptor: $0, size: size) } ?? .systemFont(ofSize: size, weight: weight)
            default:
                guard installed.contains(name) else { continue }
                let traits: NSFontTraitMask = weight >= .semibold ? .boldFontMask : []
                let w = weight >= .bold ? 9 : weight >= .semibold ? 8 : weight >= .medium ? 6 : 5
                if let f = NSFontManager.shared.font(withFamily: name, traits: traits, weight: w, size: size) { return f }
            }
        }
        return nil
    }

    private static func descriptor(_ candidates: [String]) -> NSFontDescriptor? {
        candidates.first { installed.contains($0) }.map { NSFontDescriptor(fontAttributes: [.family: $0]) }
    }

    /// Latin face from the theme, with Korean/Japanese faces as an explicit cascade (order follows the UI language).
    static func nsFont(theme id: String, size: CGFloat, weight: NSFont.Weight = .regular, language: AppLanguage) -> NSFont {
        let t = FontTheme.find(id)
        let base = baseFont(t.latin, size: size, weight: weight) ?? .systemFont(ofSize: size, weight: weight)
        let cjk = (language == .ja ? [t.japanese, t.korean] : [t.korean, t.japanese]).compactMap(descriptor)
        guard !cjk.isEmpty else { return base }
        let d = base.fontDescriptor.addingAttributes([.cascadeList: cjk])
        return NSFont(descriptor: d, size: size) ?? base
    }

    static func font(theme id: String, size: CGFloat, weight: NSFont.Weight = .regular, language: AppLanguage) -> Font {
        Font(nsFont(theme: id, size: size, weight: weight, language: language) as CTFont)
    }
}
