import SwiftUI

struct CaptureView: View {
    @ObservedObject var model: FlowModel
    var compact = false
    var body: some View { AssistantView(model: model) }
}

struct ItemEditor: View {
    @ObservedObject var model: FlowModel
    @State var item: FlowItem
    var body: some View { PlanEditor(model: model, original: item) }
}

struct TaskSourceDetails: View {
    @Binding var item: FlowItem
    @ObservedObject private var inbox = RichCaptureModel.shared
    var body: some View {
        if item.captureSourceID != nil || !(item.relatedSources ?? []).isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                if let sourceID = item.captureSourceID, let source = inbox.sources.first(where: { $0.id == sourceID }) {
                    DisclosureGroup("Captured from: \(source.name)") {
                        Text(source.suggestions?.first(where: { $0.keptID == item.id })?.evidence ?? source.summary ?? "Original source is kept in Capture.")
                            .font(.flowCaption).textSelection(.enabled)
                    }
                }
                if let links = item.relatedSources, !links.isEmpty {
                    DisclosureGroup(FlowL.text("Related sources")) {
                        ForEach(links) { link in
                            VStack(alignment: .leading, spacing: 6) {
                                Label(FlowL.text(link.service) + " · " + link.title, systemImage: "link").font(.flowCallout)
                                if let sourceID = link.captureSourceID, let source = inbox.sources.first(where: { $0.id == sourceID }), let text = source.text {
                                    Text(text).font(.flowCaption).lineLimit(5).textSelection(.enabled)
                                }
                                Button(FlowL.text("Remove link")) { item.relatedSources?.removeAll { $0.id == link.id } }
                                    .buttonStyle(FlowGlassButtonStyle())
                            }.padding(.vertical, 6)
                        }
                    }
                }
            }.worldSurface()
        }
    }
}
