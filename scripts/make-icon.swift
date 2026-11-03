// Draws the Sticco app icon (three stickies on a cream tile, the front one smiling) into Resources/AppIcon.icns.
// Usage: swift scripts/make-icon.swift [preview.png]
import AppKit

func c(_ hex: UInt32) -> NSColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255, blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
}

func shadowed(_ blur: CGFloat, _ y: CGFloat, _ alpha: CGFloat, _ draw: () -> Void) {
    NSGraphicsContext.saveGraphicsState()
    let s = NSShadow(); s.shadowColor = NSColor.black.withAlphaComponent(alpha); s.shadowBlurRadius = blur; s.shadowOffset = NSSize(width: 0, height: y); s.set()
    draw()
    NSGraphicsContext.restoreGraphicsState()
}

func rotated(_ center: CGPoint, _ degrees: CGFloat, _ draw: () -> Void) {
    NSGraphicsContext.saveGraphicsState()
    let t = NSAffineTransform(); t.translateX(by: center.x, yBy: center.y); t.rotate(byDegrees: degrees); t.concat()
    draw()
    NSGraphicsContext.restoreGraphicsState()
}

/// Drawn in a 512-point space.
func drawIcon() {
    // tile
    let tile = NSBezierPath(roundedRect: CGRect(x: 50, y: 50, width: 412, height: 412), xRadius: 92, yRadius: 92)
    shadowed(14, -6, 0.22) { c(0xF7EFE4).setFill(); tile.fill() }
    NSGraphicsContext.saveGraphicsState(); tile.addClip()
    c(0xFFFFFF).withAlphaComponent(0.35).setStroke(); tile.lineWidth = 3; tile.stroke()
    NSGraphicsContext.restoreGraphicsState()

    // back notes
    rotated(CGPoint(x: 206, y: 318), -4) {
        let r = NSBezierPath(roundedRect: CGRect(x: -100, y: -72, width: 200, height: 144), xRadius: 10, yRadius: 10)
        shadowed(10, -4, 0.18) { c(0xF2A6B6).setFill(); r.fill() }
    }
    rotated(CGPoint(x: 322, y: 196), 3) {
        let r = NSBezierPath(roundedRect: CGRect(x: -88, y: -70, width: 176, height: 140), xRadius: 10, yRadius: 10)
        shadowed(10, -4, 0.18) { c(0xA8D5F7).setFill(); r.fill() }
    }

    // front note with a curled corner
    rotated(CGPoint(x: 248, y: 252), -3) {
        let w: CGFloat = 228, h: CGFloat = 214, curl: CGFloat = 62, rad: CGFloat = 10
        let x0 = -w / 2, y0 = -h / 2, x1 = w / 2, y1 = h / 2
        let body = NSBezierPath()
        body.move(to: CGPoint(x: x0 + rad, y: y1))
        body.line(to: CGPoint(x: x1 - rad, y: y1))
        body.appendArc(withCenter: CGPoint(x: x1 - rad, y: y1 - rad), radius: rad, startAngle: 90, endAngle: 0, clockwise: true)
        body.line(to: CGPoint(x: x1, y: y0 + curl))
        body.curve(to: CGPoint(x: x1 - curl, y: y0), controlPoint1: CGPoint(x: x1 - 10, y: y0 + 20), controlPoint2: CGPoint(x: x1 - 30, y: y0 + 4))
        body.line(to: CGPoint(x: x0 + rad, y: y0))
        body.appendArc(withCenter: CGPoint(x: x0 + rad, y: y0 + rad), radius: rad, startAngle: 270, endAngle: 180, clockwise: true)
        body.line(to: CGPoint(x: x0, y: y1 - rad))
        body.appendArc(withCenter: CGPoint(x: x0 + rad, y: y1 - rad), radius: rad, startAngle: 180, endAngle: 90, clockwise: true)
        body.close()
        shadowed(16, -8, 0.22) { c(0xF9DA6A).setFill(); body.fill() }

        let flap = NSBezierPath()
        flap.move(to: CGPoint(x: x1, y: y0 + curl))
        flap.curve(to: CGPoint(x: x1 - curl, y: y0), controlPoint1: CGPoint(x: x1 - 18, y: y0 + curl - 6), controlPoint2: CGPoint(x: x1 - curl + 4, y: y0 + 22))
        flap.curve(to: CGPoint(x: x1, y: y0 + curl), controlPoint1: CGPoint(x: x1 - 30, y: y0 + 4), controlPoint2: CGPoint(x: x1 - 10, y: y0 + 20))
        flap.close()
        shadowed(6, -2, 0.18) { c(0xFDECA6).setFill(); flap.fill() }

        let ink = c(0x5A3A1E)
        ink.setStroke()
        for ex in [-34.0, 30.0] as [CGFloat] {
            let eye = NSBezierPath(); eye.lineWidth = 12; eye.lineCapStyle = .round
            eye.move(to: CGPoint(x: ex, y: 40)); eye.line(to: CGPoint(x: ex, y: 62)); eye.stroke()
        }
        let smile = NSBezierPath(); smile.lineWidth = 11; smile.lineCapStyle = .round
        smile.appendArc(withCenter: CGPoint(x: 0, y: 26), radius: 58, startAngle: 212, endAngle: 328)
        smile.stroke()
    }
}

func png(_ px: Int) -> Data {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px, bitsPerSample: 8, samplesPerPixel: 4,
                               hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let t = NSAffineTransform(); t.scale(by: CGFloat(px) / 512); t.concat()
    drawIcon()
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

let iconset = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("Sticco.iconset")
try? FileManager.default.removeItem(at: iconset)
try! FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
for base in [16, 32, 128, 256, 512] {
    try! png(base).write(to: iconset.appendingPathComponent("icon_\(base)x\(base).png"))
    try! png(base * 2).write(to: iconset.appendingPathComponent("icon_\(base)x\(base)@2x.png"))
}
if CommandLine.arguments.count > 1 { try! png(256).write(to: URL(fileURLWithPath: CommandLine.arguments[1])) }
let p = Process()
p.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
p.arguments = ["-c", "icns", iconset.path, "-o", "Resources/AppIcon.icns"]
try! p.run(); p.waitUntilExit()
print(p.terminationStatus == 0 ? "Resources/AppIcon.icns written" : "iconutil failed")
