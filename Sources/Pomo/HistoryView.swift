import SwiftUI

struct HistoryView: View {
    @ObservedObject var store: TimerStore

    @State private var weekOffset = 0

    private let calendar = Calendar.current
    private var currentLocale: Locale { AppLanguage.locale }

    private var report: WeeklyFocusReport {
        store.weeklyReport(containing: selectedDate, calendar: calendar)
    }

    private var selectedDate: Date {
        calendar.date(
            byAdding: .weekOfYear,
            value: weekOffset,
            to: Date()
        ) ?? Date()
    }

    private var palette: PomoPalette { store.theme.palette }

    private var events: [HistoryEvent] {
        let sessionEvents = report.sessions.map(HistoryEvent.session)
        let taskEvents = report.completedTasks.map(HistoryEvent.task)
        return (sessionEvents + taskEvents).sorted {
            $0.date > $1.date
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                weekNavigation
                summaryPanel
                weeklyChart
                historyList
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.never)
    }

    private var weekNavigation: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(weekOffset == 0 ? appText("Эта неделя", "This week") : appText("Неделя", "Week"))
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(palette.ink)

                Text(weekRangeLabel)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(palette.muted)
            }

            Spacer()

            historyNavigationButton(
                systemImage: "chevron.left",
                label: appText("Предыдущая неделя", "Previous week"),
                isEnabled: true
            ) {
                withAnimation(.easeOut(duration: 0.18)) {
                    weekOffset -= 1
                }
            }

            historyNavigationButton(
                systemImage: "chevron.right",
                label: appText("Следующая неделя", "Next week"),
                isEnabled: weekOffset < 0
            ) {
                withAnimation(.easeOut(duration: 0.18)) {
                    weekOffset += 1
                }
            }
        }
    }

    private var summaryPanel: some View {
        HStack(spacing: 0) {
            summaryMetric(
                value: durationLabel(report.totalFocusSeconds),
                title: appText("работы", "work")
            )

            summaryDivider

            summaryMetric(
                value: "\(report.sessionCount)",
                title: pomodoroLabel(report.sessionCount)
            )

            summaryDivider

            summaryMetric(
                value: "\(report.completedTaskCount)",
                title: taskLabel(report.completedTaskCount)
            )
        }
        .padding(.vertical, 14)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(palette.surface)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(palette.border, lineWidth: 1)
        }
    }

    private var summaryDivider: some View {
        Rectangle()
            .fill(palette.border)
            .frame(width: 1, height: 34)
    }

    private func summaryMetric(value: String, title: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 17, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(palette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.78)

            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(palette.muted)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }

    private var weeklyChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(appText("Работа по дням", "Work by day"))
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(palette.ink)

            HStack(alignment: .bottom, spacing: 8) {
                ForEach(report.days) { day in
                    dayColumn(day)
                }
            }
            .frame(height: 112)
        }
    }

    private func dayColumn(_ day: DailyFocusSummary) -> some View {
        let maximum = max(
            report.days.map(\.focusedSeconds).max() ?? 0,
            60
        )
        let ratio = day.focusedSeconds / maximum
        let isToday = calendar.isDateInToday(day.date)

        return VStack(spacing: 5) {
            Text(
                day.focusedSeconds > 0
                    ? compactMinutes(day.focusedSeconds)
                    : ""
            )
            .font(.system(size: 9, weight: .medium))
            .monospacedDigit()
            .foregroundStyle(palette.muted)
            .frame(height: 11)

            GeometryReader { geometry in
                ZStack(alignment: .bottom) {
                    Capsule()
                        .fill(palette.raised)

                    if day.focusedSeconds > 0 {
                        Capsule()
                            .fill(palette.tomato)
                            .frame(
                                height: max(
                                    5,
                                    geometry.size.height * ratio
                                )
                            )
                    }
                }
            }
            .frame(height: 72)

            Text(weekdayLabel(day.date))
                .font(.system(size: 10, weight: isToday ? .semibold : .medium))
                .foregroundStyle(isToday ? palette.tomato : palette.muted)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(fullDateLabel(day.date)), \(durationLabel(day.focusedSeconds)) \(appText("работы", "of work"))"
        )
    }

    private var historyList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(appText("История недели", "Week history"))
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(palette.ink)

            if events.isEmpty {
                emptyHistory
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(events.enumerated()), id: \.element.id) {
                        index,
                        event in
                        historyRow(event)

                        if index < events.count - 1 {
                            Divider()
                                .overlay(palette.border)
                                .padding(.leading, 43)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .background {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(palette.surface)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(palette.border, lineWidth: 1)
                }
            }
        }
    }

    private var emptyHistory: some View {
        VStack(spacing: 8) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 23, weight: .medium))
                .foregroundStyle(palette.tomato)

            Text(appText("История появится после первой завершённой сессии или задачи.", "History appears after your first completed session or task."))
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(palette.muted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 270)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(palette.raised)
        }
    }

    private func historyRow(_ event: HistoryEvent) -> some View {
        HStack(spacing: 10) {
            Image(systemName: event.systemImage)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(event.isFocus ? palette.tomato : palette.ink)
                .frame(width: 30, height: 30)
                .background(Circle().fill(palette.raised))

            VStack(alignment: .leading, spacing: 3) {
                Text(event.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(palette.ink)
                    .lineLimit(2)

                Text(event.detail)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(palette.muted)
            }

            Spacer(minLength: 8)

            Text(eventTimeLabel(event.date))
                .font(.system(size: 10, weight: .medium))
                .monospacedDigit()
                .foregroundStyle(palette.muted)
        }
        .padding(.vertical, 9)
        .accessibilityElement(children: .combine)
    }

    private func historyNavigationButton(
        systemImage: String,
        label: String,
        isEnabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(palette.ink)
                .frame(width: 32, height: 32)
                .background(Circle().fill(palette.raised))
                .overlay {
                    Circle()
                        .stroke(palette.border, lineWidth: 1)
                }
        }
        .buttonStyle(GlassPressButtonStyle())
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.34)
        .accessibilityLabel(label)
        .pomoHelp(label)
    }

    private var weekRangeLabel: String {
        let end = report.interval.end.addingTimeInterval(-1)
        let startLabel = report.interval.start.formatted(
            .dateTime
                .day()
                .month(.abbreviated)
                .locale(currentLocale)
        )
        let endLabel = end.formatted(
            .dateTime
                .day()
                .month(.abbreviated)
                .locale(currentLocale)
        )
        return "\(startLabel) — \(endLabel)"
    }

    private func weekdayLabel(_ date: Date) -> String {
        date.formatted(
            .dateTime
                .weekday(.narrow)
                .locale(currentLocale)
        )
    }

    private func fullDateLabel(_ date: Date) -> String {
        date.formatted(
            .dateTime
                .day()
                .month(.wide)
                .weekday(.wide)
                .locale(currentLocale)
        )
    }

    private func eventTimeLabel(_ date: Date) -> String {
        if calendar.isDateInToday(date) {
            return date.formatted(
                .dateTime
                    .hour()
                    .minute()
                    .locale(currentLocale)
            )
        }
        return date.formatted(
            .dateTime
                .day()
                .month(.abbreviated)
                .locale(currentLocale)
        )
    }

    private func durationLabel(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds / 60)
        if minutes >= 60 {
            let hours = minutes / 60
            let remainder = minutes % 60
            return remainder == 0
                ? appText("\(hours) ч", "\(hours) h")
                : appText("\(hours) ч \(remainder) мин", "\(hours) h \(remainder) min")
        }
        return appText("\(minutes) мин", "\(minutes) min")
    }

    private func compactMinutes(_ seconds: TimeInterval) -> String {
        "\(Int(seconds / 60))"
    }

    private func pomodoroLabel(_ count: Int) -> String {
        AppLanguage.isRussian ? (count == 1 ? "сессия" : "сессий") : (count == 1 ? "session" : "sessions")
    }

    private func taskLabel(_ count: Int) -> String {
        AppLanguage.isRussian ? (count == 1 ? "задача" : "задач") : (count == 1 ? "task" : "tasks")
    }
}

private enum HistoryEvent: Identifiable {
    case session(FocusSessionRecord)
    case task(CompletedTaskRecord)

    var id: String {
        switch self {
        case .session(let session):
            "session-\(session.id.uuidString)"
        case .task(let task):
            "task-\(task.id.uuidString)"
        }
    }

    var date: Date {
        switch self {
        case .session(let session): session.endedAt
        case .task(let task): task.completedAt
        }
    }

    var title: String {
        switch self {
        case .session(let session):
            session.taskTitle ?? appText("Работа без задачи", "Work without a task")
        case .task(let task):
            task.title
        }
    }

    var detail: String {
        switch self {
        case .session(let session):
            appText("\(Int(session.focusedSeconds / 60)) мин · сессия завершена", "\(Int(session.focusedSeconds / 60)) min · session complete")
        case .task:
            appText("Задача завершена", "Task completed")
        }
    }

    var systemImage: String {
        switch self {
        case .session: "timer"
        case .task: "checkmark"
        }
    }

    var isFocus: Bool {
        if case .session = self { return true }
        return false
    }
}
