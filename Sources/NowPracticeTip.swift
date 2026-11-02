import SwiftUI

struct NowPracticeTip: View {
    @ObservedObject private var language = FlowLanguageSettings.shared
    @SceneStorage("now.practiceTip") private var index = 0
    private let tips = ["Put your keys, wallet, and phone together.", "Let your shoulders settle.", "Choose just two minutes to begin again.", "Leave one return thread for tomorrow.", "Review your tasks without judging the list.", "Let go of one thing that no longer fits."]
    var body: some View {
        DisclosureGroup(language.code == "pt-BR" ? "Uma pequena prática, se ajudar" : language.code == "es" ? "Una pequeña práctica, si ayuda" : "A small practice, if it helps") {
            HStack(alignment: .top, spacing: 16) {
                Text(FlowL.text(tips[index % tips.count])).font(.flowCallout).foregroundStyle(.secondary)
                Spacer()
                Button(FlowL.text("Next small step")) { index = (index + 1) % tips.count }.buttonStyle(FlowGlassButtonStyle())
            }.padding(.top, 8)
        }.font(.flowCaption).padding(.horizontal, 8)
    }
}
