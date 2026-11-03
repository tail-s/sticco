// Draws the Sticco app icon (a lilac sticky with a folded corner) into Resources/AppIcon.icns.
// Usage: swift scripts/make-icon.swift
import AppKit

func render(_ px: Int) -> Data {
    let s = CGFloat(px)
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px, bitsPerSample: 8, samplesPerPixel: 4,
                               hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let inset = s * 0.1, side = s - inset * 2, r = side * 0.2, fold = side * 0.3
    let rect = CGRect(x: inset, y: inset, width: side, height: side)
    let path = NSBezierPath()
    path.move(to: CGPoint(x: rect.minX + r, y: rect.maxY))
    path.line(to: CGPoint(x: rect.maxX - r, y: rect.maxY))
    path.appendArc(withCenter: CGPoint(x: rect.maxX - r, y: rect.maxY - r), radius: r, startAngle: 90, endAngle: 0, clockwise: true)
    path.line(to: CGPoint(x: rect.maxX, y: rect.minY + fold))
    path.line(to: CGPoint(x: rect.maxX - fold, y: rect.minY))
    path.line(to: CGPoint(x: rect.minX + r, y: rect.minY))
    path.appendArc(withCenter: CGPoint(x: rect.minX + r, y: rect.minY + r), radius: r, startAngle: 270, endAngle: 180, clockwise: true)
    path.line(to: CGPoint(x: rect.minX, y: rect.maxY - r))
    path.appendArc(withCenter: CGPoint(x: rect.minX + r, y: rect.maxY - r), radius: r, startAngle: 180, endAngle: 90, clockwise: true)
    path.close()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.25)
    shadow.shadowBlurRadius = s * 0.03
    shadow.shadowOffset = NSSize(width: 0, height: -s * 0.015)
    shadow.set()
    NSColor(srgbRed: 0.77, green: 0.70, blue: 0.96, alpha: 1).setFill()
    path.fill()
    NSShadow().set()
    let foldPath = NSBezierPath()
    foldPath.move(to: CGPoint(x: rect.maxX, y: rect.minY + fold))
    foldPath.line(to: CGPoint(x: rect.maxX - fold * 0.75, y: rect.minY + fold))
    foldPath.curve(to: CGPoint(x: rect.maxX - fold, y: rect.minY), controlPoint1: CGPoint(x: rect.maxX - fold, y: rect.minY + fold),
                   controlPoint2: CGPoint(x: rect.maxX - fold, y: rect.minY + fold * 0.4))
    foldPath.close()
    NSColor(srgbRed: 0.60, green: 0.52, blue: 0.88, alpha: 1).setFill()
    foldPath.fill()
    let font = NSFont.systemFont(ofSize: side * 0.62, weight: .black)
    let rounded = font.fontDescriptor.withDesign(.rounded).flatMap { NSFont(descriptor: $0, size: side * 0.62) } ?? font
    let text = NSAttributedString(string: "s", attributes: [.font: rounded, .foregroundColor: NSColor(srgbRed: 0.13, green: 0.09, blue: 0.26, alpha: 1)])
    let size = text.size()
    text.draw(at: CGPoint(x: rect.midX - size.width / 2 - side * 0.04, y: rect.midY - size.height / 2 + side * 0.03))
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

let iconset = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("Sticco.iconset")
try? FileManager.default.removeItem(at: iconset)
try! FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
for base in [16, 32, 128, 256, 512] {
    try! render(base).write(to: iconset.appendingPathComponent("icon_\(base)x\(base).png"))
    try! render(base * 2).write(to: iconset.appendingPathComponent("icon_\(base)x\(base)@2x.png"))
}
let p = Process()
p.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
p.arguments = ["-c", "icns", iconset.path, "-o", "Resources/AppIcon.icns"]
try! p.run(); p.waitUntilExit()
print(p.terminationStatus == 0 ? "Resources/AppIcon.icns written" : "iconutil failed")
