import SwiftUI

/// This particular reset was explicitly requested; its receipt prevents repeating it.
struct FlowRequestedReset: View {
    @ObservedObject var model: FlowModel
    var finished: () -> Void
    var body: some View {
        Color.clear.task { @MainActor in
            let receipt = "requested-reset-2026-11-01-examples-01"
            guard LampStore.load(Bool.self, from: receipt) != true else { return }
            LampStore.save(model.items, to: receipt + "-previous-tasks")
            LampStore.save(VictoryStore.shared.entries, to: receipt + "-previous-victories")
            await RichCaptureModel.shared.resetForFreshStart()
            model.focus = FocusState(); model.saveFocus()
            model.items.forEach { model.collection.delete($0.id) }
            model.items = []
            let removed = LampStore.collection("removed-examples", of: FlowItem.self)
            removed.all().forEach { removed.delete($0.id) }
            VictoryStore.shared.resetForFreshStart()
            model.selectedID = nil; LampStore.save(Optional<UUID>.none, to: "selected")
            model.quietUntil = nil; LampStore.save(Optional<Date>.none, to: "quietUntil")
            model.capacity = 30
            FlowPreferences.shared.appearance = "Dark"
            FlowPreferences.shared.assistant = .cat
            FlowPreferences.shared.defaultFocusMinutes = 25
            FocusSound.shared.choices = FocusSoundChoices()
            FlowNotifications.shared.preferences = FlowNoticePreferences()
            for item in FlowExampleData.items() { model.put(item) }
            LampStore.save(true, to: "welcomed")
            LampStore.save(true, to: receipt)
            model.notice = FlowLanguageSettings.shared.code == "pt-BR" ? "Exemplos padrão restaurados." : "Default examples restored."
            finished()
            print("FLOW reset: requested fresh start completed with \(model.items.count) example records")
        }
    }
}

enum FlowExampleData {
    @MainActor static func items() -> [FlowItem] {
        let pt = FlowLanguageSettings.shared.code == "pt-BR"
        let es = FlowLanguageSettings.shared.code == "es"
        func words(_ en: String, _ br: String, _ spanish: String) -> String { pt ? br : es ? spanish : en }
        let project = FlowItem(title: words("A calmer workspace", "Um espaço de trabalho mais calmo", "Un espacio de trabajo más tranquilo"), kind: "Project", example: true)
        var desk = FlowItem(title: words("Clear one corner of the desk", "Liberar um canto da mesa", "Despejar una esquina del escritorio"), step: words("Move three things back to their places.", "Guardar três coisas nos seus lugares.", "Guardar tres cosas en su lugar."), minutes: 10, kind: "Task", example: true)
        desk.projectID = project.id
        var supplies = FlowItem(title: words("Gather the essentials", "Reunir o essencial", "Reunir lo esencial"), step: words("Put a notebook and pen within reach.", "Deixar um caderno e uma caneta por perto.", "Dejar un cuaderno y un bolígrafo a mano."), minutes: 5, kind: "Task", example: true)
        supplies.projectID = project.id
        var habit = FlowItem(title: words("A little morning stretch", "Um alongamento pela manhã", "Un estiramiento por la mañana"), step: words("Stand up and gently stretch your shoulders.", "Levantar e alongar os ombros com suavidade.", "Levantarte y estirar los hombros suavemente."), minutes: 5, kind: "Habit", example: true)
        habit.repeatDays = 1; habit.repeatEvery = 1; habit.repeatUnit = "day"; habit.repeatAnchor = Calendar.current.startOfDay(for: Date()); habit.schedulePeriod = "Morning"
        habit.completionDates = [Calendar.current.date(byAdding: .day, value: -1, to: Date())!]
        var completed = FlowItem(title: words("Book the dentist appointment", "Marcar a consulta no dentista", "Reservar la cita con el dentista"), minutes: 10, kind: "Task", done: true, example: true)
        completed.completedAt = Calendar.current.date(byAdding: .day, value: -1, to: Date())
        var finishedProject = FlowItem(title: words("A welcoming reading corner", "Um cantinho de leitura acolhedor", "Un rincón de lectura acogedor"), kind: "Project", done: true, example: true)
        finishedProject.completedAt = Calendar.current.date(byAdding: .day, value: -3, to: Date())
        var evening = FlowItem(title: words("Settle in for the evening", "Preparar uma noite tranquila", "Preparar una noche tranquila"), step: words("Put your phone aside for five minutes.", "Deixar o celular de lado por cinco minutos.", "Dejar el móvil a un lado cinco minutos."), minutes: 5, kind: "Habit", example: true)
        evening.repeatEvery = 1; evening.repeatUnit = "day"; evening.repeatAnchor = Date(); evening.schedulePeriod = "Evening"
        var result = [
            FlowItem(title: words("Prepare tomorrow’s presentation", "Preparar a apresentação de amanhã", "Preparar la presentación de mañana"), step: words("Open the slides and write one heading.", "Abrir os slides e escrever um título.", "Abrir las diapositivas y escribir un título."), minutes: 20, kind: "Task", example: true),
            FlowItem(title: words("Send a restaurant recommendation", "Enviar uma indicação de restaurante", "Enviar una recomendación de restaurante"), step: words("Find the restaurant’s name.", "Encontrar o nome do restaurante.", "Encontrar el nombre del restaurante."), minutes: 5, kind: "Task", example: true),
            project, desk, supplies, habit, evening, completed, finishedProject
        ]
        result[0].todayDate = Date(); result[1].todayDate = Date()
        return result
    }
}

/// Adds the newly requested examples once, without replacing the person's records.
struct FlowExamplePopulation: View {
    @ObservedObject var model: FlowModel
    var body: some View {
        Color.clear.task { @MainActor in
            let receipt = "requested-expanded-examples-2026-11-01"
            guard LampStore.load(Bool.self, from: receipt) != true else { return }
            let samples = FlowExampleData.items()
            var mapping: [UUID: UUID] = [:]
            for sample in samples {
                if let existing = model.items.first(where: { $0.example == true && $0.title == sample.title }) { mapping[sample.id] = existing.id }
            }
            for var sample in samples where mapping[sample.id] == nil {
                if let project = sample.projectID { sample.projectID = mapping[project] ?? project }
                model.put(sample)
            }
            if model.todayItems.isEmpty {
                for sample in samples.prefix(2) {
                    if var existing = model.items.first(where: { $0.example == true && $0.title == sample.title && $0.done != true }) {
                        existing.todayDate = Date(); model.put(existing)
                    }
                }
            }
            LampStore.save(true, to: receipt)
        }
    }
}
