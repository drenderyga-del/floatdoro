import AppKit
import Combine
import Foundation
import ServiceManagement
import UserNotifications

@MainActor
final class TimerStore: ObservableObject {
    @Published private(set) var tasks: [FocusTask]
    @Published private(set) var phase: TimerPhase
    @Published private(set) var isRunning: Bool
    @Published private(set) var endDate: Date?
    @Published private(set) var pausedSeconds: TimeInterval
    @Published private(set) var now = Date()
    @Published private(set) var completedSessions: Int
    @Published private(set) var focusHistory: [FocusSessionRecord]
    @Published private(set) var taskHistory: [CompletedTaskRecord]
    @Published private(set) var isFloatingVisible: Bool
    @Published private(set) var isFloatingExpanded: Bool
    @Published private(set) var soundEnabled: Bool
    @Published private(set) var theme: PomoThemeMode
    @Published private(set) var launchAtLoginEnabled: Bool
    @Published private(set) var errorMessage: String?
    @Published private(set) var completionPulse = 0

    @Published private(set) var focusMinutes: Int
    @Published private(set) var breakMinutes: Int
    @Published private(set) var workStatusLabel: String
    @Published private(set) var restStatusLabel: String
    @Published private(set) var currentWorkSessionID: UUID

    private let defaults: UserDefaults
    private let persistenceKey = "pomo.state.v1"
    private var ticker: Timer?
    private var notificationPermissionRequested = false
    private var activeFocusStartedAt: Date?
    private var activeFocusTaskID: UUID?
    private var activeFocusTaskTitle: String?
    private var activeFocusPlannedSeconds: TimeInterval?

    init(defaults: UserDefaults = .standard, startsTicker: Bool = true) {
        self.defaults = defaults

        if
            let data = defaults.data(forKey: persistenceKey),
            let snapshot = try? JSONDecoder().decode(PersistedPomoState.self, from: data)
        {
            let restoredWorkSessionID = snapshot.currentWorkSessionID ?? UUID()
            currentWorkSessionID = restoredWorkSessionID
            tasks = snapshot.tasks.map { task in
                var task = task
                if !task.isCompleted || task.sessionID == nil {
                    task.sessionID = restoredWorkSessionID
                }
                return task
            }
            phase = snapshot.phase
            isRunning = snapshot.isRunning
            endDate = snapshot.endDate
            pausedSeconds = snapshot.pausedSeconds
            focusMinutes = snapshot.focusMinutes
            breakMinutes = snapshot.breakMinutes
            completedSessions = snapshot.completedSessions
            focusHistory = snapshot.focusHistory ?? []
            taskHistory = snapshot.taskHistory ?? snapshot.tasks.compactMap { task in
                guard let completedAt = task.completedAt else { return nil }
                return CompletedTaskRecord(
                    taskID: task.id,
                    title: task.title,
                    completedAt: completedAt
                )
            }
            isFloatingVisible = snapshot.isFloatingVisible
            isFloatingExpanded = snapshot.isFloatingExpanded ?? false
            soundEnabled = snapshot.soundEnabled
            theme = snapshot.theme ?? .light
            activeFocusStartedAt = snapshot.activeFocusStartedAt
            activeFocusTaskID = snapshot.activeFocusTaskID
            activeFocusTaskTitle = snapshot.activeFocusTaskTitle
            activeFocusPlannedSeconds = snapshot.activeFocusPlannedSeconds
            workStatusLabel = snapshot.workStatusLabel ?? ""
            restStatusLabel = snapshot.restStatusLabel ?? ""
        } else {
            tasks = []
            phase = .focus
            isRunning = false
            endDate = nil
            pausedSeconds = 25 * 60
            focusMinutes = 25
            breakMinutes = 5
            completedSessions = 0
            focusHistory = []
            taskHistory = []
            isFloatingVisible = true
            isFloatingExpanded = false
            soundEnabled = true
            theme = .light
            activeFocusStartedAt = nil
            activeFocusTaskID = nil
            activeFocusTaskTitle = nil
            activeFocusPlannedSeconds = nil
            workStatusLabel = ""
            restStatusLabel = ""
            currentWorkSessionID = UUID()
        }

        launchAtLoginEnabled = SMAppService.mainApp.status == .enabled

        if isRunning, let endDate, endDate <= Date() {
            isRunning = false
            self.endDate = nil
            pausedSeconds = 0
            completeInterval(notify: false, completedAt: endDate)
        }

        if startsTicker {
            startTicker()
        }
    }

