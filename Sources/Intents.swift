import AppIntents
struct CaptureThoughtIntent: AppIntent {
    static let title: LocalizedStringResource = "Capture task"
    static let description = IntentDescription("Add a task to FLOW.")
    @Parameter(title: "Task title") var thought: String
    @MainActor func perform() async throws -> some IntentResult & ProvidesDialog {
        let value = thought.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return .result(dialog: "Enter a task title first.") }
        LampStore.collection("intentions", of: FlowItem.self).put(FlowItem(title: value, kind: "Task"))
        NotificationCenter.default.post(name: .flowRefresh, object: nil)
        return .result(dialog: "Task saved in FLOW.")
    }
}
struct FlowShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: CaptureThoughtIntent(), phrases: ["Capture a task in \(.applicationName)"], shortTitle: "Capture task", systemImageName: "plus.circle")
    }
}
extension Notification.Name {
    static let flowCapture = Notification.Name("flow.capture")
    static let flowRefresh = Notification.Name("flow.refresh")
}
