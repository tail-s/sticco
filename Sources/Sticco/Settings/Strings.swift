import Foundation

enum AppLanguage: String, CaseIterable, Identifiable, Codable {
    case en, ko, ja
    var id: String { rawValue }
    var nativeName: String { ["en": "English", "ko": "한국어", "ja": "日本語"][rawValue]! }
    var locale: Locale { Locale(identifier: rawValue) }
    var strings: Strings { switch self { case .en: .en; case .ko: .ko; case .ja: .ja } }
}

/// All UI copy. In-app language switching reads from these tables directly (no restart needed).
/// Adding a language = adding a case above and one more `Strings` value below.
struct Strings {
    var dashboard, allNotes, onDesktop, withAlarm, stages, colors, newNote, search: String
    var board, list, openAsSticky, closeSticky, delete, noNotes, untitled, titlePlaceholder, bodyHint: String
    var alarm, alarmOn, alarmOff, repeatLabel, time, date, keepOnTop, color, stage, more, done: String
    var repeatNames: [RepeatRule: String]
    var stageNames: [String: String]
    var colorNames: [NoteColor: String]
    var addStage, newStageName, removeStage, moveUp, moveDown: String
    var settings, general, appearance, notifications, about: String
    var language, theme, fontTheme, themeDefault, appearanceMode, auto, light, dark: String
    var openAtLogin, alarmSound, soundDefault, soundNone, openThemesFolder, themesHint, openFontsFolder, fontsHint: String
    var fontThemeNames: [String: String]
    var showAllNotes, hideAllNotes, version, viewSource, notifyPermission: String
    var progressFormat: String // {done} {total}
    var edit, newNoteShortcut, preview, sampleTitle, sampleBody: String

    func progress(_ done: Int, _ total: Int) -> String {
        progressFormat.replacingOccurrences(of: "{done}", with: "\(done)").replacingOccurrences(of: "{total}", with: "\(total)")
    }

    static let en = Strings(
        dashboard: "Dashboard", allNotes: "All Notes", onDesktop: "On Desktop", withAlarm: "With Alarm",
        stages: "Stages", colors: "Colors", newNote: "New Note", search: "Search notes",
        board: "Board", list: "List", openAsSticky: "Open as Sticky", closeSticky: "Close Sticky", delete: "Delete Note",
        noNotes: "No notes here yet", untitled: "Untitled", titlePlaceholder: "Subtitle",
        bodyHint: "Type [ ] for a checkbox, - for a bullet",
        alarm: "Alarm", alarmOn: "On", alarmOff: "Off", repeatLabel: "Repeat", time: "Time", date: "Date",
        keepOnTop: "Keep on Top", color: "Color", stage: "Stage", more: "More", done: "Done",
        repeatNames: [.never: "Never", .daily: "Every day", .weekdays: "Weekdays", .weekly: "Every week"],
        stageNames: ["todo": "Not started", "doing": "In progress", "done": "Done"],
        colorNames: [.yellow: "Yellow", .peach: "Peach", .mint: "Mint", .sky: "Sky", .lilac: "Lilac", .graphite: "Graphite"],
        addStage: "Add Stage", newStageName: "New stage", removeStage: "Remove", moveUp: "Move Up", moveDown: "Move Down",
        settings: "Settings", general: "General", appearance: "Appearance", notifications: "Notifications", about: "About",
        language: "Language", theme: "Theme", fontTheme: "Font theme", themeDefault: "Theme default",
        appearanceMode: "Appearance", auto: "Auto", light: "Light", dark: "Dark",
        openAtLogin: "Open at login", alarmSound: "Alarm sound", soundDefault: "Default", soundNone: "None",
        openThemesFolder: "Open Themes Folder", themesHint: "Add your own: put a folder containing theme.json in the themes folder, then reopen Settings.",
        openFontsFolder: "Open Fonts Folder", fontsHint: "Font themes use bundled OFL fonts when present and fall back to macOS fonts.",
        fontThemeNames: ["system": "System", "plex": "Plex", "rounded": "Rounded", "hand": "Handwritten", "serif": "Serif", "mono": "Mono"],
        showAllNotes: "Show All Stickies", hideAllNotes: "Hide All Stickies", version: "Version", viewSource: "View Source on GitHub",
        notifyPermission: "Allow notifications in System Settings to hear alarms.",
        progressFormat: "{done} of {total} done",
        edit: "Edit", newNoteShortcut: "New note shortcut", preview: "Preview", sampleTitle: "Launch checklist",
        sampleBody: "[x] Write release notes\n[ ] Update the Homebrew cask\n- Ship before Friday"
    )

