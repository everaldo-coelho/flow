import SwiftUI

struct WorldBackdrop: View {
    @ObservedObject private var preferences = FlowPreferences.shared
    @ObservedObject var appLanguage = FlowLanguageSettings.shared
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        ZStack {
            if scheme == .dark {
                Color.flowWindowBackground
                LinearGradient(colors: [Color.accentColor.opacity(0.18), Color.accentColor.opacity(0.07), Color.accentColor.opacity(0.11)], startPoint: .topLeading, endPoint: .bottomTrailing)
            } else {
                if preferences.assistant.animal == .penguin {
                    Color(red: 1.0, green: 0.972, blue: 0.934)
                } else {
                    Color(red: 0.955, green: 0.958, blue: 0.965)
                }
                LinearGradient(colors: [Color.accentColor.opacity(0.085), Color.accentColor.opacity(0.015), Color.accentColor.opacity(0.035)], startPoint: .topLeading, endPoint: .bottomTrailing)
            }
        }.ignoresSafeArea().accessibilityHidden(true)
    }
}

struct WorldNavigation: View {
    @ObservedObject var appLanguage = FlowLanguageSettings.shared
    @Binding var destination: String
    private let places = [
        ("Today", "Base camp", "sun.max.fill"),
        ("Capture", "The pocket", "tray.and.arrow.down.fill"),
        ("You", "Your rhythm", "heart.fill")
    ]
    var body: some View {
        AnimalSidebar(destination: $destination)
    }
}

struct AnimalSidebar: View {
    @ObservedObject private var preferences = FlowPreferences.shared
    @ObservedObject var appLanguage = FlowLanguageSettings.shared
    @Binding var destination: String
    @SceneStorage("sidebarCollapsed") private var collapsed = false
    @Environment(\.compactFlow) private var compactLayout
    private var iconOnly: Bool { collapsed || compactLayout }
    private var selectedInk: Color { .primary }
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let destinations = [("Today", "sun.max"), ("Plans", "calendar"), ("Achievements", "trophy"), ("You", "heart")]
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Button(action: toggleSidebar) {
                Text(iconOnly ? "f." : "flow.")
                    .font(.system(size: 20, weight: .semibold, design: .rounded)).tracking(-0.7)
                    .foregroundStyle(iconOnly ? Color.accentColor : Color.primary)
                    .frame(maxWidth: .infinity, minHeight: 30, alignment: iconOnly ? .center : .leading)
                    .contentShape(Rectangle())
            }.buttonStyle(.plain)
                .help(FlowL.text(iconOnly ? "Expand sidebar" : "Collapse sidebar"))
                .accessibilityLabel("FLOW · " + FlowL.text(iconOnly ? "Expand sidebar" : "Collapse sidebar"))
                .keyboardShortcut("s", modifiers: [.command, .control])
                .padding(.horizontal, 6).padding(.top, 4).padding(.bottom, 14)
            ForEach(destinations, id: \.0) { place in
                if place.0 == "You" { Spacer(minLength: 20) }
                Button {
                    destination = place.0
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: place.1).font(.system(size: 15)).frame(width: 22)
                            .foregroundStyle(destination == place.0 ? selectedInk : Color.secondary)
                        if !iconOnly { Text(pageTitle(place.0)).font(.system(size: 14, weight: destination == place.0 ? .semibold : .regular)).foregroundStyle(destination == place.0 ? selectedInk : Color.primary).lineLimit(1); Spacer(minLength: 0) }
                    }.padding(.horizontal, 10).frame(height: 32).frame(maxWidth: .infinity, alignment: iconOnly ? .center : .leading)
                        .background {
                            if destination == place.0 {
                                Capsule().fill(.regularMaterial)
                                Capsule().fill(Color.accentColor.opacity(scheme == .dark ? 0.24 : 0.14))
                                Capsule().strokeBorder(Color.primary.opacity(scheme == .dark ? 0.18 : 0.09), lineWidth: 0.75)
                            }
                        }
                }.buttonStyle(.plain).accessibilityLabel(pageTitle(place.0)).help(pageTitle(place.0))
                    .accessibilityAddTraits(destination == place.0 ? .isSelected : [])
            }
        }.padding(10).frame(width: iconOnly ? 66 : 196).foregroundStyle(.primary)
            .background {
                FlowGlassPanel(radius: 14).allowsHitTesting(false)
            }
    }
    private func pageTitle(_ key: String) -> String {
        FlowL.text(key == "Plans" ? "Later" : key == "Today" ? "Now" : key)
    }
    private func toggleSidebar() {
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) { collapsed.toggle() }
    }
}

