import SwiftUI

struct AdventureHeader: View {
    @ObservedObject var appLanguage = FlowLanguageSettings.shared
    @Environment(\.compactFlow) private var compactLayout
    var completed: Int
    var begin: () -> Void = {}
    var body: some View {
        ZStack(alignment: .leading) {
            FlowAdaptiveStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 14) {
                    Label(FlowL.text("NOW"), systemImage: "sparkles").font(.flowCaption.weight(.semibold)).tracking(2).foregroundStyle(.secondary)
                    Text(FlowL.text("A small step.\nA lighter day.")).font(.system(size: compactLayout ? 26 : 34, weight: .semibold, design: .rounded)).tracking(-1).foregroundStyle(.primary).fixedSize(horizontal: false, vertical: true)
                    Text(FlowL.text("Just your next little thing, at your own pace.")).font(.system(.callout, design: .rounded)).foregroundStyle(.secondary).frame(maxWidth: 340, alignment: .leading)
                    Button(action: begin) {
                        Label(completed == 0 ? FlowL.text("Begin wherever you are") : FlowL.format("%@ little victories, all yours", String(completed)), systemImage: "sparkle")
                        .font(.flowCaption.weight(.medium)).foregroundStyle(Color.accentColor).padding(.horizontal, 12).padding(.vertical, 8).background(Color.accentColor.opacity(0.06), in: Capsule())
                    }.buttonStyle(.plain).help(FlowL.text("Begin with five minutes"))
                }.frame(maxWidth: .infinity, alignment: .leading)
                VStack(spacing: 4) {
                    PipPortrait().frame(width: compactLayout ? 80 : 140, height: compactLayout ? 90 : 170).shadow(color: .black.opacity(0.08), radius: 12, y: 6)
                }
            }
        }
    }
}

struct PipPortrait: View {
    var still = false
    @ObservedObject var appLanguage = FlowLanguageSettings.shared
    @ObservedObject private var preferences = FlowPreferences.shared
    var body: some View {
        AnimatedCompanionPortrait(animal: preferences.assistant.animal, still: still)
    }
}

struct LittleVictory: View {
    @ObservedObject var appLanguage = FlowLanguageSettings.shared
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State private var appeared = false
    var dismiss: () -> Void
    var body: some View {
        VStack(spacing: 14) {
            PipPortrait().frame(width: 130, height: 130)
                .scaleEffect(appeared || reduceMotion ? 1 : 0.7)
            Label(FlowL.text("Little quest. Real victory."), systemImage: "sparkles")
                .font(.title2.weight(.semibold))
            Text(FlowL.text("Look at you, making room for life.")).foregroundStyle(.secondary)
            Button(FlowL.text("Onward, at my pace"), action: dismiss).buttonStyle(.borderedProminent).tint(Color.accentColor)
        }.padding(32).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 30))
            .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color.accentColor.opacity(0.25)))
            .shadow(color: .black.opacity(0.12), radius: 30, y: 12)
            .onAppear { withAnimation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.55)) { appeared = true } }
    }
}
