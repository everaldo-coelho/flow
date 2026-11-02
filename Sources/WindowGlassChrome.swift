#if os(macOS)
import SwiftUI
import AppKit

/// Makes the window's own title area transparent, without replacing its controls or toolbar.
struct WindowGlassChrome: NSViewRepresentable {
    func makeNSView(context: Context) -> WindowGlassAnchor { WindowGlassAnchor() }
    func updateNSView(_ view: WindowGlassAnchor, context: Context) { view.applyChrome() }
}

final class WindowGlassAnchor: NSView {
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        applyChrome()
    }
    func applyChrome() {
        guard let window else { return }
        window.title = "FLOW."
        window.subtitle = ""
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.titlebarSeparatorStyle = .none
        window.styleMask.insert(.fullSizeContentView)
    }
}

#else
import SwiftUI
struct WindowGlassChrome: View { var body: some View { EmptyView() } }
#endif
