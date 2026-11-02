import SwiftUI
struct ContentView: View {
    @ObservedObject var appLanguage = FlowLanguageSettings.shared
    @StateObject var model = FlowModel()
    @StateObject private var focusPlayer = FocusPlayerController()
    @SceneStorage("destination") var destination = "Today"
    @State var showCapture = false
    private struct AssistantSession: Identifiable {
        let id = UUID()
        var task: FlowItem?
    }
    @State private var assistantSession: AssistantSession?
    @State private var pendingBreakdown: FlowItem?
    @State var search = ""
    @State var editing: FlowItem? = nil
    @State private var showVictory = false
    @State private var compactLayout = false
    @State private var choosingNow = false
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        GeometryReader { geometry in
            platformWindow.environment(\.compactFlow, geometry.size.width < 760)
                .onAppear { compactLayout = geometry.size.width < 760 }
                .onChange(of: geometry.size.width) { _, width in compactLayout = width < 760 }
        }
        .background { FocusWindowAnchor(controller: focusPlayer).frame(width: 0, height: 0) }
        .background { FlowExamplePopulation(model: model).frame(width: 0, height: 0) }
        .background { FlowRequestedReset(model: model) {
            destination = "Today"; editing = nil; showCapture = false; assistantSession = nil
        }.frame(width: 0, height: 0) }
        .overlay(alignment: .bottomTrailing) { VictoryCelebration() }
        .onChange(of: model.focusPresentation) { _, _ in
            print("FLOW focus: opening request received")
            focusPlayer.present(model)
        }
        .onReceive(NotificationCenter.default.publisher(for: .flowCapture)) { _ in assistantSession = AssistantSession() }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("flow.openYou"))) { _ in
            showCapture = false; assistantSession = nil; destination = "You"
        }
        .onReceive(NotificationCenter.default.publisher(for: .flowRefresh)) { _ in model.items = model.collection.all().sorted { $0.created < $1.created } }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("flow.openTask"))) { notification in
            guard let id = notification.object as? UUID, let item = model.items.first(where: { $0.id == id }) else { return }
            editing = item
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("flow.makeSmaller"))) { notification in
            guard let id = notification.object as? UUID, let item = model.items.first(where: { $0.id == id }) else { return }
            showCapture = false; choosingNow = false
            if editing != nil {
                pendingBreakdown = item
                editing = nil
            } else {
                assistantSession = AssistantSession(task: item)
            }
        }
        .onChange(of: model.items) { _, _ in syncNotifications() }
        .onChange(of: model.focus.end) { _, _ in syncNotifications() }
        .onReceive(FocusSound.shared.$choices) { _ in Task { @MainActor in syncNotifications() } }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { syncNotifications(); Task { await FlowNotifications.shared.refresh() } }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("flow.notificationTask"))) { notification in
            if let id = notification.object as? UUID, let item = model.items.first(where: { $0.id == id }) {
                if !model.isToday(item) { model.toggleToday(item) }
                model.choose(item); destination = "Today"
            }
        }
        .task {
            LampNotifications.onAction { _, id in
                let parts = id.split(separator: ".")
                if parts.count >= 3, parts[1] == "task", let taskID = UUID(uuidString: String(parts[2])) {
                    NotificationCenter.default.post(name: Notification.Name("flow.notificationTask"), object: taskID)
                }
            }
            syncNotifications()
            await FlowNotifications.shared.refresh()
            FlowFixedIcon.apply()
            VictoryStore.shared.reconcile(model.items)
            if destination == "Connections" { destination = "Capture" }
            if destination == "Focus" { destination = "Today" }
            if destination == "Memory" { destination = "Plans" }
            LampShare.onReceive { items in
                let inbox = RichCaptureModel.shared
                for item in items {
                    if item.fileURL == nil, item.url == nil, let text = item.text { inbox.addText(text) }
                }
                destination = "Capture"
            }
        }
    }
    private func syncNotifications() {
        FlowNotifications.shared.update(items: model.items, focus: model.focus, quietUntil: nil)
    }
    @ViewBuilder private var platformWindow: some View {
        #if os(macOS)
        presentedWindow
        #else
        phoneWindow
        #endif
    }
    private var presentedWindow: some View {
        windowLayout.background { WorldBackdrop() }
        .background { WindowGlassChrome().frame(width: 0, height: 0) }
        .ignoresSafeArea(.container, edges: .top)
        .toolbar {
            ToolbarItem(placement: .automatic) { Spacer() }
            ToolbarItemGroup(placement: .primaryAction) {
                Button { assistantSession = AssistantSession() } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .regular))
                        .frame(width: 30, height: 30)
                        .contentShape(Rectangle())
                }.buttonStyle(.automatic).controlSize(.regular)
                    .accessibilityLabel(FlowSubtaskWords.text("Add task", "Adicionar tarefa", "Añadir tarea"))
                .help(FlowSubtaskWords.text("Add task", "Adicionar tarefa", "Añadir tarea"))
            }
        }
        .flowToolbarMaterial()
        .sheet(isPresented: $showCapture) { FlowStyledRoot { CaptureView(model: model, compact: true).frame(minWidth: 420, idealWidth: 640, maxWidth: .infinity, minHeight: 440, idealHeight: 680, maxHeight: .infinity).background { WorldBackdrop() } } }
        .sheet(item: $assistantSession) { session in FlowStyledRoot { assistantPage(session) } }
        .sheet(isPresented: $choosingNow) { FlowStyledRoot { NowTaskPicker(model: model) } }
        .sheet(item: $editing, onDismiss: openPendingBreakdown) { item in FlowStyledRoot { PlanEditor(model: model, original: item).background { WorldBackdrop() } } }

    }
    private var windowLayout: some View {
        HStack(spacing: 0) {
            WorldNavigation(destination: $destination).padding(12).padding(.top, 44)
            VStack(spacing: 0) {
                ZStack {
                    destinationPage
                        .id(destination)
                        .transition(.opacity)
                }
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: destination)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .safeAreaInset(edge: .top, spacing: 0) {
                    Color.clear.frame(height: 44).allowsHitTesting(false)
                }
            }.overlay(alignment: .bottom) {
                if !model.notice.isEmpty {
                    FlowToast(message: model.notice) { model.notice = "" }.frame(maxWidth: .infinity)
                }
            }
        }
    }
    @ViewBuilder private var destinationPage: some View {
                    switch destination {
                    case "Capture": CaptureView(model: model)
                    case "Memory", "Plans": PlansView(model: model, start: { item in model.openFocus(item) }, edit: { item in
                        showCapture = false; assistantSession = nil; choosingNow = false
                        editing = item
                        print("FLOW Later: main window presenting task details \(item.id)")
                    })
                     case "You", "Preferences": youPage
                     case "Achievements": AchievementsView(model: model)
                    case "Connections": CaptureView(model: model)
                    default: today
                    }
    }
    #if os(iOS)
    private var phoneWindow: some View {
        NavigationStack {
            ZStack {
                destinationPage
                    .id(destination)
                    .transition(.opacity)
            }
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: destination)
                .background { WorldBackdrop() }
                .toolbar(.hidden, for: .navigationBar)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    PhoneNavigation(destination: $destination) {
                        assistantSession = AssistantSession()
                    }
                }
            }
        .sheet(item: $assistantSession) { session in FlowStyledRoot { assistantPage(session) } }
        .sheet(isPresented: $choosingNow) { FlowStyledRoot { NowTaskPicker(model: model) } }
        .sheet(item: $editing, onDismiss: openPendingBreakdown) { item in
            FlowStyledRoot { PlanEditor(model: model, original: item).background { WorldBackdrop() } }
        }
        .fullScreenCover(isPresented: $focusPlayer.showing, onDismiss: { model.pause() }) {
            FlowStyledRoot {
                FocusMiniPlayer(model: model, controller: focusPlayer) { focusPlayer.showing = false }
            }.preferredColorScheme(.dark)
        }
    }
    #endif
    var today: some View {
        GeometryReader { viewport in
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 24) {
                    HStack {
                         VStack(alignment: .leading, spacing: 8) {
                             Label(FlowL.text("NOW"), systemImage: "sparkles")
                                 .font(.flowCaption.weight(.semibold)).tracking(2).foregroundStyle(.secondary)
                             Text(FlowSubtaskWords.text("One small step is enough to begin.", "Um pequeno passo já é um começo.", "Un pequeño paso basta para empezar."))
                                 .font(.flowCallout).foregroundStyle(.secondary)
                                 .fixedSize(horizontal: false, vertical: true)
                         }
                        Spacer()
                    }
                VStack(alignment: .leading, spacing: 8) {
                ViewThatFits(in: .horizontal) {
                    HStack { Text(FlowL.text("How much time do you have available now?")).font(.system(.headline, design: .rounded)); Spacer(); CapacityChips(capacity: $model.capacity) }
                    VStack(alignment: .leading, spacing: 12) { Text(FlowL.text("How much time do you have available now?")).font(.system(.headline, design: .rounded)); CapacityChips(capacity: $model.capacity) }
                }
                    Text(FlowLanguageSettings.shared.code == "pt-BR" ? "Reserve alguns minutos para uma transição tranquila." : FlowLanguageSettings.shared.code == "es" ? "Reserva unos minutos para una transición tranquila." : "Leave a few minutes for a gentle transition.")
                        .font(.flowCaption).foregroundStyle(.secondary)
                }
                Divider().overlay(Color.accentColor.opacity(0.08))
                if model.choosingAutomatically {
                    HStack { ProgressView().controlSize(.small); Text(FlowSubtaskWords.text("Finding a task for this time…", "Escolhendo uma tarefa para esse tempo…", "Eligiendo una tarea para este tiempo…")).font(.flowCaption).foregroundStyle(.secondary) }
                }
                if let item = model.current {
                    VStack(alignment: .leading, spacing: 20) {
                        HStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 14) {
                                Button { editing = item } label: {
                                    Text(item.title).font(.system(size: compactLayout ? 26 : 30, weight: .bold, design: .rounded)).tracking(-0.5)
                                        .frame(maxWidth: .infinity, alignment: .leading).contentShape(Rectangle())
                                }.buttonStyle(.plain).accessibilityHint(FlowL.text("Edit"))
                                Text(item.breadcrumb ?? item.step ?? "Give this a tiny beginning. What’s the first physical action?").font(.title3).foregroundStyle(.secondary)
                            }.frame(maxWidth: .infinity, alignment: .leading)
                            PipPortrait().frame(width: compactLayout ? 70 : 100, height: compactLayout ? 80 : 110)
                        }
                        HStack(spacing: 8) {
                            Button { model.openFocus(item) } label: {
                                Label(FlowL.text("Start focus"), systemImage: "play.fill")
                            }.buttonStyle(NowActionStyle(prominent: true))
                            Button(FlowL.text("Make it smaller")) {
                                FlowTaskActions.makeSmaller(item)
                            }.buttonStyle(NowActionStyle())
                        }
                        TaskScheduleSummary(item: item)
                        FlowAdaptiveStack(spacing: 12) {
                            Label(FlowL.text(model.suggestedID != item.id ? "Chosen by you. Change it whenever you like." : "Fits your time window. Choose differently whenever you like."), systemImage: "slider.horizontal.3").font(.flowCaption).foregroundStyle(.secondary)
                        }
                        nowSelectionControls
                    }.frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    ContentUnavailableView(FlowL.text("A little room to breathe"), systemImage: "sun.max", description: Text(FlowL.text("Capture something to remember, or simply enjoy the space.")))
                    nowSelectionControls
                }
                }.frame(maxWidth: .infinity, alignment: .topLeading).worldSurface(emphasis: true)
                TodaySavedItems(model: model)
                NowPracticeTip()
            }.padding(compactLayout ? 16 : 36).frame(maxWidth: .infinity)
        }
        }
        .task(id: "\(model.capacity)-\(model.tasks.map { $0.id.uuidString }.joined())-\(model.items.compactMap { $0.completedAt?.timeIntervalSince1970 }.sorted().description)") {
            do { try await Task.sleep(for: .milliseconds(350)); try Task.checkCancellation() } catch { return }
            await model.suggestForAvailableTime(automatic: true)
        }
    }
    private var nowSelectionControls: some View {
        HStack(spacing: 8) { nowSelectionButtons }
    }
    @ViewBuilder private var nowSelectionButtons: some View {
        Button { choosingNow = true } label: {
            Text(FlowSubtaskWords.text("Choose a task", "Escolher tarefa", "Elegir tarea"))
        }.buttonStyle(NowActionStyle())
        Button { model.chooseAutomatically() } label: {
            Text(FlowSubtaskWords.text("Let FLOW choose", "FLOW escolhe", "FLOW elige"))
        }.buttonStyle(NowActionStyle())
            .disabled(model.choosingAutomatically || model.tasks.isEmpty)
    }
    var youPage: some View {
        #if os(iOS)
        YouView(model: model, pageTitle: FlowSubtaskWords.text("Preferences", "Preferências", "Preferencias"))
        #else
        YouView(model: model)
        #endif
    }
    @ViewBuilder private func assistantPage(_ session: AssistantSession) -> some View {
        if let task = session.task {
            AssistantView(model: model, question: FlowL.text("Make it smaller") + ": " + task.title, parentTaskID: task.id)
                .id(session.id)
        } else {
            AddTaskView(model: model).id(session.id)
        }
    }
    private func openPendingBreakdown() {
        guard let item = pendingBreakdown else { return }
        pendingBreakdown = nil
        assistantSession = AssistantSession(task: item)
    }
}
