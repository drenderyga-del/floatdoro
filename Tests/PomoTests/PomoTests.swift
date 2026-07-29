import Foundation
import Testing
@testable import Floatdoro

@Suite("Floatdoro core behavior", .serialized)
@MainActor
struct PomoTests {
    @Test("Timer formats long and short durations")
    func formatsDurations() {
        #expect(timerDisplay(seconds: 25 * 60) == "25:00")
        #expect(timerDisplay(seconds: 9) == "00:09")
        #expect(timerDisplay(seconds: 90 * 60) == "90:00")
    }

    @Test("Completing a task promotes the next unfinished task")
    func completesAndPromotesTask() {
        let defaults = makeDefaults()
        let store = TimerStore(defaults: defaults, startsTicker: false)

        store.addTask(title: "Первая")
        store.addTask(title: "Вторая")
        #expect(store.activeTask?.title == "Первая")

        store.completeCurrentTask()
        #expect(store.tasks.first?.isCompleted == true)
        #expect(store.activeTask?.title == "Вторая")
    }

    @Test("Completed tasks stay visible for the current work session")
    func keepsCompletedTasksInCurrentSession() {
        let defaults = makeDefaults()
        let store = TimerStore(defaults: defaults, startsTicker: false)

        store.addTask(title: "Первая")
        store.addTask(title: "Вторая")
        store.completeCurrentTask()

        #expect(store.currentSessionTasks.count == 2)
        #expect(store.currentSessionTasks.first?.isCompleted == true)
        #expect(store.activeTask?.title == "Вторая")

        store.skipToNextPhase()
        #expect(store.currentSessionTasks.isEmpty)

        store.addTask(title: "Новая сессия")
        #expect(store.currentSessionTasks.map(\.title) == ["Новая сессия"])
    }

    @Test("Custom durations reset the paused interval")
    func appliesCustomDuration() {
        let defaults = makeDefaults()
        let store = TimerStore(defaults: defaults, startsTicker: false)

        store.setDurations(focus: 50, breakTime: 10)
        #expect(store.focusMinutes == 50)
        #expect(store.breakMinutes == 10)
        #expect(store.remainingSeconds == 3_000)
    }

    @Test("Starting a focus reveals the floating window")
    func startingFocusShowsFloatingWindow() {
        let defaults = makeDefaults()
        let store = TimerStore(defaults: defaults, startsTicker: false)

        store.setFloatingVisible(false)
        store.start()

        #expect(store.isRunning)
        #expect(store.isFloatingVisible)
    }

    @Test("Clearing completed tasks keeps their history")
    func completedTasksRemainInHistory() {
        let defaults = makeDefaults()
        let store = TimerStore(defaults: defaults, startsTicker: false)

        store.addTask(title: "Сохранить в истории")
        store.completeCurrentTask()

        #expect(store.taskHistory.count == 1)
        #expect(store.taskHistory.first?.title == "Сохранить в истории")

        store.clearCompletedTasks()

        #expect(store.tasks.isEmpty)
        #expect(store.taskHistory.count == 1)
    }

    @Test("An expired focus is recorded in the weekly report")
    func recordsCompletedFocusInWeeklyReport() throws {
        let defaults = makeDefaults()
        let taskID = UUID()
        let endedAt = Date().addingTimeInterval(-5)
        let startedAt = endedAt.addingTimeInterval(-60)

        try save(
            snapshot(
                tasks: [FocusTask(id: taskID, title: "Историческая задача")],
                phase: .focus,
                isRunning: true,
                endDate: endedAt,
                pausedSeconds: 0,
                focusMinutes: 1,
                activeFocusStartedAt: startedAt,
                activeFocusTaskID: taskID,
                activeFocusTaskTitle: "Историческая задача",
                activeFocusPlannedSeconds: 60
            ),
            to: defaults
        )

        let store = TimerStore(defaults: defaults, startsTicker: false)
        let report = store.weeklyReport(containing: endedAt)

        #expect(store.completedSessions == 1)
        #expect(store.focusHistory.count == 1)
        #expect(store.focusHistory.first?.taskTitle == "Историческая задача")
        #expect(report.sessionCount == 1)
        #expect(report.totalFocusSeconds == 60)
    }

    @Test("Legacy completed tasks migrate into task history")
    func migratesLegacyTaskHistory() throws {
        let defaults = makeDefaults()
        let completedAt = Date()
        let completedTask = FocusTask(
            title: "Старая готовая задача",
            isCompleted: true,
            completedAt: completedAt
        )

        try save(
            snapshot(
                tasks: [completedTask],
                taskHistory: nil
            ),
            to: defaults
        )

        let store = TimerStore(defaults: defaults, startsTicker: false)

        #expect(store.taskHistory.count == 1)
        #expect(store.taskHistory.first?.taskID == completedTask.id)
        #expect(store.taskHistory.first?.completedAt == completedAt)
    }

    private func snapshot(
        tasks: [FocusTask] = [],
        phase: TimerPhase = .focus,
        isRunning: Bool = false,
        endDate: Date? = nil,
        pausedSeconds: TimeInterval = 25 * 60,
        focusMinutes: Int = 25,
        breakMinutes: Int = 5,
        completedSessions: Int = 0,
        focusHistory: [FocusSessionRecord]? = [],
        taskHistory: [CompletedTaskRecord]? = [],
        activeFocusStartedAt: Date? = nil,
        activeFocusTaskID: UUID? = nil,
        activeFocusTaskTitle: String? = nil,
        activeFocusPlannedSeconds: TimeInterval? = nil
    ) -> PersistedPomoState {
        PersistedPomoState(
            tasks: tasks,
            phase: phase,
            isRunning: isRunning,
            endDate: endDate,
            pausedSeconds: pausedSeconds,
            focusMinutes: focusMinutes,
            breakMinutes: breakMinutes,
            completedSessions: completedSessions,
            isFloatingVisible: false,
            soundEnabled: false,
            theme: .light,
            isFloatingExpanded: false,
            focusHistory: focusHistory,
            taskHistory: taskHistory,
            activeFocusStartedAt: activeFocusStartedAt,
            activeFocusTaskID: activeFocusTaskID,
            activeFocusTaskTitle: activeFocusTaskTitle,
            activeFocusPlannedSeconds: activeFocusPlannedSeconds
        )
    }

    private func save(
        _ snapshot: PersistedPomoState,
        to defaults: UserDefaults
    ) throws {
        let data = try JSONEncoder().encode(snapshot)
        defaults.set(data, forKey: "pomo.state.v1")
    }

    private func makeDefaults() -> UserDefaults {
        let suite = "PomoTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }
}
