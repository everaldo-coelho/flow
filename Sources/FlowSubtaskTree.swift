import SwiftUI

enum FlowTaskActions {
    static func makeSmaller(_ item: FlowItem) {
        NotificationCenter.default.post(name: Notification.Name("flow.makeSmaller"), object: item.id)
    }
}

struct FlowSubtaskTree: View {
    @ObservedObject var model: FlowModel
    let parent: FlowItem
    @State private var expanded = true
    private struct Branch: Identifiable {
        var item: FlowItem
        var depth: Int
        var last: Bool
        var id: UUID { item.id }
    }
    private var branches: [Branch] {
        var result: [Branch] = []
        var visited: Set<UUID> = [parent.id]
        let childrenByParent = Dictionary(grouping: model.items.filter { $0.parentTaskID != nil }.sorted { $0.created < $1.created }, by: { $0.parentTaskID! })
        func appendChildren(_ id: UUID, depth: Int) {
            guard depth < 64 else { return }
            let children = childrenByParent[id] ?? []
            for (index, child) in children.enumerated() where !visited.contains(child.id) {
                visited.insert(child.id)
                result.append(Branch(item: child, depth: depth, last: index == children.count - 1))
                appendChildren(child.id, depth: depth + 1)
            }
        }
        appendChildren(parent.id, depth: 0)
        return result
    }
    var body: some View {
        let branches = branches
        if !branches.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Button { expanded.toggle() } label: {
                    HStack(spacing: 6) {
                        Image(systemName: expanded ? "chevron.down" : "chevron.right")
                            .font(.system(size: 10, weight: .semibold)).frame(width: 12)
                        Text(FlowSubtaskWords.text("Subtasks", "Subtarefas", "Subtareas") + " · \(branches.count)")
                    }
                    .font(.flowCaption).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 28, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityValue(expanded ? FlowSubtaskWords.text("Expanded", "Expandido", "Expandido") : FlowSubtaskWords.text("Collapsed", "Recolhido", "Contraído"))
                if expanded {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(branches) { branch in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(branch.last ? "└─" : "├─").font(.system(.body, design: .monospaced)).foregroundStyle(Color.accentColor.opacity(0.7)).accessibilityHidden(true)
                        Button {
                            NotificationCenter.default.post(name: Notification.Name("flow.openTask"), object: branch.id)
                        } label: {
                            HStack(spacing: 6) {
                                Text(branch.item.title).strikethrough(branch.item.done == true).multilineTextAlignment(.leading)
                                if branch.item.done == true { Image(systemName: "checkmark").accessibilityLabel(FlowL.text("Completed")) }
                            }.frame(maxWidth: .infinity, alignment: .leading).contentShape(Rectangle())
                        }.buttonStyle(.plain).font(.flowCallout).foregroundStyle(branch.item.done == true ? .secondary : .primary)
                        Menu {
                            Button(FlowL.text("Edit")) { NotificationCenter.default.post(name: Notification.Name("flow.openTask"), object: branch.id) }
                            Button(FlowL.text("Start focus")) { model.openFocus(branch.item) }
                            Button(FlowL.text("Make it smaller")) { FlowTaskActions.makeSmaller(branch.item) }
                            FlowProjectConversionAction(model: model, item: branch.item)
                            Button(FlowL.text(model.isToday(branch.item) ? "Remove from today" : "Mark for today")) { model.toggleToday(branch.item) }
                            Button(FlowL.text(branch.item.done == true ? "Reopen task" : "Mark complete")) {
                                if branch.item.done == true { var copy = branch.item; copy.done = false; model.put(copy) }
                                else { model.complete(branch.item) }
                            }
                        } label: { Image(systemName: "ellipsis") }.menuStyle(.borderlessButton).fixedSize()
                            .accessibilityLabel(FlowL.text("Plan actions") + ": " + branch.item.title)
                    }.padding(.leading, CGFloat(min(branch.depth, 6)) * 14)
                }
            }.padding(.leading, 6).padding(.vertical, 4)
                }
            }
        }
    }
}
