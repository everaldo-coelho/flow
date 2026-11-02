import SwiftUI

enum FlowRecurrence {
    static func unit(_ item: FlowItem) -> String { item.repeatUnit ?? ((item.repeatDays ?? 1) % 7 == 0 ? "week" : "day") }
    static func every(_ item: FlowItem) -> Int { max(1, item.repeatEvery ?? (unit(item) == "week" ? (item.repeatDays ?? 7) / 7 : item.repeatDays ?? 1)) }
    static func weekdays(_ item: FlowItem) -> [Int] {
        item.repeatWeekdays ?? (item.weekdaysOnly == true ? [2, 3, 4, 5, 6] : [])
    }
    static func matches(_ date: Date, item: FlowItem, calendar: Calendar = .current) -> Bool {
        let day = calendar.startOfDay(for: date)
        let anchor = calendar.startOfDay(for: item.repeatAnchor ?? item.due ?? item.created)
        guard day >= anchor else { return false }
        let selected = weekdays(item)
        if !selected.isEmpty && !selected.contains(calendar.component(.weekday, from: day)) { return false }
        switch unit(item) {
        case "week":
            let first = calendar.dateInterval(of: .weekOfYear, for: anchor)?.start ?? anchor
            let current = calendar.dateInterval(of: .weekOfYear, for: day)?.start ?? day
            let weeks = (calendar.dateComponents([.day], from: first, to: current).day ?? 0) / 7
            return weeks % every(item) == 0 && (!selected.isEmpty || calendar.component(.weekday, from: day) == calendar.component(.weekday, from: anchor))
        case "month":
            let a = calendar.dateComponents([.year, .month, .day], from: anchor)
            let b = calendar.dateComponents([.year, .month, .day], from: day)
            let months = ((b.year ?? 0) - (a.year ?? 0)) * 12 + (b.month ?? 1) - (a.month ?? 1)
            let last = calendar.range(of: .day, in: .month, for: day)?.count ?? 28
            return months % every(item) == 0 && b.day == min(a.day ?? 1, last)
        default: return (calendar.dateComponents([.day], from: anchor, to: day).day ?? 0) % every(item) == 0
        }
    }
    static func next(after date: Date, item: FlowItem) -> Date {
        let calendar = Calendar.current
        for offset in 1...11320 {
            if let candidate = calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: date)), matches(candidate, item: item) { return candidate }
        }
        return calendar.date(byAdding: .day, value: max(1, item.repeatDays ?? 1), to: date) ?? date.addingTimeInterval(86400)
    }
    static func copy(from source: FlowItem, to target: inout FlowItem) {
        target.repeatEvery = source.repeatEvery; target.repeatUnit = source.repeatUnit
        target.repeatWeekdays = source.repeatWeekdays; target.repeatAnchor = source.repeatAnchor
    }
    static func word(_ english: String) -> String {
        let pt = ["Never": "Não repetir", "Make it a habit": "Transforme em hábito", "Every": "A cada", "day": "dia(s)", "week": "semana(s)", "month": "mês(es)", "On these days": "Nestes dias"]
        let es = ["Never": "No repetir", "Make it a habit": "Conviértela en hábito", "Every": "Cada", "day": "día(s)", "week": "semana(s)", "month": "mes(es)", "On these days": "Estos días"]
        return FlowLanguageSettings.shared.code == "pt-BR" ? pt[english] ?? FlowL.text(english) : FlowLanguageSettings.shared.code == "es" ? es[english] ?? FlowL.text(english) : english
    }
    static func summary(_ item: FlowItem) -> String {
        var value = "\(word("Every")) \(every(item)) \(word(unit(item)))"
        let symbols = Calendar.current.shortWeekdaySymbols
        let days = weekdays(item).filter { (1...7).contains($0) }.map { symbols[$0 - 1] }
        if !days.isEmpty { value += " · " + days.joined(separator: ", ") }
        return value
    }
}

