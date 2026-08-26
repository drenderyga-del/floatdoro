import SwiftUI

struct ModeBadge: View {
    let phase: TimerPhase
    let title: String
    let accessibilityLabel: String
    @Environment(\.pomoPalette) private var palette

    private var color: Color {
        phase == .focus ? palette.tomato : palette.breakGreen
    }

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .foregroundStyle(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(palette.raised)
                .stroke(palette.border, lineWidth: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }
}

struct CircleActionButton: View {
    enum Treatment {
        case primary
        case secondary
        case quiet
    }

    let systemImage: String
    let label: String
    var size: CGFloat = 44
    var treatment: Treatment = .secondary
    var isEnabled = true
    let action: () -> Void
    @Environment(\.pomoPalette) private var palette

    private var foreground: Color {
        switch treatment {
        case .primary: palette.onHoney
        case .secondary, .quiet: palette.ink
        }
    }

    private var background: Color {
        switch treatment {
        case .primary: palette.honey
        case .secondary: palette.raised
        case .quiet: .clear
        }
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: size * 0.36, weight: .bold))
                .frame(width: size, height: size)
                .foregroundStyle(foreground)
                .background(Circle().fill(background))
                .contentShape(Circle())
        }
        .buttonStyle(PomoCircleButtonStyle())
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.38)
        .accessibilityLabel(label)
        .pomoHelp(label)
    }
}

private struct PomoCircleButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.92 : 1)
            .brightness(configuration.isPressed ? -0.08 : 0)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

struct ProgressRail: View {
    let progress: Double
    let phase: TimerPhase
    @Environment(\.pomoPalette) private var palette

    private var color: Color {
        phase == .focus ? palette.tomato : palette.breakGreen
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(palette.raised)
                Capsule()
                    .fill(color)
                    .frame(width: max(6, geometry.size.width * progress))
            }
        }
        .frame(height: 6)
        .accessibilityElement()
        .accessibilityLabel(appText("Прогресс интервала", "Interval progress"))
        .accessibilityValue(appText("\(Int(progress * 100)) процентов", "\(Int(progress * 100)) percent"))
    }
}

struct SegmentedProgressRail: View {
    let progress: Double
    let phase: TimerPhase
    var segmentCount = 24

    @Environment(\.pomoPalette) private var palette

    private var activeColor: Color {
        phase == .focus ? palette.tomato : palette.breakGreen
    }

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<segmentCount, id: \.self) { index in
                Capsule()
                    .fill(
                        Double(index + 1) / Double(segmentCount) <= progress
                            ? activeColor
                            : palette.raised
                    )
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 9)
        .accessibilityElement()
        .accessibilityLabel(appText("Прогресс интервала", "Interval progress"))
        .accessibilityValue(appText("\(Int(progress * 100)) процентов", "\(Int(progress * 100)) percent"))
    }
}

struct TaskRow: View {
    let task: FocusTask
    let isActive: Bool
    let toggle: () -> Void
    let delete: () -> Void
    @Environment(\.pomoPalette) private var palette

    private var indicatorColor: Color {
        if task.isCompleted { return palette.breakGreen }
        if isActive { return palette.tomato }
        return palette.muted
    }

    var body: some View {
        HStack(spacing: 10) {
            Button(action: toggle) {
                Circle()
                    .fill(indicatorColor)
                    .frame(width: 9, height: 9)
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(task.isCompleted ? appText("Вернуть задачу \(task.title)", "Restore task \(task.title)") : appText("Завершить задачу \(task.title)", "Complete task \(task.title)"))

            Text(task.title)
                .font(.system(size: 14, weight: isActive ? .semibold : .regular))
                .foregroundStyle(task.isCompleted ? palette.muted : palette.ink)
                .strikethrough(task.isCompleted, color: palette.muted)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            Menu {
                Button(task.isCompleted ? appText("Вернуть в список", "Restore to list") : appText("Отметить выполненной", "Mark complete"), action: toggle)
                Divider()
                Button(appText("Удалить", "Delete"), role: .destructive, action: delete)
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(palette.muted)
                    .frame(width: 30, height: 30)
                    .contentShape(Rectangle())
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
            .accessibilityLabel(appText("Действия с задачей \(task.title)", "Actions for task \(task.title)"))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(isActive ? palette.surface : palette.raised.opacity(0.45))
                .stroke(isActive ? palette.border : .clear, lineWidth: 1)
        )
        .contentShape(Rectangle())
    }
}

struct DurationStepper: View {
    let title: String
    let value: Int
    let range: ClosedRange<Int>
    let update: (Int) -> Void
    @Environment(\.pomoPalette) private var palette

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(palette.ink)
            Spacer()
            Button {
                update(max(range.lowerBound, value - 1))
            } label: {
                Image(systemName: "minus")
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(palette.raised))
            }
            .buttonStyle(.plain)
            .disabled(value <= range.lowerBound)
            .accessibilityLabel(appText("Уменьшить \(title.lowercased())", "Decrease \(title.lowercased())"))

            Text(appMinutes(value))
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(palette.ink)
                .frame(width: 58)

            Button {
                update(min(range.upperBound, value + 1))
            } label: {
                Image(systemName: "plus")
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(palette.raised))
            }
            .buttonStyle(.plain)
            .disabled(value >= range.upperBound)
            .accessibilityLabel(appText("Увеличить \(title.lowercased())", "Increase \(title.lowercased())"))
        }
    }
}

struct SettingsToggleRow: View {
    let title: String
    let detail: String
    @Binding var isOn: Bool
    @Environment(\.pomoPalette) private var palette

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(palette.ink)
                Text(detail)
                    .font(.system(size: 11))
                    .foregroundStyle(palette.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 12)
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(.switch)
                .tint(palette.tomato)
                .accessibilityLabel(title)
                .accessibilityHint(detail)
        }
    }
}

struct FloatingActionButton: View {
    enum Treatment {
        case primary
        case secondary
        case success
    }

    let systemImage: String
    let title: String
    var treatment: Treatment = .secondary
    var isEnabled = true
    let action: () -> Void

    @Environment(\.pomoPalette) private var palette

    private var fill: Color {
        switch treatment {
        case .primary: palette.tomato
        case .secondary: palette.raised
        case .success: palette.breakWash
        }
    }

    private var foreground: Color {
        switch treatment {
        case .primary: .white
        case .secondary: palette.ink
        case .success: palette.breakGreen
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .bold))
                Text(title)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
            }
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(fill)
            )
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(PomoPressButtonStyle())
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.42)
        .accessibilityLabel(title)
    }
}

private struct PomoPressButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .brightness(configuration.isPressed ? -0.05 : 0)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }
}
