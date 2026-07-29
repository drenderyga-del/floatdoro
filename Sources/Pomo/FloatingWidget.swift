import AppKit
import SwiftUI

struct BehindWindowGlass: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .sidebar
        view.blendingMode = .behindWindow
        view.state = .active
        view.isEmphasized = false
        view.alphaValue = 1
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = .sidebar
        nsView.blendingMode = .behindWindow
        nsView.state = .active
        nsView.alphaValue = 1
    }
}

struct FloatingWidgetView: View {
    @ObservedObject var store: TimerStore

    private var palette: PomoPalette { store.theme.palette }

    private var unfinishedTasks: [FocusTask] {
        store.currentSessionTasks.filter { !$0.isCompleted }
    }

    private var nextTask: FocusTask? {
        unfinishedTasks.dropFirst().first
    }

    private var queuedTasks: [FocusTask] {
        Array(unfinishedTasks.dropFirst())
    }

    private var completedTasks: [FocusTask] {
        store.currentSessionTasks.filter(\.isCompleted)
    }

    private var remainingProgress: Double {
        max(0, min(1, 1 - store.progress))
    }

    private var completedTaskCount: Int {
        completedTasks.count
    }

    var body: some View {
        GeometryReader { geometry in
            let contentSize = CGSize(
                width: geometry.size.width,
                height: max(0, geometry.size.height - 50)
            )

            ZStack {
                if store.theme == .light {
                    palette.canvas
                } else {
                    BehindWindowGlass()
                    Color.black.opacity(0.20)
                }

                VStack(spacing: 0) {
                    header(compact: geometry.size.width < 430)
                        .frame(height: 50)

                    verticalContent(size: contentSize)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(palette.border, lineWidth: 1)
            }
            .overlay(alignment: .bottomTrailing) {
                resizeAffordance
            }
            .contentShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        }
        .environment(\.pomoPalette, palette)
        .preferredColorScheme(store.theme.colorScheme)
    }

    private func header(compact: Bool) -> some View {
        ZStack {
            HStack {
                glassIconButton(
                    systemImage: store.isFloatingExpanded
                        ? "list.bullet.rectangle.fill"
                        : "list.bullet",
                    label: store.isFloatingExpanded
                        ? appText("Скрыть очередь задач", "Hide task queue")
                        : appText("Показать очередь задач", "Show task queue")
                ) {
                    withAnimation(.easeOut(duration: 0.20)) {
                        store.setFloatingExpanded(!store.isFloatingExpanded)
                    }
                }

                Spacer()

                glassIconButton(
                    systemImage: "xmark",
                    label: appText("Скрыть плавающее окно", "Hide floating window")
                ) {
                    store.setFloatingVisible(false)
                }
            }

            HStack(spacing: 7) {
                Circle()
                    .fill(palette.tomato)
                    .frame(width: 9, height: 9)

                Text(store.phaseStatusLabel)
                    .font(.system(size: compact ? 13 : 14, weight: .semibold))
                    .foregroundStyle(palette.tomato)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(store.phaseStatusAccessibilityLabel)
        }
        .padding(.horizontal, compact ? 13 : 16)
    }

    @ViewBuilder
    private func verticalContent(size: CGSize) -> some View {
        let dense = size.height < 360
        let expandedQueue = store.isFloatingExpanded && size.height >= 340
        let showsNext = !expandedQueue && size.height >= 390
        let showsFooter = size.height >= 350

        VStack(spacing: dense ? 7 : 11) {
            timerScale(compact: dense)

            taskPanel(
                expanded: expandedQueue,
                showsNext: showsNext,
                compact: size.width < 410 || dense
            )
            .frame(
                maxHeight: expandedQueue
                    ? max(110, size.height * 0.31)
                    : nil
            )

            actionBar(compact: size.width < 405)

            if showsFooter {
                Spacer(minLength: 0)

                progressFooter
                    .transition(.opacity)
            }
        }
        .padding(.horizontal, size.width < 410 ? 14 : 20)
        .padding(.bottom, dense ? 11 : 15)
        .frame(maxWidth: 520, maxHeight: .infinity, alignment: .top)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func timerScale(compact: Bool) -> some View {
        VStack(spacing: compact ? 5 : 8) {
            Text(store.displayTime)
                .font(
                    .system(
                        size: compact ? 54 : 72,
                        weight: .light,
                        design: .rounded
                    )
                )
                .monospacedDigit()
                .tracking(-1.7)
                .foregroundStyle(palette.ink)
                .contentTransition(.numericText(countsDown: true))
                .minimumScaleFactor(0.72)
                .accessibilityLabel(
                    timerAccessibilityLabel(seconds: store.remainingSeconds)
                )

            Text(appText("из", "of") + " \(timerDisplay(seconds: store.durationSeconds))")
                .font(.system(size: compact ? 14 : 17, weight: .medium))
                .monospacedDigit()
                .foregroundStyle(palette.muted)

            SegmentedTimeScale(
                remainingProgress: remainingProgress,
                segmentCount: 10
            )
            .frame(maxWidth: 380)
            .frame(height: compact ? 10 : 13)
            .padding(.top, compact ? 3 : 7)

            HStack {
                Text("0")
                Spacer()
                Text(timerDisplay(seconds: store.durationSeconds / 2))
                Spacer()
                Text(timerDisplay(seconds: store.durationSeconds))
            }
            .font(.system(size: compact ? 10 : 11, weight: .medium))
            .monospacedDigit()
            .foregroundStyle(palette.muted)
            .frame(maxWidth: 380)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
    }

    private func taskPanel(
        expanded: Bool,
        showsNext: Bool,
        compact: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: compact ? 7 : 9) {
            if expanded {
                HStack {
                    Text(appText("Задачи", "Tasks"))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(palette.muted)

                    Spacer()

                    Text(appText("\(unfinishedTasks.count) осталось", "\(unfinishedTasks.count) left"))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(palette.muted)
                }

                if unfinishedTasks.isEmpty {
                    emptyTaskRow
                } else {
                    ScrollView {
                        LazyVStack(spacing: 6) {
                            if let activeTask = store.activeTask {
                                GlassTaskRow(
                                    task: activeTask,
                                    isActive: true,
                                    isQuiet: false,
                                    action: {
                                        store.completeCurrentTask()
                                    }
                                )
                            }

                            ForEach(queuedTasks) { task in
                                GlassTaskRow(
                                    task: task,
                                    isActive: false,
                                    isQuiet: false,
                                    action: {
                                        store.toggleTask(id: task.id)
                                    }
                                )
                            }

                            if !completedTasks.isEmpty {
                                ForEach(completedTasks) { task in
                                    GlassTaskRow(
                                        task: task,
                                        isActive: false,
                                        isQuiet: true,
                                        action: {
                                            store.toggleTask(id: task.id)
                                        }
                                    )
                                }
                            }
                        }
                    }
                    .scrollIndicators(.never)
                }
            } else {
                Text(appText("Текущая задача", "Current task"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(palette.muted)

                if let task = store.activeTask {
                    GlassTaskRow(
                        task: task,
                        isActive: true,
                        isQuiet: false,
                        action: {
                            store.completeCurrentTask()
                        }
                    )
                } else {
                    emptyTaskRow
                }

                if showsNext, let nextTask {
                    Text(appText("Далее", "Next"))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(palette.muted)
                        .padding(.top, 1)

                    GlassTaskRow(
                        task: nextTask,
                        isActive: false,
                        isQuiet: true,
                        action: {
                            store.toggleTask(id: nextTask.id)
                        }
                    )
                }
            }
        }
        .padding(compact ? 11 : 13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(palette.raised.opacity(0.72))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(palette.border, lineWidth: 1)
        }
    }

    private var emptyTaskRow: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(palette.tomato)
                .frame(width: 9, height: 9)

            Text(store.activeTaskTitle)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(palette.ink)
                .lineLimit(2)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(palette.raised.opacity(0.92))
        }
    }

    private func actionBar(compact: Bool) -> some View {
        HStack(spacing: compact ? 7 : 9) {
            GlassActionButton(
                systemImage: store.isRunning ? "pause.fill" : "play.fill",
                title: compact
                    ? nil
                    : (store.isRunning ? appText("Пауза", "Pause") : appText("Старт", "Start")),
                accessibilityLabel: store.isRunning
                    ? appText("Поставить на паузу", "Pause timer")
                    : appText("Запустить таймер", "Start timer"),
                isEnabled: true
            ) {
                store.toggleRunning()
            }

            GlassActionButton(
                systemImage: "checkmark",
                title: compact ? nil : appText("Готово", "Done"),
                accessibilityLabel: appText("Завершить текущую задачу", "Complete current task"),
                isEnabled: store.canCompleteTask
            ) {
                store.completeCurrentTask()
            }

            GlassActionButton(
                systemImage: "forward.fill",
                title: compact ? nil : appText("Дальше", "Next"),
                accessibilityLabel: store.phase == .focus
                    ? appText("Перейти к \(store.resolvedRestStatusLabel.lowercased())", "Start \(store.resolvedRestStatusLabel)")
                    : appText("Перейти к \(store.resolvedWorkStatusLabel.lowercased())", "Start \(store.resolvedWorkStatusLabel)"),
                isEnabled: true
            ) {
                store.skipToNextPhase()
            }
        }
    }

    private var progressFooter: some View {
        HStack {
            Label {
                Text("\(sessionCountInSet) / 4")
            } icon: {
                Image(systemName: "timer")
            }

            Spacer()

            Label {
                Text(appText("\(completedTaskCount) / \(store.currentSessionTasks.count) задач", "\(completedTaskCount) / \(store.currentSessionTasks.count) tasks"))
            } icon: {
                Image(systemName: "checkmark.circle")
            }
        }
        .font(.system(size: 11, weight: .medium))
        .foregroundStyle(palette.muted)
        .padding(.horizontal, 7)
    }

    private var sessionCountInSet: Int {
        guard store.completedSessions > 0 else { return 0 }
        let remainder = store.completedSessions % 4
        return remainder == 0 ? 4 : remainder
    }

    private func glassIconButton(
        systemImage: String,
        label: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(palette.ink)
                .frame(width: 34, height: 34)
                .background {
                    Circle()
                        .fill(palette.raised.opacity(0.72))
                }
                .overlay {
                    Circle()
                        .stroke(palette.border, lineWidth: 1)
                }
                .contentShape(Circle())
        }
        .buttonStyle(GlassPressButtonStyle())
        .accessibilityLabel(label)
        .help(label)
    }

    private var resizeAffordance: some View {
        Image(systemName: "line.diagonal.arrow")
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(palette.muted.opacity(0.55))
            .rotationEffect(.degrees(90))
            .padding(.trailing, 8)
            .padding(.bottom, 7)
            .accessibilityHidden(true)
    }
}

private struct SegmentedTimeScale: View {
    let remainingProgress: Double
    let segmentCount: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.pomoPalette) private var palette

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<segmentCount, id: \.self) { index in
                GeometryReader { geometry in
                    let fill = fillAmount(for: index)

                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(palette.raised)

                        Capsule()
                            .fill(palette.tomato)
                            .frame(
                                width: geometry.size.width * fill
                            )
                    }
                    .clipShape(Capsule())
                }
                .frame(maxWidth: .infinity)
            }
        }
        .animation(
            reduceMotion ? nil : .linear(duration: 0.28),
            value: remainingProgress
        )
        .accessibilityElement()
        .accessibilityLabel(appText("Оставшееся время", "Time remaining"))
        .accessibilityValue(
            appText(
                "\(Int(remainingProgress * 100)) процентов",
                "\(Int(remainingProgress * 100)) percent"
            )
        )
    }

    private func fillAmount(for index: Int) -> CGFloat {
        let scaledProgress =
            remainingProgress * Double(segmentCount)
            - Double(index)
        return CGFloat(min(max(scaledProgress, 0), 1))
    }
}

