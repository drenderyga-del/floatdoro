import AppKit
import Combine
import SwiftUI

struct FloatingWidgetView: View {
    @ObservedObject var store: TimerStore

    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.pomoReduceMotionOverride) private var reduceMotionOverride

    private var palette: PomoPalette { store.theme.palette }
    private var phaseColor: Color {
        store.phase == .focus ? palette.focusAccent : palette.restAccent
    }
    private var phaseForeground: Color {
        store.phase == .focus ? palette.onFocusAccent : palette.onRestAccent
    }
    private var reduceMotion: Bool {
        reduceMotionOverride ?? systemReduceMotion
    }

    private var waitingTasks: [FocusTask] {
        let unfinished = store.unfinishedTasks
        return store.phase == .focus
            ? Array(unfinished.dropFirst())
            : unfinished
    }

    private var queue: [FocusTask] {
        waitingTasks + store.currentSessionTasks.filter(\.isCompleted)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(.ultraThinMaterial)

                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(palette.canvas.opacity(0.80))

                RadialGradient(
                    colors: [phaseColor.opacity(0.15), .clear],
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: 300
                )
                .allowsHitTesting(false)

                VStack(spacing: 0) {
                    floatingHeader
                    timerContent

                    if store.isFloatingExpanded {
                        expandedQueue
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(.white.opacity(0.26), lineWidth: 0.8)
            }
            .overlay(alignment: .bottomTrailing) {
                resizeAffordance
            }
            .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .environment(\.pomoPalette, palette)
        .tint(phaseColor)
        .preferredColorScheme(store.theme.colorScheme)
    }

    private var floatingHeader: some View {
        HStack(spacing: 8) {
            ModeBadge(
                phase: store.phase,
                title: store.phaseStatusLabel,
                accessibilityLabel: store.phaseStatusAccessibilityLabel
            )

            Spacer(minLength: 8)

            Button {
                store.setFloatingExpanded(!store.isFloatingExpanded)
            } label: {
                HStack(spacing: 5) {
                    Image(
                        systemName: store.isFloatingExpanded
                            ? "list.bullet.rectangle.fill"
                            : "list.bullet"
                    )
                    Text("\(waitingTasks.count)")
                        .monospacedDigit()
                }
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(
                    store.isFloatingExpanded ? phaseColor : palette.muted
                )
                .frame(minWidth: 36, minHeight: 32)
                .background {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(palette.surface.opacity(0.52))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(FloatingIconButtonStyle())
            .accessibilityLabel(
                store.isFloatingExpanded
                    ? appText("Скрыть очередь задач", "Hide task queue")
                    : appText("Показать очередь задач", "Show task queue")
            )
            .pomoHelp(
                store.isFloatingExpanded
                    ? appText("Скрыть очередь задач", "Hide task queue")
                    : appText("Показать очередь задач", "Show task queue")
            )

            Button {
                store.setFloatingVisible(false)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(palette.muted)
                    .frame(width: 32, height: 32)
                    .background {
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .fill(palette.surface.opacity(0.52))
                    }
                    .contentShape(Rectangle())
            }
            .buttonStyle(FloatingIconButtonStyle())
            .accessibilityLabel(
                appText("Скрыть плавающий таймер", "Hide floating timer")
            )
            .pomoHelp(
                appText("Скрыть плавающий таймер", "Hide floating timer")
            )
        }
        .frame(height: 48)
        .padding(.horizontal, 16)
    }

    private var timerContent: some View {
        VStack(spacing: 14) {
            HStack(alignment: .lastTextBaseline, spacing: 12) {
                Text(store.displayTime)
                    .font(.system(size: 60, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .tracking(-1.8)
                    .foregroundStyle(palette.ink)
                    .contentTransition(
                        reduceMotion
                            ? .identity
                            : .numericText(countsDown: true)
                    )
                    .minimumScaleFactor(0.72)
                    .lineLimit(1)
                    .accessibilityLabel(
                        timerAccessibilityLabel(seconds: store.remainingSeconds)
                    )

                Spacer(minLength: 0)

                VStack(alignment: .trailing, spacing: 2) {
                    Text(
                        floatingTimerState
                    )
                    .foregroundStyle(store.isRunning ? phaseColor : palette.muted)

                    Text(timerDisplay(seconds: store.durationSeconds))
                        .monospacedDigit()
                        .foregroundStyle(palette.muted)
                }
                .font(.system(size: 10, weight: .semibold))
                .textCase(.uppercase)
                .tracking(0.45)
            }

            ProgressRail(progress: store.progress, phase: store.phase)
            floatingTaskLine
            floatingTransport
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 16)
    }

    private var floatingTaskLine: some View {
        HStack(spacing: 9) {
            Image(
                systemName: store.phase == .focus
                    ? "scope"
                    : "cup.and.saucer.fill"
            )
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(phaseColor)
            .frame(width: 17)

            Text(floatingTaskTitle)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(palette.ink)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)

            if store.canCompleteTask {
                Button {
                    store.completeCurrentTask()
                } label: {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(phaseColor)
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(FloatingIconButtonStyle())
                .accessibilityLabel(
                    appText("Завершить текущую задачу", "Complete current task")
                )
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(palette.surface.opacity(0.68))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(.white.opacity(0.22), lineWidth: 0.75)
        }
    }

    private var floatingTransport: some View {
        HStack(spacing: 8) {
            floatingUtilityButton(
                systemImage: "arrow.counterclockwise",
                label: appText(
                    "Сбросить текущий интервал",
                    "Reset current interval"
                ),
                action: store.resetCurrentInterval
            )

            Button {
                store.toggleRunning()
            } label: {
                HStack(spacing: 7) {
                    Image(
                        systemName: store.isRunning
                            ? "pause.fill"
                            : "play.fill"
                    )
                    Text(
                        store.isRunning
                            ? appText("Пауза", "Pause")
                            : appText("Старт", "Start")
                    )
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(phaseForeground)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background {
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .fill(phaseColor)
                        .shadow(color: phaseColor.opacity(0.22), radius: 10, y: 4)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(FloatingPrimaryButtonStyle())
            .accessibilityLabel(
                store.isRunning
                    ? appText("Поставить таймер на паузу", "Pause timer")
                    : appText("Запустить таймер", "Start timer")
            )

            floatingUtilityButton(
                systemImage: "forward.fill",
                label: nextPhaseAccessibilityLabel,
                action: store.skipToNextPhase
            )
        }
    }

    private func floatingUtilityButton(
        systemImage: String,
        label: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(palette.ink)
                .frame(width: 40, height: 40)
                .background {
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .fill(palette.surface.opacity(0.70))
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(FloatingIconButtonStyle())
        .accessibilityLabel(label)
        .pomoHelp(label)
    }

    private var expandedQueue: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(appText("Очередь", "Queue"))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(palette.ink)
                Spacer()
                Text(
                    appText(
                        "\(waitingTasks.count) в очереди",
                        "\(waitingTasks.count) queued"
                    )
                )
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(palette.muted)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)

            if queue.isEmpty {
                VStack(spacing: 7) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 17))
                    Text(appText("Очередь пуста", "The queue is empty"))
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(palette.muted)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(12)
                .accessibilityElement(children: .combine)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(queue.enumerated()), id: \.element.id) {
                            index,
                            task in
                            TaskRow(
                                task: task,
                                toggle: { store.toggleTask(id: task.id) },
                                delete: { store.deleteTask(id: task.id) }
                            )

                            if index < queue.count - 1 {
                                Rectangle()
                                    .fill(palette.border)
                                    .frame(height: 1)
                                    .padding(.leading, 40)
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.bottom, 8)
                }
                .scrollIndicators(.automatic)
            }
        }
        .background {
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .fill(palette.surface.opacity(0.56))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .stroke(.white.opacity(0.20), lineWidth: 0.75)
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 10)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private var floatingTaskTitle: String {
        if store.phase == .focus {
            return store.activeTaskTitle
        }
        if let nextTask = store.focusTask {
            return appText("Далее: \(nextTask.title)", "Next: \(nextTask.title)")
        }
        return store.activeTaskTitle
    }

    private var floatingTimerState: String {
        if store.isRunning {
            return appText("ИДЁТ", "RUNNING")
        }
        if store.progress > 0 {
            return appText("ПАУЗА", "PAUSED")
        }
        return appText("ГОТОВ", "READY")
    }

    private var nextPhaseAccessibilityLabel: String {
        store.phase == .focus
            ? appText(
                "Перейти к \(store.resolvedRestStatusLabel.lowercased())",
                "Start \(store.resolvedRestStatusLabel)"
            )
            : appText(
                "Перейти к \(store.resolvedWorkStatusLabel.lowercased())",
                "Start \(store.resolvedWorkStatusLabel)"
            )
    }

    private var resizeAffordance: some View {
        Image(systemName: "line.diagonal.arrow")
            .font(.system(size: 8, weight: .semibold))
            .foregroundStyle(palette.muted.opacity(0.55))
            .rotationEffect(.degrees(90))
            .padding(.trailing, 6)
            .padding(.bottom, 5)
            .accessibilityHidden(true)
    }
}

private struct FloatingIconButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.pomoReduceMotionOverride) private var reduceMotionOverride

    private var reduceMotion: Bool {
        reduceMotionOverride ?? systemReduceMotion
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.7 : 1)
            .animation(
                reduceMotion ? nil : .easeOut(duration: 0.12),
                value: configuration.isPressed
            )
    }
}

private struct FloatingPrimaryButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.pomoReduceMotionOverride) private var reduceMotionOverride

    private var reduceMotion: Bool {
        reduceMotionOverride ?? systemReduceMotion
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.985 : 1)
            .brightness(configuration.isPressed ? -0.06 : 0)
            .animation(
                reduceMotion ? nil : .easeOut(duration: 0.12),
                value: configuration.isPressed
            )
    }
}

