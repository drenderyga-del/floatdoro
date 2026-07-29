import AppKit
import Foundation

guard CommandLine.arguments.count == 2 else {
    fputs("Usage: render_icon.swift <output.icns>\n", stderr)
    exit(2)
}

let outputURL = URL(fileURLWithPath: CommandLine.arguments[1])
let fileManager = FileManager.default
let temporaryURL = fileManager.temporaryDirectory
    .appendingPathComponent("PomoIcon-\(UUID().uuidString).iconset", isDirectory: true)

try fileManager.createDirectory(at: temporaryURL, withIntermediateDirectories: true)
defer { try? fileManager.removeItem(at: temporaryURL) }

let representations: [(name: String, points: Int, scale: Int)] = [
    ("icon_16x16.png", 16, 1),
    ("icon_16x16@2x.png", 16, 2),
    ("icon_32x32.png", 32, 1),
    ("icon_32x32@2x.png", 32, 2),
    ("icon_128x128.png", 128, 1),
    ("icon_128x128@2x.png", 128, 2),
    ("icon_256x256.png", 256, 1),
    ("icon_256x256@2x.png", 256, 2),
    ("icon_512x512.png", 512, 1),
    ("icon_512x512@2x.png", 512, 2)
]

func makeIcon(pixelSize: Int) throws -> Data {
    let image = NSImage(size: NSSize(width: pixelSize, height: pixelSize))
    image.lockFocus()

    guard let context = NSGraphicsContext.current?.cgContext else {
        throw NSError(domain: "PomoIcon", code: 1)
    }

    context.setAllowsAntialiasing(true)
    let bounds = CGRect(x: 0, y: 0, width: pixelSize, height: pixelSize)
    let inset = CGFloat(pixelSize) * 0.055
    let tile = bounds.insetBy(dx: inset, dy: inset)
    let radius = CGFloat(pixelSize) * 0.24

    NSColor.white.setFill()
    NSBezierPath(roundedRect: tile, xRadius: radius, yRadius: radius).fill()

    let dialCenter = CGPoint(x: CGFloat(pixelSize) * 0.5, y: CGFloat(pixelSize) * 0.48)
    let dialRadius = CGFloat(pixelSize) * 0.255
    let lineWidth = CGFloat(pixelSize) * 0.075
    context.setStrokeColor(NSColor(srgbRed: 0.16, green: 0.55, blue: 0.32, alpha: 1).cgColor)
    context.setLineWidth(lineWidth)
    context.setLineCap(.round)
    context.addArc(
        center: dialCenter,
        radius: dialRadius,
        startAngle: -.pi * 0.12,
        endAngle: .pi * 1.52,
        clockwise: false
    )
    context.strokePath()

    let stemWidth = CGFloat(pixelSize) * 0.19
    let stemHeight = CGFloat(pixelSize) * 0.07
    let stemRect = CGRect(
        x: CGFloat(pixelSize) * 0.5 - stemWidth / 2,
        y: CGFloat(pixelSize) * 0.77,
        width: stemWidth,
        height: stemHeight
    )
    NSColor(srgbRed: 0.16, green: 0.55, blue: 0.32, alpha: 1).setFill()
    NSBezierPath(roundedRect: stemRect, xRadius: stemHeight / 2, yRadius: stemHeight / 2).fill()

    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .center
    let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.monospacedDigitSystemFont(
            ofSize: CGFloat(pixelSize) * 0.24,
            weight: .bold
        ),
        .foregroundColor: NSColor(srgbRed: 0.10, green: 0.18, blue: 0.12, alpha: 1),
        .paragraphStyle: paragraph
    ]
    let textRect = CGRect(
        x: CGFloat(pixelSize) * 0.22,
        y: CGFloat(pixelSize) * 0.34,
        width: CGFloat(pixelSize) * 0.56,
        height: CGFloat(pixelSize) * 0.28
    )
    NSString(string: "25").draw(in: textRect, withAttributes: attributes)

    image.unlockFocus()
    guard
        let tiff = image.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiff),
        let png = bitmap.representation(using: .png, properties: [:])
    else {
        throw NSError(domain: "PomoIcon", code: 2)
    }
    return png
}

for representation in representations {
    let pixels = representation.points * representation.scale
    let data = try makeIcon(pixelSize: pixels)
    try data.write(to: temporaryURL.appendingPathComponent(representation.name))
}

let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", temporaryURL.path, "-o", outputURL.path]
try process.run()
process.waitUntilExit()

guard process.terminationStatus == 0 else {
    throw NSError(domain: "PomoIcon", code: Int(process.terminationStatus))
}
