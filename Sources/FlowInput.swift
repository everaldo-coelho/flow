import SwiftUI

/// Shared, opaque writing surface for search, forms and longer notes.
private struct FlowInputSurface: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    var multiline: Bool
    var height: CGFloat?
    func body(content: Content) -> some View {
        content
            .font(.flowBody)
            .textFieldStyle(.plain)
            .scrollContentBackground(.hidden)
            .frame(minHeight: height ?? (multiline ? 110 : 22),
                   maxHeight: multiline ? (height ?? 110) : nil, alignment: .topLeading)
            .padding(10)
            .background {
                RoundedRectangle(cornerRadius: 10).fill(Color.flowInputBackground)
                RoundedRectangle(cornerRadius: 10).fill(Color.accentColor.opacity(scheme == .dark ? 0.04 : 0.012))
                RoundedRectangle(cornerRadius: 10).strokeBorder(Color.primary.opacity(scheme == .dark ? 0.20 : 0.13))
            }
            .foregroundStyle(.primary)
    }
}

extension View {
    func flowInput(multiline: Bool = false, minHeight: CGFloat? = nil) -> some View {
        modifier(FlowInputSurface(multiline: multiline, height: minHeight))
    }
}