    var remainingSeconds: TimeInterval {
        if isRunning, let endDate {
            return max(0, endDate.timeIntervalSince(now))
        }
        return max(0, pausedSeconds)
    }

    var durationSeconds: TimeInterval {
        TimeInterval((phase == .focus ? focusMinutes : breakMinutes) * 60)
    }

    var progress: Double {
        guard durationSeconds > 0 else { return 0 }
        return min(max(1 - remainingSeconds / durationSeconds, 0), 1)
    }

    var displayTime: String {
        timerDisplay(seconds: remainingSeconds)
    }

    var defaultWorkStatusLabel: String { appText("Работа", "Work") }
    var defaultRestStatusLabel: String { appText("Отдых", "Rest") }

    var phaseStatusLabel: String {
        phase == .focus ? resolvedWorkStatusLabel : resolvedRestStatusLabel
    }

    var phaseStatusAccessibilityLabel: String {
        appText("Режим: \(phaseStatusLabel)", "Mode: \(phaseStatusLabel)")
    }

    var resolvedWorkStatusLabel: String {
        workStatusLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? defaultWorkStatusLabel
            : workStatusLabel
    }

    var resolvedRestStatusLabel: String {
        restStatusLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? defaultRestStatusLabel
            : restStatusLabel
    }

    var activeTask: FocusTask? {
        currentSessionTasks.first(where: { !$0.isCompleted })
    }

    var currentSessionTasks: [FocusTask] {
        tasks.filter { $0.sessionID == currentWorkSessionID }
    }

    var activeTaskTitle: String {
        if phase == .breakTime {
            return appText("Можно выдохнуть", "Take a breather")
        }
        return activeTask?.title ?? appText(
            "Добавь задачу для \(resolvedWorkStatusLabel.lowercased())",
            "Add a task for \(resolvedWorkStatusLabel.lowercased())"
        )
    }

    var canCompleteTask: Bool {
        phase == .focus && activeTask != nil
    }

    func weeklyReport(
        containing date: Date = Date(),
        calendar: Calendar = .current
    ) -> WeeklyFocusReport {
        let interval = calendar.dateInterval(of: .weekOfYear, for: date)
            ?? DateInterval(
                start: calendar.startOfDay(for: date),
                duration: 7 * 24 * 60 * 60
            )

        let sessions = focusHistory
            .filter { interval.contains($0.endedAt) }
            .sorted { $0.endedAt > $1.endedAt }
        let completedTasks = taskHistory
            .filter { interval.contains($0.completedAt) }
            .sorted { $0.completedAt > $1.completedAt }

        let days = (0..<7).compactMap { offset -> DailyFocusSummary? in
            guard
                let dayStart = calendar.date(
                    byAdding: .day,
                    value: offset,
                    to: interval.start
                ),
                let dayEnd = calendar.date(
                    byAdding: .day,
                    value: 1,
                    to: dayStart
                )
            else { return nil }

            let total = sessions
                .filter { $0.endedAt >= dayStart && $0.endedAt < dayEnd }
                .reduce(0) { $0 + $1.focusedSeconds }
            return DailyFocusSummary(
                date: dayStart,
                focusedSeconds: total
            )
        }

        return WeeklyFocusReport(
            interval: interval,
            totalFocusSeconds: sessions.reduce(0) {
                $0 + $1.focusedSeconds
            },
            sessionCount: sessions.count,
            completedTaskCount: completedTasks.count,
            days: days,
            sessions: sessions,
            completedTasks: completedTasks
        )
    }

    func toggleRunning() {
        isRunning ? pause() : start()
    }

