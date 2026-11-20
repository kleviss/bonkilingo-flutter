import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

// Draws icon concept C ("highlighted b") in a 120-unit design space.
// Usage: swift tool/draw_app_icon.swift <out.png> <size> <mode>
//   mode "full": cream background, full bleed (iOS / legacy Android)
//   mode "fg":   transparent, glyph scaled into the adaptive-icon safe zone
let args = CommandLine.arguments
let out = args[1]
let size = Int(args[2])!
let mode = args[3]

func rgb(_ hex: UInt32, _ a: CGFloat = 1) -> CGColor {
  CGColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
          green: CGFloat((hex >> 8) & 0xFF) / 255,
          blue: CGFloat(hex & 0xFF) / 255, alpha: a)
}

let cs = CGColorSpace(name: CGColorSpace.sRGB)!
let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8,
                    bytesPerRow: 0, space: cs,
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
// Flip to a top-left origin and scale the 120-unit design to the canvas.
ctx.translateBy(x: 0, y: CGFloat(size))
ctx.scaleBy(x: CGFloat(size) / 120, y: -CGFloat(size) / 120)

if mode == "full" {
  ctx.setFillColor(rgb(0xFFF8EC))
  ctx.fill(CGRect(x: 0, y: 0, width: 120, height: 120))
} else {
  // Transparent foreground at full size: flutter_launcher_icons already
  // insets it 16% into the adaptive icon's safe zone.
}

// Nudge left so the glyph (stem + bowl) is optically centred.
ctx.translateBy(x: -3, y: 0)

// Highlighter stroke.
let bar = CGMutablePath()
bar.move(to: CGPoint(x: 26, y: 62))
bar.addLine(to: CGPoint(x: 98, y: 56))
bar.addLine(to: CGPoint(x: 98, y: 90))
bar.addLine(to: CGPoint(x: 27, y: 94))
bar.closeSubpath()
ctx.addPath(bar)
ctx.setFillColor(rgb(0xFFD84D))
ctx.fillPath()

// The "b": rounded stem and a ring bowl.
ctx.setFillColor(rgb(0x1C1C1E))
ctx.addPath(CGPath(roundedRect: CGRect(x: 34, y: 20, width: 17, height: 74),
                   cornerWidth: 8.5, cornerHeight: 8.5, transform: nil))
ctx.fillPath()
ctx.setStrokeColor(rgb(0x1C1C1E))
ctx.setLineWidth(16)
ctx.strokeEllipse(in: CGRect(x: 46, y: 52, width: 40, height: 40))

let image = ctx.makeImage()!
let dest = CGImageDestinationCreateWithURL(URL(fileURLWithPath: out) as CFURL,
                                           UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(dest, image, nil)
CGImageDestinationFinalize(dest)
print("wrote \(out)")
