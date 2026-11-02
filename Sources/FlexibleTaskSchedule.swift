import SwiftUI

enum FlowTiming {
    static let periods = ["Any time", "Morning", "Afternoon", "Evening", "Exact time"]
    static func text(_ key: String) -> String {
        let words: [String: (String, String)] = [
            "When it fits": ("Quando couber", "Cuando encaje"), "Any time": ("Sem horário", "Sin horario"),
            "Morning": ("Pela manhã", "Por la mañana"), "Afternoon": ("À tarde", "Por la tarde"),
            "Evening": ("À noite", "Por la noche"), "Exact time": ("Horário específico", "Hora específica"),
            "Choose a day": ("Escolher um dia", "Elegir un día"), "Remind me": ("Lembrar-me", "Recordármelo"),
            "Choose Time": ("Escolher horário", "Elegir horario"),
            "Time": ("Horário", "Horario"),
            "A time window is an invitation, not a deadline.": ("O período é um convite, não um prazo rígido.", "El período es una invitación, no un plazo rígido.")]
        guard let pair = words[key] else { return FlowL.text(key) }
        return FlowLanguageSettings.shared.code == "pt-BR" ? pair.0 : FlowLanguageSettings.shared.code == "es" ? pair.1 : key
    }
}

struct FlexibleTaskSchedule: View {
    @Binding var item: FlowItem
    @ObservedObject private var language = FlowLanguageSettings.shared
    private var scheduled: Bool { item.due != nil || (item.schedulePeriod != nil && item.schedulePeriod != "Any time") }
    private var date: Binding<Date> {
        Binding(get: { item.due ?? Date() }, set: {
            item.due = $0
            if item.kind == "Habit" { item.repeatAnchor = $0 }
        })
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: Binding(get: { scheduled }, set: { enabled in
                if enabled {
                    item.due = item.due ?? Date()
                    item.schedulePeriod = item.schedulePeriod ?? "Any time"
                } else {
                    item.due = nil
                    item.schedulePeriod = "Any time"
                    item.reminderEnabled = false
                }
                if item.kind == "Habit" { item.repeatAnchor = item.due ?? Date() }
            })) {
                Label(FlowTiming.text("Choose Time"), systemImage: "calendar.badge.clock")
                    .font(.headline)
            }
            if scheduled {
            DatePicker(FlowL.text("Date"), selection: date, displayedComponents: [.date])
                .datePickerStyle(.compact)
            Picker(FlowTiming.text("Time"), selection: Binding(get: { item.schedulePeriod ?? (item.kind == "Habit" ? "Any time" : "Exact time") }, set: { value in
                item.schedulePeriod = value
                if value == "Exact time", item.due == nil { item.due = Date().addingTimeInterval(3600) }
            })) {
                ForEach(FlowTiming.periods, id: \.self) { Text(FlowTiming.text($0)).tag($0) }
            }.pickerStyle(.menu)
                if item.schedulePeriod == "Exact time" || (item.schedulePeriod == nil && item.kind != "Habit") {
                    DatePicker(FlowTiming.text("Exact time"), selection: date, displayedComponents: [.hourAndMinute])
                        .datePickerStyle(.compact)
                }
            Text(FlowTiming.text("A time window is an invitation, not a deadline.")).font(.flowCaption).foregroundStyle(.secondary)
            Toggle(FlowTiming.text("Remind me"), isOn: Binding(get: { item.reminderEnabled == true }, set: { item.reminderEnabled = $0 }))
            if item.reminderEnabled == true {
                Text(FlowNoticeWords.text("Reminder preferences live in You. Flexible periods use your chosen reminder times."))
                    .font(.flowCaption).foregroundStyle(.secondary)
            }
            }
        }
    }
}

struct TaskScheduleSummary: View {
    let item: FlowItem
    @ObservedObject private var language = FlowLanguageSettings.shared
    var body: some View {
        HStack(spacing: 10) {
            if let due = item.due {
                Label(due.formatted(date: .abbreviated, time: item.schedulePeriod == "Exact time" || (item.schedulePeriod == nil && item.kind != "Habit") ? .shortened : .omitted), systemImage: "calendar")
            }
            if let period = item.schedulePeriod, period != "Any time", period != "Exact time" {
                Label(FlowTiming.text(period), systemImage: "clock")
            }
        }.font(.flowCaption).foregroundStyle(.secondary)
    }
}
