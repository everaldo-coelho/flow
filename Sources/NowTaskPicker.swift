import SwiftUI

struct NowTaskPicker: View {
    @ObservedObject var model: FlowModel
    @ObservedObject private var language = FlowLanguageSettings.shared
    @Environment(\.dismiss) private var dismiss
    @State private var search = ""
    @State private var newTask = ""
    @State private var organization = FlowItem(title: "", kind: "Task")

    private var quickAddWords: (title: String, placeholder: String, button: String) {
        switch language.code {
        case "pt-BR": return ("Ou crie uma tarefa para agora", "O que você quer fazer?", "Adicionar e escolher")
        case "es": return ("O crea una tarea para ahora", "¿Qué quieres hacer?", "Añadir y elegir")
        default: return ("Or add a task for now", "What would you like to do?", "Add & choose")
        }
    }

    private var candidates: [FlowItem] {
        model.items.filter {
            $0.kind != "Project" && $0.done != true &&
            (search.isEmpty || $0.title.localizedCaseInsensitiveContains(search) ||
             ($0.step?.localizedCaseInsensitiveContains(search) ?? false))
        }.sorted {
            if ($0.id == model.current?.id) != ($1.id == model.current?.id) {
                return $0.id == model.current?.id
            }
            return $0.created > $1.created
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(FlowL.text("Choose for now")).font(.title2.weight(.semibold))
                Spacer()
                Button(FlowL.text("Cancel")) { dismiss() }.keyboardShortcut(.cancelAction)
            }
            Text(FlowL.text("Your choice comes first, even if it takes longer than your available time."))
                .font(.flowCallout).foregroundStyle(.secondary)
            TextField(FlowL.text("Search tasks"), text: $search)
                .flowInput()
            if candidates.isEmpty {
                ContentUnavailableView(FlowL.text("No tasks found"), systemImage: "tray",
                    description: Text(FlowL.text("Capture something new, or try another search.")))
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(candidates) { item in
                            Button {
                                guard let latest = model.items.first(where: { $0.id == item.id }), latest.done != true else { return }
                                if !model.isToday(latest) { model.toggleToday(latest) }
                                model.choose(latest)
                                dismiss()
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: item.id == model.current?.id ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(Color.accentColor)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.title).font(.headline).foregroundStyle(.primary)
                                        if let step = item.step, !step.isEmpty {
                                            Text(step).font(.flowCallout).foregroundStyle(.secondary).lineLimit(2)
                                        }
                                        if let minutes = item.minutes, minutes > 0 {
                                            Text(FlowL.format("%@ minutes", String(minutes))).font(.flowCaption).foregroundStyle(.secondary)
                                        }
                                    }
                                    Spacer(minLength: 0)
                                }.padding(14).frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.accentColor.opacity(item.id == model.current?.id ? 0.14 : 0.05), in: RoundedRectangle(cornerRadius: 12))
                                    .contentShape(Rectangle())
                            }.buttonStyle(.plain)
                                .accessibilityLabel(FlowL.text("Choose for now") + ": " + item.title)
                        }
                    }
                }
            }
            Divider()
            VStack(alignment: .leading, spacing: 10) {
                Text(quickAddWords.title).font(.headline)
                TextField(quickAddWords.placeholder, text: $newTask)
                    .flowInput()
                    .accessibilityLabel(quickAddWords.placeholder)
                    .onSubmit(addAndChoose)
                TaskDurationField(minutes: Binding(get: { organization.minutes }, set: { organization.minutes = $0 }))
                DisclosureGroup(FlowL.text("Project") + " · " + FlowL.text("Habit")) {
                    ScrollView { TaskOrganizationFields(model: model, item: $organization, includesDuration: false).padding(.vertical, 8) }.frame(maxHeight: 180)
                }
                HStack {
                    Spacer()
                    Button(action: addAndChoose) {
                        Label(quickAddWords.button, systemImage: "plus")
                    }.buttonStyle(FlowGlassButtonStyle(prominent: true))
                        .disabled(newTask.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || organization.minutes == nil)
                }
            }
        }.padding(22).flowSheetSize(width: 440, height: 520).background { WorldBackdrop() }
    }

    private func addAndChoose() {
        guard organization.minutes != nil else { return }
        guard var task = model.capture(newTask, kind: organization.kind ?? "Task") else { return }
        task.projectID = organization.projectID; task.repeatDays = organization.repeatDays
        task.weekdaysOnly = organization.weekdaysOnly; task.paused = organization.paused
        task.due = organization.due
        task.minutes = organization.minutes
        FlowRecurrence.copy(from: organization, to: &task)
        task.schedulePeriod = organization.schedulePeriod; task.reminderEnabled = organization.reminderEnabled
        model.put(task)
        model.toggleToday(task)
        model.choose(task)
        newTask = ""
        dismiss()
    }
}
