import SwiftUI

/// Lets menus open the dashboard on a settings pane.
@MainActor
final class DashboardRouter: ObservableObject {
    static let shared = DashboardRouter()
    @Published var settingsPane: SettingsPane?
}

enum DashboardFilter: Hashable {
    case all, desktop, alarm, stage(String), color(NoteColor)
}

/// Three columns, as in design B: sidebar filters · note list · inspector. Board mode swaps list + inspector for stage columns.
struct DashboardView: View {
    @EnvironmentObject var store: NoteStore
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var themes: ThemeStore
    @Environment(\.colorScheme) private var scheme
    @State private var filter: DashboardFilter = .all
    @State private var query = ""
    @State private var selected: UUID?
    @AppStorage("dashboardBoard") private var boardMode = false
    @ObservedObject private var router = DashboardRouter.shared

    var body: some View {
        let ctx = ThemeContext(settings: settings, themes: themes, scheme: scheme)
        let chrome = ctx.palette.chrome
        let notes = filtered()
        HStack(spacing: 0) {
            DashboardSidebar(filter: $filter, settingsPane: $router.settingsPane, ctx: ctx)
                .frame(width: 220)
            Divider()
            VStack(spacing: 0) {
                if let pane = router.settingsPane {
                    SettingsPaneView(pane: pane).padding(.top, 20)
                } else {
                    toolbar(ctx, count: notes.count)
                    Divider()
                    if boardMode {
                        board(notes, ctx)
                    } else {
                        HStack(spacing: 0) {
                            list(notes, ctx).frame(width: 340)
                            Divider()
                            inspector(ctx)
                        }
                    }
                }
            }
            .background(chrome.window.color)
        }
        .foregroundStyle(chrome.text.color)
        .tint(chrome.accent.color)
        .environment(\.locale, ctx.language.locale)
        .frame(minWidth: 900, minHeight: 560)
        .onAppear { if selected == nil { selected = notes.first?.id } }
        .onChange(of: filter) { _, _ in
            if let s = selected, !filtered().contains(where: { $0.id == s }) { selected = filtered().first?.id }
        }
    }

    // MARK: Filtering

    static func matches(_ note: Note, _ f: DashboardFilter) -> Bool {
        switch f {
        case .all: true
        case .desktop: note.isOpen
        case .alarm: note.alarm.isOn
        case .stage(let id): note.stageID == id
        case .color(let c): note.color == c
        }
    }

    private func filtered() -> [Note] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        return store.notes
            .filter { Self.matches($0, filter) }
            .filter { q.isEmpty || $0.title.lowercased().contains(q) || $0.body.lowercased().contains(q) }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    private func title(_ ctx: ThemeContext) -> String {
        let s = ctx.s
        switch filter {
        case .all: return s.allNotes
        case .desktop: return s.onDesktop
        case .alarm: return s.withAlarm
        case .stage(let id): return ctx.stageName(store.stage(id))
        case .color(let c): return s.colorNames[c] ?? c.rawValue
        }
    }

    // MARK: Toolbar

