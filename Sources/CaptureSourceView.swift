import SwiftUI


struct CaptureSourceView: View {
    @ObservedObject var appLanguage = FlowLanguageSettings.shared
    @Environment(\.openURL) private var openURL
    var source: CapturedSource
    @ObservedObject var inbox: RichCaptureModel
    @ObservedObject var model: FlowModel
    var conversation = false
    @State private var confirmRemove = false
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                Image(systemName: source.link == nil ? "doc.text" : "link").foregroundStyle(Color.accentColor)
                VStack(alignment: .leading, spacing: 5) {
                    Text(conversation ? "FLOW." : source.name).font(.headline).textSelection(.enabled)
                    Text(FlowL.text(source.status)).font(.flowCaption).foregroundStyle(.secondary)
                }
                Spacer()
                if source.fileName != nil || source.link != nil {
                    Button(FlowL.text("Original")) {
                        if let file = RichCaptureModel.fileURL(source) { openURL(file) }
                        else if let link = source.link, let url = URL(string: link) { openURL(url) }
                    }.help(FlowL.text("Open the original source"))
                }
                if inbox.busyID == source.id {
                    Button(FlowL.text("Cancel")) { inbox.cancelAll() }
                } else {
                    Button(FlowL.text("Retry")) { inbox.enqueue(source.id) }
                        .disabled(source.fileName == nil && source.link == nil && (source.text ?? "").isEmpty)
                }
                Button { confirmRemove = true } label: { Image(systemName: "trash") }.help(FlowL.text("Remove this capture source")).accessibilityLabel(FlowL.text("Remove source")).disabled(inbox.busyID == source.id)
            }
            if let warning = source.warning, !warning.isEmpty {
                Label(warning, systemImage: "info.circle").font(.flowCaption).foregroundStyle(.secondary).textSelection(.enabled)
            }
            if let summary = source.summary { Text(summary).font(.flowCallout).textSelection(.enabled) }
            ForEach((source.suggestions ?? []).filter { $0.dismissed != true }) { suggestion in
                CaptureSuggestionRow(suggestion: suggestion, sourceID: source.id, inbox: inbox, model: model)
            }
            if !conversation, let text = source.text, !text.isEmpty {
                DisclosureGroup(FlowSubtaskWords.text("Read text / transcript", "Ler texto / transcrição", "Leer texto / transcripción")) {
                    Text(text).font(.flowCallout).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading)
                }.font(.flowCaption)
            }
        }.worldSurface()
        .confirmationDialog(FlowSubtaskWords.text("Remove this capture?", "Remover esta captura?", "¿Eliminar esta captura?"), isPresented: $confirmRemove) {
            Button(FlowL.text("Remove source"), role: .destructive) { inbox.remove(source) }
        } message: { Text(FlowSubtaskWords.text("Tasks you already kept remain.", "As tarefas que você já salvou permanecem.", "Las tareas que ya guardaste permanecen.")) }
    }
}

struct CaptureSuggestionRow: View {
    @ObservedObject var appLanguage = FlowLanguageSettings.shared
    let suggestion: CaptureSuggestion
    let sourceID: UUID
    @ObservedObject var inbox: RichCaptureModel
    @ObservedObject var model: FlowModel
    @State private var draft: CaptureSuggestion
    @State private var organization = FlowItem(title: "", kind: "Task")
    init(suggestion: CaptureSuggestion, sourceID: UUID, inbox: RichCaptureModel, model: FlowModel) {
        self.suggestion = suggestion; self.sourceID = sourceID; self.inbox = inbox; self.model = model
        _draft = State(initialValue: suggestion)
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if suggestion.keptID != nil {
                Label(suggestion.title, systemImage: "checkmark.circle.fill").foregroundStyle(Color.accentColor)
                Text(FlowL.text("Kept for Later")).font(.flowCaption).foregroundStyle(.secondary)
            } else {
                TextField(FlowL.text("Task"), text: $draft.title, axis: .vertical).lineLimit(1...3).flowInput()
                TextField(FlowL.text("First tiny step"), text: $draft.step, axis: .vertical).lineLimit(3...6).flowInput(multiline: true)
                if let due = draft.due {
                    HStack {
                        Label(due.formatted(date: .abbreviated, time: .shortened), systemImage: "calendar").font(.flowCaption)
                        Button(FlowL.text("Remove deadline")) { draft.due = nil }.buttonStyle(FlowGlassButtonStyle()).font(.flowCaption)
                    }
                }
                if let uncertainty = suggestion.uncertainty, !uncertainty.isEmpty {
                    Label(uncertainty, systemImage: "questionmark.circle").font(.flowCallout).foregroundStyle(.orange)
                }
                Text(FlowL.format("Why this stood out: %@", suggestion.evidence)).font(.flowCaption).foregroundStyle(.secondary).textSelection(.enabled)
                TaskDurationField(minutes: $organization.minutes)
                DisclosureGroup(FlowL.text("Project") + " · " + FlowL.text("Habit")) {
                    TaskOrganizationFields(model: model, item: $organization, includesDuration: false).padding(.top, 8)
                }
                HStack {
                    Text(FlowL.format("About %@ min · AI estimate", String(draft.minutes))).font(.flowCaption).foregroundStyle(.secondary)
                    Spacer()
                    Button(FlowL.text("Skip")) { inbox.dismiss(suggestion.id, sourceID: sourceID) }.buttonStyle(FlowGlassButtonStyle())
                    Button(FlowL.text("Keep task")) {
                        inbox.keep(draft, from: sourceID, model: model)
                        if let id = inbox.sources.first(where: { $0.id == sourceID })?.suggestions?.first(where: { $0.id == draft.id })?.keptID,
                           var item = model.items.first(where: { $0.id == id }) {
                            item.projectID = organization.projectID; item.kind = organization.kind ?? "Task"
                            item.minutes = organization.minutes ?? draft.minutes
                            FlowRecurrence.copy(from: organization, to: &item)
                            item.schedulePeriod = organization.schedulePeriod; item.reminderEnabled = organization.reminderEnabled
                            if organization.due != nil { item.due = organization.due }
                            item.repeatDays = organization.repeatDays; item.weekdaysOnly = organization.weekdaysOnly; item.paused = organization.paused
                            if organization.kind == "Habit" { item.due = organization.due }
                            model.put(item)
                        }
                    }.buttonStyle(FlowGlassButtonStyle(prominent: true)).tint(Color.accentColor)
                        .disabled(draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }.padding(16).background(Color.accentColor.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
            .onAppear { if organization.minutes == nil { organization.minutes = draft.minutes } }
    }
}
