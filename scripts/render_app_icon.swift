import AppKit

let outputURL = URL(fileURLWithPath: CommandLine.arguments[1])
let image = NSImage(size: NSSize(width: 1024, height: 1024))

image.lockFocus()
NSColor.clear.setFill()
NSRect(x: 0, y: 0, width: 1024, height: 1024).fill()

let tile = NSBezierPath(
    roundedRect: NSRect(x: 64, y: 64, width: 896, height: 896),
    xRadius: 210,
    yRadius: 210
)
NSGradient(colors: [
    NSColor(calibratedRed: 0.115, green: 0.118, blue: 0.128, alpha: 1),
    NSColor(calibratedRed: 0.035, green: 0.038, blue: 0.045, alpha: 1)
])?.draw(in: tile, angle: -70)
NSColor(calibratedRed: 0.23, green: 0.24, blue: 0.26, alpha: 1).setStroke()
tile.lineWidth = 2
tile.stroke()

let center = CGPoint(x: 512, y: 512)
let radius: CGFloat = 245
let strokeWidth: CGFloat = 105
let startAngle: CGFloat = 32
let endAngle: CGFloat = 328

let letter = NSBezierPath()
letter.lineWidth = strokeWidth
letter.lineCapStyle = .round
letter.appendArc(
    withCenter: NSPoint(x: center.x, y: center.y),
    radius: radius,
    startAngle: startAngle,
    endAngle: endAngle
)
NSColor.white.setStroke()
letter.stroke()

// The C is also the progress-ring motif. A short color accent finishes in white.
if let context = NSGraphicsContext.current?.cgContext,
   let gradient = CGGradient(
       colorsSpace: CGColorSpaceCreateDeviceRGB(),
       colors: [
           NSColor(calibratedRed: 0.02, green: 0.42, blue: 0.98, alpha: 1).cgColor,
           NSColor(calibratedRed: 0.39, green: 0.81, blue: 1, alpha: 1).cgColor,
           NSColor.white.cgColor
       ] as CFArray,
       locations: [0, 0.55, 1]
   ) {
    context.saveGState()
    context.addArc(
        center: center,
        radius: radius,
        startAngle: startAngle * .pi / 180,
        endAngle: 78 * .pi / 180,
        clockwise: false
    )
    context.setLineWidth(strokeWidth)
    context.setLineCap(.round)
    context.replacePathWithStrokedPath()
    context.clip()
    context.drawLinearGradient(
        gradient,
        start: CGPoint(x: 792, y: 656),
        end: CGPoint(x: 560, y: 656),
        options: []
    )
    context.restoreGState()
}

image.unlockFocus()

guard let tiffData = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiffData),
      let pngData = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Failed to render ReadyCheck app icon")
}

try pngData.write(to: outputURL)
