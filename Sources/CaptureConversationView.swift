import SwiftUI

struct CaptureConversationView: View {
    @ObservedObject var model: FlowModel
    var compact = false
    @ObservedObject private var inbox = RichCaptureModel.shared
    @ObservedObject private var language = FlowLanguageSettings.shared
    @StateObject private var voice = CaptureVoice()
    @State private var message = ""
    @State private var manualDraft: FlowItem?
    @Environment(\.dismiss) private var dismiss
    private var sendLabel: String { FlowSubtaskWords.text("Send message", "Enviar mensagem", "Enviar mensaje") }
    var body: some View {
        VStack(spacing: 0) {
            FlowConversationHeader(close: compact ? { dismiss() } : nil)
            Divider().opacity(0.4)
            ScrollViewReader { scroll in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 24) {
                        if inbox.sources.isEmpty {
                            Text(FlowSubtaskWords.text("Tell me what’s on your mind. I’ll suggest tasks you can choose to keep.", "Conte o que está na sua cabeça. Vou sugerir tarefas que você pode escolher salvar.", "Cuéntame qué tienes en mente. Te sugeriré tareas que puedes guardar.")).foregroundStyle(.secondary).padding(18).worldSurface()
                        }
                        ForEach(inbox.sources.sorted { $0.created < $1.created }) { source in
                            CaptureMessageExchange(source: source, inbox: inbox, model: model)
                        }
                        Color.clear.frame(height: 1).id("captureEnd")
                    }.padding(20).frame(maxWidth: 850).frame(maxWidth: .infinity)
                }
                .onAppear { scroll.scrollTo("captureEnd", anchor: .bottom) }
                .onChange(of: inbox.sources.count) { _, _ in withAnimation { scroll.scrollTo("captureEnd", anchor: .bottom) } }
            }
            composer
        }
        .task { inbox.available = await LampAI.isAvailable(.text) }
        .onDisappear { voice.finish(keep: false) }
        .sheet(item: $manualDraft) { draft in FlowStyledRoot { ItemEditor(model: model, item: draft) } }
    }
    private var composer: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let _ = inbox.busyID {
                HStack { ProgressView().controlSize(.small); Text(inbox.activity).font(.flowCaption).lineLimit(2); Spacer(); Button(FlowL.text("Cancel")) { inbox.cancelAll() }.buttonStyle(FlowGlassButtonStyle()) }
            }
            if !inbox.error.isEmpty { Text(inbox.error).font(.flowCallout).foregroundStyle(.orange).textSelection(.enabled) }
            if !voice.error.isEmpty { Text(voice.error).font(.flowCallout).foregroundStyle(.orange) }
            if inbox.available == false {
                HStack {
                    Text(FlowSubtaskWords.text("AI is unavailable. Your messages remain here for retry.", "A IA está indisponível. Suas mensagens ficam aqui para tentar novamente.", "La IA no está disponible. Tus mensajes quedan aquí para reintentar.")).font(.flowCaption).foregroundStyle(.secondary)
                    Spacer()
                    Button(FlowL.text("Save as task")) {
                        manualDraft = FlowItem(title: message, kind: "Task")
                    }.disabled(message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty).buttonStyle(FlowGlassButtonStyle())
                }
            }
            if voice.recording { CaptureRecordingMeter(voice: voice) }
            HStack(alignment: .bottom, spacing: 10) {
                if voice.recording {
                    Button { voice.finish(keep: false) } label: { Image(systemName: "xmark").frame(width: 24, height: 24) }.accessibilityLabel(FlowL.text("Cancel"))
                    Text(FlowSubtaskWords.text("Recording a voice message…", "Gravando uma mensagem de voz…", "Grabando un mensaje de voz…")).font(.flowCallout).frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 8)
                    Button { voice.finish(keep: true) } label: { Image(systemName: "arrow.up").font(.headline).frame(width: 24, height: 24) }.accessibilityLabel(FlowSubtaskWords.text("Send voice message", "Enviar mensagem de voz", "Enviar mensaje de voz"))
                } else {
                    TextField(FlowSubtaskWords.text("Message FLOW…", "Mensagem para o FLOW…", "Mensaje para FLOW…"), text: $message, axis: .vertical)
                        .textFieldStyle(.plain).lineLimit(1...6).font(.body).padding(.vertical, 9)
                        .accessibilityLabel(FlowSubtaskWords.text("Message", "Mensagem", "Mensaje"))
                        .onSubmit { send() }
                    Button { Task { await voice.begin() } } label: { Image(systemName: "mic.fill").frame(width: 24, height: 24) }.accessibilityLabel(FlowL.text("Start recording")).help(FlowL.text("Start recording"))
                    if !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Button { send() } label: { Image(systemName: "arrow.up").font(.headline).frame(width: 24, height: 24) }.accessibilityLabel(sendLabel).help(sendLabel).keyboardShortcut(.return, modifiers: .command)
                    }
                }
            }.flowMessageInput()
            Text(FlowSubtaskWords.text("Voice becomes text automatically. Review suggestions before saving tasks.", "A voz vira texto automaticamente. Revise as sugestões antes de salvar tarefas.", "La voz se convierte en texto automáticamente. Revisa las sugerencias antes de guardar tareas.")).font(.flowCaption).foregroundStyle(.secondary)
        }.padding(20).frame(maxWidth: 850).frame(maxWidth: .infinity)
    }
    private func send() {
        guard !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        inbox.addText(message); message = ""
    }
}

private struct CaptureMessageExchange: View {
    var source: CapturedSource
    @ObservedObject var inbox: RichCaptureModel
    @ObservedObject var model: FlowModel
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Spacer(minLength: 36)
                Text(source.text ?? source.name)
                    .font(.body).textSelection(.enabled).padding(.horizontal, 16).padding(.vertical, 12)
                    .background(Color.accentColor.opacity(0.18), in: RoundedRectangle(cornerRadius: 20))
                    .frame(maxWidth: 620, alignment: .trailing)
            }
            if source.summary != nil || source.warning != nil || source.suggestions != nil {
                HStack(alignment: .top, spacing: 10) {
                    PipPortrait().frame(width: 32, height: 32)
                    CaptureSourceView(source: source, inbox: inbox, model: model, conversation: true)
                }
            } else {
                HStack(spacing: 10) {
                    PipPortrait().frame(width: 32, height: 32)
                    Text(FlowL.text(source.status)).font(.flowCallout).foregroundStyle(.secondary)
                    if inbox.busyID != source.id { Button(FlowL.text("Retry")) { inbox.enqueue(source.id) }.buttonStyle(FlowGlassButtonStyle()) }
                }
            }
        }
    }
}
