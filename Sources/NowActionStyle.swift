import SwiftUI

struct NowActionStyle: ButtonStyle {
    var prominent = false
    @Environment(\.isEnabled) private var enabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.callout.weight(.semibold))
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .foregroundStyle(Color.primary)
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(.regularMaterial, in: Capsule())
            .overlay(Capsule().fill(Color.accentColor.opacity(prominent ? 0.24 : 0.04)))
            .overlay(Capsule().strokeBorder(Color.accentColor.opacity(prominent ? 0.5 : 0.18), lineWidth: 0.75))
            .opacity(enabled ? (configuration.isPressed ? 0.65 : 1) : 0.4)
    }
}
