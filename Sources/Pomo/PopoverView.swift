import SwiftUI

struct PopoverView: View {
    enum Page {
        case timer
        case history
        case settings
    }

    private enum StatusField: Hashable {
        case work
        case rest
    }

    @ObservedObject var store: TimerStore
    let onQuit: () -> Void

    @State private var page: Page = .timer
    @State private var newTaskTitle = ""
    @FocusState private var focusedStatusField: StatusField?

    private var palette: PomoPalette { store.theme.palette }

    var body: some View {
        ZStack {
            if store.theme == .light {
                palette.canvas
            } else {
                BehindWindowGlass()
                Color.black.opacity(0.20)
            }

            VStack(spacing: 0) {
                header

                Group {
                    switch page {
                    case .timer:
                        timerPage
                            .transition(.opacity)
                    case .history:
                        HistoryView(store: store)
                            .transition(.opacity)
                    case .settings:
                        settingsPage
                            .transition(.opacity)
                    }
                }
                .animation(.easeOut(duration: 0.18), value: page)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .environment(\.pomoPalette, palette)
        .tint(palette.tomato)
        .preferredColorScheme(store.theme.colorScheme)
    }

    private var header: some View {
        HStack(spacing: 7) {
            Text("Floatdoro")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(palette.ink)
                .lineLimit(1)
                .frame(width: 64, alignment: .leading)

            Spacer()

            ModeBadge(
                phase: store.phase,
                title: store.phaseStatusLabel,
                accessibilityLabel: store.phaseStatusAccessibilityLabel
            )
            .frame(maxWidth: 90)

            headerIconButton(
                systemImage: "clock.arrow.circlepath",
                label: page == .history
                    ? appText("Закрыть историю", "Close history")
                    : appText("Открыть историю", "Open history"),
                isSelected: page == .history
            ) {
                page = page == .history ? .timer : .history
                store.clearError()
            }

            headerIconButton(
                systemImage: page == .settings ? "xmark" : "gearshape.fill",
                label: page == .settings
                    ? appText("Закрыть настройки", "Close settings")
                    : appText("Открыть настройки", "Open settings"),
                isSelected: page == .settings
            ) {
                page = page == .settings ? .timer : .settings
                store.clearError()
            }

            headerIconButton(
                systemImage: "power",
                label: appText("Выйти из Floatdoro", "Quit Floatdoro"),
                isSelected: false,
                action: onQuit
            )
        }
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .padding(.bottom, 8)
    }

    private func headerIconButton(
        systemImage: String,
        label: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(isSelected ? palette.tomato : palette.muted)
                .frame(width: 30, height: 30)
                .background(
                    Circle()
                        .fill(isSelected ? palette.surface : palette.raised)
                )
                .overlay {
                    Circle()
                        .stroke(palette.border, lineWidth: 1)
                }
        }
        .buttonStyle(GlassPressButtonStyle())
        .focusEffectDisabled()
        .accessibilityLabel(label)
        .pomoHelp(label)
    }

    private var timerPage: some View {
        VStack(spacing: 0) {
            timerOverview
            timerControls

            Divider()
                .overlay(palette.border)

            taskSection
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private var timerOverview: some View {
        VStack(spacing: 8) {
            Text(store.displayTime)
                .font(.system(size: 58, weight: .light, design: .rounded))
                .monospacedDigit()
                .tracking(-1.4)
                .foregroundStyle(palette.ink)
                .contentTransition(.numericText(countsDown: true))
                .accessibilityLabel(
                    timerAccessibilityLabel(seconds: store.remainingSeconds)
                )

            Text(
                appText("из", "of")
                    + " \(timerDisplay(seconds: store.durationSeconds))"
            )
            .font(.system(size: 13, weight: .medium))
            .monospacedDigit()
            .foregroundStyle(palette.muted)

            SegmentedProgressRail(
                progress: max(0, min(1, 1 - store.progress)),
                phase: store.phase,
                segmentCount: 10
            )

            HStack {
                Text("0")
                Spacer()
                Text(timerDisplay(seconds: store.durationSeconds / 2))
                Spacer()
                Text(timerDisplay(seconds: store.durationSeconds))
            }
            .font(.system(size: 9, weight: .medium))
            .monospacedDigit()
            .foregroundStyle(palette.muted)

            if store.phase == .breakTime || store.activeTask != nil {
                HStack(spacing: 9) {
                    Circle()
                        .fill(
                            store.phase == .focus
                                ? palette.tomato
                                : palette.breakGreen
                        )
                        .frame(width: 8, height: 8)

                    Text(store.activeTaskTitle)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(palette.ink)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(minHeight: 28)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 8)
    }

    private var timerControls: some View {
        HStack(spacing: 8) {
            CircleActionButton(
                systemImage: "arrow.counterclockwise",
                label: appText(
                    "Сбросить текущий интервал",
                    "Reset current interval"
                ),
                size: 36,
                action: { store.resetCurrentInterval() }
            )

            Button(action: { store.toggleRunning() }) {
                HStack(spacing: 7) {
                    Image(
                        systemName: store.isRunning
                            ? "pause.fill"
                            : "play.fill"
                    )
                    .font(.system(size: 12, weight: .bold))

                    Text(
                        store.isRunning
                            ? appText("Пауза", "Pause")
                            : appText("Старт", "Start")
                    )
                    .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(palette.onHoney)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(palette.honey)
                )
                .contentShape(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                )
            }
            .buttonStyle(GlassPressButtonStyle())
            .accessibilityLabel(
                store.isRunning
                    ? appText("Поставить на паузу", "Pause timer")
                    : appText("Запустить таймер", "Start timer")
            )

            CircleActionButton(
                systemImage: "forward.fill",
                label: store.phase == .focus
                    ? appText(
                        "Перейти к \(store.resolvedRestStatusLabel.lowercased())",
                        "Start \(store.resolvedRestStatusLabel)"
                    )
                    : appText(
                        "Перейти к \(store.resolvedWorkStatusLabel.lowercased())",
                        "Start \(store.resolvedWorkStatusLabel)"
                    ),
                size: 36,
                action: { store.skipToNextPhase() }
            )

            CircleActionButton(
                systemImage: "checkmark",
                label: appText(
                    "Завершить текущую задачу",
                    "Complete current task"
                ),
                size: 36,
                isEnabled: store.canCompleteTask,
                action: { store.completeCurrentTask() }
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
    }

    private var taskSection: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Text(appText("Новая задача", "New task"))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(palette.ink)

                addTaskField
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 9)

            Divider()
                .overlay(palette.border)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(appText("Очередь", "Queue"))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(palette.ink)
                    Text(taskSummary)
                        .font(.system(size: 11))
                        .foregroundStyle(palette.muted)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            if queuedTasks.isEmpty && completedTasks.isEmpty {
                Spacer(minLength: 0)
            } else {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(queuedTasks) { task in
                            TaskRow(
                                task: task,
                                isActive: false,
                                toggle: { store.toggleTask(id: task.id) },
                                delete: { store.deleteTask(id: task.id) }
                            )
                        }

                        if !completedTasks.isEmpty {
                            ForEach(completedTasks) { task in
                                TaskRow(
                                    task: task,
                                    isActive: false,
                                    toggle: { store.toggleTask(id: task.id) },
                                    delete: { store.deleteTask(id: task.id) }
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
                }
            }

        }
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private var addTaskField: some View {
        HStack(spacing: 8) {
            TextField(appText("Например: написать план проекта", "For example: write the project plan"), text: $newTaskTitle)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .foregroundStyle(palette.ink)
                .onSubmit(addTask)
                .accessibilityLabel(appText("Название новой задачи", "New task title"))

            Button(action: addTask) {
                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(palette.onHoney)
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(palette.honey))
            }
            .buttonStyle(.plain)
            .disabled(newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1)
            .accessibilityLabel(appText("Добавить задачу", "Add task"))
        }
        .padding(.leading, 11)
        .padding(.trailing, 4)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(palette.surface)
                .stroke(palette.border, lineWidth: 1)
        )
    }

    private var settingsPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 14) {
                    settingsSectionTitle(appText("Оформление", "Appearance"), detail: appText("Светлая тема включена по умолчанию.", "Light theme is enabled by default."))

                    HStack(spacing: 8) {
                        ForEach(PomoThemeMode.allCases, id: \.self) { theme in
                            Button {
                                store.setTheme(theme)
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: theme == .light ? "sun.max.fill" : "moon.stars.fill")
                                    Text(theme.title)
                                }
                            }
                            .buttonStyle(ThemeButtonStyle(
                                selected: store.theme == theme,
                                theme: theme
                            ))
                        }
                    }
                }

                Divider()
                    .overlay(palette.border)

                VStack(alignment: .leading, spacing: 14) {
                    settingsSectionTitle(appText("Интервалы", "Durations"), detail: appText("Изменения применяются сразу, если таймер на паузе.", "Changes apply immediately while the timer is paused."))

                    HStack(spacing: 8) {
                        ForEach(DurationPreset.defaults) { preset in
                            Button(preset.label) {
                                store.applyPreset(preset)
                            }
                            .buttonStyle(PresetButtonStyle(
                                selected: store.focusMinutes == preset.focus &&
                                    store.breakMinutes == preset.breakTime
                            ))
                        }
                    }

                    DurationStepper(
                        title: store.resolvedWorkStatusLabel,
                        value: store.focusMinutes,
                        range: 1...180,
                        update: { store.setDurations(focus: $0, breakTime: store.breakMinutes) }
                    )
                    DurationStepper(
                        title: store.resolvedRestStatusLabel,
                        value: store.breakMinutes,
                        range: 1...60,
                        update: { store.setDurations(focus: store.focusMinutes, breakTime: $0) }
                    )
                }

                Divider()
                    .overlay(palette.border)

                VStack(alignment: .leading, spacing: 10) {
                    settingsSectionTitle(
                        appText("Подписи режимов", "Mode labels"),
                        detail: appText(
                            "Они показываются вверху таймера. Нажми на поле и напиши своё.",
                            "They appear at the top of the timer. Click a field to write your own."
                        )
                    )

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

                Divider()
                    .overlay(palette.border)

                VStack(alignment: .leading, spacing: 18) {
                    settingsSectionTitle(appText("Поведение", "Behaviour"), detail: appText("Настрой, где таймер остаётся видимым.", "Choose where the timer stays visible."))

                    SettingsToggleRow(
                        title: appText("Большая плавающая плашка", "Floating window"),
                        detail: appText("Поверх окон и на всех рабочих столах.", "Above windows and across all spaces."),
                        isOn: Binding(
                            get: { store.isFloatingVisible },
                            set: { store.setFloatingVisible($0) }
                        )
                    )

                    SettingsToggleRow(
                        title: appText("Звук завершения", "Completion sound"),
                        detail: appText("Системный сигнал вместе с уведомлением.", "System sound with the notification."),
                        isOn: Binding(
                            get: { store.soundEnabled },
                            set: { store.setSoundEnabled($0) }
                        )
                    )

                    SettingsToggleRow(
                        title: appText("Запускать при входе", "Launch at login"),
                        detail: appText("Floatdoro появляется в меню-баре после входа в macOS.", "Floatdoro appears in the menu bar after login."),
                        isOn: Binding(
                            get: { store.launchAtLoginEnabled },
                            set: { store.setLaunchAtLogin($0) }
                        )
                    )
                }

                if let error = store.errorMessage {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(palette.tomato)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(palette.focusWash)
                        )
                        .accessibilityLabel(appText("Ошибка. \(error)", "Error. \(error)"))
                }

                Divider()
                    .overlay(palette.border)

                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 18) {
                        Link(
                            appText("Конфиденциальность", "Privacy"),
                            destination: URL(string: "https://drenderyga-del.github.io/floatdoro/privacy.html")!
                        )
                        Link(
                            appText("Поддержка", "Support"),
                            destination: URL(string: "https://drenderyga-del.github.io/floatdoro/support.html")!
                        )
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(palette.muted)

                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(appText("Завершённых сессий", "Completed sessions"))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(palette.muted)
                            Text("\(store.completedSessions)")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(palette.ink)
                        }
                        Spacer()
                        Button(appText("Выйти из Floatdoro", "Quit Floatdoro"), action: onQuit)
                            .buttonStyle(.plain)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(palette.tomato)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(Capsule().fill(palette.focusWash))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 20)
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
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(palette.ink)
                .frame(width: 70, alignment: .leading)

