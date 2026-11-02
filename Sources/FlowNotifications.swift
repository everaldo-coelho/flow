import SwiftUI
import UserNotifications

enum FlowNoticeWords {
    static func text(_ key: String) -> String {
        let words: [String: String] = [
            "Notifications": "Notificações", "Enable notifications": "Ativar notificações",
            "Task reminders": "Lembretes de tarefas", "Habit and ritual reminders": "Lembretes de hábitos e rituais",
            "Focus finished": "Fim do foco", "Notification sounds": "Sons das notificações",
            "Flexible reminder times": "Horários para períodos flexíveis", "No-time reminders": "Lembretes sem horário",
            "Reminder preferences live in You. Flexible periods use your chosen reminder times.": "Configure as notificações em Você. Períodos flexíveis usam os horários que você escolher.",
            "One gentle reminder per occurrence. No overdue alerts or repeated nudges.": "Um lembrete gentil por ocorrência. Sem alertas de atraso ou cobranças repetidas.",
            "Ready when you are": "Quando fizer sentido para você", "Your focus time is complete. Take a breath and choose your next step.": "Seu tempo de foco terminou. Respire e escolha seu próximo passo.",
            "System permission is off. You can continue using FLOW without notifications.": "A permissão do sistema está desativada. Você pode continuar usando FLOW sem notificações.",
            "Notifications are enabled.": "As notificações estão ativadas.", "Check permission": "Conferir permissão",
            "Notifications are optional. macOS asks for permission when you enable them.": "As notificações são opcionais. O macOS pede permissão quando você as ativa."]
        return FlowLanguageSettings.shared.code == "pt-BR" ? (words[key] ?? key) : key
    }
}

struct FlowNoticePreferences: Codable {
    var enabled: Bool? = nil
    var tasks: Bool? = nil
    var habits: Bool? = nil
    var focus: Bool? = nil
    var sound: Bool? = nil
    var morning: Int? = nil
    var afternoon: Int? = nil
    var evening: Int? = nil
    var anytime: Int? = nil
}

@MainActor final class FlowNotifications: ObservableObject {
    static let shared = FlowNotifications()
    @Published var preferences = LampStore.load(FlowNoticePreferences.self, from: "notification-preferences") ?? FlowNoticePreferences() {
        didSet { LampStore.save(preferences, to: "notification-preferences"); schedule() }
    }
    @Published var allowed = false
    @Published var denied = false
    @Published var requesting = false
    private var items: [FlowItem] = []
    private var focus = FocusState()
    private var quietUntil: Date?
    private struct Notice: Equatable {
        var title: String
        var body: String
        var date: Date
        var sound: Bool
    }
    private var planned: [String: Notice] = [:]
    private var scheduleTask: Task<Void, Never>?
    private var savedIDs = Set(LampStore.load([String].self, from: "flow-notification-ids") ?? [])
    func enable(_ value: Bool) async {
        if !value { preferences.enabled = false; return }
        requesting = true
        defer { requesting = false }
        do {
            allowed = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
            denied = !allowed
            preferences.enabled = allowed
        } catch { allowed = false; denied = true; preferences.enabled = false; print("FLOW notification permission: \(error.localizedDescription)") }
    }
    func refresh() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        allowed = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
        denied = settings.authorizationStatus == .denied
        schedule()
    }
    func update(items: [FlowItem], focus: FocusState, quietUntil: Date?) {
        self.items = items; self.focus = focus; self.quietUntil = quietUntil
        schedule()
    }
    private func minute(_ period: String) -> Int {
        switch period {
        case "Morning": return preferences.morning ?? 540
        case "Afternoon": return preferences.afternoon ?? 840
        case "Evening": return preferences.evening ?? 1140
        default: return preferences.anytime ?? 600
        }
    }
    private func schedule() {
        scheduleTask?.cancel()
        scheduleTask = Task { @MainActor [weak self] in
            do { try await Task.sleep(for: .milliseconds(200)) } catch { return }
            self?.performSchedule()
        }
    }
    private func performSchedule() {
        let now = Date(), calendar = Calendar.current
        var candidates: [String: Notice] = [:]
        let sound = preferences.sound == true
        if preferences.enabled == true && allowed {
            for item in items where item.kind != "Project" && item.done != true && item.example != true && item.reminderEnabled == true && item.paused != true {
                let habit = item.kind == "Habit"
                guard habit ? preferences.habits != false : preferences.tasks != false else { continue }
                let period = item.schedulePeriod ?? (habit || item.due == nil ? "Any time" : "Exact time")
                let base = habit ? max(calendar.startOfDay(for: item.due ?? now), calendar.startOfDay(for: now)) : calendar.startOfDay(for: item.due ?? now)
                let count = habit ? 366 : 1
                var queued = 0
                for occurrence in 0..<count {
                    if queued >= 28 { break }
                    guard let day = calendar.date(byAdding: .day, value: occurrence, to: base) else { continue }
                    if habit && !FlowRecurrence.matches(day, item: item) { continue }
                    let exact = calendar.dateComponents([.hour, .minute], from: item.due ?? now)
                    let time = period == "Exact time" ? (exact.hour ?? 9) * 60 + (exact.minute ?? 0) : minute(period)
                    guard var date = calendar.date(bySettingHour: time / 60, minute: time % 60, second: 0, of: day) else { continue }
                    if !habit && item.due == nil && date <= now { date = calendar.date(byAdding: .day, value: 1, to: date) ?? date }
                    guard date > now, date > (quietUntil ?? .distantPast) else { continue }
                    let id = "flow.task.\(item.id.uuidString).\(Int(date.timeIntervalSince1970))"
                    candidates[id] = Notice(title: item.title, body: FlowNoticeWords.text("Ready when you are") + (period == "Any time" || period == "Exact time" ? "" : " · " + FlowTiming.text(period)), date: date, sound: sound)
                    queued += 1
                }
            }
            if preferences.focus != false, let end = focus.end, end > now {
                candidates["flow.focus.end"] = Notice(title: FlowNoticeWords.text("Focus finished"), body: FlowNoticeWords.text("Your focus time is complete. Take a breath and choose your next step."), date: end, sound: sound && !FocusSound.shared.choices.muted)
            }
        }
        // Stay below the system pending-notification limit; refresh the horizon whenever FLOW is used.
        let next = Dictionary(uniqueKeysWithValues: candidates.sorted { $0.value.date < $1.value.date }.prefix(50).map { ($0.key, $0.value) })
        let previous = savedIDs.union(planned.keys)
        for id in previous where next[id] == nil {
            // Let an already-due banner arrive instead of racing the foreground timer.
            if let old = planned[id], old.date <= now, preferences.enabled == true { continue }
            LampNotifications.cancel(id)
        }
        for (id, notice) in next where planned[id] != notice {
            LampNotifications.send(notice.title, body: notice.body, sound: notice.sound, at: notice.date, id: id)
        }
        planned = next
        let nextIDs = Set(next.keys)
        if nextIDs != savedIDs {
            LampStore.save(Array(nextIDs), to: "flow-notification-ids")
            savedIDs = nextIDs
        }
    }
}

