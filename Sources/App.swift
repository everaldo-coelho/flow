import SwiftUI
#if os(macOS)
import AppKit
#endif

@main
struct MainApp: SwiftUI.App {
    var body: some SwiftUI.Scene {
        WindowGroup("FLOW.", id: "flow-main") {
            FlowStyledRoot {
                #if os(macOS)
                ContentView().frame(minWidth: 480, minHeight: 420)
                #else
                ContentView()
                #endif
            }
        }
        #if os(macOS)
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
        .defaultSize(width: 1120, height: 800)
        .commands {
            LampCommands()
            FlowPreferencesCommands()
            CommandGroup(replacing: .appInfo) {
                Button("About FLOW.") {
                    NSApplication.shared.orderFrontStandardAboutPanel(options: [.applicationName: "FLOW."])
                }
            }
            CommandMenu("FLOW.") {
                Button(FlowL.text("Capture task")) { NotificationCenter.default.post(name: .flowCapture, object: nil) }.keyboardShortcut("k", modifiers: .command)
            }
        }
        #endif
    }
}

#if os(macOS)
struct FlowPreferencesCommands: Commands {
    @Environment(\.openWindow) private var openWindow
    var body: some Commands {
        CommandGroup(replacing: .appSettings) {
            Button(FlowL.text("Settings…")) {
                let existing = NSApp.windows.first { $0.isVisible && $0.canBecomeMain && !($0 is NSPanel) }
                if let existing { existing.makeKeyAndOrderFront(nil) }
                else { openWindow(id: "flow-main") }
                NSApp.activate(ignoringOtherApps: true)
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(200))
                    NotificationCenter.default.post(name: Notification.Name("flow.openYou"), object: nil)
                }
            }.keyboardShortcut(",", modifiers: .command)
        }
    }
}

#endif
