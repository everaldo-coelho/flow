import SwiftUI

struct FlowAIContextPreferences: View {
    @ObservedObject private var preferences = FlowPreferences.shared
    @ObservedObject private var language = FlowLanguageSettings.shared
    @State private var route = ""
    @State private var clearConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(FlowL.text("Include my tasks"), isOn: $preferences.includeTasksInAI)
            Text(FlowL.text(preferences.includeTasksInAI ? "This conversation and up to 100 recent tasks go to your configured AI. You choose what to keep." : "Only this conversation goes to your configured AI."))
                .font(.flowCaption).foregroundStyle(.secondary)
            Text(FlowSubtaskWords.text("Make it smaller always includes the selected task and your available time.", "Make it smaller sempre inclui a tarefa selecionada e seu tempo disponível.", "Make it smaller siempre incluye la tarea seleccionada y tu tiempo disponible."))
                .font(.flowCaption).foregroundStyle(.secondary)
            if !route.isEmpty { Text(route).font(.flowCaption).foregroundStyle(.secondary) }
            Button { clearConfirmation = true } label: {
                Label(FlowSubtaskWords.text("Clear conversation", "Limpar conversa", "Limpiar conversación"), systemImage: "broom")
            }
        }
        .confirmationDialog(FlowSubtaskWords.text("Clear conversation?", "Limpar conversa?", "¿Limpiar conversación?"), isPresented: $clearConfirmation) {
            Button(FlowSubtaskWords.text("Clear conversation", "Limpar conversa", "Limpiar conversación"), role: .destructive) {
                NotificationCenter.default.post(name: Notification.Name("flow.clearConversation"), object: nil)
            }
        } message: { Text(FlowSubtaskWords.text("Saved tasks stay in FLOW.", "As tarefas salvas permanecem no FLOW.", "Las tareas guardadas permanecen en FLOW.")) }
        .task {
            let status = await LampAI.status(.text)
            route = [status.route, status.processing == .onDevice ? FlowSubtaskWords.text("Processed on this device", "Processado neste dispositivo", "Procesado en este dispositivo") : status.processing == .remote ? FlowL.text("Processed by your AI service") : nil].compactMap { $0 }.joined(separator: " · ")
        }
    }
}
