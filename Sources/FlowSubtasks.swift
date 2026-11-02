import SwiftUI

enum FlowSubtaskWords {
    static func text(_ en: String, _ pt: String, _ es: String) -> String {
        FlowLanguageSettings.shared.code == "pt-BR" ? pt : FlowLanguageSettings.shared.code == "es" ? es : en
    }
}

struct FlowSubtasks: View {
    @ObservedObject var model: FlowModel
    let parent: FlowItem
    @ObservedObject private var language = FlowLanguageSettings.shared
    @State private var title = ""
    @State private var minutes: Int? = 5
    @State private var deletion: FlowItem?
    private var children: [FlowItem] { model.items.filter { $0.parentTaskID == parent.id }.sorted { $0.created < $1.created } }
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(FlowSubtaskWords.text("Subtasks", "Subtarefas", "Subtareas")).font(.headline)
            ForEach(children) { child in
                HStack {
                    TextField(FlowL.text("Title"), text: Binding(get: { model.items.first { $0.id == child.id }?.title ?? child.title }, set: { value in
                        guard !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                        var copy = child; copy.title = value; model.put(copy)
                    })).flowInput().strikethrough(child.done == true)
                    Menu {
                        Button(FlowL.text(child.done == true ? "Reopen task" : "Mark complete")) {
                            if child.done == true { var copy = child; copy.done = false; model.put(copy) } else { model.complete(child) }
                        }
                        Button(FlowL.text("Mark for today")) { model.toggleToday(child) }
                        Button(FlowSubtaskWords.text("Make independent task", "Tornar tarefa independente", "Convertir en tarea independiente")) {
                            var copy = child; copy.parentTaskID = nil; model.put(copy)
                        }
                        Button(FlowL.text("Delete…"), role: .destructive) { deletion = child }
                    } label: { Image(systemName: "ellipsis") }.accessibilityLabel(FlowL.text("Plan actions") + ": " + child.title)
                }
            }
            TextField(FlowSubtaskWords.text("One small action…", "Uma pequena ação…", "Una pequeña acción…"), text: $title).flowInput().onSubmit(add)
            TaskDurationField(minutes: $minutes)
            Button(action: add) { Label(FlowSubtaskWords.text("Add subtask", "Adicionar subtarefa", "Añadir subtarea"), systemImage: "plus") }
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            Text(FlowSubtaskWords.text("Subtasks save immediately. Completing one does not complete its parent.", "Subtarefas são salvas imediatamente. Concluir uma não conclui a tarefa principal.", "Las subtareas se guardan al instante. Completarlas no completa su tarea principal.")).font(.flowCaption).foregroundStyle(.secondary)
        }
        .confirmationDialog(FlowL.text("Delete…"), isPresented: Binding(get: { deletion != nil }, set: { if !$0 { deletion = nil } })) {
            Button(FlowL.text("Delete"), role: .destructive) { if let deletion { model.delete(deletion) }; deletion = nil }
        }
    }
    private func add() {
        let clean = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty, let current = model.items.first(where: { $0.id == parent.id }) else { return }
        var child = FlowItem(title: clean, minutes: minutes, kind: "Task")
        child.parentTaskID = current.id; child.projectID = current.projectID
        model.put(child); title = ""
    }
}

struct DraftTaskSubtasks: View {
    @Binding var items: [FlowItem]
    @State private var title = ""
    @State private var minutes: Int? = 5
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(FlowSubtaskWords.text("Subtasks", "Subtarefas", "Subtareas")).font(.headline)
            ForEach(items) { child in
                HStack {
                    Text(child.title).frame(maxWidth: .infinity, alignment: .leading)
                    Text("\(child.minutes ?? 5) min").font(.flowCaption).foregroundStyle(.secondary)
                    Button { items.removeAll { $0.id == child.id } } label: { Image(systemName: "minus.circle") .frame(width: 44, height: 44) }
                        .buttonStyle(.plain).accessibilityLabel(FlowL.text("Delete") + ": " + child.title)
                }
            }
            TextField(FlowSubtaskWords.text("One small action…", "Uma pequena ação…", "Una pequeña acción…"), text: $title).flowInput().onSubmit(add)
            TaskDurationField(minutes: $minutes)
            Button(action: add) { Label(FlowSubtaskWords.text("Add subtask", "Adicionar subtarefa", "Añadir subtarea"), systemImage: "plus") }
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            Text(FlowSubtaskWords.text("Subtasks are saved with this task.", "As subtarefas serão salvas com esta tarefa.", "Las subtareas se guardan con esta tarea.")).font(.flowCaption).foregroundStyle(.secondary)
        }
    }
    private func add() {
        let clean = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        items.append(FlowItem(title: clean, minutes: minutes, kind: "Task"))
        title = ""
    }
}
