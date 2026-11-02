import SwiftUI

struct PlansView: View {
    @ObservedObject var model: FlowModel
    var start: (FlowItem) -> Void
    var edit: (FlowItem) -> Void
    @SceneStorage("plansStatus") private var status = "Active"
    @SceneStorage("plansCategory") private var category = "All"
    @State private var search = ""
    @State private var showingSearch = false
    @SwiftUI.FocusState private var searchFocused: Bool
    @State private var targetedGroup: String?
    @State private var draft: FlowItem?
    @State private var deletion: FlowItem?
    @ObservedObject private var language = FlowLanguageSettings.shared
    @Environment(\.compactFlow) private var compact
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var projects: [FlowItem] { model.items.filter { $0.kind == "Project" }.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending } }
    private var visible: [FlowItem] {
        let matchingProjects = Set(projects.filter { $0.title.localizedCaseInsensitiveContains(search) }.map(\.id))
        let candidates = model.items.filter { item in
            let matches = search.isEmpty || (item.title + " " + (item.step ?? "")).localizedCaseInsensitiveContains(search)
                || item.projectID.map { matchingProjects.contains($0) } == true
            return item.kind != "Project"
                && (status == "All" || (status == "Completed" ? item.done == true : item.done != true))
                && matches
        }.sorted {
            if ($0.done == true) != ($1.done == true) { return $0.done != true }
            return $0.created < $1.created
        }
        let candidateIDs = Set(candidates.map(\.id))
        return candidates.filter { item in
            guard let parent = item.parentTaskID else { return true }
            return !candidateIDs.contains(parent)
        }
    }
    private var ungrouped: [FlowItem] {
        let projectIDs = Set(projects.map(\.id))
        return visible.filter { item in item.kind != "Habit" && (item.projectID == nil || !projectIDs.contains(item.projectID!)) }
    }
    private var rituals: [FlowItem] { visible.filter { $0.kind == "Habit" } }
    private var shownProjects: [FlowItem] {
        projects.filter { project in
            search.isEmpty || project.title.localizedCaseInsensitiveContains(search)
                || visible.contains { $0.projectID == project.id }
        }
    }
    private func groupWords(_ english: String, _ portuguese: String, _ spanish: String) -> String {
        language.code == "pt-BR" ? portuguese : language.code == "es" ? spanish : english
    }
    private func sectionHeading(_ title: String, symbol: String) -> some View {
        Label(title, systemImage: symbol).font(.title3.weight(.semibold))
            .foregroundStyle(.primary)
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 12) {
                HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Label(FlowL.text("Later").uppercased(), systemImage: "calendar")
                        .font(.flowCaption.weight(.semibold)).tracking(2).foregroundStyle(.secondary)
                    Text(groupWords("Make room for what matters, at your own pace.", "Abra espaço para o que importa, no seu ritmo.", "Haz espacio para lo que importa, a tu ritmo."))
                        .font(.flowCallout).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                PipPortrait().frame(width: 48, height: 48)
                }
                }.frame(maxWidth: .infinity, alignment: .leading).worldSurface(emphasis: true)
                VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 4) {
                if showingSearch {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary).padding(.leading, 14)
                    TextField(FlowL.text("Search tasks"), text: $search)
                        .textFieldStyle(.plain)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .focused($searchFocused)
                        .onAppear { searchFocused = true }
                        .transition(.opacity)
                } else {
                FlowPillTabs(title: groupWords("Show", "Mostrar", "Mostrar"),
                    values: ["All", "Actions", "Projects", "Habits"],
                    labels: [FlowL.text("All"), groupWords("Actions", "Ações", "Acciones"), groupWords("Projects", "Projetos", "Proyectos"), groupWords("Habits", "Hábitos", "Hábitos")],
                    selection: $category, embedded: true)
                statusMenu
                }
                Button {
                    showingSearch.toggle()
                    if !showingSearch { search = "" }
                    searchFocused = showingSearch
                } label: {
                    Image(systemName: showingSearch ? "xmark" : "magnifyingglass")
                        .frame(width: 44, height: 44)
                }.buttonStyle(.plain)
                    .foregroundStyle(showingSearch ? Color.accentColor : Color.primary)
                    .accessibilityLabel(FlowL.text(showingSearch ? "Close" : "Search tasks"))
                    .help(FlowL.text(showingSearch ? "Close" : "Search tasks"))
                    .keyboardShortcut("f", modifiers: .command)
                }.padding(4)
                    .background {
                        if reduceTransparency { Capsule().fill(Color.flowWindowBackground) }
                        else { Capsule().fill(.ultraThinMaterial) }
                    }
                    .overlay(Capsule().strokeBorder(Color.primary.opacity(0.12), lineWidth: 0.75))
                    .clipShape(Capsule())
                    .animation(reduceMotion ? nil : .easeInOut(duration: 0.22), value: showingSearch)
                }.frame(maxWidth: .infinity, alignment: .leading)
                LazyVStack(alignment: .leading, spacing: 18) {
                    if category == "All" || category == "Actions" {
                    VStack(alignment: .leading, spacing: 16) {
                    sectionHeading(groupWords("Actions", "Ações", "Acciones"), symbol: "checklist")
                    Divider().overlay(Color.accentColor.opacity(0.08))
                    ungroupedList
                    }.frame(maxWidth: .infinity, alignment: .leading).worldSurface(emphasis: true)
                    }
                    if category == "All" || category == "Projects" {
                    HStack {
                        sectionHeading(groupWords("Projects", "Projetos", "Proyectos"), symbol: "folder")
                        Spacer()
                        Button { edit(FlowItem(title: "", kind: "Project")) } label: {
                            Image(systemName: "plus")
                        }.help(FlowL.text("New project")).accessibilityLabel(FlowL.text("New project"))
                    }
                    if shownProjects.isEmpty {
                        Text(groupWords("No projects here yet.", "Nenhum projeto por aqui ainda.", "Todavía no hay proyectos aquí."))
                            .font(.flowCallout).foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading).worldSurface(emphasis: true)
                    }
                    ForEach(shownProjects) { project in
                        taskGroup(title: project.title, project: project, children: visible.filter { $0.projectID == project.id && $0.kind != "Habit" })
                    }
                    }
                    if category == "All" || category == "Habits" {
                    VStack(alignment: .leading, spacing: 16) {
                    sectionHeading(groupWords("Rituals / habits", "Rituais / hábitos", "Rituales / hábitos"), symbol: "repeat")
                    Divider().overlay(Color.accentColor.opacity(0.08))
                    if rituals.isEmpty {
                        Text(groupWords("Your recurring tasks will appear here.", "Suas tarefas recorrentes aparecerão aqui.", "Tus tareas recurrentes aparecerán aquí."))
                            .font(.flowCallout).foregroundStyle(.secondary)
                    } else {
                        VStack(spacing: 0) {
                            ForEach(rituals) { item in
                                if item.id != rituals.first?.id { Divider() }
                                planRow(item).padding(.vertical, 14)
                            }
                        }
                    }
                    }.frame(maxWidth: .infinity, alignment: .leading).worldSurface(emphasis: true)
                    }
                }
            }.padding(compact ? 16 : 36).frame(maxWidth: .infinity)
        }
        .confirmationDialog(FlowL.text("Delete this plan?"), isPresented: Binding(get: { deletion != nil }, set: { if !$0 { deletion = nil } }), titleVisibility: .visible) {
            Button(FlowL.text("Delete"), role: .destructive) { if let item = deletion { model.delete(item) }; deletion = nil }
            Button(FlowL.text("Cancel"), role: .cancel) { deletion = nil }
        } message: {
            Text(FlowL.text(deletion?.kind == "Project" ? "The project is removed. Its tasks and habits stay in your plans." : "This removes the plan and its saved habit history."))
        }
    }
    private var statusMenu: some View {
        Menu {
            Picker(FlowL.text("Status"), selection: $status) {
                Text(FlowL.text("Active")).tag("Active")
                Text(FlowL.text("Completed")).tag("Completed")
                Text(FlowL.text("All")).tag("All")
            }
        } label: { Image(systemName: "line.3.horizontal.decrease.circle").frame(minWidth: 44, minHeight: 44) }
        .menuStyle(.borderlessButton).fixedSize().accessibilityLabel(FlowL.text("Status"))
    }
    private var ungroupedList: some View {
        VStack(spacing: 0) {
            if ungrouped.isEmpty {
                Text(groupWords("Your individual actions will appear here.", "Suas ações individuais aparecerão aqui.", "Tus acciones individuales aparecerán aquí."))
                    .font(.flowCallout).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 8)
            }
            ForEach(ungrouped) { item in
                if item.id != ungrouped.first?.id { Divider() }
                planRow(item).padding(.vertical, 14)
            }
        }
            .frame(maxWidth: .infinity, minHeight: 24)
            .contentShape(Rectangle())
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.accentColor.opacity(targetedGroup == "ungrouped" ? 0.7 : 0), lineWidth: 2)
                    .allowsHitTesting(false)
            }
            .dropDestination(for: String.self) { payloads, _ in
                move(payloads, to: nil)
            } isTargeted: { active in
                if active { targetedGroup = "ungrouped" }
                else if targetedGroup == "ungrouped" { targetedGroup = nil }
            }
    }
    private func taskGroup(title: String, project: FlowItem?, children: [FlowItem]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(title, systemImage: project == nil ? "tray" : "folder").font(.headline)
                if project?.done == true { Image(systemName: "checkmark.seal").foregroundStyle(Color.accentColor).accessibilityLabel(FlowL.text("Completed")) }
                Text(String(children.count)).font(.flowCaption).foregroundStyle(.secondary)
                Spacer()
                if let project {
                    Menu {
                        Button(FlowL.text("Edit project")) { openDetails(project) }
                        if project.done == true {
                            Button(FlowL.text("Reopen project")) { var copy = project; copy.done = false; model.put(copy) }
                        } else {
                            Button(FlowL.text("Finish project")) { model.complete(project) }
                        }
                        Button(FlowL.text("Delete…"), role: .destructive) { deletion = project }
                    } label: { Image(systemName: "ellipsis") }.menuStyle(.borderlessButton).fixedSize()
                        .accessibilityLabel(FlowL.text("Plan actions") + ": " + title)
                }
            }.padding(.vertical, 6)
            if children.isEmpty {
                Text(FlowL.text("Drop tasks here")).font(.flowCallout).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 45, alignment: .leading)
            }
            ForEach(children) { item in
                Divider()
                planRow(item)
            }
        }.worldSurface(emphasis: true)
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.accentColor.opacity(targetedGroup == (project?.id.uuidString ?? "ungrouped") ? 0.7 : 0), lineWidth: 2)
                .allowsHitTesting(false)
        }
        .dropDestination(for: String.self) { payloads, _ in
            move(payloads, to: project?.id)
        } isTargeted: { active in
            let key = project?.id.uuidString ?? "ungrouped"
            if active { targetedGroup = key }
            else if targetedGroup == key { targetedGroup = nil }
        }
    }
    @discardableResult private func move(_ payloads: [String], to projectID: UUID?) -> Bool {
        guard projectID == nil || projects.contains(where: { $0.id == projectID }) else { return false }
        var accepted = false
        for payload in payloads where payload.hasPrefix("flow-task:") {
            guard let id = UUID(uuidString: String(payload.dropFirst("flow-task:".count))),
                  var item = model.items.first(where: { $0.id == id }),
                  item.kind != "Project" else { continue }
            item.projectID = projectID
            model.put(item)
            accepted = true
        }
        targetedGroup = nil
        return accepted
    }
    @ViewBuilder private func planRow(_ item: FlowItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Button { openDetails(item) } label: {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(item.title).font(.headline).strikethrough(item.done == true).foregroundStyle(.primary)
                        if let step = item.step, !step.isEmpty { Text(step).font(.flowCallout).foregroundStyle(.secondary) }
                    }.frame(maxWidth: .infinity, minHeight: 36, alignment: .leading)
                        .contentShape(Rectangle())
                }.buttonStyle(.plain).help(FlowL.text("Edit"))
                    .accessibilityLabel(FlowL.text("Edit") + ": " + item.title)
                    .draggable("flow-task:" + item.id.uuidString)
                Menu {
                    Button(FlowL.text("Edit")) { openDetails(item) }
                    Button(FlowL.text("Make it smaller")) { FlowTaskActions.makeSmaller(item) }
                    FlowProjectConversionAction(model: model, item: item)
                    Menu(FlowL.text("Move to project")) {
                        Button(FlowL.text("No project")) { move(["flow-task:" + item.id.uuidString], to: nil) }
                        ForEach(projects) { project in
                            Button(project.title) { move(["flow-task:" + item.id.uuidString], to: project.id) }
                        }
                    }
                    Button(FlowL.text("Start focus")) { start(item) }
                    Button(FlowL.text(model.isToday(item) ? "Remove from today" : "Mark for today")) { model.toggleToday(item) }
                    if item.kind == "Habit" {
                        Button(FlowL.text("Complete this occurrence")) { model.complete(item) }
                            .disabled(!model.canCompleteHabit(item))
                        Button(FlowL.text(item.paused == true ? "Resume habit" : "Pause habit")) { var copy = item; copy.paused = item.paused != true; model.put(copy) }
                    } else {
                        Button(FlowL.text(item.done == true ? "Reopen" : "Mark completed")) { var copy = item; copy.done = item.done != true; model.put(copy) }
                    }
                    Divider()
                    Button(FlowL.text("Delete…"), role: .destructive) { deletion = item }
                } label: { Image(systemName: "ellipsis") }.menuStyle(.borderlessButton).fixedSize()
                    .accessibilityLabel(FlowL.text("Plan actions") + ": " + item.title)
            }
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 12) { details(item) }
                    VStack(alignment: .leading, spacing: 6) { details(item) }
                }.font(.flowCaption).foregroundStyle(.secondary)
            FlowSubtaskTree(model: model, parent: item)
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) { rowActions(item) }
                VStack(alignment: .leading, spacing: 12) { rowActions(item) }
            }
        }.padding(.vertical, 10)
        .contextMenu {
            FlowProjectConversionAction(model: model, item: item)
            Button(FlowL.text("Make it smaller")) { FlowTaskActions.makeSmaller(item) }
            Button(FlowL.text("Start focus")) { start(item) }
            Button(FlowL.text(model.isToday(item) ? "Remove from today" : "Mark for today")) { model.toggleToday(item) }
            Button(FlowL.text("Edit")) { openDetails(item) }
            Menu(FlowL.text("Move to project")) {
                Button(FlowL.text("No project")) { move(["flow-task:" + item.id.uuidString], to: nil) }
                ForEach(projects) { project in
                    Button(project.title) { move(["flow-task:" + item.id.uuidString], to: project.id) }
                }
            }
            Button(FlowL.text("Delete…"), role: .destructive) { deletion = item }
        }
    }
    @ViewBuilder private func rowActions(_ item: FlowItem) -> some View {
                Button { openDetails(item) } label: {
                    Label(FlowL.text("Edit"), systemImage: "square.and.pencil")
                }.buttonStyle(FlowGlassButtonStyle())
                Button { model.toggleToday(item) } label: {
                    Label(groupWords("Today", "Hoje", "Hoy"), systemImage: model.isToday(item) ? "sun.max.fill" : "sun.max")
                }.buttonStyle(FlowGlassButtonStyle())
                    .foregroundStyle(model.isToday(item) ? Color.accentColor : Color.secondary)
                    .help(FlowL.text(model.isToday(item) ? "Remove from today" : "Mark for today"))
                Button { start(item) } label: { Label(FlowL.text("Start focus"), systemImage: "play.fill") }
                    .buttonStyle(FlowGlassButtonStyle(prominent: true))
    }
    private func openDetails(_ item: FlowItem) {
        print("FLOW Later: opening task details \(item.id)")
        edit(model.items.first(where: { $0.id == item.id }) ?? item)
    }
    @ViewBuilder private func details(_ item: FlowItem) -> some View {
        if let id = item.parentTaskID, let parent = model.items.first(where: { $0.id == id }) {
            Label(parent.title, systemImage: "arrow.turn.down.right")
        }
        let children = model.items.filter { $0.parentTaskID == item.id }
        if !children.isEmpty { Text("\(children.filter { $0.done == true }.count)/\(children.count) " + FlowSubtaskWords.text("subtasks", "subtarefas", "subtareas")) }
        if let period = item.schedulePeriod, period != "Any time" { Label(FlowTiming.text(period), systemImage: "clock") }
        if let kind = item.kind, kind != "Habit" { Text(FlowL.text(["Memory", "Idea", "Thought"].contains(kind) ? "Task" : kind)) }
        if item.example == true { Text(FlowL.text("Example")) }
        if item.kind == "Habit" {
            Text(item.paused == true ? FlowL.text("Paused") : FlowRecurrence.summary(item))
            Text(FlowL.format("%@ completions", String(item.completionDates?.count ?? 0)))
        }
        if let due = item.due { Label(due.formatted(date: .abbreviated, time: item.schedulePeriod == "Exact time" ? .shortened : .omitted), systemImage: "calendar") }
        if let id = item.projectID, let project = projects.first(where: { $0.id == id }) { Label(project.title, systemImage: "folder") }
    }
}

