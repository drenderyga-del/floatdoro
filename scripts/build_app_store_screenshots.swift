#!/usr/bin/env swift

import AppKit
import Foundation

private struct ScreenshotSpec {
    let input: String
    let output: String
    let locale: String
    let index: Int
    let title: String
    let body: String
    let background: NSColor
    let foreground: NSColor
    let muted: NSColor
    let screenshotOnLeft: Bool
}

private let canvas = NSSize(width: 1440, height: 900)
private let projectRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
private let accent = NSColor(
    srgbRed: 0.27,
    green: 0.49,
    blue: 0.13,
    alpha: 1
)

private let specs = [
    ScreenshotSpec(
        input: "app-store/raw/01-timer-en.png",
        output: "app-store/screenshots/en-US/01-focus.jpg",
        locale: "en-US",
        index: 1,
        title: "Focus, without losing your place.",
        body: "A clear timer, task queue, and controls—one click from the menu bar.",
        background: NSColor(srgbRed: 0.96, green: 0.97, blue: 0.95, alpha: 1),
        foreground: NSColor(srgbRed: 0.08, green: 0.13, blue: 0.07, alpha: 1),
        muted: NSColor(srgbRed: 0.32, green: 0.39, blue: 0.29, alpha: 1),
        screenshotOnLeft: false
    ),
    ScreenshotSpec(
        input: "app-store/raw/02-floating-en.png",
        output: "app-store/screenshots/en-US/02-floating.jpg",
        locale: "en-US",
        index: 2,
        title: "Always visible. Never in the way.",
        body: "Keep the floating timer above every workspace and resize it around your flow.",
        background: NSColor(srgbRed: 0.10, green: 0.13, blue: 0.10, alpha: 1),
        foreground: .white,
        muted: NSColor(white: 0.80, alpha: 1),
        screenshotOnLeft: true
    ),
    ScreenshotSpec(
        input: "app-store/raw/03-history-en.png",
        output: "app-store/screenshots/en-US/03-history.jpg",
        locale: "en-US",
        index: 3,
        title: "See where your focus went.",
        body: "Weekly sessions and completed tasks stay on your Mac.",
        background: NSColor(srgbRed: 0.91, green: 0.95, blue: 0.89, alpha: 1),
        foreground: NSColor(srgbRed: 0.08, green: 0.13, blue: 0.07, alpha: 1),
        muted: NSColor(srgbRed: 0.30, green: 0.38, blue: 0.27, alpha: 1),
        screenshotOnLeft: false
    ),
    ScreenshotSpec(
        input: "app-store/raw/04-settings-en.png",
        output: "app-store/screenshots/en-US/04-settings.jpg",
        locale: "en-US",
        index: 4,
        title: "Make the timer yours.",
        body: "Choose durations, labels, appearance, sound, and launch behaviour.",
        background: NSColor(srgbRed: 0.18, green: 0.28, blue: 0.14, alpha: 1),
        foreground: .white,
        muted: NSColor(srgbRed: 0.79, green: 0.86, blue: 0.75, alpha: 1),
        screenshotOnLeft: true
    ),
    ScreenshotSpec(
        input: "app-store/raw/01-timer-ru.png",
        output: "app-store/screenshots/ru/01-focus.jpg",
        locale: "ru",
        index: 1,
        title: "Фокус — всегда под рукой.",
        body: "Таймер, очередь задач и управление — в одном клике из строки меню.",
        background: NSColor(srgbRed: 0.96, green: 0.97, blue: 0.95, alpha: 1),
        foreground: NSColor(srgbRed: 0.08, green: 0.13, blue: 0.07, alpha: 1),
        muted: NSColor(srgbRed: 0.32, green: 0.39, blue: 0.29, alpha: 1),
        screenshotOnLeft: false
    ),
    ScreenshotSpec(
        input: "app-store/raw/02-floating-ru.png",
        output: "app-store/screenshots/ru/02-floating.jpg",
        locale: "ru",
        index: 2,
        title: "Всегда виден. Никогда не мешает.",
        body: "Плавающий таймер остаётся поверх окон на любом рабочем столе.",
        background: NSColor(srgbRed: 0.10, green: 0.13, blue: 0.10, alpha: 1),
        foreground: .white,
        muted: NSColor(white: 0.80, alpha: 1),
        screenshotOnLeft: true
    ),
    ScreenshotSpec(
        input: "app-store/raw/03-history-ru.png",
        output: "app-store/screenshots/ru/03-history.jpg",
        locale: "ru",
        index: 3,
        title: "Понятная история фокуса.",
        body: "Сессии и выполненные задачи остаются только на вашем Mac.",
        background: NSColor(srgbRed: 0.91, green: 0.95, blue: 0.89, alpha: 1),
        foreground: NSColor(srgbRed: 0.08, green: 0.13, blue: 0.07, alpha: 1),
        muted: NSColor(srgbRed: 0.30, green: 0.38, blue: 0.27, alpha: 1),
        screenshotOnLeft: false
    ),
    ScreenshotSpec(
        input: "app-store/raw/04-settings-ru.png",
        output: "app-store/screenshots/ru/04-settings.jpg",
        locale: "ru",
        index: 4,
        title: "Настройте таймер под себя.",
        body: "Интервалы, подписи, оформление, звук и автозапуск.",
        background: NSColor(srgbRed: 0.18, green: 0.28, blue: 0.14, alpha: 1),
        foreground: .white,
        muted: NSColor(srgbRed: 0.79, green: 0.86, blue: 0.75, alpha: 1),
        screenshotOnLeft: true
    )
]

