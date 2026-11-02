import SwiftUI

struct FocusDurationPicker: View {
    @ObservedObject var model: FlowModel
    @ObservedObject private var language = FlowLanguageSettings.shared
    var close: () -> Void
    private var minutes: Binding<Int> {
        Binding(get: { max(1, Int(model.focus.length / 60)) }, set: { model.setFocusMinutes($0) })
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(FlowL.text("Focus duration")).font(.headline)
            Text(FlowL.text("Choose your time, then press play.")).font(.flowCallout).foregroundStyle(.secondary)
            Picker(FlowL.text("Minutes"), selection: minutes) {
                ForEach([2, 5, 10, 15, 25, 45, 60], id: \.self) { count in
                    Text(FlowL.format("%@ minutes", String(count))).tag(count)
                }
                if ![2, 5, 10, 15, 25, 45, 60].contains(minutes.wrappedValue) {
                    Text(FlowL.format("%@ minutes", String(minutes.wrappedValue))).tag(minutes.wrappedValue)
                }
            }
            Stepper(FlowL.format("%@ minutes", String(minutes.wrappedValue)), value: minutes, in: 1...240)
            Button(FlowL.text("Start focus")) {
                if model.seconds() <= 0 { model.setFocusMinutes(minutes.wrappedValue) }
                model.resume(); close()
            }.buttonStyle(FlowGlassButtonStyle(prominent: true)).frame(maxWidth: .infinity, alignment: .trailing)
        }.padding(18).frame(width: 260)
    }
}
