import SwiftUI

// DIRECTION CONTRACT — Quiet Current
// THESIS: a contemporary macOS instrument with depth, air, and one landmark timecode.
// OWN WORLD: cool translucent material, near-black type, coral Work, blue Rest.
// STORY: identify the phase, read the time, act, then manage what comes next.
// FIRST VIEWPORT: timer, current task, transport, and queue are visible at once.
// FORM: native material, soft grouped surfaces, tabular numerals, restrained SF Symbols.
// FINISH: keyboard, VoiceOver, localization, contrast, and Reduce Motion all ship.
struct PopoverView: View {
    enum Page: Equatable {
        case timer
        case history
        case settings

        var title: String {
            switch self {
            case .timer: ""
            case .history: appText("История", "History")
            case .settings: appText("Настройки", "Settings")
            }
        }
    }

    private enum StatusField: Hashable {
        case work
        case rest
    }

    @ObservedObject var store: TimerStore
    let onQuit: () -> Void

    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.pomoReduceMotionOverride) private var reduceMotionOverride
    @State private var page: Page = .timer
    @State private var newTaskTitle = ""
    @FocusState private var focusedStatusField: StatusField?

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

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)

            palette.canvas.opacity(0.82)

            RadialGradient(
                colors: [phaseColor.opacity(0.12), .clear],
                center: .topLeading,
                startRadius: 0,
                endRadius: 310
            )
            .allowsHitTesting(false)

            VStack(spacing: 0) {
                toolbar

                Group {
                    switch page {
                    case .timer:
                        timerPage
                    case .history:
                        HistoryView(store: store)
                    case .settings:
                        settingsPage
                    }
                }
                .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .environment(\.pomoPalette, palette)
        .tint(phaseColor)
        .preferredColorScheme(store.theme.colorScheme)
    }

    private var toolbar: some View {
        HStack(spacing: 7) {
            if page == .timer {
                ModeBadge(
                    phase: store.phase,
                    title: store.phaseStatusLabel,
                    accessibilityLabel: store.phaseStatusAccessibilityLabel
                )
            } else {
                Button {
                    navigate(to: .timer)
                } label: {
                    HStack(spacing: 7) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 11, weight: .semibold))
                        Text(page.title)
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(palette.ink)
                    .frame(minHeight: 28)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(
                    appText("Вернуться к таймеру", "Back to timer")
                )
            }

            Spacer(minLength: 8)

            if page == .timer {
                toolbarButton(
                    systemImage: "rectangle.on.rectangle",
                    label: store.isFloatingVisible
                        ? appText("Скрыть плавающий таймер", "Hide floating timer")
                        : appText("Показать плавающий таймер", "Show floating timer"),
                    isSelected: store.isFloatingVisible
                ) {
                    store.setFloatingVisible(!store.isFloatingVisible)
                }

                toolbarButton(
                    systemImage: "clock.arrow.circlepath",
                    label: appText("Открыть историю", "Open history")
                ) {
                    navigate(to: .history)
                }

                toolbarButton(
                    systemImage: "gearshape",
                    label: appText("Открыть настройки", "Open settings")
                ) {
                    navigate(to: .settings)
                }
            }
        }
        .frame(height: 48)
        .padding(.horizontal, 18)
    }

    private func toolbarButton(
        systemImage: String,
        label: String,
        isSelected: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isSelected ? palette.ink : palette.muted)
                .frame(width: 32, height: 32)
                .background {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(
                            isSelected
                                ? phaseWash.opacity(0.92)
                                : palette.surface.opacity(0.46)
                        )
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(PomoIconButtonStyle())
        .accessibilityLabel(label)
        .pomoHelp(label)
    }

    private var timerPage: some View {
        VStack(spacing: 10) {
            timerStage
            taskQueue
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private var timerStage: some View {
        VStack(spacing: 17) {
            VStack(spacing: 4) {
                Text(store.displayTime)
                    .font(.system(size: 76, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .tracking(-2.4)
                    .foregroundStyle(palette.ink)
                    .contentTransition(
                        reduceMotion
                            ? .identity
                            : .numericText(countsDown: true)
                    )
                    .minimumScaleFactor(0.72)
                    .accessibilityLabel(
                        timerAccessibilityLabel(seconds: store.remainingSeconds)
                    )

                Text(timerStateLine)
                    .font(.system(size: 11, weight: .semibold))
                    .monospacedDigit()
                    .textCase(.uppercase)
                    .tracking(0.55)
                    .foregroundStyle(palette.muted)
            }

            ProgressRail(progress: store.progress, phase: store.phase)

            currentTaskLine
            timerControls
        }
        .padding(.horizontal, 8)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    private var timerStateLine: String {
        let state: String
        if store.isRunning {
            state = appText("идёт", "running")
        } else if store.progress > 0 {
            state = appText("пауза", "paused")
        } else {
            state = appText("готов", "ready")
        }
        return "\(state) · \(timerDisplay(seconds: store.durationSeconds))"
    }

    private var currentTaskLine: some View {
        HStack(spacing: 10) {
            Image(
                systemName: store.phase == .focus
                    ? "scope"
                    : "cup.and.saucer.fill"
            )
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(phaseColor)
            .frame(width: 18)

            Text(timerTaskStatus)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(palette.ink)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            if store.canCompleteTask {
                Button {
                    store.completeCurrentTask()
                } label: {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(phaseColor)
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PomoIconButtonStyle())
                .accessibilityLabel(
                    appText("Завершить текущую задачу", "Complete current task")
                )
                .pomoHelp(
                    appText("Завершить текущую задачу", "Complete current task")
                )
            }
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 11)
        .background {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(palette.surface.opacity(0.70))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .stroke(.white.opacity(0.24), lineWidth: 0.75)
        }
    }

    private var timerControls: some View {
        HStack(spacing: 8) {
            IconActionButton(
                systemImage: "arrow.counterclockwise",
                label: appText(
                    "Сбросить текущий интервал",
                    "Reset current interval"
                ),
                size: 40,
                action: { store.resetCurrentInterval() }
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
                    .font(.system(size: 11, weight: .bold))

                    Text(
                        store.isRunning
                            ? appText("Пауза", "Pause")
                            : appText("Старт", "Start")
                    )
                    .font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(phaseForeground)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(phaseColor)
                        .shadow(color: phaseColor.opacity(0.24), radius: 12, y: 5)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(PomoPrimaryButtonStyle())
            .accessibilityLabel(
                store.isRunning
                    ? appText("Поставить таймер на паузу", "Pause timer")
                    : appText("Запустить таймер", "Start timer")
            )

            IconActionButton(
                systemImage: "forward.fill",
                label: nextPhaseAccessibilityLabel,
                size: 40,
                action: { store.skipToNextPhase() }
            )
        }
    }

    private var taskQueue: some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text(
                    store.phase == .focus
                        ? appText("Очередь", "Queue")
                        : appText("После перерыва", "After the break")
                )
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(palette.ink)

                Spacer()

                Text(taskSummary)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(palette.muted)
                    .lineLimit(1)
            }
            .padding(.horizontal, 14)
            .padding(.top, 13)
            .padding(.bottom, 9)

            addTaskField
                .padding(.horizontal, 12)
                .padding(.bottom, 10)

            if ledgerTasks.isEmpty {
                VStack(spacing: 7) {
                    Image(systemName: "tray")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(palette.muted)
                    Text(
                        store.phase == .focus && store.activeTask != nil
                            ? appText(
                                "После текущей задачи очередь пуста",
                                "Nothing queued after the current task"
                            )
                            : appText("Очередь пуста", "The queue is empty")
                    )
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(palette.muted)
                    .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(14)
                .accessibilityElement(children: .combine)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(ledgerTasks.enumerated()), id: \.element.id) {
                            index,
                            task in
                            TaskRow(
                                task: task,
                                toggle: { store.toggleTask(id: task.id) },
                                delete: { store.deleteTask(id: task.id) }
                            )

                            if index < ledgerTasks.count - 1 {
                                Rectangle()
                                    .fill(palette.border)
                                    .frame(height: 1)
                                    .padding(.leading, 40)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                }
            }
        }
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(palette.surface.opacity(0.58))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.20), lineWidth: 0.75)
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private var addTaskField: some View {
        HStack(spacing: 7) {
            TextField(
                appText("Добавить следующую задачу", "Add the next task"),
                text: $newTaskTitle
            )
            .textFieldStyle(.plain)
            .font(.system(size: 12))
            .foregroundStyle(palette.ink)
            .onSubmit(addTask)
            .accessibilityLabel(
                appText("Название новой задачи", "New task title")
            )

            Button(action: addTask) {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(canAddTask ? phaseColor : palette.muted)
                    .frame(width: 30, height: 30)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PomoIconButtonStyle())
            .disabled(!canAddTask)
            .accessibilityLabel(appText("Добавить задачу", "Add task"))
        }
        .padding(.leading, 12)
        .padding(.trailing, 4)
        .padding(.vertical, 4)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(palette.canvas.opacity(0.72))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(.white.opacity(0.24), lineWidth: 0.75)
        }
    }

    private var settingsPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                settingsSection(
                    appText("Оформление", "Appearance"),
                    detail: appText(
                        "Выбери комфортный контраст для рабочего стола.",
                        "Choose the contrast that fits your desktop."
                    )
                ) {
                    Picker(
                        appText("Тема", "Theme"),
                        selection: Binding(
                            get: { store.theme },
                            set: { store.setTheme($0) }
                        )
                    ) {
                        ForEach(PomoThemeMode.allCases, id: \.self) { theme in
                            Text(theme.title).tag(theme)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }

                settingsSection(
                    appText("Интервалы", "Durations"),
                    detail: appText(
                        "На паузе изменения применяются сразу.",
                        "Changes apply immediately while paused."
                    )
                ) {
                    HStack(spacing: 7) {
                        ForEach(DurationPreset.defaults) { preset in
                            Button(preset.label) {
                                store.applyPreset(preset)
                            }
                            .buttonStyle(
                                PresetButtonStyle(
                                    selected: store.focusMinutes == preset.focus
                                        && store.breakMinutes == preset.breakTime
                                )
                            )
                        }
                    }

                    DurationStepper(
                        title: store.resolvedWorkStatusLabel,
                        value: store.focusMinutes,
                        range: 1...180,
                        update: {
                            store.setDurations(
                                focus: $0,
                                breakTime: store.breakMinutes
                            )
                        }
                    )
                    DurationStepper(
                        title: store.resolvedRestStatusLabel,
                        value: store.breakMinutes,
                        range: 1...60,
                        update: {
                            store.setDurations(
                                focus: store.focusMinutes,
                                breakTime: $0
                            )
                        }
                    )
                }

                settingsSection(
                    appText("Названия режимов", "Mode names"),
                    detail: appText(
                        "Короткие подписи видны в панели и плавающем таймере.",
                        "Short labels appear in the panel and floating timer."
                    )
                ) {
                    statusLabelField(
                        title: appText("Работа", "Work"),
                        field: .work,
                        placeholder: store.defaultWorkStatusLabel,
                        text: Binding(
                            get: { store.workStatusLabel },
                            set: { store.setWorkStatusLabel($0) }
                        )
                    )
                    statusLabelField(
                        title: appText("Отдых", "Rest"),
                        field: .rest,
                        placeholder: store.defaultRestStatusLabel,
                        text: Binding(
                            get: { store.restStatusLabel },
                            set: { store.setRestStatusLabel($0) }
                        )
                    )
                }

                settingsSection(
                    appText("Поведение", "Behaviour"),
                    detail: appText(
                        "Настрой автоматизацию и системную интеграцию.",
                        "Configure automation and system integration."
                    )
                ) {
                    SettingsToggleRow(
                        title: appText("Плавающий таймер", "Floating timer"),
                        detail: appText(
                            "Поверх окон и на всех рабочих столах.",
                            "Above windows and across all spaces."
                        ),
                        isOn: Binding(
                            get: { store.isFloatingVisible },
                            set: { store.setFloatingVisible($0) }
                        )
                    )

                    SettingsToggleRow(
                        title: appText("Автозапуск отдыха", "Auto-start break"),
                        detail: appText(
                            "После завершения работы отдых начнётся сам.",
                            "Start the break automatically when focus ends."
                        ),
                        isOn: Binding(
                            get: { store.autoStartBreak },
                            set: { store.setAutoStartBreak($0) }
                        )
                    )

                    SettingsToggleRow(
                        title: appText("Звук завершения", "Completion sound"),
                        detail: appText(
                            "Системный сигнал вместе с уведомлением.",
                            "System sound with the notification."
                        ),
                        isOn: Binding(
                            get: { store.soundEnabled },
                            set: { store.setSoundEnabled($0) }
                        )
                    )

                    SettingsToggleRow(
                        title: appText("Запускать при входе", "Launch at login"),
                        detail: appText(
                            "Показывать Floatdoro в меню-баре после входа.",
                            "Show Floatdoro in the menu bar after login."
                        ),
                        isOn: Binding(
                            get: { store.launchAtLoginEnabled },
                            set: { store.setLaunchAtLogin($0) }
                        )
                    )

                    if let error = store.errorMessage {
                        HStack(alignment: .top, spacing: 10) {
                            Label(
                                error,
                                systemImage: "exclamationmark.triangle.fill"
                            )
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.red)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityLabel(
                                appText("Ошибка. \(error)", "Error. \(error)")
                            )

                            Spacer(minLength: 0)

                            Button {
                                store.clearError()
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 10, weight: .semibold))
                                    .frame(width: 28, height: 28)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(
                                appText("Закрыть сообщение об ошибке", "Dismiss error")
                            )
                        }
                        .padding(10)
                        .background {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.red.opacity(0.08))
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.red.opacity(0.24), lineWidth: 0.75)
                        }
                    }
                }

                settingsSection(
                    "Floatdoro",
                    detail: appText(
                        "Завершённых интервалов: \(store.completedSessions)",
                        "Completed intervals: \(store.completedSessions)"
                    )
                ) {
                    HStack(spacing: 16) {
                        Link(
                            appText("Конфиденциальность", "Privacy"),
                            destination: URL(
                                string: "https://drenderyga-del.github.io/floatdoro/privacy.html"
                            )!
                        )
                        .frame(minHeight: 28)
                        Link(
                            appText("Поддержка", "Support"),
                            destination: URL(
                                string: "https://drenderyga-del.github.io/floatdoro/support.html"
                            )!
                        )
                        .frame(minHeight: 28)
                        Spacer()
                        Button(
                            appText("Выйти", "Quit"),
                            role: .destructive,
                            action: onQuit
                        )
                        .buttonStyle(.plain)
                        .foregroundStyle(.red)
                        .frame(minHeight: 28)
                    }
                    .font(.system(size: 11, weight: .medium))
                    .frame(minHeight: 28)
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 4)
            .padding(.bottom, 16)
        }
    }

    private func settingsSection<Content: View>(
        _ title: String,
        detail: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            settingsSectionTitle(title, detail: detail)
            content()
        }
        .padding(15)
        .background {
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .fill(palette.surface.opacity(0.62))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .stroke(.white.opacity(0.20), lineWidth: 0.75)
        }
    }

    private func statusLabelField(
        title: String,
        field: StatusField,
        placeholder: String,
        text: Binding<String>
    ) -> some View {
        HStack(spacing: 10) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(palette.ink)
                .frame(width: 58, alignment: .leading)

            TextField(placeholder, text: text)
                .textFieldStyle(.plain)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(palette.ink)
                .focused($focusedStatusField, equals: field)
                .accessibilityLabel(title)
                .padding(.horizontal, 9)
                .frame(height: 36)
                .background {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(palette.canvas.opacity(0.64))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .stroke(
                            focusedStatusField == field
                                ? phaseColor
                                : palette.border,
                            lineWidth: focusedStatusField == field ? 2 : 1
                        )
                }
        }
    }

    private var phaseWash: Color {
        store.phase == .focus ? palette.focusWash : palette.breakWash
    }

    private var taskSummary: String {
        let completed = completedTasks.count
        return appText(
            "\(queuedTasks.count) далее · \(completed) готово",
            "\(queuedTasks.count) next · \(completed) done"
        )
    }

    private var queuedTasks: [FocusTask] {
        let unfinishedTasks = store.unfinishedTasks
        return store.phase == .focus
            ? Array(unfinishedTasks.dropFirst())
            : unfinishedTasks
    }

    private var completedTasks: [FocusTask] {
        store.currentSessionTasks.filter(\.isCompleted)
    }

    private var ledgerTasks: [FocusTask] {
        queuedTasks + completedTasks
    }

    private var timerTaskStatus: String {
        guard store.phase == .breakTime else { return store.activeTaskTitle }
        guard let nextTask = store.focusTask else { return store.activeTaskTitle }
        return appText(
            "Далее: \(nextTask.title)",
            "Next: \(nextTask.title)"
        )
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

    private var canAddTask: Bool {
        !newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func settingsSectionTitle(_ title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(palette.ink)
            Text(detail)
                .font(.system(size: 11))
                .foregroundStyle(palette.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func addTask() {
        guard canAddTask else { return }
        store.addTask(title: newTaskTitle)
        newTaskTitle = ""
    }

    private func navigate(to destination: Page) {
        store.clearError()
        if reduceMotion {
            page = destination
        } else {
            withAnimation(.easeOut(duration: 0.14)) {
                page = destination
            }
        }
    }
}

private struct PresetButtonStyle: ButtonStyle {
    let selected: Bool
    @Environment(\.pomoPalette) private var palette

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold))
            .monospacedDigit()
            .foregroundStyle(palette.ink)
            .frame(maxWidth: .infinity)
            .frame(height: 36)
            .background {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(selected ? palette.focusWash : palette.raised)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .stroke(selected ? palette.focusAccent : palette.border, lineWidth: 1)
            }
            .brightness(configuration.isPressed ? -0.06 : 0)
    }
}

private struct PomoIconButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.pomoReduceMotionOverride) private var reduceMotionOverride

    private var reduceMotion: Bool {
        reduceMotionOverride ?? systemReduceMotion
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.72 : 1)
            .animation(
                reduceMotion ? nil : .easeOut(duration: 0.12),
                value: configuration.isPressed
            )
    }
}

private struct PomoPrimaryButtonStyle: ButtonStyle {
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