private struct GlassTaskRow: View {
    let task: FocusTask
    let isActive: Bool
    let isQuiet: Bool
    let action: () -> Void
    @Environment(\.pomoPalette) private var palette

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Circle()
                    .fill(
                        task.isCompleted
                            ? palette.muted.opacity(0.55)
                            : (isActive
                                ? palette.tomato
                                : palette.muted.opacity(0.55))
                    )
                    .frame(width: 9, height: 9)

                Text(task.title)
                    .font(
                        .system(
                            size: 14,
                            weight: isActive ? .semibold : .regular
                        )
                    )
                    .foregroundStyle(
                        task.isCompleted || isQuiet
                            ? palette.muted
                            : palette.ink
                    )
                    .strikethrough(
                        task.isCompleted,
                        color: palette.muted
                    )
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Image(
                    systemName: task.isCompleted
                        ? "checkmark"
                        : "list.bullet"
                )
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(palette.muted)
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 10)
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        isActive
                            ? palette.raised.opacity(0.92)
                            : palette.raised.opacity(0.42)
                    )
            }
            .contentShape(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
        }
        .buttonStyle(GlassPressButtonStyle())
        .accessibilityLabel(
            task.isCompleted
                ? appText(
                    "Вернуть задачу \(task.title)",
                    "Restore task \(task.title)"
                )
                : appText(
                    "Завершить задачу \(task.title)",
                    "Complete task \(task.title)"
                )
        )
    }
}

