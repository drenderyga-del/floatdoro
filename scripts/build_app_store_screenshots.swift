#!/usr/bin/env swift

import AppKit
import Foundation

private struct ScreenshotSpec {
    let input: String
    let output: String
    let locale: String
    let index: Int
    let eyebrow: String
    let title: String
    let body: String
    let backgroundStart: NSColor
    let backgroundEnd: NSColor
    let accent: NSColor
    let foreground: NSColor
    let muted: NSColor
    let screenshotOnLeft: Bool
}

private let canvas = NSSize(width: 1440, height: 900)
private let outputScale: CGFloat = 2
private let projectRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
private let focusAccent = NSColor(srgbRed: 0.91, green: 0.18, blue: 0.14, alpha: 1)
private let restAccent = NSColor(srgbRed: 0.18, green: 0.42, blue: 0.95, alpha: 1)
private let lightInk = NSColor(srgbRed: 0.055, green: 0.065, blue: 0.095, alpha: 1)
private let lightMuted = NSColor(srgbRed: 0.31, green: 0.33, blue: 0.39, alpha: 1)
private let darkInk = NSColor(srgbRed: 0.97, green: 0.975, blue: 0.99, alpha: 1)
private let darkMuted = NSColor(srgbRed: 0.70, green: 0.72, blue: 0.78, alpha: 1)

