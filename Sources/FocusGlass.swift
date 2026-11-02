import SwiftUI
#if os(macOS)
import AppKit
#endif

/// Behind-window vibrancy keeps the compact player translucent without dimming its text.
struct FocusGlass: View {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    var body: some View {
        ZStack {
            if reduceTransparency {
                Color.flowWindowBackground
            } else {
                FocusGlassMaterial()
                Color.black.opacity(0.24)
                Color.accentColor.opacity(0.045)
                LinearGradient(colors: [.white.opacity(0.10), .clear, .black.opacity(0.04)], startPoint: .topLeading, endPoint: .bottomTrailing)
            }
        }.overlay {
            RoundedRectangle(cornerRadius: 10).strokeBorder(
                LinearGradient(colors: [.white.opacity(0.3), .white.opacity(0.04), Color.accentColor.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 0.7)
        }.allowsHitTesting(false).accessibilityHidden(true)
    }
}

#if os(macOS)
private struct FocusGlassMaterial: NSViewRepresentable {
    func makeNSView(context: Context) -> FocusGlassEffect {
        let view = FocusGlassEffect()
        view.material = .hudWindow
        view.blendingMode = .behindWindow
        view.state = .active
        view.appearance = NSAppearance(named: .darkAqua)
        return view
    }
    func updateNSView(_ view: FocusGlassEffect, context: Context) {
        view.window?.isOpaque = false
        view.window?.backgroundColor = .clear
        view.window?.appearance = NSAppearance(named: .darkAqua)
    }
}

private final class FocusGlassEffect: NSVisualEffectView {
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.isOpaque = false
        window?.backgroundColor = .clear
        window?.appearance = NSAppearance(named: .darkAqua)
    }
}

#else
private struct FocusGlassMaterial: View { var body: some View { Rectangle().fill(.regularMaterial) } }
#endif