struct GlassActionButton: View {
    let systemImage: String
    let title: String?
    let accessibilityLabel: String
    let isEnabled: Bool
    let action: () -> Void
    @Environment(\.pomoPalette) private var palette

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 14, weight: .semibold))

                if let title {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                }
            }
            .foregroundStyle(palette.ink)
            .frame(maxWidth: .infinity, minHeight: 42)
            .background {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(palette.raised.opacity(0.72))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(palette.border, lineWidth: 1)
            }
            .contentShape(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
            )
        }
        .buttonStyle(GlassPressButtonStyle())
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.38)
        .accessibilityLabel(accessibilityLabel)
    }
}

struct GlassPressButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(
                configuration.isPressed && !reduceMotion
                    ? 0.96
                    : 1
            )
            .brightness(configuration.isPressed ? -0.035 : 0)
            .animation(
                reduceMotion ? nil : .easeOut(duration: 0.14),
                value: configuration.isPressed
            )
    }
}

private final class DraggableHostingView<Content: View>: NSHostingView<Content> {
    override var mouseDownCanMoveWindow: Bool { true }
}

private final class TopMovablePanel: NSPanel {
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        frameRect
    }
}

@MainActor
final class FloatingPanelController {
    private let store: TimerStore
    private var panel: NSPanel?

