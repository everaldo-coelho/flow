import SwiftUI

extension FlowModel {
    func canConvertToProject(_ id: UUID) -> Bool {
        items.contains { $0.id == id && $0.kind != "Project" }
            && items.contains { $0.parentTaskID == id }
    }

    func convertToProject(_ id: UUID) {
        guard canConvertToProject(id), var project = items.first(where: { $0.id == id }) else { return }
        var descendants: [FlowItem] = []
        var visited: Set<UUID> = [id]
        var pending = [id]
        while let parent = pending.popLast() {
            for child in items where child.parentTaskID == parent && !visited.contains(child.id) {
                visited.insert(child.id); descendants.append(child); pending.append(child.id)
            }
        }
        // Keep the same identities, content, dates and historical completion records.
        project.kind = "Project"; project.parentTaskID = nil; project.projectID = nil
        project.todayDate = nil; project.reminderEnabled = false
        project.repeatEvery = nil; project.repeatUnit = nil; project.repeatWeekdays = nil
        project.repeatAnchor = nil; project.repeatDays = nil; project.weekdaysOnly = nil; project.paused = nil
        put(project)
        for var child in descendants {
            child.parentTaskID = nil; child.projectID = id
            put(child)
        }
        if selectedID == id { selectedID = nil; LampStore.save(Optional<UUID>.none, to: "selected") }
        if focus.itemID == id { focus = FocusState(); saveFocus() }
        notice = FlowSubtaskWords.text("Project created. Its subtasks are now project tasks.", "Projeto criado. As subtarefas agora são tarefas do projeto.", "Proyecto creado. Sus subtareas ahora son tareas del proyecto.")
    }
}

struct FlowProjectConversionAction: View {
    @ObservedObject var model: FlowModel
    let item: FlowItem
    var beforeConversion: () -> Void = {}
    var body: some View {
        if model.canConvertToProject(item.id) {
            Button {
                beforeConversion()
                model.convertToProject(item.id)
            } label: {
                Label(FlowSubtaskWords.text("Convert to project", "Transformar em projeto", "Convertir en proyecto"), systemImage: "folder.badge.plus")
            }
        }
    }
}
