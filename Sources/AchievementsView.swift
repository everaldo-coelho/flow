import SwiftUI

struct AchievementsView: View {
    @ObservedObject var model: FlowModel
    @ObservedObject private var language = FlowLanguageSettings.shared
    @ObservedObject private var history = VictoryStore.shared
    @Environment(\.compactFlow) private var compact
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @SceneStorage("victories-period") private var period = "All time"
    @SceneStorage("victories-kind") private var kind = "All"
    @State private var editing: FlowVictory?
    @State private var search = ""
    private var showingExamples: Bool { history.entries.isEmpty && model.items.contains { $0.example == true } }
    private var displayedEntries: [FlowVictory] {
        guard showingExamples else { return history.entries }
        return model.items.filter { $0.example == true }.flatMap { item -> [FlowVictory] in
            let dates: [Date] = item.kind == "Habit" ? (item.completionDates ?? []) : item.done == true ? [item.completedAt ?? item.created] : []
            return dates.enumerated().map { index, date in
                FlowVictory(id: "example-" + item.id.uuidString + "-\(index)", title: item.title, kind: item.kind ?? "Task", date: date, special: item.kind == "Project", sourceID: item.id)
            }
        }
    }
    private var periodEntries: [FlowVictory] {
        guard period != "All time" else { return displayedEntries }
        let unit: Calendar.Component = period == "This week" ? .weekOfYear : .month
        let interval = Calendar.current.dateInterval(of: unit, for: Date())
        return displayedEntries.filter { entry in entry.date.map { interval?.contains($0) == true } ?? false }
    }
    private var visible: [FlowVictory] {
        periodEntries.filter {
            (kind == "All" || $0.kind == kind) && (search.isEmpty || [$0.title, $0.note ?? "", $0.project ?? ""].joined(separator: " ").localizedCaseInsensitiveContains(search))
        }.sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }
    }
    private var headline: String {
        let today = history.entries.filter { $0.date.map { Calendar.current.isDateInToday($0) } ?? false }
        if today.contains(where: { $0.kind == "Project" }) { return "That was a big one. You did it!" }
        if today.count >= 3 { return "Look at everything you made happen!" }
        return today.isEmpty ? "Your past progress is still yours." : "One more thing off your mind."
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                hero
                if showingExamples {
                    Text(language.code == "pt-BR" ? "Demonstração · Estes exemplos não contam como suas conquistas. Sua primeira conquista real substitui esta prévia." : language.code == "es" ? "Demostración · Estos ejemplos no cuentan como tus logros. Tu primer logro real sustituye esta vista previa." : "Demonstration · These examples do not count as your achievements. Your first real victory replaces this preview.")
                        .font(.flowCallout).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .leading).worldSurface()
                }
                periodPicker
                statistics
                moments
                timeline
                keepsakes
            }.padding(compact ? 16 : 28).frame(maxWidth: 960).frame(maxWidth: .infinity)
        }
        .task { history.reconcile(model.items) }
        .sheet(item: $editing) { entry in FlowStyledRoot { VictoryEditor(entry: entry).background { WorldBackdrop() } } }
    }
    private var hero: some View {
        HStack(spacing: compact ? 8 : 24) {
            VStack(alignment: .leading, spacing: 14) {
                Label(FlowL.text("Achievements"), systemImage: "trophy").font(.flowCaption.weight(.semibold)).foregroundStyle(Color.accentColor)
                Text(FlowL.text(history.entries.isEmpty ? "Every journey starts somewhere." : history.choices.mutePraise ? "Look how far you’ve come." : headline))
                    .font(.system(compact ? .title2 : .largeTitle, design: .rounded, weight: .bold)).fixedSize(horizontal: false, vertical: true)
                Text(FlowL.text(history.entries.isEmpty ? "Your victories will live here." : history.choices.mutePraise ? "Your victories" : "Small steps. Real progress.")).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            VStack(spacing: 6) {
                VictoryPortrait(still: history.choices.reduceAnimation).frame(width: compact ? 88 : 146, height: compact ? 110 : 164)
                if history.choices.keepsakes,
                   let chosen = history.rewards.first(where: { $0.0 == history.choices.selectedKeepsake && $0.3 }) {
                    Label(FlowL.text(chosen.1), systemImage: chosen.0).font(.flowCaption).foregroundStyle(Color.accentColor)
                }
            }
        }.frame(maxWidth: .infinity, alignment: .leading).worldSurface()
    }
    private var periodPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(language.code == "pt-BR" ? "Período" : language.code == "es" ? "Periodo" : "Period")
                .font(.flowCallout).foregroundStyle(.secondary).fixedSize()
            FlowPillTabs(title: FlowL.text("Perspective"),
                values: ["This week", "This month", "All time"],
                labels: ["This week", "This month", "All time"].map { FlowL.text($0) }, selection: $period)
        }.frame(maxWidth: 350, alignment: .leading)
    }
    private var statistics: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), alignment: .topLeading), count: compact ? 2 : 4), alignment: .leading, spacing: 12) {
            ForEach(["Task", "Project", "Habit", "Milestone"], id: \.self) { type in
                VStack(alignment: .leading, spacing: 9) {
                    Image(systemName: symbol(type)).foregroundStyle(Color.accentColor)
                    Text(String(periodEntries.filter { $0.kind == type }.count)).font(.system(.title, design: .rounded, weight: .semibold)).monospacedDigit()
                    Text(FlowL.text(statTitle(type))).font(.flowCaption).foregroundStyle(.secondary)
                }.frame(maxWidth: .infinity, minHeight: 122, alignment: .topLeading).padding(16).background { FlowGlassPanel(radius: 16) }
            }
        }
    }
    private var moments: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(FlowL.text("Moments worth remembering")).font(.title2.bold())
            Text(FlowL.text("The moments that matter to you.")).foregroundStyle(.secondary)
            let special = periodEntries.filter { $0.special == true }.sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }
            if special.isEmpty {
                Text(FlowL.text("Mark as special")).font(.flowCallout).foregroundStyle(.secondary)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 220))], alignment: .leading, spacing: 12) {
                    ForEach(special) { entry in
                        Button { editing = entry } label: {
                            VStack(alignment: .leading, spacing: 10) {
                                Image(systemName: "star.fill").foregroundStyle(Color.accentColor)
                                Text(entry.title).font(.headline)
                                if let note = entry.note, !note.isEmpty { Text(note).font(.flowCallout).foregroundStyle(.secondary).lineLimit(4) }
                                Text(dateLabel(entry)).font(.flowCaption).foregroundStyle(.secondary)
                            }.frame(maxWidth: .infinity, alignment: .leading).padding(18).background { FlowGlassPanel(radius: 18) }
                        }.buttonStyle(.plain).disabled(showingExamples).help(FlowL.text("Edit personal note"))
                    }
                }
            }
        }.frame(maxWidth: .infinity, alignment: .leading).worldSurface()
    }
    private var timeline: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(FlowL.text("Your victories")).font(.title2.bold())
            HStack {
                TextField(FlowL.text("Search victories"), text: $search).flowInput()
                Picker(FlowL.text("Activity"), selection: $kind) {
                    Text(FlowL.text("All")).tag("All")
                    ForEach(["Task", "Project", "Habit", "Milestone"], id: \.self) { Text(FlowL.text(statTitle($0))).tag($0) }
                }.labelsHidden().frame(width: 130)
            }
            if visible.isEmpty {
                ContentUnavailableView(FlowL.text(history.entries.isEmpty ? "Every journey starts somewhere." : "Nothing in this view yet"), systemImage: "sparkles", description: Text(FlowL.text("Everything you’ve accomplished still counts.")))
            } else {
                LazyVStack(alignment: .leading, spacing: 20) {
                    ForEach(["Today", "Yesterday", "This week", "Earlier", "Date not recorded"], id: \.self) { group in
                        let entries = visible.filter { bucket($0) == group }
                        if !entries.isEmpty {
                            VStack(alignment: .leading, spacing: 0) {
                                Text(FlowL.text(group)).font(.headline).foregroundStyle(.secondary).padding(.bottom, 12)
                                ForEach(entries) { entry in victoryRow(entry); Divider().opacity(0.4) }
                            }
                        }
                    }
                }
            }
            if history.entries.contains(where: { $0.date == nil }) {
                Text(FlowL.text("Older completed items without a saved date appear in All time. Their completion dates are not guessed.")).font(.flowCaption).foregroundStyle(.secondary)
            }
            if model.items.contains(where: { $0.example == true && $0.done == true }) {
                Text(FlowL.text("Demonstration tasks are excluded from your victories.")).font(.flowCaption).foregroundStyle(.secondary)
            }
        }.frame(maxWidth: .infinity, alignment: .leading).worldSurface()
    }
    private func victoryRow(_ entry: FlowVictory) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol(entry.kind)).foregroundStyle(Color.accentColor).frame(width: 24).padding(.top, 3)
            VStack(alignment: .leading, spacing: 5) {
                Text(entry.title).font(.headline).textSelection(.enabled)
                Text([FlowL.text(entry.kind), entry.project, dateLabel(entry)].compactMap { $0 }.joined(separator: " · ")).font(.flowCaption).foregroundStyle(.secondary)
                if let note = entry.note, !note.isEmpty { Text(note).font(.flowCallout).foregroundStyle(.secondary) }
                if let sourceID = entry.sourceID, model.items.contains(where: { $0.id == sourceID }) {
                    Button(FlowL.text("View task")) {
                        NotificationCenter.default.post(name: Notification.Name("flow.openTask"), object: sourceID)
                    }.buttonStyle(FlowGlassButtonStyle())
                }
            }
            Spacer(minLength: 4)
            if !showingExamples {
            Button { history.markSpecial(entry) } label: { Image(systemName: entry.special == true ? "star.fill" : "star") }
                .buttonStyle(FlowGlassButtonStyle()).help(FlowL.text(entry.special == true ? "Remove from special moments" : "Mark as special"))
                .accessibilityLabel(FlowL.text("Mark as special") + ": " + entry.title)
            Button { editing = entry } label: { Image(systemName: "square.and.pencil") }
                .buttonStyle(FlowGlassButtonStyle()).help(FlowL.text("Edit personal note"))
                .accessibilityLabel(FlowL.text("Edit personal note") + ": " + entry.title)
            }
        }.padding(.vertical, 14)
    }
    @ViewBuilder private var keepsakes: some View {
        if history.choices.keepsakes {
        VStack(alignment: .leading, spacing: 14) {
            Text(FlowL.text("Companion keepsakes")).font(.title2.bold())
                Text(FlowL.text("Small reminders, never points. Choose an unlocked keepsake to display beside your companion.")).font(.flowCallout).foregroundStyle(.secondary)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 190))], spacing: 12) {
                    ForEach(history.rewards, id: \.0) { reward in
                        Button {
                            history.choices.selectedKeepsake = history.choices.selectedKeepsake == reward.0 ? nil : reward.0
                        } label: {
                            VStack(alignment: .leading, spacing: 9) {
                                Image(systemName: reward.3 ? reward.0 : "lock").font(.title2)
                                Text(FlowL.text(reward.1)).font(.headline)
                                Text(FlowL.text(reward.2)).font(.flowCaption)
                                if history.choices.selectedKeepsake == reward.0 { Label(FlowL.text("Selected"), systemImage: "checkmark") }
                            }.frame(maxWidth: .infinity, alignment: .leading).padding(16).background { FlowGlassPanel(radius: 16) }
                        }.buttonStyle(.plain).disabled(!reward.3).opacity(reward.3 ? 1 : 0.55)
                    }
                }
        }.frame(maxWidth: .infinity, alignment: .leading).worldSurface()
        }
    }
    private func symbol(_ kind: String) -> String { kind == "Project" ? "folder.fill" : kind == "Habit" ? "leaf" : kind == "Milestone" ? "star" : "checkmark.circle" }
    private func statTitle(_ kind: String) -> String { kind == "Project" ? "Projects finished" : kind == "Habit" ? "Habit occurrences completed" : kind == "Milestone" ? "Personal milestones" : "Tasks completed" }
    private func dateLabel(_ entry: FlowVictory) -> String { entry.date?.formatted(date: .abbreviated, time: .omitted) ?? FlowL.text("Date not recorded") }
    private func bucket(_ entry: FlowVictory) -> String {
        guard let date = entry.date else { return "Date not recorded" }
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }
        if calendar.dateInterval(of: .weekOfYear, for: Date())?.contains(date) == true { return "This week" }
        return "Earlier"
    }
}

struct VictoryEditor: View {
    var entry: FlowVictory
    @Environment(\.dismiss) private var dismiss
    @State private var note = ""
    @State private var special = true
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(FlowL.text("Edit personal note")).font(.title2.bold())
            Text(entry.title).font(.headline)
            Text(FlowL.text("Personal note (optional)")).font(.flowCallout)
            TextEditor(text: $note).flowInput(multiline: true)
            Toggle(FlowL.text("Moments worth remembering"), isOn: $special)
            HStack {
                Button(FlowL.text("Cancel")) { dismiss() }.keyboardShortcut(.cancelAction)
                Spacer()
                Button(FlowL.text("Save")) {
                    var updated = entry
                    updated.note = note; updated.special = special
                    VictoryStore.shared.save(updated)
                    dismiss()
                }.keyboardShortcut(.defaultAction)
            }
        }.padding(24).frame(width: 360)
            .onAppear { note = entry.note ?? ""; special = entry.special ?? false }
    }
}