private let specs = [
    ScreenshotSpec(
        input: "app-store/raw/01-timer-en.png",
        output: "app-store/screenshots/en-US/01-focus.jpg",
        locale: "en-US",
        index: 1,
        eyebrow: "MENU BAR FOCUS TIMER",
        title: "Your focus.\nOne glance away.",
        body: "A clear countdown, current task, and queue—right from the menu bar.",
        backgroundStart: NSColor(srgbRed: 0.96, green: 0.97, blue: 0.995, alpha: 1),
        backgroundEnd: NSColor(srgbRed: 1.00, green: 0.945, blue: 0.935, alpha: 1),
        accent: focusAccent,
        foreground: lightInk,
        muted: lightMuted,
        screenshotOnLeft: false
    ),
    ScreenshotSpec(
        input: "app-store/raw/02-floating-en.png",
        output: "app-store/screenshots/en-US/02-floating.jpg",
        locale: "en-US",
        index: 2,
        eyebrow: "FLOATING TIMER",
        title: "Stay visible.\nStay in flow.",
        body: "Keep the floating timer above every workspace, compact or expanded.",
        backgroundStart: NSColor(srgbRed: 0.055, green: 0.065, blue: 0.095, alpha: 1),
        backgroundEnd: NSColor(srgbRed: 0.15, green: 0.085, blue: 0.105, alpha: 1),
        accent: focusAccent,
        foreground: darkInk,
        muted: darkMuted,
        screenshotOnLeft: true
    ),
    ScreenshotSpec(
        input: "app-store/raw/03-history-en.png",
        output: "app-store/screenshots/en-US/03-history.jpg",
        locale: "en-US",
        index: 3,
        eyebrow: "LOCAL HISTORY",
        title: "See the work\nyou finished.",
        body: "Review weekly intervals and checked-off tasks. Everything stays on your Mac.",
        backgroundStart: NSColor(srgbRed: 0.91, green: 0.945, blue: 1.00, alpha: 1),
        backgroundEnd: NSColor(srgbRed: 0.975, green: 0.98, blue: 0.995, alpha: 1),
        accent: restAccent,
        foreground: lightInk,
        muted: lightMuted,
        screenshotOnLeft: false
    ),
    ScreenshotSpec(
        input: "app-store/raw/04-settings-en.png",
        output: "app-store/screenshots/en-US/04-settings.jpg",
        locale: "en-US",
        index: 4,
        eyebrow: "YOUR SETTINGS",
        title: "Built around\nyour rhythm.",
        body: "Automate breaks, keep the timer floating, and tune sound and startup.",
        backgroundStart: NSColor(srgbRed: 1.00, green: 0.945, blue: 0.935, alpha: 1),
        backgroundEnd: NSColor(srgbRed: 0.95, green: 0.965, blue: 0.995, alpha: 1),
        accent: focusAccent,
        foreground: lightInk,
        muted: lightMuted,
        screenshotOnLeft: true
    ),
    ScreenshotSpec(
        input: "app-store/raw/01-timer-ru.png",
        output: "app-store/screenshots/ru/01-focus.jpg",
        locale: "ru",
        index: 1,
        eyebrow: "ТАЙМЕР В СТРОКЕ МЕНЮ",
        title: "Фокус — всегда\nперед глазами.",
        body: "Таймер, текущая задача и очередь — прямо из строки меню.",
        backgroundStart: NSColor(srgbRed: 0.96, green: 0.97, blue: 0.995, alpha: 1),
        backgroundEnd: NSColor(srgbRed: 1.00, green: 0.945, blue: 0.935, alpha: 1),
        accent: focusAccent,
        foreground: lightInk,
        muted: lightMuted,
        screenshotOnLeft: false
    ),
    ScreenshotSpec(
        input: "app-store/raw/02-floating-ru.png",
        output: "app-store/screenshots/ru/02-floating.jpg",
        locale: "ru",
        index: 2,
        eyebrow: "ПЛАВАЮЩИЙ ТАЙМЕР",
        title: "На виду.\nБез помех.",
        body: "Плавающий таймер остаётся поверх окон: компактный или с очередью.",
        backgroundStart: NSColor(srgbRed: 0.055, green: 0.065, blue: 0.095, alpha: 1),
        backgroundEnd: NSColor(srgbRed: 0.15, green: 0.085, blue: 0.105, alpha: 1),
        accent: focusAccent,
        foreground: darkInk,
        muted: darkMuted,
        screenshotOnLeft: true
    ),
    ScreenshotSpec(
        input: "app-store/raw/03-history-ru.png",
        output: "app-store/screenshots/ru/03-history.jpg",
        locale: "ru",
        index: 3,
        eyebrow: "ЛОКАЛЬНАЯ ИСТОРИЯ",
        title: "Видно, что\nсделано.",
        body: "Смотрите интервалы и завершённые задачи за неделю. Данные остаются на Mac.",
        backgroundStart: NSColor(srgbRed: 0.91, green: 0.945, blue: 1.00, alpha: 1),
        backgroundEnd: NSColor(srgbRed: 0.975, green: 0.98, blue: 0.995, alpha: 1),
        accent: restAccent,
        foreground: lightInk,
        muted: lightMuted,
        screenshotOnLeft: false
    ),
    ScreenshotSpec(
        input: "app-store/raw/04-settings-ru.png",
        output: "app-store/screenshots/ru/04-settings.jpg",
        locale: "ru",
        index: 4,
        eyebrow: "ВАШИ НАСТРОЙКИ",
        title: "Работает\nв вашем ритме.",
        body: "Автоматизируйте отдых, плавающий таймер, звук и запуск при входе.",
        backgroundStart: NSColor(srgbRed: 1.00, green: 0.945, blue: 0.935, alpha: 1),
        backgroundEnd: NSColor(srgbRed: 0.95, green: 0.965, blue: 0.995, alpha: 1),
        accent: focusAccent,
        foreground: lightInk,
        muted: lightMuted,
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
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.24)
    shadow.shadowBlurRadius = 42
    shadow.shadowOffset = NSSize(width: 0, height: -16)
    shadow.set()

    NSColor.white.setFill()
    NSBezierPath(roundedRect: rect, xRadius: 26, yRadius: 26).fill()
    NSGraphicsContext.restoreGraphicsState()

    NSGraphicsContext.saveGraphicsState()
    NSBezierPath(roundedRect: rect, xRadius: 26, yRadius: 26).addClip()
    image.draw(in: rect, from: .zero, operation: .copy, fraction: 1)
    NSGraphicsContext.restoreGraphicsState()

    NSColor.white.withAlphaComponent(0.32).setStroke()
    let border = NSBezierPath(roundedRect: rect, xRadius: 26, yRadius: 26)
    border.lineWidth = 1
    border.stroke()
}