    static let ko = Strings(
        dashboard: "대시보드", allNotes: "모든 메모", onDesktop: "데스크톱에 띄운 메모", withAlarm: "알림 있는 메모",
        stages: "진행 단계", colors: "색상", newNote: "새 메모", search: "메모 검색",
        board: "보드", list: "목록", openAsSticky: "스티커로 띄우기", closeSticky: "스티커 닫기", delete: "메모 삭제",
        noNotes: "아직 메모가 없어요", untitled: "제목 없음", titlePlaceholder: "소제목",
        bodyHint: "[ ] 입력 시 체크박스, - 입력 시 글머리 기호",
        alarm: "알림", alarmOn: "켬", alarmOff: "끔", repeatLabel: "반복", time: "시간", date: "날짜",
        keepOnTop: "항상 위에 표시", color: "색상", stage: "진행 단계", more: "더 보기", done: "완료",
        repeatNames: [.never: "반복 안 함", .daily: "매일", .weekdays: "평일", .weekly: "매주"],
        stageNames: ["todo": "시작 전", "doing": "진행 중", "done": "완료"],
        colorNames: [.yellow: "노랑", .peach: "피치", .mint: "민트", .sky: "하늘", .lilac: "라일락", .graphite: "그래파이트"],
        addStage: "단계 추가", newStageName: "새 단계", removeStage: "삭제", moveUp: "위로", moveDown: "아래로",
        settings: "설정", general: "일반", appearance: "화면", notifications: "알림", about: "정보",
        language: "언어", theme: "테마", fontTheme: "글꼴 테마", themeDefault: "테마 기본값",
        appearanceMode: "화면 모드", auto: "자동", light: "라이트", dark: "다크",
        openAtLogin: "로그인 시 열기", alarmSound: "알림 소리", soundDefault: "기본", soundNone: "없음",
        openThemesFolder: "테마 폴더 열기", themesHint: "theme.json이 든 폴더를 테마 폴더에 넣고 설정을 다시 열면 나만의 테마가 추가됩니다.",
        openFontsFolder: "글꼴 폴더 열기", fontsHint: "글꼴 테마는 번들된 OFL 글꼴을 쓰고, 없으면 macOS 글꼴로 대체합니다.",
        fontThemeNames: ["system": "시스템", "plex": "플렉스", "rounded": "둥근 고딕", "hand": "손글씨", "serif": "명조", "mono": "고정폭"],
        showAllNotes: "모든 스티커 보이기", hideAllNotes: "모든 스티커 숨기기", version: "버전", viewSource: "GitHub에서 소스 보기",
        notifyPermission: "알림을 받으려면 시스템 설정에서 알림을 허용해 주세요.",
        progressFormat: "{total}개 중 {done}개 완료",
        edit: "편집", newNoteShortcut: "새 메모 단축키", preview: "미리보기", sampleTitle: "출시 체크리스트",
        sampleBody: "[x] 릴리스 노트 작성\n[ ] Homebrew cask 업데이트\n- 금요일 전에 배포하기"
    )

    static let ja = Strings(
        dashboard: "ダッシュボード", allNotes: "すべてのメモ", onDesktop: "デスクトップに表示中", withAlarm: "アラームあり",
        stages: "ステージ", colors: "カラー", newNote: "新規メモ", search: "メモを検索",
        board: "ボード", list: "リスト", openAsSticky: "付箋として開く", closeSticky: "付箋を閉じる", delete: "メモを削除",
        noNotes: "まだメモがありません", untitled: "無題", titlePlaceholder: "小見出し",
        bodyHint: "[ ] でチェックボックス、- で箇条書き",
        alarm: "アラーム", alarmOn: "オン", alarmOff: "オフ", repeatLabel: "繰り返し", time: "時刻", date: "日付",
        keepOnTop: "常に手前に表示", color: "カラー", stage: "ステージ", more: "その他", done: "完了",
        repeatNames: [.never: "なし", .daily: "毎日", .weekdays: "平日", .weekly: "毎週"],
        stageNames: ["todo": "未着手", "doing": "進行中", "done": "完了"],
        colorNames: [.yellow: "イエロー", .peach: "ピーチ", .mint: "ミント", .sky: "スカイ", .lilac: "ライラック", .graphite: "グラファイト"],
        addStage: "ステージを追加", newStageName: "新しいステージ", removeStage: "削除", moveUp: "上へ", moveDown: "下へ",
        settings: "設定", general: "一般", appearance: "外観", notifications: "通知", about: "情報",
        language: "言語", theme: "テーマ", fontTheme: "フォントテーマ", themeDefault: "テーマの既定",
        appearanceMode: "外観モード", auto: "自動", light: "ライト", dark: "ダーク",
        openAtLogin: "ログイン時に開く", alarmSound: "アラーム音", soundDefault: "デフォルト", soundNone: "なし",
        openThemesFolder: "テーマフォルダを開く", themesHint: "theme.json を含むフォルダをテーマフォルダに入れて設定を開き直すと、独自のテーマを追加できます。",
        openFontsFolder: "フォントフォルダを開く", fontsHint: "フォントテーマは同梱のOFLフォントを使い、ない場合はmacOSのフォントで代用します。",
        fontThemeNames: ["system": "システム", "plex": "Plex", "rounded": "丸ゴシック", "hand": "手書き", "serif": "明朝", "mono": "等幅"],
        showAllNotes: "すべての付箋を表示", hideAllNotes: "すべての付箋を隠す", version: "バージョン", viewSource: "GitHubでソースを見る",
        notifyPermission: "アラームを受け取るには、システム設定で通知を許可してください。",
        progressFormat: "{total}件中{done}件完了",
        edit: "編集", newNoteShortcut: "新規メモのショートカット", preview: "プレビュー", sampleTitle: "リリースチェックリスト",
        sampleBody: "[x] リリースノートを書く\n[ ] Homebrew caskを更新\n- 金曜日までに出す"
    )
}
