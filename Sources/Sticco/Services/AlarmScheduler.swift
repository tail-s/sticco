import Foundation
import Combine
import UserNotifications

/// Mirrors every note's alarm into UNUserNotificationCenter. Requests are rebuilt from the store on each change.
@MainActor
final class AlarmScheduler: NSObject, UNUserNotificationCenterDelegate {
    static let shared = AlarmScheduler()
    private var bag = Set<AnyCancellable>()
    private let prefix = "sticco.alarm."

    /// Notifications need a real app bundle; `swift run` has none.
    private var center: UNUserNotificationCenter? {
        Bundle.main.bundleIdentifier == nil ? nil : UNUserNotificationCenter.current()
    }

    func start() {
        center?.delegate = self
        NoteStore.shared.$notes
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .sink { [weak self] notes in self?.sync(notes) }
            .store(in: &bag)
    }

    func requestAuthorization() {
        center?.requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func sync(_ notes: [Note]) {
        guard let center else { return }
        if notes.contains(where: { $0.alarm.isOn }) { requestAuthorization() }
        let prefix = self.prefix
        let requests = notes.filter { $0.alarm.isOn }.flatMap(makeRequests)
        center.getPendingNotificationRequests { pending in
            let stale = pending.map(\.identifier).filter { $0.hasPrefix(prefix) }
            center.removePendingNotificationRequests(withIdentifiers: stale)
            for r in requests { center.add(r) }
        }
    }

    private func makeRequests(_ note: Note) -> [UNNotificationRequest] {
        let s = AppSettings.shared.strings
        let content = UNMutableNotificationContent()
        content.title = note.title.isEmpty ? s.untitled : note.title
        content.body = note.lines.map(\.text).filter { !$0.isEmpty }.prefix(3).joined(separator: "\n")
        content.sound = AppSettings.shared.alarmSound ? .default : nil
        content.userInfo = ["noteID": note.id.uuidString]
        content.threadIdentifier = note.id.uuidString

        let cal = Calendar.current
        let hm = cal.dateComponents([.hour, .minute], from: note.alarm.date)
        var triggers: [UNCalendarNotificationTrigger] = []
        switch note.alarm.repeatRule {
        case .never:
            guard note.alarm.date > Date() else { return [] }
            let c = cal.dateComponents([.year, .month, .day, .hour, .minute], from: note.alarm.date)
            triggers = [UNCalendarNotificationTrigger(dateMatching: c, repeats: false)]
        case .daily:
            triggers = [UNCalendarNotificationTrigger(dateMatching: hm, repeats: true)]
        case .weekdays:
            triggers = (2...6).map { day in
                var c = hm; c.weekday = day
                return UNCalendarNotificationTrigger(dateMatching: c, repeats: true)
            }
        case .weekly:
            var c = hm; c.weekday = cal.component(.weekday, from: note.alarm.date)
            triggers = [UNCalendarNotificationTrigger(dateMatching: c, repeats: true)]
        }
        return triggers.enumerated().map { i, t in
            UNNotificationRequest(identifier: "\(prefix)\(note.id.uuidString).\(i)", content: content, trigger: t)
        }
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
                                            withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .list])
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
                                            withCompletionHandler completionHandler: @escaping () -> Void) {
        let idString = response.notification.request.content.userInfo["noteID"] as? String
        Task { @MainActor in
            if let idString, let id = UUID(uuidString: idString) { NoteWindowManager.shared.open(id) }
        }
        completionHandler()
    }
}
