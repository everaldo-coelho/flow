import SwiftUI

struct FlowConversationHeader: View {
    var close: (() -> Void)?
    @ObservedObject private var preferences = FlowPreferences.shared
    var body: some View {
        HStack(spacing: 12) {
            PipPortrait().frame(width: 44, height: 44)
            VStack(alignment: .leading, spacing: 3) {
                Text("FLOW.").font(.headline)
                Text(preferences.assistant.displayName).font(.flowCaption).foregroundStyle(.secondary)
            }
            Spacer()
            if let close {
                Button(action: close) { Image(systemName: "xmark").frame(width: 24, height: 24) }
                    .buttonStyle(FlowGlassButtonStyle()).accessibilityLabel(FlowL.text("Close"))
                    .keyboardShortcut(.cancelAction)
            }
        }.padding(.horizontal, 20).padding(.vertical, 12)
            .background(.ultraThinMaterial)
    }
}

extension View {
    func flowMessageInput() -> some View {
        self.buttonStyle(FlowGlassButtonStyle())
            .padding(8).padding(.leading, 8)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
            .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(.primary.opacity(0.12)))
    }
}