struct TaskRepeatControl: View {
    @Binding var item: FlowItem
    @ObservedObject private var language = FlowLanguageSettings.shared
    private var calendar: Calendar { var value = Calendar.current; value.locale = language.locale; return value }
    private var selectedDays: [Int] {
        let saved = FlowRecurrence.weekdays(item)
        if !saved.isEmpty { return saved }
        return FlowRecurrence.unit(item) == "week" ? [calendar.component(.weekday, from: item.repeatAnchor ?? item.due ?? item.created)] : Array(1...7)
    }
    private var selection: Binding<String> {
        Binding(get: { item.kind == "Habit" ? FlowRecurrence.unit(item) : "none" }, set: { value in
            if value == "none" {
                item.kind = "Task"; item.repeatDays = nil; item.repeatEvery = nil; item.repeatUnit = nil
                item.repeatWeekdays = nil; item.repeatAnchor = nil; item.weekdaysOnly = nil; item.paused = nil
            } else {
                item.kind = "Habit"; item.done = false; item.repeatUnit = value; item.repeatEvery = 1
                item.repeatAnchor = item.due ?? Date(); item.weekdaysOnly = false
                item.repeatWeekdays = value == "week" ? [Calendar.current.component(.weekday, from: item.repeatAnchor!)] : []
                item.repeatDays = value == "week" ? 7 : value == "month" ? 30 : 1
            }
        })
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: Binding(get: { item.kind == "Habit" }, set: { selection.wrappedValue = $0 ? "day" : "none" })) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(FlowL.text("Repeat")).font(.headline)
                    Text(FlowRecurrence.word("Make it a habit")).font(.flowCaption).foregroundStyle(.secondary)
                }
            }
            if item.kind == "Habit" {
                Picker(FlowL.text("Repeat"), selection: selection) {
                    Text(FlowL.text("Daily")).tag("day")
                    Text(FlowL.text("Weekly")).tag("week")
                    Text(language.code == "pt-BR" ? "Mensalmente" : language.code == "es" ? "Mensualmente" : "Monthly").tag("month")
                }.pickerStyle(.menu)
                Stepper("\(FlowRecurrence.word("Every")) \(FlowRecurrence.every(item)) \(FlowRecurrence.word(FlowRecurrence.unit(item)))", value: Binding(get: { FlowRecurrence.every(item) }, set: {
                    item.repeatEvery = $0; item.repeatUnit = FlowRecurrence.unit(item)
                    item.repeatAnchor = item.repeatAnchor ?? item.due ?? Date()
                    item.repeatDays = $0 * (FlowRecurrence.unit(item) == "week" ? 7 : FlowRecurrence.unit(item) == "month" ? 30 : 1)
                }), in: 1...365)
                if FlowRecurrence.unit(item) != "month" {
                    Text(FlowRecurrence.word("On these days")).font(.flowCaption).foregroundStyle(.secondary)
                    HStack(spacing: 5) {
                        ForEach(0..<7) { offset in
                            let day = ((calendar.firstWeekday - 1 + offset) % 7) + 1
                            let selected = selectedDays.contains(day)
                            Button {
                                var days = selectedDays
                                guard !selected || days.count > 1 else { return }
                                if selected { days.removeAll { $0 == day } } else { days.append(day) }
                                item.repeatWeekdays = days.sorted(); item.weekdaysOnly = false
                                item.repeatAnchor = item.repeatAnchor ?? item.due ?? Date()
                            } label: {
                                Text(calendar.veryShortWeekdaySymbols[day - 1]).font(.flowCaption.weight(.semibold))
                                    .frame(maxWidth: .infinity).frame(height: 32)
                                    .background(Color.accentColor.opacity(selected ? 0.28 : 0.07), in: RoundedRectangle(cornerRadius: 8))
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(selected ? Color.accentColor : .clear))
                            }.buttonStyle(.plain).accessibilityLabel(calendar.weekdaySymbols[day - 1])
                                .accessibilityAddTraits(selected ? .isSelected : [])
                        }
                    }
                }
                Toggle(FlowL.text("Pause habit"), isOn: Binding(get: { item.paused == true }, set: { item.paused = $0 }))
            }
        }.padding(.vertical, 8)
    }
}
