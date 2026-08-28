import SwiftUI

struct ModeBadge: View {
    let phase: TimerPhase
    let title: String
    let accessibilityLabel: String
    @Environment(\.pomoPalette) private var palette

    private var color: Color {
        phase == .focus ? palette.focusAccent : palette.restAccent
    }

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .shadow(color: color.opacity(0.35), radius: 5)
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .foregroundStyle(palette.ink)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }
}

struct IconActionButton: View {
    let systemImage: String
    let label: String
    var size: CGFloat = 44
    var isEnabled = true
    let action: () -> Void
    @Environment(\.pomoPalette) private var palette

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: size * 0.34, weight: .semibold))
                .frame(width: size, height: size)
                .foregroundStyle(palette.ink)
                .background(
                    RoundedRectangle(cornerRadius: size * 0.32, style: .continuous)
                        .fill(palette.surface.opacity(0.66))
                )
                .overlay {
                    RoundedRectangle(cornerRadius: size * 0.32, style: .continuous)
                        .stroke(.white.opacity(0.22), lineWidth: 0.75)
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(IconPressButtonStyle())
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.38)
        .accessibilityLabel(label)
        .pomoHelp(label)
    }
}

private struct IconPressButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.pomoReduceMotionOverride) private var reduceMotionOverride

    private var reduceMotion: Bool {
        reduceMotionOverride ?? systemReduceMotion
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.96 : 1)
            .brightness(configuration.isPressed ? -0.08 : 0)
            .animation(
                reduceMotion ? nil : .easeOut(duration: 0.16),
                value: configuration.isPressed
            )
    }
}

struct ProgressRail: View {
    let progress: Double
    let phase: TimerPhase
    @Environment(\.pomoPalette) private var palette

    private var color: Color {
        phase == .focus ? palette.focusAccent : palette.restAccent
    }

    var body: some View {
        GeometryReader { geometry in
            let clampedProgress = min(max(progress, 0), 1)
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(palette.raised)
                if clampedProgress > 0 {
                    Capsule()
                        .fill(color)
                        .frame(
                            width: max(
                                2,
                                geometry.size.width * clampedProgress
                            )
                        )
                }
            }
        }
        .frame(height: 6)
        .accessibilityElement()
        .accessibilityLabel(appText("Прогресс интервала", "Interval progress"))
        .accessibilityValue(
            appText(
                "\(Int(min(max(progress, 0), 1) * 100)) процентов",
                "\(Int(min(max(progress, 0), 1) * 100)) percent"
            )
        )
    }
}

struct TaskRow: View {
    let task: FocusTask
    let toggle: () -> Void
    let delete: () -> Void
    @Environment(\.pomoPalette) private var palette

    var body: some View {
        HStack(spacing: 10) {
            Button(action: toggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(
                        task.isCompleted ? palette.focusAccent : palette.muted
                    )
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(task.isCompleted ? appText("Вернуть задачу \(task.title)", "Restore task \(task.title)") : appText("Завершить задачу \(task.title)", "Complete task \(task.title)"))

            Text(task.title)
                .font(.system(size: 14, weight: .regular))
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
        .padding(.horizontal, 6)
        .padding(.vertical, 7)
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
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(palette.surface.opacity(0.72))
                    )
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
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(palette.surface.opacity(0.72))
                    )
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
                .tint(palette.focusAccent)
                .accessibilityLabel(title)
                .accessibilityHint(detail)
        }
    }
}