struct FlowNotificationSection: View {
    @ObservedObject private var notices = FlowNotifications.shared
    @ObservedObject private var language = FlowLanguageSettings.shared
    private func option(_ key: WritableKeyPath<FlowNoticePreferences, Bool?>, default fallback: Bool) -> Binding<Bool> {
        Binding(get: { notices.preferences[keyPath: key] ?? fallback }, set: { notices.preferences[keyPath: key] = $0 })
    }
    private func time(_ key: WritableKeyPath<FlowNoticePreferences, Int?>, fallback: Int) -> Binding<Date> {
        Binding(get: {
            let value = notices.preferences[keyPath: key] ?? fallback
            return Calendar.current.date(bySettingHour: value / 60, minute: value % 60, second: 0, of: Date()) ?? Date()
        }, set: {
            let parts = Calendar.current.dateComponents([.hour, .minute], from: $0)
            notices.preferences[keyPath: key] = (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
        })
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(FlowNoticeWords.text("Notifications")).font(.title2.bold())
            Text(FlowNoticeWords.text("Notifications are optional. macOS asks for permission when you enable them."))
                .foregroundStyle(.secondary)
            Toggle(FlowNoticeWords.text("Enable notifications"), isOn: Binding(get: { notices.preferences.enabled == true }, set: { value in Task { await notices.enable(value) } }))
                .disabled(notices.requesting)
            if notices.denied {
                Text(FlowNoticeWords.text("System permission is off. You can continue using FLOW without notifications.")).font(.flowCaption).foregroundStyle(.secondary)
                Button(FlowNoticeWords.text("Check permission")) { Task { await notices.refresh() } }
            }
            if notices.preferences.enabled == true {
                Toggle(FlowNoticeWords.text("Task reminders"), isOn: option(\.tasks, default: true))
                Toggle(FlowNoticeWords.text("Habit and ritual reminders"), isOn: option(\.habits, default: true))
                Toggle(FlowNoticeWords.text("Focus finished"), isOn: option(\.focus, default: true))
                Toggle(FlowNoticeWords.text("Notification sounds"), isOn: option(\.sound, default: false))
                Divider()
                Text(FlowNoticeWords.text("Flexible reminder times")).font(.headline)
                DatePicker(FlowTiming.text("Morning"), selection: time(\.morning, fallback: 540), displayedComponents: [.hourAndMinute])
                DatePicker(FlowTiming.text("Afternoon"), selection: time(\.afternoon, fallback: 840), displayedComponents: [.hourAndMinute])
                DatePicker(FlowTiming.text("Evening"), selection: time(\.evening, fallback: 1140), displayedComponents: [.hourAndMinute])
                DatePicker(FlowNoticeWords.text("No-time reminders"), selection: time(\.anytime, fallback: 600), displayedComponents: [.hourAndMinute])
            }
            Text(FlowNoticeWords.text("One gentle reminder per occurrence. No overdue alerts or repeated nudges.")).font(.flowCaption).foregroundStyle(.secondary)
        }.frame(maxWidth: .infinity, alignment: .leading).worldSurface()
            .task { await notices.refresh() }
    }
}
