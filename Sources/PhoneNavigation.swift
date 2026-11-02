import SwiftUI

#if os(iOS)
struct PhoneNavigation: View {
    @Binding var destination: String
    var capture: () -> Void
    @ObservedObject private var preferences = FlowPreferences.shared
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var selection
    private var accent: Color { preferences.accent }

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 4) {
                Button { destination = "Today" } label: {
                    tab("Now", symbol: "sun.max", selected: destination == "Today")
                }
                Button { destination = "Plans" } label: {
                    tab("Later", symbol: "calendar", selected: destination == "Plans")
                }
                Menu {
                    Button { destination = "Preferences" } label: {
                        Label(FlowSubtaskWords.text("Preferences", "Preferências", "Preferencias"), systemImage: "slider.horizontal.3")
                    }
                    Button { destination = "Achievements" } label: {
                        Label(FlowL.text("Achievements"), systemImage: "trophy")
                    }
                } label: {
                    tab("You", symbol: "person.crop.circle", selected: ["You", "Preferences", "Achievements"].contains(destination))
                }
                .accessibilityLabel(FlowL.text("You"))
            }
            .buttonStyle(.plain)
            .padding(5)
            .background { navigationGlass(Capsule()) }
            .shadow(color: accent.opacity(0.16), radius: 12, y: 5)
            .shadow(color: .black.opacity(0.16), radius: 8, y: 4)

            Button(action: capture) {
                Image(systemName: "plus")
                    .font(.title2)
                    .foregroundStyle(accent)
                    .frame(width: 64, height: 64)
                    .background { navigationGlass(Circle()) }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(FlowSubtaskWords.text("Add task", "Adicionar tarefa", "Añadir tarea"))
            .shadow(color: accent.opacity(0.16), radius: 12, y: 5)
            .shadow(color: .black.opacity(0.16), radius: 8, y: 4)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: destination)
    }

    private func tab(_ title: String, symbol: String, selected: Bool) -> some View {
        VStack(spacing: 4) {
            Image(systemName: symbol).font(.title3)
            Text(FlowL.text(title)).font(.caption2.weight(.semibold))
        }
        .frame(maxWidth: .infinity, minHeight: 54)
        .foregroundStyle(scheme == .dark && !selected ? Color.white.opacity(0.9) : accent)
        .background {
            if selected {
                Capsule().fill(accent.opacity(scheme == .dark ? 0.32 : 0.17))
                    .overlay(Capsule().strokeBorder(accent.opacity(scheme == .dark ? 0.75 : 0.4), lineWidth: 1))
                    .matchedGeometryEffect(id: "selectedTab", in: selection)
            }
        }
        .contentShape(Capsule())
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func navigationGlass<S: InsettableShape>(_ shape: S) -> some View {
        ZStack {
            if reduceTransparency {
                shape.fill(Color.flowWindowBackground)
            } else {
                shape.fill(.ultraThinMaterial)
            }
            shape.fill(accent.opacity(scheme == .dark ? 0.06 : 0.09))
            shape.fill(LinearGradient(
                colors: [.white.opacity(scheme == .dark ? 0.08 : 0.5), .white.opacity(0.02), accent.opacity(scheme == .dark ? 0.04 : 0.08)],
                startPoint: .topLeading, endPoint: .bottomTrailing))
            shape.strokeBorder(LinearGradient(
                colors: [.white.opacity(0.75), accent.opacity(scheme == .dark ? 0.5 : 0.22), .white.opacity(0.4)],
                startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
        }.allowsHitTesting(false)
    }
}
#endif
