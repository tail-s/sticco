import SwiftUI

enum SettingsPane: String, CaseIterable, Identifiable {
    case general, appearance, stages, about
    var id: String { rawValue }
    var icon: String { ["general": "gearshape.fill", "appearance": "paintpalette.fill", "stages": "list.number", "about": "info"][rawValue]! }
    var tint: Color {
        switch self {
        case .general: Color(red: 0.47, green: 0.47, blue: 0.50)
        case .appearance: Color(red: 0.20, green: 0.45, blue: 0.95)
        case .stages: Color(red: 0.95, green: 0.55, blue: 0.10)
        case .about: Color(red: 0.55, green: 0.40, blue: 0.85)
        }
    }
    func title(_ s: Strings) -> String {
        switch self { case .general: s.general; case .appearance: s.appearance; case .stages: s.stages; case .about: s.about }
    }
}

/// One settings pane, shown inside the dashboard window (design B grouped sections).
struct SettingsPaneView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var themes: ThemeStore
    @EnvironmentObject var store: NoteStore
    @Environment(\.colorScheme) private var scheme
    let pane: SettingsPane

    var body: some View {
        let s = settings.strings
        Group {
            if pane == .stages {
                VStack(alignment: .leading, spacing: 0) {
                    Text(s.stages).font(.title2.bold()).padding([.horizontal, .top], 24)
                    StagesSettings()
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        Text(pane.title(s)).font(.title2.bold())
                        switch pane {
                        case .general: general
                        case .appearance: appearance
                        default: about
                        }
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .environment(\.locale, settings.language.locale)
        .onAppear { themes.reload() }
    }

    // MARK: General

    private var general: some View {
        let s = settings.strings
        return VStack(alignment: .leading, spacing: 22) {
            SettingsGroup {
                SettingsRow(s.language) {
                    Picker("", selection: $settings.language) {
                        ForEach(AppLanguage.allCases) { Text($0.nativeName).tag($0) }
                    }
                    .pickerStyle(.segmented).labelsHidden().fixedSize()
                }
            }
            SettingsGroup(title: s.appearanceMode) {
                HStack(spacing: 18) {
                    ForEach(AppearanceMode.allCases) { mode in
                        Button { settings.appearance = mode } label: {
                            VStack(spacing: 6) {
                                AppearanceThumb(mode: mode)
                                    .overlay(RoundedRectangle(cornerRadius: 8)
                                        .strokeBorder(settings.appearance == mode ? Color.accentColor : .secondary.opacity(0.3),
                                                      lineWidth: settings.appearance == mode ? 2.5 : 1))
                                Text(mode == .auto ? s.auto : mode == .light ? s.light : s.dark).font(.system(size: 12))
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(14)
            }
            SettingsGroup {
                SettingsRow(s.openAtLogin) {
                    Toggle("", isOn: Binding(get: { settings.openAtLogin }, set: { settings.openAtLogin = $0 }))
                        .toggleStyle(.switch).labelsHidden()
                }
                Divider().padding(.leading, 14)
                SettingsRow(s.newNoteShortcut) {
                    Text("⌥⌘N").font(.system(size: 12, weight: .medium, design: .rounded))
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(RoundedRectangle(cornerRadius: 5).fill(Color.secondary.opacity(0.15)))
                }
                Divider().padding(.leading, 14)
                SettingsRow(s.alarmSound) {
                    Picker("", selection: $settings.alarmSound) {
                        Text(s.soundDefault).tag(true)
                        Text(s.soundNone).tag(false)
                    }
                    .labelsHidden().fixedSize()
                }
            }
            Text(s.notifyPermission).font(.footnote).foregroundStyle(.secondary)
        }
    }

    // MARK: Appearance

    private var appearance: some View {
        let s = settings.strings
        let lang = settings.language
        let currentTheme = themes.theme(settings.themeID)
        return VStack(alignment: .leading, spacing: 22) {
            HStack(alignment: .top, spacing: 20) {
                SettingsGroup(title: s.theme) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 104), spacing: 10)], spacing: 10) {
                        ForEach(themes.themes) { theme in
                            Button { settings.themeID = theme.id } label: { ThemeTile(theme: theme, selected: theme.id == settings.themeID) }
                                .buttonStyle(.plain)
                        }
                    }
                    .padding(12)
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text(s.preview).font(.system(size: 12, weight: .semibold)).foregroundStyle(.secondary)
                    PreviewNote()
                }
                .frame(width: 230)
            }
            HStack {
                Text(s.themesHint).font(.footnote).foregroundStyle(.secondary)
                Spacer()
                Button(s.openThemesFolder) { NSWorkspace.shared.open(ThemeStore.userThemesDirectory) }
            }
            SettingsGroup(title: s.fontTheme) {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 118), spacing: 10)], spacing: 10) {
                    fontTile(id: nil, name: "\(s.themeDefault)", sampleTheme: currentTheme.defaultFontTheme, lang: lang)
                    ForEach(FontTheme.all) { ft in fontTile(id: ft.id, name: s.fontThemeNames[ft.id] ?? ft.id, sampleTheme: ft.id, lang: lang) }
                }
                .padding(12)
            }
            HStack {
                Text(s.fontsHint).font(.footnote).foregroundStyle(.secondary)
                Spacer()
                Button(s.openFontsFolder) { NSWorkspace.shared.open(FontKit.userFontsDirectory) }
            }
        }
    }

    private func fontTile(id: String?, name: String, sampleTheme: String, lang: AppLanguage) -> some View {
        let on = settings.fontThemeID == id
        return Button { settings.fontThemeID = id } label: {
            VStack(spacing: 6) {
                Text("Aa 가 あ").font(FontKit.font(theme: sampleTheme, size: 21, language: lang)).lineLimit(1).minimumScaleFactor(0.7)
                Text(name).font(.system(size: 11)).foregroundStyle(.secondary).lineLimit(1)
            }
            .frame(maxWidth: .infinity, minHeight: 70)
            .background(RoundedRectangle(cornerRadius: 9).fill(Color(nsColor: .textBackgroundColor)))
            .overlay(RoundedRectangle(cornerRadius: 9).strokeBorder(on ? Color.accentColor : .secondary.opacity(0.25), lineWidth: on ? 2.5 : 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: About

    private var about: some View {
        let s = settings.strings
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev"
        return VStack(spacing: 10) {
            Image(nsImage: NSApp.applicationIconImage).resizable().frame(width: 96, height: 96)
            Text("Sticco").font(.system(size: 28, weight: .heavy, design: .rounded))
            Text("\(s.version) \(version)").foregroundStyle(.secondary)
            Link(s.viewSource, destination: URL(string: "https://github.com/tail-s/sticco")!)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 30)
    }
}

// MARK: - Building blocks

struct SettingsGroup<Content: View>: View {
    var title: String? = nil
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title { Text(title).font(.system(size: 12, weight: .semibold)).foregroundStyle(.secondary) }
            VStack(alignment: .leading, spacing: 0) { content }
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color(nsColor: .controlBackgroundColor)))
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.secondary.opacity(0.2)))
        }
    }
}

