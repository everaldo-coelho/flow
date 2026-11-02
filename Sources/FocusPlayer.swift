import SwiftUI
#if os(macOS)
import AppKit

/// Owns only this main window's player; closing the player restores that same window.
@MainActor final class FocusPlayerController: NSObject, ObservableObject, NSWindowDelegate {
    weak var mainWindow: NSWindow?
    private var player: NSWindow?
    private weak var model: FlowModel?
    @Published var selected = true

    func present(_ model: FlowModel) {
        guard model.focus.itemID != nil else {
            print("FLOW focus: presentation ignored, no selected item")
            return
        }
        // A representable can update before AppKit attaches it to a window.
        // Resolve the clicked window too, rather than silently dropping the action.
        let activeWindow = NSApplication.shared.keyWindow
        guard let mainWindow = mainWindow ?? activeWindow?.sheetParent ?? activeWindow ?? NSApplication.shared.mainWindow,
              mainWindow !== player else {
            print("FLOW focus: presentation deferred, main window unavailable")
            model.notice = FlowL.text("Focus could not open. Please try again.")
            return
        }
        self.mainWindow = mainWindow
        self.model = model
        print("FLOW focus: presenting mini player")
        if let player { player.makeKeyAndOrderFront(nil); mainWindow.orderOut(nil); return }
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 320, height: 156),
                              styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView], backing: .buffered, defer: false)
        window.title = "FLOW · " + FlowL.text("Focus")
        window.isReleasedWhenClosed = false
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.level = .floating
        window.isMovableByWindowBackground = true
        window.delegate = self
        window.contentView = NSHostingView(rootView: FlowStyledRoot {
            FocusMiniPlayer(model: model, controller: self) { [weak self] in self?.player?.close() }
        })
        window.center()
        player = window
        window.makeKeyAndOrderFront(nil)
        mainWindow.orderOut(nil)
        print("FLOW focus: mini player visible = \(window.isVisible)")
    }

    func windowDidBecomeKey(_ notification: Notification) { setSelected(true) }
    func windowDidResignKey(_ notification: Notification) { setSelected(false) }
    private func setSelected(_ value: Bool) {
        selected = value
        for button in [NSWindow.ButtonType.closeButton, .miniaturizeButton, .zoomButton] {
            player?.standardWindowButton(button)?.isHidden = !value
        }
    }

    func windowWillClose(_ notification: Notification) {
        print("FLOW focus: restoring main window")
        model?.pause()
        player = nil
        mainWindow?.makeKeyAndOrderFront(nil)
    }
}

struct FocusWindowAnchor: NSViewRepresentable {
    let controller: FocusPlayerController
    func makeNSView(context: Context) -> FocusMainWindowProbe {
        let view = FocusMainWindowProbe()
        view.controller = controller
        return view
    }
    func updateNSView(_ view: FocusMainWindowProbe, context: Context) {
        view.controller = controller
        if let window = view.window { controller.mainWindow = window }
    }
}

final class FocusMainWindowProbe: NSView {
    weak var controller: FocusPlayerController?
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard let window else { return }
        controller?.mainWindow = window
        print("FLOW focus: main window attached")
    }
}

#else
@MainActor final class FocusPlayerController: ObservableObject {
    @Published var selected = true
    @Published var showing = false
    func present(_ model: FlowModel) { showing = model.focus.itemID != nil }
}
struct FocusWindowAnchor: View {
    let controller: FocusPlayerController
    var body: some View { EmptyView() }
}
#endif

struct FocusMiniPlayer: View {
    @ObservedObject var model: FlowModel
    @ObservedObject var controller: FocusPlayerController
    @ObservedObject private var language = FlowLanguageSettings.shared
    @State private var note = ""
    @State private var thought = ""
    @State private var showNotes = false
    @State private var showSounds = false
    @State private var showDuration = false
    @State private var thoughtSaved = false
    var close: () -> Void
    private var item: FlowItem? { model.items.first { $0.id == model.focus.itemID } }

    var body: some View {
        #if os(iOS)
        immersivePlayer
        #else
        compactPlayer
        #endif
    }

