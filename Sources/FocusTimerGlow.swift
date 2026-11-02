import SwiftUI

/// A soft, moving wash of light along the bottom edge, behind the controls.
struct FocusTimerGlow: View {
    let running: Bool
    var verticalScale: CGFloat = 1
    @ObservedObject private var sound = FocusSound.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: !running || reduceMotion || reduceTransparency)) { timeline in
            let phase = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate * 0.45
            Canvas { originalContext, viewport in
                var context = originalContext
                let size = CGSize(width: viewport.width, height: viewport.height / verticalScale)
                context.scaleBy(x: 1, y: verticalScale)
                guard running, !reduceTransparency else { return }
                context.drawLayer { glow in
                glow.addFilter(.blur(radius: 7))
                for index in 0..<7 {
                    let n = Double(index)
                    let x = size.width * (CGFloat(index) / 6 + CGFloat(sin(phase + n * 1.7)) * 0.11)
                    // Keep every light anchored below the physical bottom edge.
                    // Only its spread and strength move, never its vertical position.
                    let spread = 86 + 15 * sin(phase * 1.3 + n * 1.9)
                    let centre = CGPoint(x: x, y: size.height + 8)
                    let rect = CGRect(x: x - spread, y: size.height - 46, width: spread * 2, height: 98)
                    let strength = (scheme == .dark ? 0.95 : 0.62) * (0.85 + 0.15 * sin(phase + n))
                    glow.fill(Path(ellipseIn: rect), with: .radialGradient(
                        Gradient(colors: [Color.accentColor.opacity(strength), Color.accentColor.opacity(0)]),
                        center: centre, startRadius: 0, endRadius: spread))
                }
                }
                // Muting returns to the quiet theme glow, rather than suggesting audible sound.
                if !reduceMotion {
                    let ambience = sound.choices.muted ? "off" : sound.choices.ambience
                    if ambience == "rain" {
                        drawRain(in: &context, size: size, time: phase / 0.45)
                    } else if ambience == "ocean" {
                        drawOcean(in: &context, size: size, time: phase / 0.45)
                    } else if ambience == "tick" {
                        drawClock(in: &context, size: size, time: phase / 0.45)
                    } else {
                    for index in 0..<72 {
                        let n = Double(index)
                        let life = (phase * (0.22 + Double(index % 5) * 0.035) + n * 0.618).truncatingRemainder(dividingBy: 1)
                        let base = (n * 0.61803398875).truncatingRemainder(dividingBy: 1)
                        let x = size.width * base + sin(phase * 1.5 + n) * 12
                        let rise = life * (ambience == "fire" ? 42 + Double(index % 7) * 5 : 28 + Double(index % 7) * 4)
                        let y = size.height - 1 - rise
                        let radius = 0.65 + Double(index % 4) * 0.3
                        let alpha = sin(life * .pi) * (scheme == .dark ? 0.9 : 0.7)
                        let dot = CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)
                        context.fill(Path(ellipseIn: dot.insetBy(dx: -2, dy: -2)), with: .color(Color.accentColor.opacity(alpha * 0.16)))
                        context.fill(Path(ellipseIn: dot), with: .color(Color.accentColor.opacity(alpha)))
                        if index.isMultiple(of: 4) {
                            context.fill(Path(ellipseIn: dot.insetBy(dx: radius * 0.45, dy: radius * 0.45)), with: .color(.white.opacity(alpha * 0.75)))
                        }
                    }
                    if ambience == "fire" {
                        drawFlames(in: &context, size: size, time: phase / 0.45)
                    }
                    }
                }
            }
                .mask(alignment: .bottom) {
                    LinearGradient(colors: [.clear, .white], startPoint: .top, endPoint: .bottom)
                        .frame(height: 70 * verticalScale)
                }
        }.clipped().allowsHitTesting(false).accessibilityHidden(true)
    }

    private func drawRain(in context: inout GraphicsContext, size: CGSize, time: Double) {
        for index in 0..<52 {
            let n = Double(index)
            let life = (time * (0.45 + Double(index % 4) * 0.09) + n * 0.618).truncatingRemainder(dividingBy: 1)
            let x = size.width * (n * 0.61803398875).truncatingRemainder(dividingBy: 1)
            let y = size.height - 60 + life * 60
            var drop = Path()
            drop.move(to: CGPoint(x: x + 2, y: y - 6))
            drop.addLine(to: CGPoint(x: x, y: y))
            context.stroke(drop, with: .color(Color.accentColor.opacity(0.65)), style: StrokeStyle(lineWidth: 1.1, lineCap: .round))
            if life > 0.8 {
                let ripple = (life - 0.8) * 5
                let rect = CGRect(x: x - ripple * 9, y: size.height - 3 - ripple * 2, width: ripple * 18, height: ripple * 4)
                context.stroke(Path(ellipseIn: rect), with: .color(Color.accentColor.opacity((1 - ripple) * 0.6)), lineWidth: 0.8)
            }
        }
    }

    private func drawOcean(in context: inout GraphicsContext, size: CGSize, time: Double) {
        for layer in 0..<4 {
            let n = Double(layer)
            var wave = Path()
            for step in 0...80 {
                let x = size.width * Double(step) / 80
                let swell = sin(x / 68 - time * 0.8 + n * 0.8) * (5 + n * 1.5)
                let point = CGPoint(x: x, y: size.height - 7 - n * 7 + swell)
                if step == 0 { wave.move(to: point) } else { wave.addLine(to: point) }
            }
            context.stroke(wave, with: .color(Color.accentColor.opacity(0.65 - n * 0.1)), style: StrokeStyle(lineWidth: 2.3 - n * 0.3, lineCap: .round))
        }
    }

    private func drawClock(in context: inout GraphicsContext, size: CGSize, time: Double) {
        let angle = sin(time * 2 * .pi) * 0.55
        let pivot = CGPoint(x: size.width / 2, y: size.height - 42)
        let bob = CGPoint(x: pivot.x + sin(angle) * 31, y: pivot.y + cos(angle) * 31)
        var rod = Path()
        rod.move(to: pivot); rod.addLine(to: bob)
        context.stroke(rod, with: .color(Color.accentColor.opacity(0.65)), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
        context.fill(Path(ellipseIn: CGRect(x: bob.x - 4, y: bob.y - 4, width: 8, height: 8)), with: .color(Color.accentColor.opacity(0.85)))
        for side in [-1.0, 1.0] {
            let pulse = pow(max(0, side * sin(time * 2 * .pi)), 8)
            let rect = CGRect(x: pivot.x + side * 48 - 3, y: size.height - 17, width: 6, height: 6)
            context.fill(Path(ellipseIn: rect), with: .color(Color.accentColor.opacity(0.15 + pulse * 0.65)))
        }
    }

    private func drawFlames(in context: inout GraphicsContext, size: CGSize, time: Double) {
        for index in 0..<18 {
            let n = Double(index)
            let x = size.width * (n + 0.5) / 18
            let height = 12 + 14 * (0.5 + 0.5 * sin(time * 2.1 + n * 2.3))
            var flame = Path()
            flame.move(to: CGPoint(x: x - 8, y: size.height + 2))
            flame.addQuadCurve(to: CGPoint(x: x + sin(time * 1.8 + n) * 5, y: size.height - height), control: CGPoint(x: x - 7, y: size.height - height * 0.55))
            flame.addQuadCurve(to: CGPoint(x: x + 8, y: size.height + 2), control: CGPoint(x: x + 5, y: size.height - height * 0.4))
            flame.closeSubpath()
            context.fill(flame, with: .linearGradient(Gradient(colors: [Color.accentColor.opacity(0), Color.accentColor.opacity(0.65)]), startPoint: CGPoint(x: x, y: size.height - height), endPoint: CGPoint(x: x, y: size.height)))
        }
    }
}
