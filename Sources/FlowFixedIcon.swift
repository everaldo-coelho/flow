#if os(macOS)
import AppKit

@MainActor enum FlowFixedIcon {
    static func apply() {
        if let url = LampAssets.url("FLOW.icns"), let icon = NSImage(contentsOf: url), icon.isValid {
            NSApp.applicationIconImage = icon
            print("FLOW icon: applied user-provided FLOW.icns")
            return
        }
        // Re-read Lamp's bundled artwork instead of retaining a previous runtime Dock icon.
        if let url = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
           let icon = NSImage(contentsOf: url), icon.isValid {
            NSApp.applicationIconImage = icon
            print("FLOW icon: reapplied bundled AppIcon artwork")
        } else if let icon = NSImage(named: "AppIcon"), icon.isValid {
            NSApp.applicationIconImage = icon
            print("FLOW icon: reapplied named AppIcon artwork")
        } else {
            print("FLOW icon: bundled AppIcon artwork is unavailable")
        }
    }
}

#else
import Foundation
enum FlowFixedIcon { static func apply() {} }
#endif
