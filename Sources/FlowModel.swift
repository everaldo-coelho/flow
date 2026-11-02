import SwiftUI
import Combine
struct FlowItem: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var created = Date()
    var step: String? = nil
    var minutes: Int? = nil
    var kind: String? = nil
    var done: Bool? = nil
    var example: Bool? = nil
    var due: Date? = nil
    var breadcrumb: String? = nil
    var captureSourceID: UUID? = nil
    var externalReminderID: String? = nil
    var relatedSources: [FlowSourceReference]? = nil
    var projectID: UUID? = nil
    var repeatDays: Int? = nil
    var weekdaysOnly: Bool? = nil
    var completionDates: [Date]? = nil
    var paused: Bool? = nil
    var todayDate: Date? = nil
    var completedAt: Date? = nil
    var schedulePeriod: String? = nil
    var reminderEnabled: Bool? = nil
    var repeatEvery: Int? = nil
    var repeatUnit: String? = nil
    var repeatWeekdays: [Int]? = nil
    var repeatAnchor: Date? = nil
    var parentTaskID: UUID? = nil
}
struct FocusState: Codable {
    var itemID: UUID? = nil
    var end: Date? = nil
    var remaining: Double = 300
    var length: Double = 300
}
@MainActor final class FlowModel: ObservableObject {
    @Published var items: [FlowItem] = []
    @Published var focus = FocusState() {
        didSet { FocusSound.shared.update(running: focus.end.map { $0 > Date() } ?? false) }
    }
    private var focusClock: AnyCancellable?
    @Published var focusPresentation = UUID()
    @Published var selectedID: UUID? = nil
    @Published var choosingAutomatically = false
    @Published var suggestedID: UUID?
    var recommendationRequest = UUID()
    @Published var capacity = 30 {
        didSet { RichCaptureModel.shared.availableMinutes = max(1, capacity) }
    }
    @Published var notice = ""
    @Published var quietUntil: Date? = nil
    let collection = LampStore.collection("intentions", of: FlowItem.self)
    init() {
        items = collection.all().sorted { $0.created < $1.created }
        // Preserve old notes as ordinary actions, with their IDs and content intact.
        for index in items.indices where ["Memory", "Idea", "Thought"].contains(items[index].kind ?? "") {
            items[index].kind = "Task"
            collection.put(items[index])
        }
        focus = LampStore.load(FocusState.self, from: "focus") ?? FocusState()
        // Expired sessions from a previous launch must not ring unexpectedly.
        if let end = focus.end, end <= Date() { focus.remaining = 0; focus.end = nil; saveFocus() }
        focusClock = Timer.publish(every: 0.25, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            guard let self, let end = self.focus.end, end <= Date() else { return }
            self.focus.remaining = 0
            self.focus.end = nil
            self.saveFocus()
            FocusSound.shared.finished()
        }
        selectedID = LampStore.load(Optional<UUID>.self, from: "selected") ?? nil
        quietUntil = LampStore.load(Optional<Date>.self, from: "quietUntil") ?? nil
        FocusSound.shared.update(running: focus.end.map { $0 > Date() } ?? false)
        if LampStore.load(Bool.self, from: "welcomed") != true {
            items = FlowExampleData.items()
            items.forEach { collection.put($0) }
            LampStore.save(true, to: "welcomed")
        }
    }
    var tasks: [FlowItem] {
        items.filter { item in
            guard item.done != true, item.kind != "Project" else { return false }
            if isToday(item) { return true }
            if item.kind == "Habit" {
                return item.paused != true && (item.due == nil || Calendar.current.startOfDay(for: item.due!) <= Calendar.current.startOfDay(for: Date()))
                    && FlowRecurrence.matches(Date(), item: item)
            }
            return item.kind == "Task" || item.kind == nil || item.id == focus.itemID
        }
    }
    func toggleExamples() {
        let archive = LampStore.collection("removed-examples", of: FlowItem.self)
        let examples = items.filter { $0.example == true }
        if !examples.isEmpty {
            archive.all().forEach { archive.delete($0.id) }
            examples.forEach { archive.put($0); delete($0) }
            notice = "The examples are cleared. This space is yours."
        } else {
            let saved = archive.all()
            let restored = saved.isEmpty ? FlowExampleData.items() : saved
            for example in restored where !items.contains(where: { $0.id == example.id }) { put(example) }
            notice = "Example content restored."
        }
    }
    var current: FlowItem? {
        tasks.first { $0.id == selectedID && ($0.minutes ?? Int.max) <= capacity }
    }
    var next: FlowItem? { tasks.first { $0.id != current?.id } }
    func chooseAutomatically() {
        guard !choosingAutomatically else { return }
        choosingAutomatically = true
        Task { await suggestForAvailableTime(); choosingAutomatically = false }
    }
    func isToday(_ item: FlowItem) -> Bool { item.todayDate.map { Calendar.current.isDateInToday($0) } ?? false }
    var todayItems: [FlowItem] { items.filter { $0.kind != "Project" && $0.done != true && isToday($0) }.sorted { $0.created < $1.created } }
    func toggleToday(_ item: FlowItem) {
        guard var copy = items.first(where: { $0.id == item.id }), copy.kind != "Project" else { return }
        copy.todayDate = isToday(copy) ? nil : Date()
        if copy.todayDate != nil { copy.done = false }
        put(copy)
    }
    func put(_ item: FlowItem, suggestBreakdown: Bool = true) {
        let old = items.first { $0.id == item.id }
        var saved = item
        if ["Memory", "Idea", "Thought"].contains(saved.kind ?? "") { saved.kind = "Task" }
        let newlyDone = saved.done == true && old?.done != true
        if newlyDone { saved.completedAt = Date() }
        collection.put(saved)
        if let i = items.firstIndex(where: { $0.id == saved.id }) { items[i] = saved } else { items.append(saved) }
        let project = items.first { $0.id == saved.projectID }?.title
        if newlyDone { VictoryStore.shared.record(saved, date: saved.completedAt, project: project, celebrate: true) }
        if saved.kind == "Habit" {
            for date in saved.completionDates ?? [] where !(old?.completionDates ?? []).contains(date) {
                VictoryStore.shared.record(saved, date: date, project: project, celebrate: true)
            }
        }
        if suggestBreakdown, saved.example != true, saved.kind != "Project", saved.done != true,
           (saved.minutes ?? 0) > 60, (old?.minutes ?? 0) <= 60 {
            let id = saved.id
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(700))
                if let latest = self.items.first(where: { $0.id == id && $0.done != true }) {
                    FlowTaskActions.makeSmaller(latest)
                }
            }
        }
    }
    @discardableResult func capture(_ text: String, kind: String = "Task") -> FlowItem? {
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines); guard !clean.isEmpty else { return nil }
        let item = FlowItem(title: clean, kind: kind); put(item); notice = "Safely remembered. You can let that thought go."; return item
    }
    func choose(_ item: FlowItem) { suggestedID = nil; selectedID = item.id; LampStore.save(item.id, to: "selected") }
    func canCompleteHabit(_ item: FlowItem) -> Bool {
        isToday(item) || (item.paused != true && (item.due == nil || Calendar.current.startOfDay(for: item.due!) <= Calendar.current.startOfDay(for: Date())))
    }
    func complete(_ item: FlowItem) {
        guard var copy = items.first(where: { $0.id == item.id }), copy.done != true else { return }
        if copy.kind == "Habit" {
            guard canCompleteHabit(copy) else { return }
            let calendar = Calendar.current
            copy.repeatAnchor = copy.repeatAnchor ?? copy.due ?? copy.created
            var next = FlowRecurrence.next(after: Date(), item: copy)
            copy.completionDates = (copy.completionDates ?? []) + [Date()]
            if copy.schedulePeriod == "Exact time", let due = copy.due {
                let time = calendar.dateComponents([.hour, .minute], from: due)
                next = calendar.date(bySettingHour: time.hour ?? 9, minute: time.minute ?? 0, second: 0, of: next) ?? next
            }
            copy.due = next
            copy.done = false
            notice = "A little habit, gently kept. It will return when it’s time."
        } else {
            copy.done = true
            notice = "That’s one less thing to carry. Nice work."
        }
        copy.todayDate = nil
        put(copy)
        if focus.itemID == item.id { focus = FocusState(); saveFocus() }
    }
    func delete(_ item: FlowItem) {
        for var child in items.filter({ $0.parentTaskID == item.id }) { child.parentTaskID = nil; put(child) }
        if item.kind == "Project" {
            for var child in items.filter({ $0.projectID == item.id }) { child.projectID = nil; put(child) }
        }
        collection.delete(item.id); items.removeAll { $0.id == item.id }
        if selectedID == item.id { selectedID = nil; LampStore.save(Optional<UUID>.none, to: "selected") }
        if focus.itemID == item.id { focus = FocusState(); saveFocus() }
    }
    func saveFocus() { LampStore.save(focus, to: "focus") }
    func seconds(at date: Date = .now) -> Double { max(0, focus.end?.timeIntervalSince(date) ?? focus.remaining) }
    func start(_ item: FlowItem, minutes: Int = 5) { choose(item); focus = FocusState(itemID: item.id, end: Date().addingTimeInterval(Double(minutes * 60)), remaining: Double(minutes * 60), length: Double(minutes * 60)); saveFocus(); focusPresentation = UUID() }
    func openFocus(_ item: FlowItem, minutes: Int? = nil) {
        print("FLOW focus: focus button activated")
        guard item.kind != "Project" else { return }
        choose(item)
        if focus.itemID != item.id || seconds() <= 0 {
            let estimate = item.minutes.flatMap { $0 > 0 ? $0 : nil }
            let duration = Double(min(240, max(1, minutes ?? estimate ?? FlowPreferences.shared.defaultFocusMinutes)) * 60)
            focus = FocusState(itemID: item.id, remaining: duration, length: duration)
        }
        if focus.end == nil { resume() }
        saveFocus(); focusPresentation = UUID()
    }
    func setFocusMinutes(_ minutes: Int) {
        let duration = Double(min(240, max(1, minutes)) * 60)
        focus.remaining = duration; focus.length = duration; focus.end = nil; saveFocus()
    }
    func pause() { focus.remaining = seconds(); focus.end = nil; saveFocus() }
    func resume() { focus.end = Date().addingTimeInterval(focus.remaining); saveFocus() }
    func park(_ text: String) { guard let id = focus.itemID, var item = items.first(where: { $0.id == id }) else { return }; item.breadcrumb = text; put(item); pause() }
}
struct FlowSection<Content: View>: View {
    @ObservedObject var appLanguage = FlowLanguageSettings.shared
    var title: String
    @ViewBuilder var content: () -> Content
    var body: some View { VStack(alignment: .leading, spacing: 18) { Text(FlowL.text(title)).font(.system(.caption, design: .rounded).weight(.bold)).tracking(1.5).foregroundStyle(Color.accentColor); content() }.frame(maxWidth: .infinity, alignment: .leading).worldSurface() }
}
struct FlowButton: View {
    @ObservedObject var appLanguage = FlowLanguageSettings.shared
    var title: String
    var symbol = "arrow.right"
    var action: () -> Void
    var body: some View { Button(action: action) { Label(FlowL.text(title), systemImage: symbol) }.buttonStyle(FlowGlassButtonStyle(prominent: true)) }
}
