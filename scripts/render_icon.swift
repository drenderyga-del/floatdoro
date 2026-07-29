import AppKit
import Foundation

guard CommandLine.arguments.count == 3 else {
    fputs("Usage: render_icon.swift <source.png> <output.icns>\n", stderr)
    exit(2)
}

let sourceURL = URL(fileURLWithPath: CommandLine.arguments[1])
let outputURL = URL(fileURLWithPath: CommandLine.arguments[2])
let fileManager = FileManager.default
let temporaryURL = fileManager.temporaryDirectory
    .appendingPathComponent("MacodoroIcon-\(UUID().uuidString).iconset", isDirectory: true)

guard let sourceImage = NSImage(contentsOf: sourceURL) else {
    fputs("Unable to read icon source: \(sourceURL.path)\n", stderr)
    exit(2)
}

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

    guard let graphicsContext = NSGraphicsContext.current else {
        throw NSError(domain: "MacodoroIcon", code: 1)
    }

    graphicsContext.imageInterpolation = .high
    sourceImage.draw(
        in: NSRect(x: 0, y: 0, width: pixelSize, height: pixelSize),
        from: NSRect(origin: .zero, size: sourceImage.size),
        operation: .copy,
        fraction: 1
    )

    image.unlockFocus()
    guard
        let tiff = image.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiff),
        let png = bitmap.representation(using: .png, properties: [:])
    else {
        throw NSError(domain: "MacodoroIcon", code: 2)
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
    throw NSError(domain: "MacodoroIcon", code: Int(process.terminationStatus))
}
