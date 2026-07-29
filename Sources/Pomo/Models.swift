import Foundation

enum TimerPhase: String, Codable, CaseIterable, Sendable {
    case focus
    case breakTime

    var title: String {
        switch self {
        case .focus: appText("Работа", "Work")
        case .breakTime: appText("Перерыв", "Break")
        }
    }

    var accessibilityTitle: String {
        switch self {
        case .focus: appText("Режим работы", "Work mode")
        case .breakTime: appText("Режим перерыва", "Break mode")
        }
    }
}

enum PomoThemeMode: String, Codable, CaseIterable, Sendable {
    case light
    case dark

    var title: String {
        switch self {
        case .light: appText("Светлая", "Light")
        case .dark: appText("Тёмная", "Dark")
        }
    }
}

struct FocusTask: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    var title: String
    var isCompleted: Bool
    var completedAt: Date?

    init(
        id: UUID = UUID(),
        title: String,
        isCompleted: Bool = false,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.completedAt = completedAt
    }
}

struct FocusSessionRecord: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    let startedAt: Date
    let endedAt: Date
    let plannedSeconds: TimeInterval
    let focusedSeconds: TimeInterval
    let taskID: UUID?
    let taskTitle: String?

    init(
        id: UUID = UUID(),
        startedAt: Date,
        endedAt: Date,
        plannedSeconds: TimeInterval,
        focusedSeconds: TimeInterval,
        taskID: UUID?,
        taskTitle: String?
    ) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.plannedSeconds = plannedSeconds
        self.focusedSeconds = focusedSeconds
        self.taskID = taskID
        self.taskTitle = taskTitle
    }
}

struct CompletedTaskRecord: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    let taskID: UUID
    let title: String
    let completedAt: Date

    init(
        id: UUID = UUID(),
        taskID: UUID,
        title: String,
        completedAt: Date
    ) {
        self.id = id
        self.taskID = taskID
        self.title = title
        self.completedAt = completedAt
    }
}

struct DailyFocusSummary: Identifiable, Equatable, Sendable {
    let date: Date
    let focusedSeconds: TimeInterval

    var id: Date { date }
}

struct WeeklyFocusReport: Equatable, Sendable {
    let interval: DateInterval
    let totalFocusSeconds: TimeInterval
    let sessionCount: Int
    let completedTaskCount: Int
    let days: [DailyFocusSummary]
    let sessions: [FocusSessionRecord]
    let completedTasks: [CompletedTaskRecord]
}

struct DurationPreset: Identifiable, Equatable, Sendable {
    let focus: Int
    let breakTime: Int

    var id: String { "\(focus)-\(breakTime)" }
    var label: String { "\(focus) / \(breakTime)" }

    static let defaults = [
        DurationPreset(focus: 25, breakTime: 5),
        DurationPreset(focus: 50, breakTime: 10),
        DurationPreset(focus: 90, breakTime: 20)
    ]
}

struct PersistedPomoState: Codable, Sendable {
    var tasks: [FocusTask]
    var phase: TimerPhase
    var isRunning: Bool
    var endDate: Date?
    var pausedSeconds: TimeInterval
    var focusMinutes: Int
    var breakMinutes: Int
    var completedSessions: Int
    var isFloatingVisible: Bool
    var soundEnabled: Bool
    var theme: PomoThemeMode?
    var isFloatingExpanded: Bool?
    var focusHistory: [FocusSessionRecord]?
    var taskHistory: [CompletedTaskRecord]?
    var activeFocusStartedAt: Date?
    var activeFocusTaskID: UUID?
    var activeFocusTaskTitle: String?
    var activeFocusPlannedSeconds: TimeInterval?
    var workStatusLabel: String?
    var restStatusLabel: String?
}

func timerDisplay(seconds rawSeconds: TimeInterval) -> String {
    let total = max(0, Int(ceil(rawSeconds)))
    let minutes = total / 60
    let seconds = total % 60
    return String(format: "%02d:%02d", minutes, seconds)
}

func timerAccessibilityLabel(seconds rawSeconds: TimeInterval) -> String {
    let total = max(0, Int(ceil(rawSeconds)))
    let minutes = total / 60
    let seconds = total % 60

    if minutes == 0 {
        return appText("\(seconds) секунд осталось", "\(seconds) seconds remaining")
    }
    if seconds == 0 {
        return appText("\(minutes) минут осталось", "\(minutes) minutes remaining")
    }
    return appText(
        "\(minutes) минут \(seconds) секунд осталось",
        "\(minutes) minutes \(seconds) seconds remaining"
    )
}
