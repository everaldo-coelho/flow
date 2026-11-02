import SwiftUI

struct AddTaskView: View {
    @ObservedObject var model: FlowModel
    @State private var draft = FlowItem(title: "", minutes: 25, kind: "Task")
    var body: some View { PlanEditor(model: model, original: draft) }
}