    func start() {
        guard !isRunning else { return }
        if pausedSeconds <= 0 {
            pausedSeconds = durationSeconds
        }

        now = Date()
        if phase == .focus, activeFocusStartedAt == nil {
            activeFocusStartedAt = now
            activeFocusTaskID = activeTask?.id
            activeFocusTaskTitle = activeTask?.title
            activeFocusPlannedSeconds = durationSeconds
        }
        endDate = now.addingTimeInterval(pausedSeconds)
        isRunning = true
        isFloatingVisible = true
        requestNotificationPermissionIfNeeded()
        persist()
    }

    func pause() {
        guard isRunning else { return }
        now = Date()
        pausedSeconds = remainingSeconds
        isRunning = false
        endDate = nil
        persist()
    }

    func resetCurrentInterval() {
        if phase == .focus {
            clearActiveFocusSession()
        }
        isRunning = false
        endDate = nil
        pausedSeconds = durationSeconds
        now = Date()
        persist()
    }

    func skipToNextPhase() {
        if phase == .focus {
            clearActiveFocusSession()
            beginNextWorkSession()
        }
        phase = phase == .focus ? .breakTime : .focus
        isRunning = false
        endDate = nil
        pausedSeconds = durationSeconds
        now = Date()
        persist()
    }

    func setDurations(focus: Int, breakTime: Int) {
        focusMinutes = min(max(focus, 1), 180)
        breakMinutes = min(max(breakTime, 1), 60)

        if !isRunning {
            if phase == .focus {
                clearActiveFocusSession()
            }
            pausedSeconds = durationSeconds
        }
        persist()
    }

    func setWorkStatusLabel(_ value: String) {
        workStatusLabel = String(value.prefix(28))
        persist()
    }

    func setRestStatusLabel(_ value: String) {
        restStatusLabel = String(value.prefix(28))
        persist()
    }

    func applyPreset(_ preset: DurationPreset) {
        setDurations(focus: preset.focus, breakTime: preset.breakTime)
    }

    func addTask(title rawTitle: String) {
        let title = rawTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        tasks.append(FocusTask(title: title, sessionID: currentWorkSessionID))
        persist()
    }

    func toggleTask(id: UUID) {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        tasks[index].isCompleted.toggle()
        if tasks[index].isCompleted {
            let completedAt = Date()
            tasks[index].completedAt = completedAt
            taskHistory.append(
                CompletedTaskRecord(
                    taskID: tasks[index].id,
                    title: tasks[index].title,
                    completedAt: completedAt
                )
            )
        } else {
            tasks[index].completedAt = nil
            if let historyIndex = taskHistory.lastIndex(
                where: { $0.taskID == tasks[index].id }
            ) {
                taskHistory.remove(at: historyIndex)
            }
        }
        completionPulse += tasks[index].isCompleted ? 1 : 0
        persist()
    }

    func completeCurrentTask() {
        guard let id = activeTask?.id else { return }
        toggleTask(id: id)
    }

    func deleteTask(id: UUID) {
        tasks.removeAll(where: { $0.id == id })
        persist()
    }

    func clearCompletedTasks() {
        tasks.removeAll(where: \.isCompleted)
        persist()
    }

    func setFloatingVisible(_ visible: Bool) {
        isFloatingVisible = visible
        persist()
    }

    func setFloatingExpanded(_ expanded: Bool) {
        isFloatingExpanded = expanded
        persist()
    }

    func setSoundEnabled(_ enabled: Bool) {
        soundEnabled = enabled
        persist()
    }