private final class DraggableHostingView<Content: View>: NSHostingView<Content> {
    override var mouseDownCanMoveWindow: Bool { true }
}

private final class TopMovablePanel: NSPanel {
    override func constrainFrameRect(
        _ frameRect: NSRect,
        to screen: NSScreen?
    ) -> NSRect {
        frameRect
    }
}

@MainActor
final class FloatingPanelController {
    private let store: TimerStore
    private let persistsFrame: Bool
    private var panel: NSPanel?
    private var cancellables: Set<AnyCancellable> = []

    private let compactSize = NSSize(width: 368, height: 280)
    private let expandedSize = NSSize(width: 368, height: 468)

    init(store: TimerStore, persistsFrame: Bool = true) {
        self.store = store
        self.persistsFrame = persistsFrame

        store.$isFloatingExpanded
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] isExpanded in
                self?.resizePanel(isExpanded: isExpanded)
            }
            .store(in: &cancellables)
    }

    func setVisible(_ visible: Bool) {
        if visible {
            show()
        } else if panel?.isVisible == true {
            panel?.orderOut(nil)
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

    private func resizePanel(isExpanded: Bool) {
        guard let panel else { return }
        let preferred = isExpanded ? expandedSize : compactSize
        var frame = panel.frame
        let anchoredTop = frame.maxY
        frame.size.width = max(frame.width, preferred.width)
        frame.size.height = preferred.height
        frame.origin.y = anchoredTop - preferred.height
        panel.setFrame(frame, display: true, animate: false)
    }

    private func makePanel() -> NSPanel {
        let defaultSize = store.isFloatingExpanded ? expandedSize : compactSize
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
        panel.animationBehavior = .none
        panel.isReleasedWhenClosed = false
        panel.minSize = NSSize(width: 336, height: 260)
        panel.maxSize = NSSize(width: 620, height: 680)
        panel.standardWindowButton(.closeButton)?.isHidden = true
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true
        panel.initialFirstResponder = nil

        let hostingView = DraggableHostingView(
            rootView: FloatingWidgetView(store: store)
        )
        hostingView.sizingOptions = []
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor
        panel.contentView = hostingView

        let restoredFrame = persistsFrame && panel.setFrameUsingName(
            "PomoFloatingPanelCurrentV2"
        )
        if let screen = NSScreen.main, !restoredFrame {
            let visible = screen.visibleFrame
            let origin = NSPoint(
                x: visible.maxX - panel.frame.width - 20,
                y: visible.maxY - panel.frame.height - 16
            )
            panel.setFrameOrigin(origin)
        }
        if persistsFrame {
            panel.setFrameAutosaveName("PomoFloatingPanelCurrentV2")
        }
        return panel
    }
}