    #if os(iOS)
    private var immersivePlayer: some View {
        GeometryReader { geometry in
            TimelineView(.periodic(from: .now, by: 1)) { context in
                let seconds = Int(model.seconds(at: context.date))
                ZStack {
                    FocusGlass().ignoresSafeArea()
                    FocusTimerGlow(running: model.focus.end != nil && seconds > 0, verticalScale: 3)
                        .ignoresSafeArea()

                    VStack(spacing: 18) {
                        PipPortrait()
                            .frame(width: min(geometry.size.width * 0.65, geometry.size.height * 0.26), height: geometry.size.height * 0.26)
                        Button { showDuration = true } label: {
                            Text(String(format: "%02d:%02d", seconds / 60, seconds % 60))
                                .font(.system(size: min(112, geometry.size.width * 0.23), weight: .light, design: .rounded))
                                .monospacedDigit().minimumScaleFactor(0.6).lineLimit(1)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(FlowL.text("Focus duration"))
                        .popover(isPresented: $showDuration) {
                            FocusDurationPicker(model: model) { showDuration = false }
                        }
                        ProgressView(value: max(0, min(1, 1 - Double(seconds) / max(1, model.focus.length))))
                            .frame(maxWidth: 240)
                    }
                    .padding(.horizontal, 24)
                    .position(x: geometry.size.width / 2, y: geometry.size.height * 0.49)

                    VStack(spacing: 16) {
                        HStack {
                            Button { showSounds = true } label: { Image(systemName: "speaker.wave.2").frame(width: 44, height: 44) }
                                .accessibilityLabel(FlowL.text("Focus sounds"))
                                .popover(isPresented: $showSounds) { FlowStyledRoot { FocusSoundSettings().padding(20) } }
                            Button { showNotes = true } label: { Image(systemName: "note.text").frame(width: 44, height: 44) }
                                .accessibilityLabel(FlowL.text("Focus notes"))
                                .sheet(isPresented: $showNotes) { FlowStyledRoot { notes } }
                            Spacer()
                            Button(action: close) { Image(systemName: "xmark").frame(width: 44, height: 44) }
                                .accessibilityLabel(FlowL.text("Close"))
                        }
                        // The centre stays clear for the camera; controls sit beside it.
                        .padding(.top, -max(0, geometry.safeAreaInsets.top - 4))
                        Text(item?.title ?? "FLOW.")
                            .font(.title2.weight(.medium))
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: 560)
                        Spacer()
                        HStack(spacing: 32) {
                            Button {
                                if seconds <= 0, let item { model.start(item) }
                                else if model.focus.end == nil { model.resume() }
                                else { model.pause() }
                            } label: {
                                Image(systemName: model.focus.end == nil || seconds <= 0 ? "play.fill" : "pause.fill")
                                    .frame(width: 44, height: 44)
                            }
                            .accessibilityLabel(FlowL.text(seconds <= 0 ? "Another 5 minutes" : model.focus.end == nil ? "Resume gently" : "Pause"))
                            Button { if let item { model.complete(item) }; close() } label: {
                                Image(systemName: "checkmark.circle")
                                    .frame(width: 44, height: 44)
                            }
                            .accessibilityLabel(FlowL.text("This task is complete"))
                        }.font(.title2)
                    }
                    .buttonStyle(.plain)
                    .controlSize(.large)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .padding(.bottom, 20)
                }
            }
        }
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
        .preferredColorScheme(.dark)
        .environment(\.colorScheme, .dark)
        .onAppear { note = item?.breadcrumb ?? "" }
        .onChange(of: model.focus.itemID) { _, _ in note = item?.breadcrumb ?? "" }
    }
    #endif