private func rectFromTop(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) -> NSRect {
    NSRect(x: x, y: canvas.height - y - height, width: width, height: height)
}

private func drawText(
    _ text: String,
    in rect: NSRect,
    font: NSFont,
    color: NSColor,
    lineHeight: CGFloat? = nil
) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.lineBreakMode = .byWordWrapping
    if let lineHeight {
        paragraph.minimumLineHeight = lineHeight
        paragraph.maximumLineHeight = lineHeight
    }
    (text as NSString).draw(
        with: rect,
        options: [.usesLineFragmentOrigin, .usesFontLeading],
        attributes: [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraph
        ]
    )
}

private func drawScreenshot(_ image: NSImage, in rect: NSRect) {
    NSGraphicsContext.saveGraphicsState()

    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.28)
    shadow.shadowBlurRadius = 34
    shadow.shadowOffset = NSSize(width: 0, height: -12)
    shadow.set()

    NSColor.white.setFill()
    NSBezierPath(roundedRect: rect, xRadius: 26, yRadius: 26).fill()
    NSGraphicsContext.restoreGraphicsState()

    NSGraphicsContext.saveGraphicsState()
    NSBezierPath(roundedRect: rect, xRadius: 26, yRadius: 26).addClip()
    image.draw(in: rect, from: .zero, operation: .copy, fraction: 1)
    NSGraphicsContext.restoreGraphicsState()
}

private func render(_ spec: ScreenshotSpec) throws {
    let inputURL = projectRoot.appendingPathComponent(spec.input)
    let outputURL = projectRoot.appendingPathComponent(spec.output)
    guard let screenshot = NSImage(contentsOf: inputURL) else {
        throw NSError(domain: "FloatdoroScreenshots", code: 1, userInfo: [
            NSLocalizedDescriptionKey: "Could not load \(inputURL.path)"
        ])
    }

    let image = NSImage(size: canvas)
    image.lockFocus()
    spec.background.setFill()
    NSBezierPath(rect: NSRect(origin: .zero, size: canvas)).fill()

    let motifColor = spec.foreground.withAlphaComponent(0.07)
    motifColor.setFill()
    for index in 0..<6 {
        let width = CGFloat(126 + index * 16)
        let rect = rectFromTop(
            x: spec.screenshotOnLeft ? 1180 - CGFloat(index * 48) : 40 + CGFloat(index * 48),
            y: 74 + CGFloat(index * 92),
            width: width,
            height: 28
        )
        NSBezierPath(roundedRect: rect, xRadius: 14, yRadius: 14).fill()
    }

    let iconURL = projectRoot.appendingPathComponent("Resources/AppIcon.png")
    if let icon = NSImage(contentsOf: iconURL) {
        icon.draw(
            in: rectFromTop(x: 72, y: 62, width: 64, height: 64),
            from: .zero,
            operation: .sourceOver,
            fraction: 1
        )
    }
    drawText(
        "FLOATDORO",
        in: rectFromTop(x: 152, y: 76, width: 260, height: 40),
        font: .systemFont(ofSize: 21, weight: .bold),
        color: spec.foreground
    )
    drawText(
        String(format: "%02d", spec.index),
        in: rectFromTop(x: 1310, y: 70, width: 70, height: 34),
        font: .monospacedDigitSystemFont(ofSize: 18, weight: .semibold),
        color: spec.muted
    )

    let textX: CGFloat = spec.screenshotOnLeft ? 820 : 74
    let titleY: CGFloat = 224
    let textWidth: CGFloat = 520
    drawText(
        spec.title,
        in: rectFromTop(x: textX, y: titleY, width: textWidth, height: 240),
        font: .systemFont(ofSize: spec.locale == "ru" ? 60 : 66, weight: .bold),
        color: spec.foreground,
        lineHeight: spec.locale == "ru" ? 66 : 72
    )
    drawText(
        spec.body,
        in: rectFromTop(x: textX, y: 500, width: textWidth, height: 170),
        font: .systemFont(ofSize: 27, weight: .medium),
        color: spec.muted,
        lineHeight: 38
    )

    let maxWidth: CGFloat = spec.input.contains("floating") ? 610 : 500
    let maxHeight: CGFloat = spec.input.contains("floating") ? 680 : 700
    let ratio = min(maxWidth / screenshot.size.width, maxHeight / screenshot.size.height)
    let shotSize = NSSize(
        width: screenshot.size.width * ratio,
        height: screenshot.size.height * ratio
    )
    let shotX: CGFloat = spec.screenshotOnLeft
        ? 112 + (610 - shotSize.width) / 2
        : 810 + (540 - shotSize.width) / 2
    let shotYFromTop = (canvas.height - shotSize.height) / 2 + 34
    drawScreenshot(
        screenshot,
        in: rectFromTop(
            x: shotX,
            y: shotYFromTop,
            width: shotSize.width,
            height: shotSize.height
        )
    )

    image.unlockFocus()

    guard
        let tiff = image.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiff),
        let jpeg = bitmap.representation(
            using: .jpeg,
            properties: [.compressionFactor: 0.94]
        )
    else {
        throw NSError(domain: "FloatdoroScreenshots", code: 2, userInfo: [
            NSLocalizedDescriptionKey: "Could not encode \(outputURL.path)"
        ])
    }

    try FileManager.default.createDirectory(
        at: outputURL.deletingLastPathComponent(),
        withIntermediateDirectories: true
    )
    try jpeg.write(to: outputURL, options: .atomic)
    print(outputURL.path)
}

for spec in specs {
    try render(spec)
}
