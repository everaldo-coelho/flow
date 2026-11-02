import SwiftUI

struct TaskDurationField: View {
    @Binding var minutes: Int?
    @ObservedObject private var language = FlowLanguageSettings.shared
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(FlowSubtaskWords.text("How long do you think this will take?", "Quanto tempo você acha que vai levar?", "¿Cuánto tiempo crees que llevará?"))
                .font(.headline)
            Text(FlowSubtaskWords.text("Your estimate helps FLOW find what fits your available time.", "Sua estimativa ajuda o FLOW a escolher o que cabe no seu tempo disponível.", "Tu estimación ayuda a FLOW a elegir lo que cabe en tu tiempo disponible."))
                .font(.flowCaption).foregroundStyle(.secondary)
            if minutes == nil {
                HStack {
                    ForEach([5, 15, 30, 60], id: \.self) { value in
                        Button("\(value) min") { minutes = value }
                    }
                }
                Button(FlowSubtaskWords.text("Another duration", "Outra duração", "Otra duración")) { minutes = 25 }
            } else {
                Text(FlowL.format("%@ minutes", String(minutes ?? 25))).font(.headline.monospacedDigit()).foregroundStyle(Color.accentColor)
                Slider(value: Binding(get: { Double(max(5, min(240, minutes ?? 25))) }, set: { minutes = Int(($0 / 5).rounded()) * 5 }), in: 5...240, step: 5)
                    .accessibilityLabel(FlowSubtaskWords.text("Estimated time", "Estimativa de tempo", "Tiempo estimado"))
                    .accessibilityValue(FlowL.format("%@ minutes", String(minutes ?? 25)))
                HStack { Text("5 min"); Spacer(); Text("4 h") }.font(.flowCaption).foregroundStyle(.secondary)
            }
            if (minutes ?? 0) > 60 {
                Label(FlowSubtaskWords.text("Long tasks can mean holding many steps in mind, making it harder to see where to start and notice progress. FLOW uses one hour as a practical cue—not a limit of your brain—to help divide the work into clear, smaller parts. After saving, FLOW will suggest subtasks or a project that fit your available time. You choose what to keep.", "Tarefas longas podem exigir que você mantenha muitas etapas em mente, dificultando enxergar por onde começar e perceber o progresso. O FLOW usa uma hora como referência prática, não como um limite do cérebro, para ajudar a dividir o trabalho em partes menores e claras. Depois de salvar, o FLOW vai sugerir subtarefas ou um projeto que caibam no seu tempo disponível. Você decide o que manter.", "Las tareas largas pueden exigir mantener muchos pasos en mente, dificultando ver por dónde empezar y reconocer el progreso. FLOW usa una hora como referencia práctica, no como un límite del cerebro, para dividir el trabajo en partes pequeñas y claras. Al guardar, FLOW sugerirá subtareas o un proyecto que se ajusten a tu tiempo disponible. Tú decides qué conservar."), systemImage: "sparkles")
                    .font(.flowCaption).foregroundStyle(.secondary)
            }
        }
    }
}
