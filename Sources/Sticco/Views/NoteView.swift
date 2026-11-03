import SwiftUI

/// The content of one sticky window.
struct NoteView: View {
    let noteID: UUID
    @EnvironmentObject var store: NoteStore
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var themes: ThemeStore
    @Environment(\.colorScheme) private var scheme
    @State private var editing = false
    @State private var showAlarm = false
    @FocusState private var bodyFocused: Bool

    var body: some View {
        if let note = store.note(noteID) {
            let ctx = ThemeContext(settings: settings, themes: themes, scheme: scheme)
            content(note, ctx)
                .padding(NoteBackground.insets(ctx.style))
                .environment(\.locale, ctx.language.locale)
        }
    }

    private func content(_ note: Note, _ ctx: ThemeContext) -> some View {
        let st = ctx.style
        let colors = ctx.palette.note(note.color)
        let ink = colors.ink.color
        let stage = store.stage(note.stageID)
        let stageIndex = store.stages.firstIndex(of: stage) ?? 0
        let progress = note.checklist

        return VStack(alignment: .leading, spacing: 0) {
            titlebar(note, ctx, colors)

            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline, spacing: 8) { titleField(ctx); stageButton(ctx, stage, stageIndex, ink) }
                VStack(alignment: .leading, spacing: 6) { titleField(ctx); stageButton(ctx, stage, stageIndex, ink) }
            }
            .padding(.horizontal, 14).padding(.top, 4).padding(.bottom, 8)

