import SwiftUI


struct FlowPersonalChoices: Codable {
    var appearance: String?
    var theme: String?
    var assistant: String?
    var defaultFocusMinutes: Int?
    var includeTasksInAI: Bool?
}
enum FlowAssistant: String, CaseIterable, Identifiable {
    case pip = "Pip", nova = "Nova", moss = "Moss"
    case rabbit = "Rabbit", fox = "Fox", cat = "Cat", penguin = "Penguin"
    // Legacy values remain readable, but only the four animals are offered.
    static var allCases: [FlowAssistant] { [.moss, .rabbit, .fox, .cat, .penguin] }
    var animal: FlowAssistant { self == .pip || self == .nova ? .moss : self }
    var id: String { rawValue }
    var animalName: String { switch animal { case .penguin: return FlowSubtaskWords.text("Cockatiel", "Calopsita", "Cacatúa ninfa"); case .rabbit: return FlowL.text("Rabbit"); case .fox: return FlowL.text("Fox"); case .cat: return FlowL.text("Cat"); default: return FlowL.text("Turtle") } }
    var displayName: String { switch animal { case .penguin: return "Pelvis"; case .rabbit: return "Zip"; case .fox: return "Fable"; case .cat: return "Briz"; default: return "Moss" } }
    var picture: String { animal == .penguin ? "cockatiel.png" : animal.rawValue.lowercased() + ".png" }
    var paletteAccent: Color {
        switch animal {
        case .penguin: return .flowAdaptive(light: (0.71,0.36,0.20), dark: (0.95,0.72,0.39))
        case .rabbit: return .flowAdaptive(light: (0.39,0.40,0.42), dark: (0.72,0.73,0.75))
        case .fox: return .flowAdaptive(light: (0.80,0.34,0.11), dark: (0.74,0.36,0.15))
        case .cat: return .flowAdaptive(light: (0.24,0.38,0.73), dark: (0.40,0.53,0.83))
        default: return .flowAdaptive(light: (0.25,0.56,0.34), dark: (0.35,0.55,0.39))
        }
    }
    var symbol: String { switch self { case .penguin: return "bird.fill"; case .pip, .nova, .moss: return FlowL.text("tortoise.fill"); case .rabbit: return FlowL.text("hare.fill"); case .fox: return FlowL.text("pawprint.fill"); case .cat: return FlowL.text("cat.fill") } }
    var detail: String { switch animal { case .penguin: return FlowSubtaskWords.text("Pelvis · your steady little companion. Gentle, loyal, and cheering for every small step.", "Pelvis · sua companhia tranquila. Gentil, leal e torcendo por cada pequeno passo.", "Pelvis · tu compañía tranquila. Amable, leal y animando cada pequeño paso."); case .rabbit: return FlowL.text("Zip · the bright spark. Quick wit, big ideas, one tiny hop at a time."); case .fox: return FlowL.text("Fable · the clever explorer. Curious questions and a knack for finding the easier path."); case .cat: return FlowL.text("Briz · the midnight muse. Quiet confidence, dry humour, absolutely no judgement."); default: return FlowL.text("Moss · the little anchor. Patient, quietly funny, and delighted by small beginnings.") } }
    var greeting: String { switch animal { case .penguin: return FlowSubtaskWords.text("I’m Pelvis. We can take this one small step at a time.", "Sou o Pelvis. Podemos dar um pequeno passo de cada vez.", "Soy Pelvis. Podemos dar un pequeño paso a la vez."); case .rabbit: return FlowL.text("Zip here! Twelve ideas, one pair of glasses. Let’s pick one little hop."); case .fox: return FlowL.text("I’m Fable. A tangled day? Excellent. I know a few shortcuts."); case .cat: return FlowL.text("Briz here. I’ve cleared a spot beside me. The world can wait a minute."); default: return FlowL.text("I’m Moss. I brought the calm. You just bring yourself.") } }
    var focusLine: String { switch animal { case .penguin: return FlowSubtaskWords.text("One little step. There’s room to go at your own pace.", "Um pequeno passo. Há espaço para seguir no seu ritmo.", "Un pequeño paso. Hay espacio para seguir a tu ritmo."); case .rabbit: return FlowL.text("One hop. Just one. I’ll hold the other eleven ideas."); case .fox: return FlowL.text("The clever move? Make the first step wonderfully small."); case .cat: return FlowL.text("A little focus. Then we can stare thoughtfully out the window."); default: return FlowL.text("Shell we begin? Slowly is a perfectly lovely speed.") } }
    var voice: String {
        switch animal {
        case .penguin: return "Pelvis is a gentle, loyal, affectionate cockatiel with a yellow crest and orange cheeks. Offer steady encouragement and practical support. Be quietly warm and patient, never clingy, childish or patronising. Respect the user's independence; never imply they owe you attention."
        case .rabbit: return "Zip is a brilliant, bespectacled rabbit: quick-witted, enthusiastically curious and full of ideas. Channel that energy into exactly one clear next hop. Speak in crisp, upbeat sentences; never rush or overwhelm the user."
        case .fox: return "Fable is a resourceful fox: curious, inventive and gently mischievous. Notice simpler routes and ask a useful question when needed. Use small exploration metaphors, never manipulate or pretend certainty."
        case .cat: return "Briz is a black cat with yellow eyes: quietly confident, observant, affectionate on her own terms, with gentle dry humour. Respect autonomy and pauses. Keep wit kind, never sarcastic towards the user."
        default: return "Moss is a calm green turtle: patient, grounded, quietly funny and fond of tiny beginnings. Offer reassuring, concrete steps without patronising. Never equate slow progress with failure."
        }
    }
    var instruction: String { "You are \(displayName), the user’s FLOW companion. \(voice) Be warm and lightly playful, with at most one brief character flourish. Prioritise concrete help over jokes. Do not roleplay physical actions, use baby talk, overuse animal puns, shame, diagnose, invent urgency or claim actions happened. Keep responses concise and factual." + FlowL.aiInstruction }
}
@MainActor final class FlowPreferences: ObservableObject {
    static let shared = FlowPreferences()
    @Published var appearance = "Dark" { didSet { save() } }
    @Published var theme = "Lagoon" { didSet { save() } }
    @Published var assistant = FlowAssistant.cat { didSet { save() } }
    @Published var defaultFocusMinutes = 25 { didSet { save() } }
    @Published var includeTasksInAI = true { didSet { save() } }
    init() {
        let choices = LampStore.load(FlowPersonalChoices.self, from: "personalChoices")
        appearance = choices?.appearance == "Light" ? "Light" : "Dark"
        theme = choices?.theme ?? "Lagoon"
        assistant = (FlowAssistant(rawValue: choices?.assistant ?? "Cat") ?? .cat).animal
        defaultFocusMinutes = min(240, max(1, choices?.defaultFocusMinutes ?? 25))
        includeTasksInAI = choices?.includeTasksInAI ?? true
    }
    var accent: Color {
        assistant.paletteAccent
    }
    var colourScheme: ColorScheme? { appearance == "Light" ? .light : .dark }
    func save() { LampStore.save(FlowPersonalChoices(appearance: appearance, theme: theme, assistant: assistant.rawValue, defaultFocusMinutes: defaultFocusMinutes, includeTasksInAI: includeTasksInAI), to: "personalChoices") }
}