    private var compactPlayer: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Spacer(minLength: 72)
                if controller.selected || showNotes || showDuration {
                    Button { showSounds.toggle() } label: { Image(systemName: "speaker.wave.2") }
                        .popover(isPresented: $showSounds) {
                            FlowStyledRoot { FocusSoundSettings().padding(20).frame(width: 340) }
                        }
                        .help(FlowL.text("Focus sounds"))
                        .accessibilityLabel(FlowL.text("Focus sounds"))
                    Button { showNotes.toggle() } label: { Image(systemName: "note.text") }
                        .help(FlowL.text("Focus notes"))
                        .accessibilityLabel(FlowL.text("Focus notes"))
                        .popover(isPresented: $showNotes, arrowEdge: .bottom) {
                            FlowStyledRoot { notes }
                        }
                    Button { if let item { model.complete(item) }; close() } label: {
                        Image(systemName: "checkmark.circle")
                    }.help(FlowL.text("This task is complete"))
                        .accessibilityLabel(FlowL.text("This task is complete"))
                }
            }.buttonStyle(.plain).frame(height: 20)
            HStack(spacing: 8) {
                Text(item?.title ?? "FLOW.").font(.flowCallout.weight(.medium)).lineLimit(2)
                    .help(item?.title ?? "FLOW.")
                Spacer(minLength: 0)
            }
            TimelineView(.periodic(from: .now, by: 1)) { context in
                let seconds = Int(model.seconds(at: context.date))
                HStack(spacing: 10) {
                    PipPortrait().frame(width: 80, height: 70)
                    VStack(spacing: 9) {
                    ProgressView(value: max(0, min(1, 1 - Double(seconds) / max(1, model.focus.length))))
                    HStack {
                        if controller.selected || showNotes || showDuration {
                            Button { showDuration.toggle() } label: {
                                HStack(spacing: 5) {
                                    Text(String(format: "%02d:%02d", seconds / 60, seconds % 60)).monospacedDigit()
                                    Image(systemName: "chevron.down").font(.flowCaption)
                                }.font(.system(.title3, design: .rounded))
                            }.buttonStyle(.plain).help(FlowL.text("Focus duration"))
                                .accessibilityLabel(FlowL.text("Focus duration"))
                                .accessibilityValue(String(format: "%02d:%02d", seconds / 60, seconds % 60))
                                .popover(isPresented: $showDuration, arrowEdge: .bottom) {
                                    FocusDurationPicker(model: model) { showDuration = false }
                                }
                        } else {
                            Text(String(format: "%02d:%02d", seconds / 60, seconds % 60))
                                .font(.system(.title3, design: .rounded).monospacedDigit())
                                .accessibilityLabel(FlowL.text("Focus time remaining"))
                        }
                        Spacer()
                        if controller.selected || showNotes || showDuration {
                Button {
                    if model.seconds() <= 0, let item { model.start(item) }
                    else if model.focus.end == nil { model.resume() }
                    else { model.pause() }
                } label: {
                    Image(systemName: model.focus.end == nil || seconds <= 0 ? "play.fill" : "pause.fill")
                        .font(.title2).frame(width: 34, height: 30)
                }.buttonStyle(.plain)
                    .accessibilityLabel(FlowL.text(seconds <= 0 ? "Another 5 minutes" : model.focus.end == nil ? "Resume gently" : "Pause"))
                        }
                    }.frame(height: 30)
                    }
                }
            }
        }.padding(.horizontal, 16).padding(.top, 6).padding(.bottom, 14)
            .frame(width: 320)
            .frame(maxHeight: .infinity, alignment: .top)
            .background {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    FocusTimerGlow(running: model.focus.end != nil && model.seconds(at: context.date) > 0)
                }
            }
            .background { FocusGlass() }
            .overlay { RoundedRectangle(cornerRadius: 10).strokeBorder(Color.accentColor.opacity(0.12)).allowsHitTesting(false) }
            .ignoresSafeArea()
            .onAppear { note = item?.breadcrumb ?? ""; showDuration = model.focus.end == nil }
            .onChange(of: model.focus.itemID) { _, _ in note = item?.breadcrumb ?? ""; showDuration = model.focus.end == nil }
            .environment(\.colorScheme, .dark)
            .preferredColorScheme(.dark)
    }
    private var notes: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label(FlowL.text("Focus notes"), systemImage: "note.text").font(.title3.weight(.semibold))
                Spacer()
                Button { showNotes = false } label: { Image(systemName: "xmark") }
                    .buttonStyle(.plain).accessibilityLabel(FlowL.text("Close"))
            }
            Text(item?.title ?? "FLOW.").font(.flowCallout).foregroundStyle(.secondary).lineLimit(2)
            VStack(alignment: .leading, spacing: 8) {
                Text(FlowL.text("Where to pick up")).font(.headline)
                Text(FlowL.text("Leave one sentence for your future self."))
                    .font(.flowCallout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                notesInput($note, placeholder: "When I return, I’ll…")
            }
            Divider()
            VStack(alignment: .leading, spacing: 8) {
                Text(FlowL.text("New task")).font(.headline)
                Text(FlowL.text("Save it in Later and stay with your current task."))
                    .font(.flowCallout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                notesInput($thought, placeholder: "Task title")
            }
            HStack {
                if thoughtSaved { Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.accentColor).accessibilityLabel(FlowL.text("Saved")) }
                Spacer()
                Button(action: saveNotes) { Label(FlowL.text("Save"), systemImage: "checkmark") }
                    .buttonStyle(FlowGlassButtonStyle(prominent: true))
                    .disabled(!hasNotesChanges)
            }
        }.padding(22).frame(width: 420)
            .foregroundStyle(.primary)
            .background { WorldBackdrop() }
    }
    private var hasNotesChanges: Bool {
        (item != nil && note != (item?.breadcrumb ?? "")) || !thought.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func notesInput(_ text: Binding<String>, placeholder: String) -> some View {
        ZStack(alignment: .topLeading) {
            if text.wrappedValue.isEmpty {
                Text(FlowL.text(placeholder)).foregroundStyle(.secondary).padding(.horizontal, 5).padding(.vertical, 8).allowsHitTesting(false)
            }
            TextEditor(text: text)
        }.flowInput(multiline: true)
            .accessibilityLabel(FlowL.text(placeholder))
            .onChange(of: text.wrappedValue) { _, _ in if hasNotesChanges { thoughtSaved = false } }
    }

    private func saveNotes() {
        if var item, item.breadcrumb != note {
            item.breadcrumb = note
            model.put(item)
        }
        if !thought.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            guard model.capture(thought, kind: "Task") != nil else { return }
            thought = ""
        }
        thoughtSaved = true
    }
}
