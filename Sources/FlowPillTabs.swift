import SwiftUI

struct FlowPillTabs: View {
    let title: String
    let values: [String]
    let labels: [String]
    @Binding var selection: String
    var embedded = false
    @Namespace private var highlight
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(Array(values.enumerated()), id: \.element) { index, value in
                    Button { selection = value } label: {
                        Text(labels[index])
                            .font(.callout.weight(selection == value ? .semibold : .medium))
                            .fixedSize()
                            .padding(.horizontal, 16)
                            .frame(minHeight: 44)
                            .foregroundStyle(selection == value ? Color.primary : Color.secondary)
                            .background {
                                if selection == value {
                                    Capsule().fill(Color.accentColor.opacity(0.22))
                                        .overlay(Capsule().strokeBorder(Color.accentColor.opacity(0.5), lineWidth: 1))
                                        .matchedGeometryEffect(id: "selection", in: highlight)
                                }
                            }
                            .contentShape(Capsule())
                    }.buttonStyle(.plain)
                        .accessibilityAddTraits(selection == value ? .isSelected : [])
                }
            }.padding(embedded ? 0 : 4)
                .background {
                    if !embedded {
                        if reduceTransparency { Capsule().fill(Color.flowWindowBackground) }
                        else { Capsule().fill(.ultraThinMaterial) }
                    }
                }
                .overlay {
                    if !embedded { Capsule().strokeBorder(Color.primary.opacity(0.12), lineWidth: 0.75) }
                }
        }
        .accessibilityLabel(title)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.22), value: selection)
    }
}