struct PlanEditor: View {
    @ObservedObject var model: FlowModel
    let original: FlowItem
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var step = ""
    @State private var minutes: Int?
    @State private var kind = "Task"
    @State private var projectID: UUID?
    @State private var hasDue = false
    @State private var due = Date()
    @State private var cadence = "Daily"
    @State private var paused = false
    @State private var loaded = false
    @State private var confirmDelete = false
    @State private var schedule = FlowItem(title: "", kind: "Task")
    @State private var talkingToAI = false
    @State private var draftSubtasks: [FlowItem] = []
    @State private var showingSubtasks = false
    private var isNew: Bool { !model.items.contains { $0.id == original.id } }
    var body: some View {
        editor.sheet(isPresented: $talkingToAI) {
            FlowStyledRoot {
            AssistantView(model: model, question: isNew ? (title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "" : "Help me create this task. My estimate is \(minutes ?? 25) minutes. Title: \(title). Project: \(model.items.first(where: { $0.id == projectID })?.title ?? "none").") : FlowL.text("Make it smaller") + ": " + title, autoStart: !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, parentTaskID: isNew ? nil : original.id)
                .environment(\.flowConversationBack, { talkingToAI = false })
            }
        }
    }
    private var editor: some View {
        VStack(spacing: 0) {
            HStack {
                Text(kind == "Project" ? FlowL.text(isNew ? "New project" : "Project") : isNew ? FlowSubtaskWords.text("Add task", "Adicionar tarefa", "Añadir tarea") : FlowL.text("Task")).font(.title2.weight(.semibold))
                Spacer()
                Button { dismiss() } label: { Image(systemName: "xmark") }
                    .buttonStyle(FlowGlassButtonStyle())
                    .accessibilityLabel(FlowL.text("Cancel"))
                    .help(FlowL.text("Cancel"))
                    .keyboardShortcut(.cancelAction)
            }.padding(22)
            Divider()
            ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                if kind == "Project" {
                    Text(FlowL.text("Project")).font(.headline)
                    TextField(FlowL.text("Project"), text: $title).flowInput()
                } else {
                    Text(FlowSubtaskWords.text("What do you want to do?", "O que você quer fazer?", "¿Qué quieres hacer?")).font(.headline)
                    TextField(FlowSubtaskWords.text("Write your task here…", "Escreva sua tarefa aqui…", "Escribe tu tarea aquí…"), text: $title, axis: .vertical)
                        .lineLimit(3...8).flowInput(multiline: true)
                        .accessibilityLabel(FlowL.text("Task"))
                }
                if kind == "Project" {
                    Text(FlowL.text("Notes")).font(.headline)
                    TextField(FlowL.text("Notes"), text: $step, axis: .vertical).lineLimit(3...6).flowInput(multiline: true)
                }
                }.worldSurface()
                TaskSourceDetails(item: $schedule)
                if kind != "Project" {
                    TaskDurationField(minutes: $minutes).worldSurface()
                    VStack(alignment: .leading, spacing: 16) {
                        ProjectAssignmentField(model: model, projectID: $projectID)
                        Divider()
                        TaskRepeatControl(item: $schedule)
                        Divider()
                        FlexibleTaskSchedule(item: $schedule)
                    }.worldSurface()
                }
                if kind != "Project" {
                    if showingSubtasks {
                        if isNew { DraftTaskSubtasks(items: $draftSubtasks).worldSurface() }
                        else { FlowSubtasks(model: model, parent: original).worldSurface() }
                    } else {
                        Button { showingSubtasks = true } label: {
                            Label(FlowSubtaskWords.text("Add subtasks", "Adicionar subtarefas", "Añadir subtareas"), systemImage: "plus")
                        }.buttonStyle(FlowGlassButtonStyle())
                    }
                }
                if !isNew {
                    FlowProjectConversionAction(model: model, item: original, beforeConversion: save)
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }.padding(22).frame(maxWidth: .infinity, alignment: .leading)
            }
            Divider()
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 10)], spacing: 10) {
                if !isNew {
                    Button(FlowL.text("Delete"), role: .destructive) { confirmDelete = true }
                }
                if !isNew && original.kind != "Project" {
                    Button(FlowL.text(original.done == true ? "Reopen task" : "Complete")) {
                        save()
                        if let current = model.items.first(where: { $0.id == original.id }) {
                            if current.done == true { var copy = current; copy.done = false; model.put(copy) }
                            else { model.complete(current) }
                        }
                    }
                    .disabled(original.kind == "Habit" && !model.canCompleteHabit(original))
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    Button(FlowL.text("Make it smaller")) {
                        persist(dismissAfter: false)
                        talkingToAI = true
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                if isNew && kind != "Project" {
                    Button { talkingToAI = true } label: {
                        Label(FlowSubtaskWords.text("Talk to AI", "Falar com a IA", "Hablar con la IA"), systemImage: "sparkles")
                    }
                }
                Button(FlowL.text("Save"), action: save).buttonStyle(FlowTaskActionStyle(prominent: true)).keyboardShortcut(.defaultAction)
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .disabled(kind != "Project" && minutes == nil)
            }.buttonStyle(FlowTaskActionStyle())
                .frame(maxWidth: .infinity)
                .padding(16).background(.regularMaterial)
        }.flowSheetSize(width: 680, minimumWidth: 560, height: 780, minimumHeight: 560)
        .background { WorldBackdrop() }
        .background { WindowGlassChrome().frame(width: 0, height: 0) }
        .confirmationDialog(FlowL.text("Delete this plan?"), isPresented: $confirmDelete, titleVisibility: .visible) {
            Button(FlowL.text("Delete"), role: .destructive) { model.delete(original); dismiss() }
            Button(FlowL.text("Cancel"), role: .cancel) { }
        } message: {
            Text(FlowL.text(original.kind == "Project" ? "The project is removed. Its tasks and habits stay in your plans." : "This removes the plan and its saved habit history."))
        }
        .onAppear {
            guard !loaded else { return }; loaded = true
            title = original.title; step = original.step ?? ""; minutes = original.minutes
            schedule = original
            kind = ["Project", "Habit"].contains(original.kind ?? "") ? original.kind! : "Task"; projectID = original.projectID
            hasDue = original.due != nil; due = original.due ?? Date(); paused = original.paused == true
            cadence = original.weekdaysOnly == true ? "Weekdays" : original.repeatDays == 7 ? "Weekly" : original.repeatDays == 2 ? "Every two days" : "Daily"
            showingSubtasks = model.items.contains { $0.parentTaskID == original.id }
        }
    }
    private func save() {
        persist(dismissAfter: true)
    }
    private func persist(dismissAfter: Bool) {
        var item = original
        item.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !item.title.isEmpty else { return }
        guard kind == "Project" || minutes != nil else { return }
        item.step = step.trimmingCharacters(in: .whitespacesAndNewlines)
        item.relatedSources = schedule.relatedSources
        item.kind = kind == "Project" ? "Project" : schedule.kind ?? "Task"; item.minutes = minutes
        item.projectID = kind == "Project" ? nil : projectID
        item.due = schedule.due; item.schedulePeriod = schedule.schedulePeriod; item.reminderEnabled = schedule.reminderEnabled
        FlowRecurrence.copy(from: schedule, to: &item)
        if item.kind == "Habit" {
            item.repeatDays = schedule.repeatDays ?? 1
            item.weekdaysOnly = schedule.weekdaysOnly; item.paused = schedule.paused; item.done = false
        } else { item.repeatDays = nil; item.weekdaysOnly = nil; item.paused = nil }
        model.put(item, suggestBreakdown: dismissAfter)
        for var child in draftSubtasks {
            child.parentTaskID = item.id
            child.projectID = item.projectID
            model.put(child)
        }
        if dismissAfter { dismiss() }
    }
}
