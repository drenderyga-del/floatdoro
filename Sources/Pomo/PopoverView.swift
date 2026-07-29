import SwiftUI

struct PopoverView: View {
    enum Page {
        case timer
        case history
        case settings
    }

    @ObservedObject var store: TimerStore
    let onQuit: () -> Void

    @State private var page: Page = .timer
    @State private var newTaskTitle = ""

    private var palette: PomoPalette { store.theme.palette }

    var body: some View {
        ZStack {
            BehindWindowGlass()

            if store.theme == .light {
                Color.white.opacity(0.02)
            } else {
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
        .frame(width: 420, height: 640)
        .environment(\.pomoPalette, palette)
        .tint(palette.tomato)
        .preferredColorScheme(store.theme.colorScheme)
    }

    private var header: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(palette.raised)
                        .frame(width: 34, height: 34)
                        .overlay {
                            Circle()
                                .stroke(palette.border, lineWidth: 1)
                        }
                    Image(systemName: "timer")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(palette.ink)
                }
                Text("POMO")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(palette.ink)
            }

            Spacer()

            ModeBadge(
                phase: store.phase,
                title: store.phaseStatusLabel,
                accessibilityLabel: store.phaseStatusAccessibilityLabel
            )

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
        }
        .padding(.horizontal, 22)
        .padding(.top, 18)
        .padding(.bottom, 10)
    }

    private func headerIconButton(
        systemImage: String,
        label: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isSelected ? palette.tomato : palette.muted)
                .frame(width: 34, height: 34)
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
            VStack(spacing: 14) {
                Text(store.displayTime)
                    .font(.system(size: 72, weight: .light, design: .rounded))
                    .monospacedDigit()
                    .tracking(-1.7)
                    .foregroundStyle(palette.ink)
                    .contentTransition(.numericText(countsDown: true))
                    .accessibilityLabel(timerAccessibilityLabel(seconds: store.remainingSeconds))

                Text(appText("из", "of") + " \(timerDisplay(seconds: store.durationSeconds))")
                    .font(.system(size: 16, weight: .medium))
                    .monospacedDigit()
                    .foregroundStyle(palette.muted)

                SegmentedProgressRail(
                    progress: max(0, min(1, 1 - store.progress)),
                    phase: store.phase,
                    segmentCount: 10
                )
                    .frame(width: 326)

                HStack {
                    Text("0")
                    Spacer()
                    Text(timerDisplay(seconds: store.durationSeconds / 2))
                    Spacer()
                    Text(timerDisplay(seconds: store.durationSeconds))
                }
                .font(.system(size: 10, weight: .medium))
                .monospacedDigit()
                .foregroundStyle(palette.muted)
                .frame(width: 326)

                HStack(spacing: 10) {
                    Circle()
                        .fill(
                            store.phase == .focus
                                ? palette.tomato
                                : palette.breakGreen
                        )
                        .frame(width: 9, height: 9)

                    Text(store.activeTaskTitle)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(palette.ink)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: 292, minHeight: 38)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .fill(palette.surface)
                )
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .padding(.top, 2)

            HStack(spacing: 8) {
                GlassActionButton(
                    systemImage: "arrow.counterclockwise",
                    title: nil,
                    accessibilityLabel: appText("Сбросить текущий интервал", "Reset current interval"),
                    isEnabled: true,
                    action: { store.resetCurrentInterval() }
                )

                GlassActionButton(
                    systemImage: store.isRunning ? "pause.fill" : "play.fill",
                    title: nil,
                    accessibilityLabel: store.isRunning
                        ? appText("Поставить на паузу", "Pause timer")
                        : appText("Запустить таймер", "Start timer"),
                    isEnabled: true,
                    action: { store.toggleRunning() }
                )

                GlassActionButton(
                    systemImage: "forward.fill",
                    title: nil,
                    accessibilityLabel: store.phase == .focus
                        ? appText("Перейти к \(store.resolvedRestStatusLabel.lowercased())", "Start \(store.resolvedRestStatusLabel)")
                        : appText("Перейти к \(store.resolvedWorkStatusLabel.lowercased())", "Start \(store.resolvedWorkStatusLabel)"),
                    isEnabled: true,
                    action: { store.skipToNextPhase() }
                )

                GlassActionButton(
                    systemImage: "checkmark",
                    title: nil,
                    accessibilityLabel: appText("Завершить текущую задачу", "Complete current task"),
                    isEnabled: store.canCompleteTask,
                    action: { store.completeCurrentTask() }
                )
            }
            .padding(.horizontal, 18)
            .padding(.top, 16)
            .padding(.bottom, 14)

            Divider()
                .overlay(palette.border)
                .padding(.horizontal, 18)

            taskSection
        }
    }

    private var taskSection: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Label(appText("Добавить задачу для работы", "Add a task for work"), systemImage: "plus.circle.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(palette.ink)

                addTaskField
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 14)

            Divider()
                .overlay(palette.border)
                .padding(.horizontal, 18)

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
                if store.tasks.contains(where: \.isCompleted) {
                    Button(appText("Убрать готовые", "Clear completed")) {
                        store.clearCompletedTasks()
                    }
                        .buttonStyle(.plain)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(palette.muted)
                        .pomoHelp("Удалить все выполненные задачи")
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 8)

            if store.tasks.isEmpty {
                emptyTasks
            } else {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(store.tasks) { task in
                            TaskRow(
                                task: task,
                                isActive: task.id == store.activeTask?.id,
                                toggle: { store.toggleTask(id: task.id) },
                                delete: { store.deleteTask(id: task.id) }
                            )
                        }
                    }
                    .padding(.horizontal, 14)
                }
                .frame(maxHeight: 160)
            }

        }
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private var emptyTasks: some View {
        VStack(spacing: 7) {
            Image(systemName: "checklist")
                .font(.system(size: 21, weight: .medium))
                .foregroundStyle(palette.tomato)
            Text(appText("Добавьте задачу выше — она появится в окне таймера.", "Add a task above — it will appear in the timer window."))
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(palette.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 82)
        .accessibilityElement(children: .combine)
    }

    private var addTaskField: some View {
        HStack(spacing: 8) {
            TextField(appText("Например: написать план проекта", "For example: write the project plan"), text: $newTaskTitle)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .foregroundStyle(palette.ink)
                .onSubmit(addTask)
                .accessibilityLabel("Название новой задачи")

            Button(action: addTask) {
                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(palette.honey))
            }
            .buttonStyle(.plain)
            .disabled(newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1)
            .accessibilityLabel("Добавить задачу")
        }
        .padding(.leading, 12)
        .padding(.trailing, 5)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(palette.surface)
                .stroke(palette.border, lineWidth: 1)
        )
    }

    private var settingsPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
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
                        placeholder: store.defaultWorkStatusLabel,
                        text: Binding(
                            get: { store.workStatusLabel },
                            set: { store.setWorkStatusLabel($0) }
                        )
                    )
                    statusLabelField(
                        title: appText("Отдых", "Rest"),
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
                        detail: appText("Pomo появляется в меню-баре после входа в macOS.", "Pomo appears in the menu bar after login."),
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
                        .accessibilityLabel("Ошибка. \(error)")
                }

                Divider()
                    .overlay(palette.border)

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
                    Button(appText("Выйти из Pomo", "Quit Pomo"), action: onQuit)
                        .buttonStyle(.plain)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(palette.tomato)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(Capsule().fill(palette.focusWash))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 24)
        }
    }

    private func statusLabelField(
        title: String,
        placeholder: String,
        text: Binding<String>
    ) -> some View {
        HStack(spacing: 10) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(palette.ink)
                .frame(width: 70, alignment: .leading)
            TextField(placeholder, text: text)
                .textFieldStyle(.plain)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(palette.ink)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 9).fill(palette.raised))
                .overlay {
                    RoundedRectangle(cornerRadius: 9)
                        .stroke(palette.border, lineWidth: 1)
                }
                .accessibilityLabel(title)
        }
    }

    private var taskSummary: String {
        let remaining = store.tasks.filter { !$0.isCompleted }.count
        if store.tasks.isEmpty {
            return appText("Список пока пуст", "The list is empty")
        }
        return appText(
            "\(remaining) осталось · \(store.tasks.count - remaining) готово",
            "\(remaining) left · \(store.tasks.count - remaining) complete"
        )
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
            .foregroundStyle(selected ? Color.white : palette.ink)
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
            .foregroundStyle(selected ? Color.white : palette.muted)
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
