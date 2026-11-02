import SwiftUI
#if os(macOS)
import AppKit
#endif

// Immutable completion snapshots survive changes to, or deletion of, the original.
struct FlowVictory: Codable, Identifiable {
    var id: String
    var title: String
    var kind: String
    var date: Date?
    var project: String?
    var special: Bool?
    var note: String?
    var sourceID: UUID?
}
struct CelebrationChoices: Codable {
    var reduceAnimation = false
    var sound = false
    var mutePraise = false
    var keepsakes = false
    var selectedKeepsake: String? = nil
}
@MainActor final class VictoryStore: ObservableObject {
    static let shared = VictoryStore()
    private let collection = LampStore.collection("completion-history", of: FlowVictory.self)
    @Published private(set) var entries: [FlowVictory] = []
    @Published var choices: CelebrationChoices {
        didSet { LampStore.save(choices, to: "celebration-choices") }
    }
    @Published var celebration: FlowVictory?
    private init() {
        choices = LampStore.load(CelebrationChoices.self, from: "celebration-choices") ?? CelebrationChoices()
        entries = collection.all()
    }
    func resetForFreshStart() {
        entries.forEach { collection.delete($0.id) }
        entries = []; celebration = nil; choices = CelebrationChoices()
    }
    func save(_ entry: FlowVictory) {
        collection.put(entry)
        if let i = entries.firstIndex(where: { $0.id == entry.id }) { entries[i] = entry }
        else { entries.append(entry) }
    }
    func reconcile(_ items: [FlowItem]) {
        for item in items where item.example != true {
            let project = items.first { $0.id == item.projectID }?.title
            if item.kind == "Habit" {
                for date in item.completionDates ?? [] { record(item, date: date, project: project, celebrate: false) }
            } else if item.done == true {
                record(item, date: item.completedAt, project: project, celebrate: false)
            }
        }
    }
    func record(_ item: FlowItem, date: Date?, project: String?, celebrate: Bool) {
        guard item.example != true else { return }
        let kind = item.kind == "Project" ? "Project" : item.kind == "Habit" ? "Habit" : "Task"
        let suffix = kind == "Habit" ? "-\(date?.timeIntervalSince1970 ?? 0)" : ""
        let id = item.id.uuidString + suffix
        guard !entries.contains(where: { $0.id == id }) else { return }
        let entry = FlowVictory(id: id, title: item.title, kind: kind, date: date, project: project, sourceID: item.id)
        save(entry)
        if celebrate && !choices.mutePraise && ([1, 5, 10, 25, 50, 100].contains(entries.count) || kind == "Project") {
            celebration = entry
            if choices.sound && !choices.mutePraise { FocusSound.shared.playBell() }
        }
    }
    func markSpecial(_ entry: FlowVictory) {
        var copy = entry
        copy.special = entry.special != true
        save(copy)
    }
    var rewards: [(String, String, String, Bool)] {
        [("sparkle", "First step", "One genuine victory", !entries.isEmpty),
         ("leaf", "Growing gently", "Five habit occurrences", entries.filter { $0.kind == "Habit" }.count >= 5),
         ("flag", "A chapter complete", "One finished project", entries.contains { $0.kind == "Project" }),
         ("heart", "Worth remembering", "One personal milestone", entries.contains { $0.kind == "Milestone" })]
    }
}

struct VictoryCelebration: View {
    @ObservedObject private var history = VictoryStore.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        Group {
            if let event = history.celebration, !history.choices.mutePraise {
                HStack(spacing: 12) {
                    PipPortrait(still: history.choices.reduceAnimation).frame(width: 48, height: 56)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(FlowL.text(event.kind == "Project" ? "That was a big one. You did it!" : event.kind == "Milestone" ? "A moment worth keeping." : event.kind == "Habit" ? "You made room for your habit." : history.entries.count == 1 ? "One more thing off your mind." : "Small steps. Real progress.")).font(.headline)
                        Text(event.title).font(.flowCallout).lineLimit(2)
                    }
                    Button { history.celebration = nil } label: { Image(systemName: "xmark") }
                        .buttonStyle(.plain).help(FlowL.text("Dismiss celebration"))
                        .accessibilityLabel(FlowL.text("Dismiss celebration"))
                }.padding(14).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.accentColor.opacity(0.35)))
                    .padding().frame(maxWidth: 440)
                    .task(id: event.id) {
                        try? await Task.sleep(for: .seconds(6))
                        if history.celebration?.id == event.id { history.celebration = nil }
                    }
            }
        }.onChange(of: history.choices.mutePraise) { _, muted in if muted { history.celebration = nil } }
    }
}