    private func toolbar(_ ctx: ThemeContext, count: Int) -> some View {
        let s = ctx.s
        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 1) {
                Text(title(ctx)).font(.system(size: 17, weight: .bold)).lineLimit(1)
                Text("\(count)").font(.system(size: 11)).foregroundStyle(ctx.palette.chrome.secondary.color).monospacedDigit()
            }
            Spacer(minLength: 8)
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass").foregroundStyle(ctx.palette.chrome.secondary.color)
                TextField(s.search, text: $query).textFieldStyle(.plain)
            }
            .padding(.horizontal, 8).frame(width: 220, height: 28)
            .background(RoundedRectangle(cornerRadius: 7).fill(ctx.palette.chrome.card.color))
            .overlay(RoundedRectangle(cornerRadius: 7).strokeBorder(ctx.palette.chrome.separator.color))
            Picker("", selection: $boardMode) {
                Image(systemName: "list.bullet").help(s.list).tag(false)
                Image(systemName: "rectangle.split.3x1").help(s.board).tag(true)
            }
            .pickerStyle(.segmented).labelsHidden().fixedSize()
            Button {
                let note = store.createNote(stageID: { if case .stage(let id) = filter { return id }; return nil }())
                selected = note.id
                NoteWindowManager.shared.open(note.id)
            } label: { Label(s.newNote, systemImage: "square.and.pencil") }
            .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal, 20)
        .frame(height: 58)
        .background(WindowDragArea())
    }

    // MARK: List + inspector

    private func list(_ notes: [Note], _ ctx: ThemeContext) -> some View {
        Group {
            if notes.isEmpty {
                Text(ctx.s.noNotes).foregroundStyle(ctx.palette.chrome.secondary.color)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(notes) { note in
                            NoteRow(note: note, ctx: ctx, isSelected: note.id == selected) { selected = note.id }
                        }
                    }
                    .padding(8)
                }
            }
        }
    }

    @ViewBuilder
    private func inspector(_ ctx: ThemeContext) -> some View {
        if let id = selected, store.note(id) != nil {
            NoteInspector(noteID: id, ctx: ctx).id(id)
        } else {
            Text(ctx.s.noNotes).foregroundStyle(ctx.palette.chrome.secondary.color)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: Board

    private func board(_ notes: [Note], _ ctx: ThemeContext) -> some View {
        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: 16) {
                ForEach(store.stages) { stage in
                    let column = notes.filter { $0.stageID == stage.id }
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Circle().fill(ctx.palette.stage(stage)).frame(width: 9, height: 9)
                            Text(ctx.stageName(stage)).font(.headline)
                            Text("\(column.count)").foregroundStyle(ctx.palette.chrome.secondary.color).monospacedDigit()
                            Spacer()
                            Button { _ = store.createNote(stageID: stage.id) } label: { Image(systemName: "plus") }
                                .buttonStyle(.plain).help(ctx.s.newNote)
                        }
                        ScrollView {
                            LazyVStack(spacing: 12) { ForEach(column) { NoteCard(note: $0, ctx: ctx) } }
                                .padding(.bottom, 12).padding(.trailing, 6)
                        }
                    }
                    .frame(width: 260)
                    .dropDestination(for: String.self) { items, _ in
                        let ids = items.compactMap(UUID.init(uuidString:))
                        for id in ids { store.update(id) { $0.stageID = stage.id } }
                        return !ids.isEmpty
                    }
                }
            }
            .padding(20)
        }
    }
}

// MARK: - Sidebar

private struct DashboardSidebar: View {
    @Binding var filter: DashboardFilter
    @Binding var settingsPane: SettingsPane?
    let ctx: ThemeContext
    @EnvironmentObject var store: NoteStore