            HStack(spacing: 8) {
                Image(systemName: "pencil")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(
                        focusedStatusField == field
                            ? palette.tomato
                            : palette.muted
                    )

                TextField(placeholder, text: text)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(palette.ink)
                    .focused($focusedStatusField, equals: field)
                    .accessibilityLabel(title)
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(palette.surface)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(
                        focusedStatusField == field
                            ? palette.tomato
                            : palette.border,
                        lineWidth: focusedStatusField == field ? 2 : 1
                    )
            }
            .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .onTapGesture {
                focusedStatusField = field
            }
            .animation(.easeOut(duration: 0.16), value: focusedStatusField)
        }
    }

    private var taskSummary: String {
        let completed = completedTasks.count
        if queuedTasks.isEmpty {
            return completed == 0
                ? appText("Следующих задач нет", "No next tasks")
                : appText("\(completed) готово в этой сессии", "\(completed) done in this session")
        }
        return appText(
            "\(queuedTasks.count) в очереди · \(completed) готово",
            "\(queuedTasks.count) in queue · \(completed) done"
        )
    }

    private var queuedTasks: [FocusTask] {
        let unfinishedTasks = store.currentSessionTasks.filter { !$0.isCompleted }
        return Array(unfinishedTasks.dropFirst())
    }

    private var completedTasks: [FocusTask] {
        store.currentSessionTasks.filter(\.isCompleted)
    }

    private func settingsSectionTitle(_ title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(palette.ink)
            Text(detail)
                .font(.system(size: 11))
                .foregroundStyle(palette.muted)
        }
    }

    private func addTask() {
        store.addTask(title: newTaskTitle)
        newTaskTitle = ""
    }
}

private struct PresetButtonStyle: ButtonStyle {
    let selected: Bool
    @Environment(\.pomoPalette) private var palette

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(selected ? palette.onHoney : palette.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(
                Capsule()
                    .fill(selected ? palette.honey : palette.raised)
            )
            .brightness(configuration.isPressed ? -0.08 : 0)
    }
}

private struct ThemeButtonStyle: ButtonStyle {
    let selected: Bool
    let theme: PomoThemeMode
    @Environment(\.pomoPalette) private var palette

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundStyle(selected ? palette.onHoney : palette.muted)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(selected ? palette.honey : palette.raised)
                    .stroke(selected ? palette.honey : palette.border, lineWidth: 1)
            )
            .brightness(configuration.isPressed ? -0.06 : 0)
    }
}
