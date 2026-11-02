import SwiftUI

struct FlowCelebrationPreferences: View {
    @ObservedObject private var history = VictoryStore.shared
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(FlowL.text("Celebration preferences")).font(.title2.bold())
            Toggle(FlowL.text("Reduce celebration animation"), isOn: $history.choices.reduceAnimation)
            Toggle(FlowL.text("Celebration sounds"), isOn: $history.choices.sound)
            Toggle(FlowL.text("Mute praise and celebration messages"), isOn: $history.choices.mutePraise)
            Toggle(FlowL.text("Companion keepsakes"), isOn: $history.choices.keepsakes)
            Text(FlowL.text("Celebrations are brief and dismissible. Your Mac’s reduced-motion preference is always respected.")).font(.flowCaption).foregroundStyle(.secondary)
        }.frame(maxWidth: .infinity, alignment: .leading).worldSurface()
    }
}