    var body: some View {
        let s = ctx.s
        let chrome = ctx.palette.chrome
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    row(.all, s.allNotes) { Image(systemName: "tray.full") }
                    row(.desktop, s.onDesktop) { Image(systemName: "macwindow.on.rectangle") }
                    row(.alarm, s.withAlarm) { Image(systemName: "bell") }
                    header(s.stages)
                    ForEach(store.stages) { st in
                        row(.stage(st.id), ctx.stageName(st)) { Circle().fill(ctx.palette.stage(st)).frame(width: 8, height: 8) }
                    }
                    header(s.colors)
                    ForEach(NoteColor.allCases) { c in
                        let colors = ctx.palette.note(c)
                        row(.color(c), s.colorNames[c] ?? c.rawValue) {
                            RoundedRectangle(cornerRadius: 3).fill((colors.swatch ?? colors.bg).opaque).frame(width: 12, height: 12)
                        }
                    }
                    header(s.settings)
                    ForEach(SettingsPane.allCases) { settingsRow($0) }
                }
                .padding(.horizontal, 10).padding(.top, 44)
            }
        }
        .foregroundStyle(chrome.text.color)
        .background {
            if ctx.style.material == .glass { VisualEffectBlur(material: .sidebar) } else { chrome.sidebar.color }
        }
    }

    private func settingsRow(_ p: SettingsPane) -> some View {
        Button { settingsPane = p } label: {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 5).fill(p.tint).frame(width: 18, height: 18)
                    .overlay(Image(systemName: p.icon).font(.system(size: 9, weight: .semibold)).foregroundStyle(.white))
                Text(p.title(ctx.s)).lineLimit(1)
                Spacer(minLength: 4)
            }
            .font(.system(size: 13))
            .padding(.horizontal, 8).frame(height: 28)
            .background(RoundedRectangle(cornerRadius: 6).fill(settingsPane == p ? ctx.palette.chrome.selection.color : .clear))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func header(_ title: String) -> some View {
        Text(title).font(.system(size: 11, weight: .semibold)).foregroundStyle(ctx.palette.chrome.secondary.color)
            .padding(.horizontal, 8).padding(.top, 16).padding(.bottom, 4)
    }

    private func row<Icon: View>(_ f: DashboardFilter, _ title: String, @ViewBuilder icon: () -> Icon) -> some View {
        let count = store.notes.filter { DashboardView.matches($0, f) }.count
        let on = settingsPane == nil && filter == f
        return Button { filter = f; settingsPane = nil } label: {
            HStack(spacing: 8) {
                icon().frame(width: 18)
                Text(title).lineLimit(1)
                Spacer(minLength: 4)
                Text("\(count)").foregroundStyle(ctx.palette.chrome.secondary.color).monospacedDigit()
            }
            .font(.system(size: 13))
            .padding(.horizontal, 8).frame(height: 28)
            .background(RoundedRectangle(cornerRadius: 6).fill(on ? ctx.palette.chrome.selection.color : .clear))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Rows, cards, inspector

/// Shared context menu + double-click for a note in the dashboard.
private struct NoteActions: ViewModifier {
    let note: Note
    let ctx: ThemeContext
    @EnvironmentObject var store: NoteStore

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(TapGesture(count: 2).onEnded { NoteWindowManager.shared.open(note.id) })
            .contextMenu {
                Button(ctx.s.openAsSticky) { NoteWindowManager.shared.open(note.id) }
                if note.isOpen { Button(ctx.s.closeSticky) { NoteWindowManager.shared.close(note.id) } }
                Menu(ctx.s.stage) {
                    ForEach(store.stages) { st in Button(ctx.stageName(st)) { store.update(note.id) { $0.stageID = st.id } } }
                }
                Menu(ctx.s.color) {
                    ForEach(NoteColor.allCases) { c in Button(ctx.s.colorNames[c] ?? c.rawValue) { store.update(note.id) { $0.color = c } } }
                }
                Divider()
                Button(ctx.s.delete, role: .destructive) { store.delete(note.id) }
            }
    }
}

private struct NoteRow: View {
    let note: Note
    let ctx: ThemeContext
    let isSelected: Bool
    let select: () -> Void
    @EnvironmentObject var store: NoteStore

    var body: some View {
        let chrome = ctx.palette.chrome
        let colors = ctx.palette.note(note.color)
        let stage = store.stage(note.stageID)
        let progress = note.checklist
        HStack(alignment: .top, spacing: 10) {
            Circle().fill((colors.swatch ?? colors.bg).opaque).frame(width: 10, height: 10)
                .overlay(Circle().strokeBorder(chrome.separator.color)).padding(.top, 4)
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(note.title.isEmpty ? ctx.s.untitled : note.title).font(.system(size: 13, weight: .semibold)).lineLimit(1)
                    Spacer(minLength: 6)
                    Text(note.updatedAt, format: .relative(presentation: .named))
                        .font(.system(size: 11)).foregroundStyle(chrome.secondary.color).lineLimit(1)
                }
                Text(note.lines.first(where: { !$0.text.isEmpty })?.text ?? " ")
                    .font(.system(size: 12)).foregroundStyle(chrome.secondary.color).lineLimit(1)
                HStack(spacing: 8) {
                    Button { store.cycleStage(note.id) } label: {
                        StageBadge(style: .pill, label: ctx.stageName(stage), color: ctx.palette.stage(stage), ink: chrome.text.color,
                                   index: store.stages.firstIndex(of: stage) ?? 0, count: store.stages.count)
                    }
                    .buttonStyle(.plain).fixedSize().help(ctx.s.stage)
                    if progress.total > 0 { Text("\(progress.done)/\(progress.total)").monospacedDigit() }
                    if note.alarm.isOn { Label(AlarmText.label(note.alarm, ctx.language), systemImage: "bell.fill").lineLimit(1) }
                    Spacer(minLength: 0)
                    if note.isOpen { Image(systemName: "macwindow").help(ctx.s.onDesktop) }
                }
                .font(.system(size: 11)).foregroundStyle(chrome.secondary.color)
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 8).fill(isSelected ? chrome.selection.color : .clear))
        .contentShape(Rectangle())
        .onTapGesture(perform: select)
        .modifier(NoteActions(note: note, ctx: ctx))
    }
}