struct FlowGlassPanel: View {
    @ObservedObject var appLanguage = FlowLanguageSettings.shared
    var radius: CGFloat
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    var body: some View {
        ZStack {
            if scheme == .light {
                RoundedRectangle(cornerRadius: radius).fill(.white.opacity(reduceTransparency ? 1 : 0.88))
            } else if reduceTransparency {
                RoundedRectangle(cornerRadius: radius).fill(Color.flowWindowBackground)
            } else {
                RoundedRectangle(cornerRadius: radius).fill(.regularMaterial)
            }
            RoundedRectangle(cornerRadius: radius).fill(Color.accentColor.opacity(scheme == .dark ? 0.09 : 0.025))
            RoundedRectangle(cornerRadius: radius)
                .strokeBorder(LinearGradient(colors: [.white.opacity(scheme == .dark ? 0.20 : 0.65), .white.opacity(0.05), .black.opacity(scheme == .dark ? 0.08 : 0.06)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 0.75)
        }.shadow(color: .black.opacity(scheme == .dark ? 0.08 : 0.045), radius: 12, y: 4)
            .accessibilityHidden(true)
    }
}

struct WorldSurface: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.compactFlow) private var compact
    var emphasis = false
    func body(content: Content) -> some View {
        content.padding(compact ? 16 : (emphasis ? 30 : 22))
            .background { FlowGlassPanel(radius: emphasis ? 26 : 22) }
    }
}
extension View {
    func worldSurface(emphasis: Bool = false) -> some View { modifier(WorldSurface(emphasis: emphasis)) }
}

struct QuestButtonStyle: ButtonStyle {
    @ObservedObject private var preferences = FlowPreferences.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var enabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(.headline, design: .rounded)).foregroundStyle(preferences.assistant.animal == .rabbit && preferences.appearance == "Dark" ? Color.black : Color.white)
            .padding(.horizontal, 20).padding(.vertical, 14)
            .background {
                RoundedRectangle(cornerRadius: 17).fill(Color.accentColor.gradient)
                    .overlay(RoundedRectangle(cornerRadius: 17).fill(.black.opacity(0.18)))
            }
            .overlay(RoundedRectangle(cornerRadius: 17).stroke(.white.opacity(0.22)))
            .shadow(color: Color.accentColor.opacity(configuration.isPressed ? 0.08 : 0.25), radius: configuration.isPressed ? 2 : 9, y: configuration.isPressed ? 1 : 5)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: configuration.isPressed)
            .opacity(enabled ? 1 : 0.45)
    }
}

struct WorldPageBanner: View {
    @ObservedObject var appLanguage = FlowLanguageSettings.shared
    var title: String
    var subtitle: String
    var symbol: String
    var body: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text(FlowL.text(title)).font(.system(size: 28, weight: .semibold, design: .rounded)).foregroundStyle(.primary)
                Text(FlowL.text(subtitle)).font(.system(.callout, design: .rounded)).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Image(systemName: symbol).font(.system(size: 24, weight: .light)).foregroundStyle(.secondary)
                .frame(width: 48, height: 48).accessibilityHidden(true)
        }.padding(26).frame(maxWidth: .infinity, alignment: .leading)
            .background { FlowGlassPanel(radius: 24) }
    }
}

struct CapacityChips: View {
    @ObservedObject private var preferences = FlowPreferences.shared
    @ObservedObject var appLanguage = FlowLanguageSettings.shared
    @Binding var capacity: Int
    var body: some View {
        HStack(spacing: 6) {
            ForEach([5, 15, 30, 60], id: \.self) { minutes in
                Button { capacity = minutes } label: {
                    Text(minutes == 60 ? "1 hr" : "\(minutes) min").font(.system(.callout, design: .rounded).weight(.semibold))
                        .padding(.horizontal, 9).padding(.vertical, 10)
                        .foregroundStyle(capacity == minutes ? (preferences.assistant.animal == .rabbit && preferences.appearance == "Dark" ? Color.black : Color.white) : Color.primary)
                        .background(capacity == minutes ? Color.accentColor.opacity(0.9) : Color.accentColor.opacity(0.07), in: Capsule())
                }.buttonStyle(.plain).accessibilityLabel("\(minutes) minutes available").accessibilityAddTraits(capacity == minutes ? .isSelected : [])
            }
            Menu {
                ForEach([75, 90, 120, 150, 180, 240], id: \.self) { minutes in
                    Button("\(minutes) min") { capacity = minutes }
                }
            } label: {
                Text(capacity > 60 ? "\(capacity) min" : FlowSubtaskWords.text("More", "Mais", "Más"))
                    .font(.system(.callout, design: .rounded).weight(.semibold))
                    .padding(.horizontal, 9).padding(.vertical, 10)
                    .foregroundStyle(capacity > 60 ? Color.white : Color.primary)
                    .background(capacity > 60 ? Color.accentColor.opacity(0.9) : Color.accentColor.opacity(0.07), in: Capsule())
            }.menuStyle(.borderlessButton).fixedSize()
                .accessibilityLabel(FlowSubtaskWords.text("More available time", "Mais tempo disponível", "Más tiempo disponible"))
        }.accessibilityElement(children: .contain).accessibilityLabel(FlowL.text("Available time"))
    }
}