            if st.progressBar && progress.total > 0 {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(ink.opacity(0.15))
                        Capsule().fill(ink).frame(width: geo.size.width * CGFloat(progress.done) / CGFloat(progress.total))
                    }
                }
                .frame(height: 8).padding(.horizontal, 14).padding(.bottom, 10)
            }

            Group {
                if editing {
                    TextEditor(text: binding(\.body))
                        .font(ctx.font(st.bodySize))
                        .scrollContentBackground(.hidden)
                        .focused($bodyFocused)
                        .onExitCommand { editing = false }
                        .padding(.horizontal, 9)
                } else {
                    ScrollView {
                        Group {
                            if note.body.isEmpty {
                                Text(ctx.s.bodyHint).font(ctx.font(st.bodySize)).opacity(0.5)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            } else {
                                NoteLinesView(note: note, ctx: ctx, ink: ink) { store.toggleCheck(noteID, line: $0) }
                            }
                        }
                        .padding(.horizontal, 14)
                        .contentShape(Rectangle())
                        .onTapGesture { editing = true; DispatchQueue.main.async { bodyFocused = true } }
                    }
                }
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .onChange(of: bodyFocused) { _, focused in if !focused { editing = false } }

            footer(note, ctx, ink)
        }
        .foregroundStyle(ink)
        .tint(ctx.palette.chrome.accent.color)
        .background(NoteBackground(style: st, colors: colors))
    }

    // MARK: Pieces

    private func titleField(_ ctx: ThemeContext) -> some View {
        TextField(ctx.s.titlePlaceholder, text: binding(\.title))
            .textFieldStyle(.plain)
            .font(ctx.font(ctx.style.titleSize, .bold))
            .fixedSize(horizontal: true, vertical: false)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func stageButton(_ ctx: ThemeContext, _ stage: Stage, _ index: Int, _ ink: Color) -> some View {
        Button { store.cycleStage(noteID) } label: {
            StageBadge(style: ctx.style.stage, label: ctx.stageName(stage), color: ctx.palette.stage(stage),
                       ink: ink, index: index, count: store.stages.count)
        }
        .buttonStyle(.plain)
        .fixedSize()
        .help(ctx.s.stage)
        .contextMenu { stageMenu(ctx) }
    }

    private func titlebar(_ note: Note, _ ctx: ThemeContext, _ colors: NoteColors) -> some View {
        let st = ctx.style
        let ink = colors.ink.color
        return HStack(spacing: 10) {
            if st.titlebar == .bar {
                Rectangle().fill((colors.swatch ?? colors.bg).opaque).frame(width: 10, height: 10)
                    .overlay(Rectangle().strokeBorder(ink, lineWidth: 1))
            }
            if st.titlebar == .compact { closeButton(ctx) }
            Spacer()
            Button { store.update(noteID) { $0.keepOnTop.toggle() } } label: {
                Image(systemName: note.keepOnTop ? "pin.fill" : "pin")
            }
            .help(ctx.s.keepOnTop)
            Menu {
                Picker(ctx.s.color, selection: binding(\.color)) {
                    ForEach(NoteColor.allCases) { Text(ctx.s.colorNames[$0] ?? $0.rawValue).tag($0) }
                }
                Picker(ctx.s.stage, selection: binding(\.stageID)) {
                    ForEach(store.stages) { Text(ctx.stageName($0)).tag($0.id) }
                }
                Divider()
                Button(ctx.s.dashboard) { AppActions.openDashboard() }
                Button(ctx.s.delete, role: .destructive) { store.delete(noteID) }
            } label: { Image(systemName: "ellipsis") }
            .menuStyle(.borderlessButton).menuIndicator(.hidden).fixedSize()
            .help(ctx.s.more)
            if st.titlebar != .compact { closeButton(ctx) }
        }
        .buttonStyle(.plain)
        .font(.system(size: 11, weight: .semibold))
        .foregroundStyle(ink.opacity(0.6))
        .padding(.horizontal, 12)
        .frame(height: 26)
        .background(titlebarBackground(st, colors))
    }

    @ViewBuilder
    private func titlebarBackground(_ st: NoteStyle, _ colors: NoteColors) -> some View {
        switch st.titlebar {
        case .strip:
            UnevenRoundedRectangle(topLeadingRadius: st.cornerRadius, topTrailingRadius: st.cornerRadius, style: .continuous)
                .fill(colors.bg.shaded(0.93))
        case .bar:
            VStack(spacing: 0) { Spacer(); Rectangle().fill(colors.ink.opaque).frame(height: 1) }
        default: Color.clear
        }
    }

    private func closeButton(_ ctx: ThemeContext) -> some View {
        Button { NoteWindowManager.shared.close(noteID) } label: { Image(systemName: "xmark") }
            .help(ctx.s.closeSticky)
    }

    @ViewBuilder
    private func stageMenu(_ ctx: ThemeContext) -> some View {
        ForEach(store.stages) { stage in
            Button(ctx.stageName(stage)) { store.update(noteID) { $0.stageID = stage.id } }
        }
    }

    private func footer(_ note: Note, _ ctx: ThemeContext, _ ink: Color) -> some View {
        let progress = note.checklist
        return HStack(spacing: 8) {
            Button { showAlarm.toggle() } label: {
                HStack(spacing: 5) {
                    Image(systemName: note.alarm.isOn ? "bell.fill" : "bell")
                    Text(note.alarm.isOn ? AlarmText.label(note.alarm, ctx.language) : ctx.s.alarm).lineLimit(1)
                }
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showAlarm, arrowEdge: .bottom) {
                AlarmEditor(noteID: noteID).environmentObject(store).environmentObject(settings)
            }
            Spacer(minLength: 4)
            if progress.total > 0 && !ctx.style.progressBar {
                Text("\(progress.done)/\(progress.total)").monospacedDigit().help(ctx.s.progress(progress.done, progress.total))
            }
            Toggle(ctx.s.alarm, isOn: binding(\.alarm.isOn)).toggleStyle(.switch).controlSize(.mini).labelsHidden()
        }
        .font(.system(size: 11.5, weight: .medium))
        .foregroundStyle(ink.opacity(0.75))
        .padding(.horizontal, 14).padding(.vertical, 9)
    }

    private func binding<T>(_ kp: WritableKeyPath<Note, T>) -> Binding<T> {
        Binding(get: { store.note(noteID)?[keyPath: kp] ?? Note()[keyPath: kp] },
                set: { v in store.update(noteID) { $0[keyPath: kp] = v } })
    }
}