struct NoteCard: View {
    let note: Note
    let ctx: ThemeContext
    @EnvironmentObject var store: NoteStore

    var body: some View {
        var st = ctx.style
        st.material = .solid
        let colors = ctx.palette.note(note.color)
        let ink = colors.ink.color
        let stage = store.stage(note.stageID)
        let progress = note.checklist
        let preview = note.lines.prefix(4).map { l -> String in
            switch l.kind { case .check(let d): return (d ? "[x] " : "[ ] ") + l.text; case .bullet: return "- " + l.text; case .text: return l.text }
        }.joined(separator: "\n")
        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(note.title.isEmpty ? ctx.s.untitled : note.title).font(ctx.font(st.titleSize - 2, .bold)).lineLimit(2)
                Spacer(minLength: 6)
                Button { store.cycleStage(note.id) } label: {
                    StageBadge(style: st.stage, label: ctx.stageName(stage), color: ctx.palette.stage(stage), ink: ink,
                               index: store.stages.firstIndex(of: stage) ?? 0, count: store.stages.count)
                }
                .buttonStyle(.plain).fixedSize()
            }
            NoteLinesView(note: Note(body: preview), ctx: ctx, ink: ink) { line in store.toggleCheck(note.id, line: line) }
            HStack(spacing: 8) {
                if progress.total > 0 { Text(ctx.s.progress(progress.done, progress.total)) }
                if note.alarm.isOn { Label(AlarmText.label(note.alarm, ctx.language), systemImage: "bell.fill").lineLimit(1) }
                Spacer()
                Button { note.isOpen ? NoteWindowManager.shared.close(note.id) : NoteWindowManager.shared.open(note.id) } label: {
                    Image(systemName: note.isOpen ? "macwindow" : "macwindow.badge.plus")
                }
                .buttonStyle(.plain).help(note.isOpen ? ctx.s.closeSticky : ctx.s.openAsSticky)
            }
            .font(.system(size: 11, weight: .medium)).opacity(0.8)
        }
        .foregroundStyle(ink)
        .padding(14)
        .background(NoteBackground(style: st, colors: NoteColors(bg: HexColor(String(colors.bg.hex.prefix(7))), ink: colors.ink, swatch: colors.swatch)))
        .padding(NoteBackground.insets(st))
        .contentShape(Rectangle())
        .draggable(note.id.uuidString)
        .modifier(NoteActions(note: note, ctx: ctx))
    }
}

/// Right column: edit everything about the selected note.
private struct NoteInspector: View {
    let noteID: UUID
    let ctx: ThemeContext
    @EnvironmentObject var store: NoteStore
    @State private var editingText = false

