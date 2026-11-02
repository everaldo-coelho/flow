import SwiftUI
struct YouView: View {
    @ObservedObject var appLanguage = FlowLanguageSettings.shared
    @ObservedObject var model: FlowModel
    var pageTitle = "You"
    @State var confirmDelete = false
    @Environment(\.compactFlow) private var compactLayout
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(FlowL.text(pageTitle)).font(.system(size: 28, weight: .semibold, design: .rounded))
                    Text(FlowL.text("Appearance, focus and preferences. At your pace.")).font(.flowCallout).foregroundStyle(.secondary)
                }.frame(maxWidth: .infinity, alignment: .leading).worldSurface()
                YouPreferences()
                VStack(alignment: .leading, spacing: 14) {
                    Text(FlowL.text("YOUR DATA, YOUR CONTROL")).font(.title2.bold())
                    Text(FlowL.text("Tasks, projects, habit history and achievements are saved locally on this Mac.")).foregroundStyle(.secondary)
                    DisclosureGroup(FlowL.text("Capture and AI privacy")) {
                        Text(FlowSubtaskWords.text("Capture accepts text and voice recordings. Speech is transcribed on this Mac; text is sent to your configured AI for task suggestions. You choose what to save. Audio is removed after processing. Ask FLOW includes tasks only when you enable that option.", "A Captura aceita texto e gravações de voz. A fala é transcrita neste Mac; o texto é enviado à sua IA para sugerir tarefas. Você escolhe o que salvar. O áudio é apagado após o processamento. O Ask FLOW inclui tarefas apenas quando você ativa essa opção.", "Captura acepta texto y grabaciones de voz. La voz se transcribe en este Mac; el texto se envía a tu IA para sugerir tareas. Tú eliges qué guardar. El audio se elimina después del procesamiento. Ask FLOW incluye tareas solo cuando activas esa opción.")).font(.flowCallout).foregroundStyle(.secondary).padding(.top, 8)
                    }
                    FlowAdaptiveStack {
                        Button(FlowL.text(model.items.contains { $0.example == true } ? "Remove example content" : "Restore example content")) { model.toggleExamples() }
                        Button(FlowL.text("Delete all tasks…"), role: .destructive) { confirmDelete = true }
                    }
                }.frame(maxWidth: .infinity, alignment: .leading).worldSurface()
                YouLanguageSection()
            }.padding(compactLayout ? 16 : 36).frame(maxWidth: 850).frame(maxWidth: .infinity)
        }.confirmationDialog(FlowL.text("Delete all tasks and projects?"), isPresented: $confirmDelete) { Button(FlowL.text("Delete all tasks"), role: .destructive) { model.items.forEach { model.delete($0) }; model.focus = FocusState(); model.saveFocus() } } message: { Text(FlowL.text("This clears tasks, habits and projects. Your achievement history stays saved.")) }
    }
}