    func setTheme(_ theme: PomoThemeMode) {
        self.theme = theme
        persist()
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        errorMessage = nil

        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            launchAtLoginEnabled = SMAppService.mainApp.status == .enabled
        } catch {
            launchAtLoginEnabled = SMAppService.mainApp.status == .enabled
            errorMessage = appText("Не удалось изменить автозапуск: \(error.localizedDescription)", "Could not change launch at login: \(error.localizedDescription)")
        }
    }

    func clearError() {
        errorMessage = nil
    }

    func persistNow() {
        persist()
    }

    private func startTicker() {
        let timer = Timer(timeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.tick()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        ticker = timer
    }

    private func tick() {
        now = Date()
        if isRunning, remainingSeconds <= 0 {
            completeInterval(notify: true, completedAt: now)
        }
    }

    private func completeInterval(notify: Bool, completedAt: Date) {
        let completedPhase = phase
        if completedPhase == .focus {
            completedSessions += 1
            recordCompletedFocus(endedAt: completedAt)
        }

        isRunning = false
        endDate = nil
        phase = completedPhase == .focus ? .breakTime : .focus
        if completedPhase == .focus {
            beginNextWorkSession()
        }
        pausedSeconds = durationSeconds
        now = Date()
        completionPulse += 1

        if notify {
            sendCompletionNotification(for: completedPhase)
            if soundEnabled {
                NSSound(named: "Glass")?.play()
            }
        }
        persist()
    }

    private func recordCompletedFocus(endedAt: Date) {
        let plannedSeconds =
            activeFocusPlannedSeconds
            ?? TimeInterval(focusMinutes * 60)
        let inferredStart = endedAt.addingTimeInterval(-plannedSeconds)
        let startedAt = min(activeFocusStartedAt ?? inferredStart, endedAt)

        focusHistory.append(
            FocusSessionRecord(
                startedAt: startedAt,
                endedAt: endedAt,
                plannedSeconds: plannedSeconds,
                focusedSeconds: plannedSeconds,
                taskID: activeFocusTaskID,
                taskTitle: activeFocusTaskTitle
            )
        )
        clearActiveFocusSession()
    }

    private func clearActiveFocusSession() {
        activeFocusStartedAt = nil
        activeFocusTaskID = nil
        activeFocusTaskTitle = nil
        activeFocusPlannedSeconds = nil
    }

    private func beginNextWorkSession() {
        let nextWorkSessionID = UUID()
        for index in tasks.indices where !tasks[index].isCompleted {
            tasks[index].sessionID = nextWorkSessionID
        }
        currentWorkSessionID = nextWorkSessionID
    }

    private func requestNotificationPermissionIfNeeded() {
        guard Bundle.main.bundleURL.pathExtension == "app" else { return }
        guard !notificationPermissionRequested else { return }
        notificationPermissionRequested = true

        Task {
            _ = try? await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound])
        }
    }

    private func sendCompletionNotification(for completedPhase: TimerPhase) {
        guard Bundle.main.bundleURL.pathExtension == "app" else { return }
        let content = UNMutableNotificationContent()
        if completedPhase == .focus {
            content.title = appText("\(resolvedWorkStatusLabel) завершён", "\(resolvedWorkStatusLabel) complete")
            content.body = appText("Время сделать перерыв.", "Time for a break.")
        } else {
            content.title = appText("Перерыв закончен", "Break complete")
            content.body = activeTask.map { appText("Следующая задача: \($0.title)", "Next task: \($0.title)") }
                ?? appText("Можно начинать: \(resolvedWorkStatusLabel.lowercased()).", "Ready for \(resolvedWorkStatusLabel.lowercased()).")
        }
        if soundEnabled {
            content.sound = .default
        }

        let request = UNNotificationRequest(
            identifier: "pomo.\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    private func persist() {
        let snapshot = PersistedPomoState(
            tasks: tasks,
            phase: phase,
            isRunning: isRunning,
            endDate: endDate,
            pausedSeconds: pausedSeconds,
            focusMinutes: focusMinutes,
            breakMinutes: breakMinutes,
            completedSessions: completedSessions,
            isFloatingVisible: isFloatingVisible,
            soundEnabled: soundEnabled,
            theme: theme,
            isFloatingExpanded: isFloatingExpanded,
            focusHistory: focusHistory,
            taskHistory: taskHistory,
            activeFocusStartedAt: activeFocusStartedAt,
            activeFocusTaskID: activeFocusTaskID,
            activeFocusTaskTitle: activeFocusTaskTitle,
            activeFocusPlannedSeconds: activeFocusPlannedSeconds
            ,workStatusLabel: workStatusLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : workStatusLabel
            ,restStatusLabel: restStatusLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : restStatusLabel
            ,currentWorkSessionID: currentWorkSessionID
        )

        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: persistenceKey)
    }
}
