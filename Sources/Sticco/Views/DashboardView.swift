import SwiftUI

enum DashboardFilter: Hashable {
    case all, desktop, alarm, stage(String), color(NoteColor)
}

struct DashboardView: View {
    @EnvironmentObject var store: NoteStore
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var themes: ThemeStore
    @Environment(\.colorScheme) private var scheme
    @State private var filter: DashboardFilter? = .all
    @State private var query = ""
    @AppStorage("dashboardBoard") private var boardMode = true

    var body: some View {
        let ctx = ThemeContext(settings: settings, themes: themes, scheme: scheme)
        let chrome = ctx.palette.chrome
        NavigationSplitView {
            sidebar(ctx).navigationSplitViewColumnWidth(min: 190, ideal: 220)
        } detail: {
            Group {
                let notes = filtered(ctx)
                if notes.isEmpty {
                    Text(ctx.s.noNotes).font(.title3).foregroundStyle(chrome.secondary.color)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if boardMode {
                    board(notes, ctx)
                } else {
                    list(notes, ctx)
                }
            }
            .background(chrome.window.color)
        }
        .searchable(text: $query, placement: .toolbar, prompt: ctx.s.search)
        .toolbar {
            ToolbarItem {
                Picker("", selection: $boardMode) {
                    Label(ctx.s.board, systemImage: "rectangle.split.3x1").tag(true)
                    Label(ctx.s.list, systemImage: "list.bullet").tag(false)
                }
                .pickerStyle(.segmented)
            }
            ToolbarItem {
                Button { NoteWindowManager.shared.newNote() } label: { Label(ctx.s.newNote, systemImage: "square.and.pencil") }
                    .help(ctx.s.newNote)
            }
        }
        .tint(chrome.accent.color)
        .environment(\.locale, ctx.language.locale)
        .frame(minWidth: 760, minHeight: 460)
    }

    // MARK: Sidebar

    private func sidebar(_ ctx: ThemeContext) -> some View {
        let s = ctx.s
        return List(selection: $filter) {
            Section {
                row(s.allNotes, "tray.full", count(.all), .all)
                row(s.onDesktop, "macwindow.on.rectangle", count(.desktop), .desktop)
                row(s.withAlarm, "bell", count(.alarm), .alarm)
            }
            Section(s.stages) {
                ForEach(store.stages) { stage in
                    HStack {
                        Circle().fill(ctx.palette.stage(stage)).frame(width: 8, height: 8)
                        Text(ctx.stageName(stage)).lineLimit(1)
                        Spacer()
                        Text("\(count(.stage(stage.id)))").foregroundStyle(.secondary).monospacedDigit()
                    }
                    .tag(DashboardFilter.stage(stage.id))
                }
            }
            Section(s.colors) {
                ForEach(NoteColor.allCases) { c in
                    let colors = ctx.palette.note(c)
                    HStack {
                        RoundedRectangle(cornerRadius: 3).fill((colors.swatch ?? colors.bg).opaque).frame(width: 12, height: 12)
                        Text(s.colorNames[c] ?? c.rawValue)
                        Spacer()
                        Text("\(count(.color(c)))").foregroundStyle(.secondary).monospacedDigit()
                    }
                    .tag(DashboardFilter.color(c))
                }
            }
        }
        .listStyle(.sidebar)
    }

    private func row(_ title: String, _ icon: String, _ n: Int, _ tag: DashboardFilter) -> some View {
        HStack {
            Label(title, systemImage: icon).lineLimit(1)
            Spacer()
            Text("\(n)").foregroundStyle(.secondary).monospacedDigit()
        }
        .tag(tag)
    }

    private func matches(_ note: Note, _ f: DashboardFilter) -> Bool {
        switch f {
        case .all: true
        case .desktop: note.isOpen
        case .alarm: note.alarm.isOn
        case .stage(let id): note.stageID == id
        case .color(let c): note.color == c
        }
    }

    private func count(_ f: DashboardFilter) -> Int { store.notes.filter { matches($0, f) }.count }

    private func filtered(_ ctx: ThemeContext) -> [Note] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        return store.notes
            .filter { matches($0, filter ?? .all) }
            .filter { q.isEmpty || $0.title.lowercased().contains(q) || $0.body.lowercased().contains(q) }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    // MARK: Board & list

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
                            Button { _ = store.createNote(stageID: stage.id); } label: { Image(systemName: "plus") }
                                .buttonStyle(.plain).help(ctx.s.newNote)
                        }
                        .foregroundStyle(ctx.palette.chrome.text.color)
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(column) { NoteCard(note: $0, ctx: ctx) }
                            }
                            .padding(.bottom, 12).padding(.trailing, 6)
                        }
                    }
                    .frame(width: 270)
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

    private func list(_ notes: [Note], _ ctx: ThemeContext) -> some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(notes) { NoteRow(note: $0, ctx: ctx) }
            }
            .padding(20)
        }
    }
}

