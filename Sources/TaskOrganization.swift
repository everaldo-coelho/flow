import SwiftUI

struct ProjectAssignmentField: View {
    @ObservedObject var model: FlowModel
    @Binding var projectID: UUID?
    @State private var adding = false
    @State private var name = ""
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Menu {
                Button(FlowL.text("No project")) { projectID = nil }
                ForEach(model.items.filter { $0.kind == "Project" }.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }) {
                    project in Button(project.title) { projectID = project.id }
                }
                Divider()
                Button(FlowL.text("New project")) { adding = true }
            } label: {
                HStack {
                    Text(FlowL.text("Project"))
                    Spacer()
                    Text(model.items.first { $0.id == projectID }?.title ?? FlowL.text("No project"))
                }
            }
            if adding {
                HStack {
                    TextField(FlowL.text("New project"), text: $name).flowInput().onSubmit(create)
                    Button(FlowL.text("Save"), action: create).disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    Button(FlowL.text("Cancel")) { adding = false; name = "" }
                }
            }
        }
    }
    private func create() {
        let title = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        let project = FlowItem(title: title, kind: "Project")
        model.put(project); projectID = project.id; name = ""; adding = false
    }
}

struct TaskOrganizationFields: View {
    @ObservedObject var model: FlowModel
    @Binding var item: FlowItem
    var includesDuration = true
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ProjectAssignmentField(model: model, projectID: $item.projectID)
            if includesDuration { TaskDurationField(minutes: $item.minutes) }
            TaskRepeatControl(item: $item)
            FlexibleTaskSchedule(item: $item)
        }
    }
}