private func render(_ spec: ScreenshotSpec) throws {
    let inputURL = projectRoot.appendingPathComponent(spec.input)
    let outputURL = projectRoot.appendingPathComponent(spec.output)
    guard let screenshot = NSImage(contentsOf: inputURL) else {
        throw NSError(domain: "FloatdoroScreenshots", code: 1, userInfo: [
            NSLocalizedDescriptionKey: "Could not load \(inputURL.path)"
        ])
    }

    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(canvas.width * outputScale),
        pixelsHigh: Int(canvas.height * outputScale),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ), let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
        throw NSError(domain: "FloatdoroScreenshots", code: 2, userInfo: [
            NSLocalizedDescriptionKey: "Could not create the 2x render target"
        ])
    }

    bitmap.size = canvas
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    defer { NSGraphicsContext.restoreGraphicsState() }
    context.cgContext.scaleBy(x: outputScale, y: outputScale)
    NSGradient(starting: spec.backgroundStart, ending: spec.backgroundEnd)?.draw(
        in: NSRect(origin: .zero, size: canvas),
        angle: spec.screenshotOnLeft ? 20 : 160
    )

    spec.accent.withAlphaComponent(0.11).setFill()
    NSBezierPath(
        ovalIn: rectFromTop(
            x: spec.screenshotOnLeft ? -210 : 815,
            y: -250,
            width: 920,
            height: 920
        )
    ).fill()
    spec.accent.withAlphaComponent(0.055).setStroke()
    let orbit = NSBezierPath(
        ovalIn: rectFromTop(
            x: spec.screenshotOnLeft ? -60 : 720,
            y: -90,
            width: 760,
            height: 760
        )
    )
    orbit.lineWidth = 2
    orbit.stroke()

    let brandMark = rectFromTop(x: 72, y: 63, width: 46, height: 46)
    spec.foreground.withAlphaComponent(0.08).setFill()
    NSBezierPath(roundedRect: brandMark, xRadius: 14, yRadius: 14).fill()
    spec.accent.setStroke()
    let ring = NSBezierPath()
    ring.appendArc(
        withCenter: NSPoint(x: brandMark.midX, y: brandMark.midY),
        radius: 11,
        startAngle: 35,
        endAngle: 326,
        clockwise: false
    )
    ring.lineWidth = 3
    ring.lineCapStyle = .round
    ring.stroke()
    spec.accent.setFill()
    NSBezierPath(
        ovalIn: NSRect(
            x: brandMark.midX + 6.5,
            y: brandMark.midY + 7.5,
            width: 5,
            height: 5
        )
    ).fill()

    drawText(
        "FLOATDORO",
        in: rectFromTop(x: 134, y: 75, width: 260, height: 34),
        font: .systemFont(ofSize: 20, weight: .bold),
        color: spec.foreground
    )

    let indexRect = rectFromTop(x: 1294, y: 65, width: 76, height: 40)
    spec.foreground.withAlphaComponent(0.07).setFill()
    NSBezierPath(roundedRect: indexRect, xRadius: 20, yRadius: 20).fill()
    drawText(
        String(format: "%02d", spec.index),
        in: rectFromTop(x: 1317, y: 74, width: 44, height: 26),
        font: .monospacedDigitSystemFont(ofSize: 16, weight: .semibold),
        color: spec.foreground
    )

    let textX: CGFloat = spec.screenshotOnLeft ? 820 : 74
    let titleY: CGFloat = 258
    let textWidth: CGFloat = 520
    drawText(
        spec.eyebrow,
        in: rectFromTop(x: textX, y: 205, width: textWidth, height: 30),
        font: .systemFont(ofSize: 16, weight: .bold),
        color: spec.accent
    )
    drawText(
        spec.title,
        in: rectFromTop(x: textX, y: titleY, width: textWidth, height: 210),
        font: .systemFont(ofSize: spec.locale == "ru" ? 56 : 62, weight: .bold),
        color: spec.foreground,
        lineHeight: spec.locale == "ru" ? 61 : 67
    )
    drawText(
        spec.body,
        in: rectFromTop(x: textX, y: 505, width: textWidth, height: 170),
        font: .systemFont(ofSize: 25, weight: .medium),
        color: spec.muted,
        lineHeight: 36
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

    context.flushGraphics()

    guard
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