    init(store: TimerStore) {
        self.store = store
    }

    func setVisible(_ visible: Bool) {
        if visible {
            show()
        } else {
            if panel?.isVisible == true {
                panel?.orderOut(nil)
            }
        }
    }

    private func show() {
        if panel == nil {
            panel = makePanel()
        }
        guard panel?.isVisible != true else { return }
        panel?.orderFrontRegardless()
        panel?.makeFirstResponder(nil)
    }

    private func makePanel() -> NSPanel {
        let defaultSize = NSSize(width: 448, height: 500)
        let panel = TopMovablePanel(
            contentRect: NSRect(origin: .zero, size: defaultSize),
            styleMask: [
                .borderless,
                .resizable,
                .nonactivatingPanel
            ],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.titlebarSeparatorStyle = .none
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        panel.isMovableByWindowBackground = true
        panel.animationBehavior = .utilityWindow
        panel.isReleasedWhenClosed = false
        panel.minSize = NSSize(width: 360, height: 400)
        panel.maxSize = NSSize(width: 860, height: 820)
        panel.standardWindowButton(.closeButton)?.isHidden = true
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true
        panel.initialFirstResponder = nil

        let hostingView = DraggableHostingView(
            rootView: FloatingWidgetView(store: store)
        )
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor
        panel.contentView = hostingView

        if
            let screen = NSScreen.main,
            !panel.setFrameUsingName("PomoFloatingPanelGlassV7")
        {
            let visible = screen.visibleFrame
            let origin = NSPoint(
                x: visible.maxX - panel.frame.width - 20,
                y: visible.maxY - panel.frame.height - 16
            )
            panel.setFrameOrigin(origin)
        }
        panel.setFrameAutosaveName("PomoFloatingPanelGlassV7")
        return panel
    }
}