/// Shared context menu + actions for a note in the dashboard.
private struct NoteActions: ViewModifier {
    let note: Note
    let ctx: ThemeContext
    @EnvironmentObject var store: NoteStore

    func body(content: Content) -> some View {
        content
            .onTapGesture(count: 2) { NoteWindowManager.shared.open(note.id) }
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

struct NoteCard: View {
    let note: Note
    let ctx: ThemeContext
    @EnvironmentObject var store: NoteStore

    var body: some View {
        let st = ctx.style
        let colors = ctx.palette.note(note.color)
        let ink = colors.ink.color
        let stage = store.stage(note.stageID)
        let progress = note.checklist
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(note.title.isEmpty ? ctx.s.untitled : note.title).font(ctx.font(st.titleSize - 2, .bold)).lineLimit(2)
                Spacer(minLength: 6)
                Button { store.cycleStage(note.id) } label: {
                    StageBadge(style: st.stage, label: ctx.stageName(stage), color: ctx.palette.stage(stage), ink: ink,
                               index: store.stages.firstIndex(of: stage) ?? 0, count: store.stages.count)
                }
                .buttonStyle(.plain).fixedSize()
            }
            NoteLinesView(note: Note(body: note.lines.prefix(4).map { l in
                switch l.kind { case .check(let d): (d ? "[x] " : "[ ] ") + l.text; case .bullet: "- " + l.text; case .text: l.text }
            }.joined(separator: "\n")), ctx: ctx, ink: ink) { line in store.toggleCheck(note.id, line: line) }
            HStack(spacing: 8) {
                if progress.total > 0 { Text(ctx.s.progress(progress.done, progress.total)) }
                if note.alarm.isOn { Label(AlarmText.label(note.alarm, ctx.language), systemImage: "bell.fill").lineLimit(1) }
                Spacer()
                Button { note.isOpen ? NoteWindowManager.shared.close(note.id) : NoteWindowManager.shared.open(note.id) } label: {
                    Image(systemName: note.isOpen ? "macwindow.badge.plus" : "macwindow")
                }
                .buttonStyle(.plain).help(note.isOpen ? ctx.s.closeSticky : ctx.s.openAsSticky)
            }
            .font(.system(size: 11, weight: .medium)).opacity(0.8)
        }
        .foregroundStyle(ink)
        .padding(14)
        .background(NoteBackground(style: { var solid = st; solid.material = .solid; return solid }(),
                                   colors: NoteColors(bg: HexColor(String(colors.bg.hex.prefix(7))), ink: colors.ink, swatch: colors.swatch)))
        .padding(NoteBackground.insets(st))
        .contentShape(Rectangle())
        .draggable(note.id.uuidString)
        .modifier(NoteActions(note: note, ctx: ctx))
    }
}

struct NoteRow: View {
    let note: Note
    let ctx: ThemeContext
    @EnvironmentObject var store: NoteStore

    var body: some View {
        let colors = ctx.palette.note(note.color)
        let chrome = ctx.palette.chrome
        let stage = store.stage(note.stageID)
        let progress = note.checklist
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 3).fill((colors.swatch ?? colors.bg).opaque).frame(width: 12, height: 12)
            VStack(alignment: .leading, spacing: 2) {
                Text(note.title.isEmpty ? ctx.s.untitled : note.title).font(ctx.font(14, .semibold)).lineLimit(1)
                Text(note.lines.first?.text ?? "").font(ctx.font(12)).foregroundStyle(chrome.secondary.color).lineLimit(1)
            }
            Spacer()
            Button { store.cycleStage(note.id) } label: {
                StageBadge(style: ctx.style.stage, label: ctx.stageName(stage), color: ctx.palette.stage(stage), ink: chrome.text.color,
                           index: store.stages.firstIndex(of: stage) ?? 0, count: store.stages.count)
            }
            .buttonStyle(.plain).fixedSize()
            Text(progress.total > 0 ? "\(progress.done)/\(progress.total)" : "—").monospacedDigit().frame(width: 40)
            Toggle(ctx.s.alarm, isOn: Binding(get: { note.alarm.isOn }, set: { v in store.update(note.id) { $0.alarm.isOn = v } }))
                .toggleStyle(.switch).controlSize(.mini).labelsHidden()
            Text(note.updatedAt, format: .relative(presentation: .named)).foregroundStyle(chrome.secondary.color).frame(width: 110, alignment: .trailing)
        }
        .font(.system(size: 12))
        .foregroundStyle(chrome.text.color)
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 10).fill(chrome.card.color))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(chrome.separator.color))
        .contentShape(Rectangle())
        .modifier(NoteActions(note: note, ctx: ctx))
    }
}
