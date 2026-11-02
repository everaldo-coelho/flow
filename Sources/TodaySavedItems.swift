import SwiftUI

struct TodaySavedItems: View {
    @ObservedObject var model: FlowModel
    @ObservedObject private var language = FlowLanguageSettings.shared
    var body: some View {
        if !model.todayItems.isEmpty {
            FlowSection(title: FlowSubtaskWords.text("Today", "Hoje", "Hoy")) {
                Text(FlowSubtaskWords.text("Tasks you’ve set aside for today. Choose one when you’re ready.", "Tarefas que você separou para hoje. Escolha uma quando estiver pronto.", "Tareas que reservaste para hoy. Elige una cuando estés listo."))
                    .font(.flowCallout).foregroundStyle(.secondary)
                ForEach(model.todayItems) { item in
                    VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .top, spacing: 12) {
                        Button { NotificationCenter.default.post(name: Notification.Name("flow.openTask"), object: item.id) } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.title).font(.headline)
                            Text(FlowL.text(item.kind ?? "Task")).font(.flowCaption).foregroundStyle(.secondary)
                        }.frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        }.buttonStyle(.plain).accessibilityLabel(FlowL.text("Edit") + ": " + item.title)
                        Menu {
                            Button(FlowL.text("Edit")) { NotificationCenter.default.post(name: Notification.Name("flow.openTask"), object: item.id) }
                            Button(FlowL.text("Make it smaller")) { FlowTaskActions.makeSmaller(item) }
                            FlowProjectConversionAction(model: model, item: item)
                            Button(FlowL.text("Remove from today")) { model.toggleToday(item) }
                        } label: { Image(systemName: "ellipsis").frame(width: 44, height: 44).contentShape(Rectangle()) }
                            .menuStyle(.borderlessButton).fixedSize()
                            .accessibilityLabel(FlowL.text("Plan actions") + ": " + item.title)
                    }
                    Button { model.openFocus(item) } label: { Label(FlowL.text("Start focus"), systemImage: "play.fill") }
                        .buttonStyle(FlowGlassButtonStyle())
                    FlowSubtaskTree(model: model, parent: item)
                    }
                }
            }
        }
    }
}
