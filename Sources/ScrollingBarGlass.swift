import SwiftUI

/// The inset protects the starting position while scroll views draw under this material.
struct ScrollingBarGlass: View {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    var body: some View {
        Group {
            if reduceTransparency {
                Rectangle().fill(Color.flowWindowBackground)
            } else {
                Rectangle().fill(.ultraThinMaterial)
            }
        }
        .overlay(Color.accentColor.opacity(0.025))
        .accessibilityHidden(true)
    }
}
