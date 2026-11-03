import SwiftUI
import AppKit

/// Everything a themed view needs, resolved once per render.
struct ThemeContext {
    let theme: ThemeManifest
    let palette: Palette
    let fontThemeID: String
    let language: AppLanguage
    var style: NoteStyle { theme.note }
    var s: Strings { language.strings }

    @MainActor
    init(settings: AppSettings, themes: ThemeStore, scheme: ColorScheme) {
        theme = themes.theme(settings.themeID)
        palette = theme.palette(scheme)
        fontThemeID = settings.fontThemeID ?? theme.defaultFontTheme
        language = settings.language
    }

    func font(_ size: Double, _ weight: NSFont.Weight = .regular) -> Font {
        FontKit.font(theme: fontThemeID, size: size, weight: weight, language: language)
    }
    func stageName(_ stage: Stage) -> String { stage.customName ?? s.stageNames[stage.id] ?? stage.id }
}

struct VisualEffectBlur: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .hudWindow
    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.material = material
        v.blendingMode = .behindWindow
        v.state = .active
        return v
    }
    func updateNSView(_ v: NSVisualEffectView, context: Context) { v.material = material }
}

struct NoteBackground: View {
    let style: NoteStyle
    let colors: NoteColors

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: style.cornerRadius, style: .continuous)
        ZStack {
            switch style.shadow {
            case .hard: shape.fill(colors.ink.opaque).offset(x: 4, y: 4)
            case .lip: shape.fill(colors.bg.shaded(0.72)).offset(y: 6)
            default: EmptyView()
            }
            if style.material == .glass {
                VisualEffectBlur().clipShape(shape)
                shape.fill(colors.bg.color)
                shape.strokeBorder(Color.white.opacity(0.35), lineWidth: 1)
            } else {
                shape.fill(colors.bg.color)
            }
            if style.borderWidth > 0 { shape.strokeBorder(colors.ink.opaque, lineWidth: style.borderWidth) }
        }
    }

    /// Room around the note so a hard/lip shadow stays inside the window.
    static func insets(_ style: NoteStyle) -> EdgeInsets {
        switch style.shadow {
        case .hard: EdgeInsets(top: 0, leading: 0, bottom: 5, trailing: 5)
        case .lip: EdgeInsets(top: 0, leading: 0, bottom: 7, trailing: 0)
        default: EdgeInsets()
        }
    }
}

struct StageBadge: View {
    let style: NoteStyle.StageStyle
    let label: String
    let color: Color
    let ink: Color
    let index: Int
    let count: Int

    var body: some View {
        switch style {
        case .stamp:
            let filled = index == count - 1
            Text(label.uppercased())
                .font(.system(size: 10.5, weight: .bold, design: .monospaced)).tracking(1)
                .lineLimit(1)
                .padding(.horizontal, 6).padding(.vertical, 2)
                .foregroundStyle(filled ? Color.white : color)
                .background(RoundedRectangle(cornerRadius: 3).fill(filled ? color : color.opacity(0.1)))
                .overlay(RoundedRectangle(cornerRadius: 3).strokeBorder(color, style: StrokeStyle(lineWidth: 1.5, dash: index == 0 ? [3, 2] : [])))
                .rotationEffect(.degrees(-3))
        case .pill:
            HStack(spacing: 5) {
                Circle().fill(color).frame(width: 6, height: 6)
                Text(label).font(.system(size: 11, weight: .medium)).lineLimit(1)
            }
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(Capsule().fill(ink.opacity(0.09)))
        case .bracket:
            HStack(spacing: 6) {
                Text("[ \(label.uppercased()) ]").font(.system(size: 10.5, weight: .bold, design: .monospaced)).tracking(0.6).lineLimit(1)
                    .foregroundStyle(color)
                HStack(spacing: 2) {
                    ForEach(0..<count, id: \.self) { i in
                        Rectangle().fill(i <= index ? color : ink.opacity(0.18)).frame(width: 9, height: 6)
                    }
                }
            }
        case .stepper:
            HStack(spacing: 6) {
                HStack(spacing: 0) {
                    ForEach(0..<count, id: \.self) { i in
                        if i > 0 { Rectangle().fill(i <= index ? ink : ink.opacity(0.25)).frame(width: 8, height: i <= index ? 3 : 2) }
                        Circle().fill(i <= index ? ink : ink.opacity(0.25)).frame(width: i == index ? 11 : 7, height: i == index ? 11 : 7)
                    }
                }
                Text(label).font(.system(size: 11, weight: .bold, design: .rounded)).lineLimit(1)
            }
        }
    }
}