struct SettingsRow<Control: View>: View {
    let label: String
    @ViewBuilder var control: Control
    init(_ label: String, @ViewBuilder control: () -> Control) { self.label = label; self.control = control() }

    var body: some View {
        HStack {
            Text(label)
            Spacer(minLength: 12)
            control
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
    }
}

private struct AppearanceThumb: View {
    let mode: AppearanceMode
    var body: some View {
        let light = Color(white: 0.95), dark = Color(white: 0.18)
        ZStack(alignment: .topLeading) {
            switch mode {
            case .light: light
            case .dark: dark
            case .auto: HStack(spacing: 0) { light; dark }
            }
            RoundedRectangle(cornerRadius: 3).fill(Color(red: 1, green: 0.85, blue: 0.35)).frame(width: 30, height: 26).offset(x: 12, y: 12)
            RoundedRectangle(cornerRadius: 3).fill(Color(red: 0.72, green: 0.64, blue: 0.98)).frame(width: 30, height: 26).offset(x: 48, y: 22)
        }
        .frame(width: 96, height: 62)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

/// A sticky drawn with the current theme, font theme, language and appearance.
private struct PreviewNote: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var themes: ThemeStore
    @EnvironmentObject var store: NoteStore
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let ctx = ThemeContext(settings: settings, themes: themes, scheme: scheme)
        var st = ctx.style
        st.material = .solid
        let colors = ctx.palette.note(.yellow)
        let ink = colors.ink.color
        let stage = store.stages.count > 1 ? store.stages[1] : store.stage("doing")
        let index = store.stages.firstIndex(of: stage) ?? 1
        var sample = Note()
        sample.body = ctx.s.sampleBody
        sample.alarm.isOn = true
        return VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 6) {
                Text(ctx.s.sampleTitle).font(ctx.font(st.titleSize, .bold)).lineLimit(2)
                StageBadge(style: st.stage, label: ctx.stageName(stage), color: ctx.palette.stage(stage), ink: ink,
                           index: index, count: store.stages.count)
            }
            NoteLinesView(note: sample, ctx: ctx, ink: ink) { _ in }
            Label(AlarmText.label(sample.alarm, ctx.language), systemImage: "bell.fill").font(.system(size: 11, weight: .medium)).opacity(0.75)
        }
        .foregroundStyle(ink)
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(NoteBackground(style: st, colors: NoteColors(bg: HexColor(String(colors.bg.hex.prefix(7))), ink: colors.ink)))
        .padding(NoteBackground.insets(st))
    }
}

