import SwiftUI

struct ShareView: View {
    let items: [LampShare.Item]
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Find the little quests inside.").font(.headline)
            Text("FLOW keeps a local copy and sends extracted text and selected pictures to your configured AI. You review tasks before keeping them.").font(.callout).foregroundStyle(.secondary)
            LampShareSheet(items: items)
        }.padding()
    }
}