struct CheckBox: View {
    let style: NoteStyle.CheckboxStyle
    let done: Bool
    let ink: Color
    let accent: Color
    let size: Double

    var body: some View {
        let side = style == .chunky ? size + 4 : size
        switch style {
        case .inked:
            RoundedRectangle(cornerRadius: 3).strokeBorder(ink, lineWidth: 1.5)
                .frame(width: side, height: side)
                .overlay(done ? Image(systemName: "checkmark").font(.system(size: side * 0.7, weight: .heavy)).offset(x: 1, y: -1) : nil)
        case .round:
            Circle().strokeBorder(done ? accent : ink.opacity(0.5), lineWidth: 1.3)
                .background(Circle().fill(done ? accent : .clear))
                .frame(width: side, height: side)
                .overlay(done ? Image(systemName: "checkmark").font(.system(size: side * 0.55, weight: .bold)).foregroundStyle(.white) : nil)
        case .bracket:
            Text(done ? "[x]" : "[ ]").font(.system(size: size * 0.95, weight: .semibold, design: .monospaced))
        case .chunky:
            RoundedRectangle(cornerRadius: 6).fill(done ? ink : ink.opacity(0.14))
                .frame(width: side, height: side)
                .overlay(done ? Image(systemName: "checkmark").font(.system(size: side * 0.55, weight: .black)).foregroundStyle(Color.white) : nil)
        }
    }
}

/// Renders a note body: checkboxes are clickable, bullets and plain text follow the theme.
struct NoteLinesView: View {
    let note: Note
    let ctx: ThemeContext
    let ink: Color
    let onToggle: (Int) -> Void

    var body: some View {
        let st = ctx.style
        VStack(alignment: .leading, spacing: 5) {
            ForEach(note.lines) { line in
                HStack(alignment: .top, spacing: 8) {
                    if st.lineNumbers {
                        Text("\(line.id + 1)").font(.system(size: 10.5, design: .monospaced)).foregroundStyle(ink.opacity(0.45))
                            .frame(width: 16, alignment: .trailing).padding(.top, 2)
                    }
                    switch line.kind {
                    case .check(let done):
                        Button { onToggle(line.id) } label: {
                            CheckBox(style: st.checkbox, done: done, ink: ink, accent: ctx.palette.chrome.accent.color, size: st.bodySize + 1)
                        }
                        .buttonStyle(.plain).padding(.top, st.checkbox == .bracket ? 0 : 1)
                        Text(line.text).strikethrough(done).opacity(done ? 0.55 : 1)
                    case .bullet:
                        Text(st.bullet).frame(width: st.checkbox == .chunky ? 20 : 15)
                        Text(line.text)
                    case .text:
                        Text(line.text.isEmpty ? " " : line.text)
                    }
                }
            }
        }
        .font(ctx.font(st.bodySize))
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct AlarmEditor: View {
    let noteID: UUID
    @EnvironmentObject var store: NoteStore
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        let s = settings.strings
        let note = store.note(noteID) ?? Note()
        let bind = { (kp: WritableKeyPath<Alarm, Bool>) in
            Binding(get: { note.alarm[keyPath: kp] }, set: { v in store.update(noteID) { $0.alarm[keyPath: kp] = v } })
        }
        Form {
            Toggle(s.alarm, isOn: bind(\.isOn))
            DatePicker(note.alarm.repeatRule == .never ? s.date : s.time,
                       selection: Binding(get: { note.alarm.date }, set: { v in store.update(noteID) { $0.alarm.date = v; $0.alarm.isOn = true } }),
                       displayedComponents: note.alarm.repeatRule == .never ? [.date, .hourAndMinute] : [.hourAndMinute])
            Picker(s.repeatLabel, selection: Binding(get: { note.alarm.repeatRule }, set: { v in store.update(noteID) { $0.alarm.repeatRule = v } })) {
                ForEach(RepeatRule.allCases) { Text(s.repeatNames[$0] ?? $0.rawValue).tag($0) }
            }
        }
        .formStyle(.grouped)
        .environment(\.locale, settings.language.locale)
        .frame(width: 300)
    }
}

enum AlarmText {
    static func label(_ alarm: Alarm, _ language: AppLanguage) -> String {
        let s = language.strings
        let time = DateFormatter()
        time.locale = language.locale
        time.setLocalizedDateFormatFromTemplate("jmm")
        if alarm.repeatRule != .never { return "\(s.repeatNames[alarm.repeatRule] ?? "") \(time.string(from: alarm.date))" }
        let day = DateFormatter()
        day.locale = language.locale
        day.dateStyle = .medium
        day.doesRelativeDateFormatting = true
        return "\(day.string(from: alarm.date)) \(time.string(from: alarm.date))"
    }
}
