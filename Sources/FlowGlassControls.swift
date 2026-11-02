import SwiftUI

struct FlowTaskActionStyle: ButtonStyle {
    var prominent = false
    @Environment(\.isEnabled) private var enabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.callout.weight(.semibold))
            .multilineTextAlignment(.center)
            .foregroundStyle(configuration.role == .destructive ? Color.red : Color.primary)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
            .background(Color.accentColor.opacity(prominent ? 0.3 : 0.06), in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.accentColor.opacity(prominent ? 0.65 : 0.18)))
            .opacity(enabled ? (configuration.isPressed ? 0.7 : 1) : 0.4)
    }
}

struct FlowGlassButtonStyle: ButtonStyle {
    var prominent = false
    @Environment(\.isEnabled) private var enabled
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(size: 14, weight: .medium))
            .foregroundStyle(configuration.role == .destructive ? Color.red : (scheme == .light && prominent ? Color.white : Color.primary))
            .padding(.horizontal, 15).padding(.vertical, 9)
            .background {
                Capsule().fill(.regularMaterial)
                if scheme == .light {
                    Capsule().fill(prominent ? Color.accentColor : Color.white.opacity(0.72))
                    Capsule().fill(Color.black.opacity(configuration.isPressed ? 0.06 : 0))
                } else {
                    Capsule().fill(Color.accentColor.opacity(prominent ? 0.24 : 0.06))
                }
                Capsule().strokeBorder(Color.primary.opacity(configuration.isPressed ? 0.28 : (scheme == .light ? 0.10 : 0.14)), lineWidth: 0.75)
            }
            .shadow(color: .black.opacity(scheme == .light ? 0.045 : 0.08), radius: 5, y: 2)
            .opacity(enabled ? 1 : 0.45)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
    }
}

struct FlowToast: View {
    let message: String
    var dismiss: () -> Void
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.accentColor)
            Text(FlowL.text(message)).font(.flowCallout).fixedSize(horizontal: false, vertical: true)
            Button(action: dismiss) { Image(systemName: "xmark").padding(5) }
                .buttonStyle(.plain).accessibilityLabel(FlowL.text("Dismiss"))
        }.padding(.horizontal, 18).padding(.vertical, 12)
            .background(.regularMaterial, in: Capsule())
            .overlay(Capsule().strokeBorder(.white.opacity(0.22), lineWidth: 0.75))
            .shadow(color: .black.opacity(0.16), radius: 16, y: 6)
            .frame(maxWidth: 560).padding(16)
            .accessibilityElement(children: .contain)
    }
}
