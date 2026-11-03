import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var themes: ThemeStore
    @EnvironmentObject var store: NoteStore
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let s = settings.strings
        TabView {
            general.tabItem { Label(s.general, systemImage: "gearshape") }
            appearance.tabItem { Label(s.appearance, systemImage: "paintpalette") }
            StagesSettings().tabItem { Label(s.stages, systemImage: "list.number") }
            about.tabItem { Label(s.about, systemImage: "info.circle") }
        }
        .frame(width: 600, height: 520)
        .environment(\.locale, settings.language.locale)
        .onAppear { themes.reload() }
    }

    private var general: some View {
        let s = settings.strings
        return Form {
            Picker(s.language, selection: $settings.language) {
                ForEach(AppLanguage.allCases) { Text($0.nativeName).tag($0) }
            }
            Picker(s.appearanceMode, selection: $settings.appearance) {
                Text(s.auto).tag(AppearanceMode.auto)
                Text(s.light).tag(AppearanceMode.light)
                Text(s.dark).tag(AppearanceMode.dark)
            }
            .pickerStyle(.segmented)
            Toggle(s.openAtLogin, isOn: Binding(get: { settings.openAtLogin }, set: { settings.openAtLogin = $0 }))
            Picker(s.alarmSound, selection: $settings.alarmSound) {
                Text(s.soundDefault).tag(true)
                Text(s.soundNone).tag(false)
            }
            Text(s.notifyPermission).font(.footnote).foregroundStyle(.secondary)
        }
        .formStyle(.grouped)
    }

    private var appearance: some View {
        let s = settings.strings
        let lang = settings.language
        return Form {
            Section(s.theme) {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 12)], spacing: 12) {
                    ForEach(themes.themes) { theme in
                        Button { settings.themeID = theme.id } label: { ThemeTile(theme: theme, selected: theme.id == settings.themeID) }
                            .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
                HStack {
                    Text(s.themesHint).font(.footnote).foregroundStyle(.secondary)
                    Spacer()
                    Button(s.openThemesFolder) { NSWorkspace.shared.open(ThemeStore.userThemesDirectory) }
                }
            }
            Section(s.fontTheme) {
                Picker(s.fontTheme, selection: $settings.fontThemeID) {
                    Text("\(s.themeDefault) (\(s.fontThemeNames[themes.theme(settings.themeID).defaultFontTheme] ?? ""))")
                        .tag(String?.none)
                    ForEach(FontTheme.all) { ft in
                        HStack {
                            Text(s.fontThemeNames[ft.id] ?? ft.id)
                            Spacer()
                            Text("Aa 가나 あア").font(FontKit.font(theme: ft.id, size: 15, language: lang))
                        }
                        .tag(Optional(ft.id))
                    }
                }
                .pickerStyle(.radioGroup)
                .labelsHidden()
                HStack {
                    Text(s.fontsHint).font(.footnote).foregroundStyle(.secondary)
                    Spacer()
                    Button(s.openFontsFolder) { NSWorkspace.shared.open(FontKit.userFontsDirectory) }
                }
            }
        }
        .formStyle(.grouped)
    }

    private var about: some View {
        let s = settings.strings
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev"
        return VStack(spacing: 10) {
            Text("Sticco").font(.system(size: 34, weight: .heavy, design: .rounded))
            Text("\(s.version) \(version)").foregroundStyle(.secondary)
            Link(s.viewSource, destination: URL(string: "https://github.com/tail-s/sticco")!)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// A miniature sticky drawn with the theme's own components.
struct ThemeTile: View {
    let theme: ThemeManifest
    let selected: Bool
    @EnvironmentObject var settings: AppSettings
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let pal = theme.palette(scheme)
        let colors = pal.note(.yellow)
        let ink = colors.ink.color
        let font = FontKit.font(theme: theme.defaultFontTheme, size: 12, weight: .bold, language: settings.language)
        VStack(alignment: .leading, spacing: 6) {
            VStack(alignment: .leading, spacing: 6) {
                Text(theme.displayName(settings.language)).font(font)
                StageBadge(style: theme.note.stage, label: settings.strings.stageNames["doing"] ?? "", color: pal.stage(Stage.defaults[1]),
                           ink: ink, index: 1, count: 3)
                    .scaleEffect(0.85, anchor: .leading)
                HStack(spacing: 6) {
                    CheckBox(style: theme.note.checkbox, done: true, ink: ink, accent: pal.chrome.accent.color, size: 11)
                    RoundedRectangle(cornerRadius: 2).fill(ink.opacity(0.3)).frame(height: 4)
                }
            }
            .foregroundStyle(ink)
            .padding(10)
            .frame(maxWidth: .infinity, minHeight: 88, alignment: .topLeading)
            .background(NoteBackground(style: { var st = theme.note; st.material = .solid; return st }(),
                                       colors: NoteColors(bg: HexColor(String(colors.bg.hex.prefix(7))), ink: colors.ink)))
            .padding(NoteBackground.insets(theme.note))
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
            Section(s.stages) {
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
