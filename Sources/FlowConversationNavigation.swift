import SwiftUI

private struct FlowConversationBackKey: EnvironmentKey {
    static let defaultValue: (() -> Void)? = nil
}

extension EnvironmentValues {
    var flowConversationBack: (() -> Void)? {
        get { self[FlowConversationBackKey.self] }
        set { self[FlowConversationBackKey.self] = newValue }
    }
}
