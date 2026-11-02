import SwiftUI

private struct CompactFlowKey: EnvironmentKey {
    static let defaultValue = false
}
extension EnvironmentValues {
    var compactFlow: Bool {
        get { self[CompactFlowKey.self] }
        set { self[CompactFlowKey.self] = newValue }
    }
}
struct FlowAdaptiveStack<Content: View>: View {
    @Environment(\.compactFlow) private var compact
    var spacing: CGFloat = 14
    @ViewBuilder var content: Content
    var body: some View {
        let layout = compact ? AnyLayout(VStackLayout(alignment: .leading, spacing: spacing)) : AnyLayout(HStackLayout(spacing: spacing))
        layout { content }
    }
}
