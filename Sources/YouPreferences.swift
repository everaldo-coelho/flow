import SwiftUI

struct YouPreferences: View {
    @ObservedObject private var preferences = FlowPreferences.shared
    @ObservedObject private var language = FlowLanguageSettings.shared
    @State private var blinkRequests: [String: UUID] = [:]
    private var compactCompanions: Bool {
        #if os(iOS)
        true
        #else
        false
        #endif
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 18) {
                Text(FlowL.text("Your companion")).font(.title2.bold())
                LazyVGrid(columns: [GridItem(.adaptive(minimum: compactCompanions ? 80 : 110))], spacing: compactCompanions ? 8 : 12) {
                    ForEach(FlowAssistant.allCases) { animal in
                        Button { preferences.assistant = animal; blinkRequests[animal.rawValue] = UUID() } label: {
                            VStack(spacing: compactCompanions ? 4 : 8) {
                                ClickBlinkPortrait(animal: animal, trigger: blinkRequests[animal.rawValue])
                                    .frame(height: compactCompanions ? 60 : 96).allowsHitTesting(false)
                                HStack(spacing: 4) {
                                Text(animal.displayName).font(compactCompanions ? .subheadline.weight(.semibold) : .headline)
                                Image(systemName: preferences.assistant == animal ? "checkmark.circle.fill" : "circle")
                                    .font(compactCompanions ? .caption : .body)
                                    .foregroundStyle(preferences.assistant == animal ? Color.accentColor : .secondary)
                                }
                            }.frame(maxWidth: .infinity).padding(compactCompanions ? 8 : 12)
                                .background(RoundedRectangle(cornerRadius: 16).fill(animal.paletteAccent.opacity(preferences.assistant == animal ? 0.18 : 0.04)))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(preferences.assistant == animal ? Color.accentColor : .clear, lineWidth: 1.5))
                        }.buttonStyle(.plain).accessibilityLabel(animal.displayName)
                            .accessibilityAddTraits(preferences.assistant == animal ? .isSelected : [])
                    }
                }
                Text(preferences.assistant.greeting).font(.headline)
                Text(preferences.assistant.detail).font(.flowCallout).foregroundStyle(.secondary)
                Picker(FlowL.text("Colour mode"), selection: $preferences.appearance) {
                    ForEach(["Light", "Dark"], id: \.self) { Text(FlowL.text($0)).tag($0) }
                }.pickerStyle(.segmented)
                Text(FlowL.text("Your animal brings its own colours to backgrounds, glass, buttons, and highlights.")).font(.flowCaption).foregroundStyle(.secondary)
            }.frame(maxWidth: .infinity, alignment: .leading).worldSurface()
            VStack(alignment: .leading, spacing: 14) {
                Text(FlowL.text("Focus duration")).font(.title2.bold())
                TimeEstimateControl(minutes: $preferences.defaultFocusMinutes)
                Text(FlowL.text("Focus starts automatically with the task estimate, or this duration when there is no estimate. Change it anytime in the mini player.")).font(.flowCaption).foregroundStyle(.secondary)
                Divider()
                FocusSoundSettings()
            }.frame(maxWidth: .infinity, alignment: .leading).worldSurface()
            VStack(alignment: .leading, spacing: 14) {
                Text(FlowL.text("Ask FLOW")).font(.title2.bold())
                FlowAIContextPreferences()
            }.frame(maxWidth: .infinity, alignment: .leading).worldSurface()
            FlowNotificationSection()
            FlowCelebrationPreferences()
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct YouLanguageSection: View {
    @ObservedObject private var language = FlowLanguageSettings.shared
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(FlowL.text("Language")).font(.title2.bold())
            FlowLanguagePicker()
            Text(FlowL.text("Choose your language. AI replies follow your choice; task titles stay as you wrote them.")).font(.flowCaption).foregroundStyle(.secondary)
        }.frame(maxWidth: .infinity, alignment: .leading).worldSurface()
    }
}