struct FlowStyledRoot<Content: View>: View {
    @ObservedObject var appLanguage = FlowLanguageSettings.shared
    @ObservedObject private var preferences = FlowPreferences.shared
    @ViewBuilder var content: () -> Content
    var body: some View { content().font(.flowBody).lineSpacing(3).buttonStyle(FlowGlassButtonStyle()).controlSize(.large).environment(\.locale, appLanguage.locale).tint(preferences.accent).accentColor(preferences.accent).preferredColorScheme(preferences.colourScheme) }
}

struct FlowSettingsView: View {
    @ObservedObject var appLanguage = FlowLanguageSettings.shared
    @ObservedObject private var preferences = FlowPreferences.shared
    var body: some View {
        Form {
            Section(FlowL.text("Ask FLOW")) { FlowAIContextPreferences() }
            Section(FlowL.text("Focus duration")) {
                Stepper(FlowL.format("Default: %@ minutes", String(preferences.defaultFocusMinutes)), value: $preferences.defaultFocusMinutes, in: 1...240)
                Text(FlowL.text("Focus starts automatically with the task estimate, or this duration when there is no estimate. Change it anytime in the mini player.")).font(.flowCaption).foregroundStyle(.secondary)
            }
            Section(FlowL.text("Language")) {
                FlowLanguagePicker()
                Text(FlowL.text("Choose your language. AI replies follow your choice; task titles stay as you wrote them.")).font(.flowCaption).foregroundStyle(.secondary)
            }
            Section(FlowL.text("Appearance")) {
                Picker(FlowL.text("Colour mode"), selection: $preferences.appearance) { ForEach(["Light", "Dark"], id: \.self) { Text(FlowL.text($0)) } }.pickerStyle(.segmented)
                Picker(FlowL.text("Character theme"), selection: Binding(get: { preferences.assistant.animal }, set: { preferences.assistant = $0 })) { ForEach(FlowAssistant.allCases) { Text($0.displayName).tag($0) } }.pickerStyle(.segmented)
                Text(FlowL.text("Your animal brings its own colours to backgrounds, glass, buttons, and highlights.")).font(.flowCaption).foregroundStyle(.secondary)
                HStack(spacing: 20) {
                    PipPortrait().frame(width: 110, height: 110)
                    VStack(alignment: .leading, spacing: 8) {
                        Text(preferences.assistant.greeting).font(.headline)
                        Text(preferences.assistant.detail).foregroundStyle(.secondary)
                    }
                }
            }
        }.formStyle(.grouped).scrollContentBackground(.hidden).padding(12).frame(width: 570, height: 540).background { WorldBackdrop() }
    }
}

struct CompanionGreeting: View {
    @ObservedObject var appLanguage = FlowLanguageSettings.shared
    @ObservedObject private var preferences = FlowPreferences.shared
    var body: some View { Text(preferences.assistant.greeting).font(.title3).foregroundStyle(.secondary) }
}
struct CompanionName: View {
    @ObservedObject private var preferences = FlowPreferences.shared
    @ObservedObject private var language = FlowLanguageSettings.shared
    var body: some View {
        Text(preferences.assistant.displayName + " · " + preferences.assistant.animalName)
            .font(.system(.caption, design: .rounded).weight(.medium)).foregroundStyle(.secondary)
    }
}
struct CompanionFocusLine: View {
    @ObservedObject var appLanguage = FlowLanguageSettings.shared
    @ObservedObject private var preferences = FlowPreferences.shared
    var body: some View { Text(preferences.assistant.focusLine).font(.flowCallout).foregroundStyle(.secondary) }
}
struct CaptureCompanionTitle: View {
    @ObservedObject var appLanguage = FlowLanguageSettings.shared
    @ObservedObject private var preferences = FlowPreferences.shared
    var body: some View { Label(FlowL.text("Capture pocket") + " · " + preferences.assistant.displayName, systemImage: "tray.and.arrow.down.fill").font(.headline) }
}