/// A miniature sticky drawn with a theme's own components.
struct ThemeTile: View {
    let theme: ThemeManifest
    let selected: Bool
    @EnvironmentObject var settings: AppSettings
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let pal = theme.palette(scheme)
        let colors = pal.note(.yellow)
        let ink = colors.ink.color
        var st = theme.note
        st.material = .solid
        return VStack(spacing: 6) {
            VStack(alignment: .leading, spacing: 6) {
                StageBadge(style: theme.note.stage, label: settings.strings.stageNames["doing"] ?? "", color: pal.stage(Stage.defaults[1]),
                           ink: ink, index: 1, count: 3)
                    .scaleEffect(0.8, anchor: .leading)
                HStack(spacing: 5) {
                    CheckBox(style: theme.note.checkbox, done: true, ink: ink, accent: pal.chrome.accent.color, size: 10)
                    RoundedRectangle(cornerRadius: 2).fill(ink.opacity(0.3)).frame(height: 4)
                }
                HStack(spacing: 5) {
                    CheckBox(style: theme.note.checkbox, done: false, ink: ink, accent: pal.chrome.accent.color, size: 10)
                    RoundedRectangle(cornerRadius: 2).fill(ink.opacity(0.3)).frame(width: 34, height: 4)
                }
            }
            .foregroundStyle(ink)
            .padding(9)
            .frame(maxWidth: .infinity, minHeight: 72, alignment: .topLeading)
            .background(NoteBackground(style: st, colors: NoteColors(bg: HexColor(String(colors.bg.hex.prefix(7))), ink: colors.ink)))
            .padding(NoteBackground.insets(theme.note))
            Text(theme.displayName(settings.language)).font(.system(size: 12, weight: selected ? .semibold : .regular))
        }
        .padding(6)
        .background(RoundedRectangle(cornerRadius: 10).strokeBorder(selected ? Color.accentColor : .clear, lineWidth: 2.5))
        .contentShape(Rectangle())
    }
}

struct StagesSettings: View {
    @EnvironmentObject var store: NoteStore
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        let s = settings.strings
        Form {
            Section {
                ForEach(Array(store.stages.enumerated()), id: \.element.id) { i, stage in
                    HStack {
                        Text("\(i + 1)").monospacedDigit().foregroundStyle(.secondary).frame(width: 18)
                        TextField("", text: Binding(
                            get: { stage.customName ?? s.stageNames[stage.id] ?? stage.id },
                            set: { v in edit(i) { $0.customName = (v == s.stageNames[stage.id]) ? nil : v } }))
                        .textFieldStyle(.roundedBorder)
                        Button { move(i, -1) } label: { Image(systemName: "chevron.up") }.disabled(i == 0).help(s.moveUp)
                        Button { move(i, 1) } label: { Image(systemName: "chevron.down") }.disabled(i == store.stages.count - 1).help(s.moveDown)
                        Button(role: .destructive) { remove(i) } label: { Image(systemName: "minus.circle") }
                            .disabled(store.stages.count <= 1).help(s.removeStage)
                    }
                    .buttonStyle(.borderless)
                }
                Button { add() } label: { Label(s.addStage, systemImage: "plus") }
            }
        }
        .formStyle(.grouped)
    }

    private func edit(_ i: Int, _ f: (inout Stage) -> Void) {
        var list = store.stages; f(&list[i]); store.setStages(list)
    }
    private func move(_ i: Int, _ d: Int) {
        var list = store.stages; list.swapAt(i, i + d); store.setStages(list)
    }
    private func remove(_ i: Int) {
        var list = store.stages; list.remove(at: i); store.setStages(list)
    }
    private func add() {
        var list = store.stages
        list.insert(Stage(id: "stage-\(UUID().uuidString.prefix(8))", customName: settings.strings.newStageName, tone: .custom),
                    at: max(0, list.count - 1))
        store.setStages(list)
    }
}