    var body: some View {
        let s = ctx.s
        let chrome = ctx.palette.chrome
        let note = store.note(noteID) ?? Note()
        var cardStyle = ctx.style
        cardStyle.material = .solid
        let colors = ctx.palette.note(note.color)
        return ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                TextField(s.titlePlaceholder, text: bind(\.title))
                    .textFieldStyle(.plain).font(ctx.font(22, .bold))

                Picker(s.stage, selection: bind(\.stageID)) {
                    ForEach(store.stages) { Text(ctx.stageName($0)).tag($0.id) }
                }
                .pickerStyle(.segmented).labelsHidden()

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Spacer()
                        Button(editingText ? s.done : s.edit) { editingText.toggle() }.buttonStyle(.link)
                    }
                    Group {
                        if editingText {
                            TextEditor(text: bind(\.body)).font(ctx.font(cardStyle.bodySize)).scrollContentBackground(.hidden)
                                .frame(minHeight: 140)
                        } else if note.body.isEmpty {
                            Text(s.bodyHint).font(ctx.font(cardStyle.bodySize)).opacity(0.5).frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            NoteLinesView(note: note, ctx: ctx, ink: colors.ink.color) { store.toggleCheck(noteID, line: $0) }
                        }
                    }
                    .foregroundStyle(colors.ink.color)
                    .padding(14)
                    .background(NoteBackground(style: cardStyle, colors: NoteColors(bg: HexColor(String(colors.bg.hex.prefix(7))), ink: colors.ink)))
                    .padding(NoteBackground.insets(cardStyle))
                }

                group {
                    Toggle(s.alarm, isOn: bind(\.alarm.isOn)).toggleStyle(.switch)
                    Divider()
                    DatePicker(note.alarm.repeatRule == .never ? s.date : s.time, selection: Binding(
                        get: { note.alarm.date }, set: { v in store.update(noteID) { $0.alarm.date = v; $0.alarm.isOn = true } }),
                        displayedComponents: note.alarm.repeatRule == .never ? [.date, .hourAndMinute] : [.hourAndMinute])
                    Divider()
                    Picker(s.repeatLabel, selection: bind(\.alarm.repeatRule)) {
                        ForEach(RepeatRule.allCases) { Text(s.repeatNames[$0] ?? $0.rawValue).tag($0) }
                    }
                }

                group {
                    HStack {
                        Text(s.color)
                        Spacer()
                        HStack(spacing: 8) {
                            ForEach(NoteColor.allCases) { c in
                                let col = ctx.palette.note(c)
                                Button { store.update(noteID) { $0.color = c } } label: {
                                    Circle().fill((col.swatch ?? col.bg).opaque).frame(width: 20, height: 20)
                                        .overlay(Circle().strokeBorder(note.color == c ? chrome.accent.color : chrome.separator.color,
                                                                       lineWidth: note.color == c ? 2.5 : 1))
                                }
                                .buttonStyle(.plain).help(s.colorNames[c] ?? c.rawValue)
                            }
                        }
                    }
                    Divider()
                    Toggle(s.keepOnTop, isOn: bind(\.keepOnTop)).toggleStyle(.switch)
                }

                HStack {
                    Button { NoteWindowManager.shared.open(noteID) } label: {
                        Label(s.openAsSticky, systemImage: "macwindow.badge.plus").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent).controlSize(.large)
                    Button(role: .destructive) { store.delete(noteID) } label: { Image(systemName: "trash") }
                        .controlSize(.large).help(s.delete)
                }
            }
            .padding(22)
        }
    }

    private func group<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) { content() }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 10).fill(ctx.palette.chrome.card.color))
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(ctx.palette.chrome.separator.color))
    }

    private func bind<T>(_ kp: WritableKeyPath<Note, T>) -> Binding<T> {
        Binding(get: { store.note(noteID)?[keyPath: kp] ?? Note()[keyPath: kp] },
                set: { v in store.update(noteID) { $0[keyPath: kp] = v } })
    }
}
