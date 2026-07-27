import SwiftUI

struct TextureCanvasView: View {
    let color: Color
    let grain: Double
    let opacity: Double
    let patternScale: Double
    let patternKind: PatternKind
    var patternAngle: Double = 0.35
    var patternDensity: Double = 0.55
    var patternThickness: Double = 0.45
    var cornerRadius: CGFloat = 18

    init(
        color: Color,
        grain: Double,
        opacity: Double,
        patternScale: Double,
        patternKind: PatternKind,
        patternAngle: Double = 0.35,
        patternDensity: Double = 0.55,
        patternThickness: Double = 0.45,
        cornerRadius: CGFloat = 18
    ) {
        self.color = color
        self.grain = grain
        self.opacity = opacity
        self.patternScale = patternScale
        self.patternKind = patternKind
        self.patternAngle = patternAngle
        self.patternDensity = patternDensity
        self.patternThickness = patternThickness
        self.cornerRadius = cornerRadius
    }

    init(item: TextureItem, cornerRadius: CGFloat = 18) {
        self.init(
            color: item.color,
            grain: item.grain,
            opacity: item.opacity,
            patternScale: item.patternScale,
            patternKind: item.patternKind,
            patternAngle: item.patternAngle,
            patternDensity: item.patternDensity,
            patternThickness: item.patternThickness,
            cornerRadius: cornerRadius
        )
    }

    var body: some View {
        Canvas { context, size in
            drawTexture(context: &context, size: size)
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .drawingGroup()
    }

    private func drawTexture(context: inout GraphicsContext, size: CGSize) {
        let base = color.opacity(opacity)
        context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(base))

        let scale = max(0.12, min(1.0, patternScale))
        let density = max(0.1, min(1.0, patternDensity))
        let thickness = max(0.1, min(1.0, patternThickness))
        let step = max(3.5, 20.0 * (1.15 - scale) * (1.35 - density * 0.7))
        let grainStrength = max(0, min(1, grain))
        let angle = patternAngle * (.pi / 2)

        switch patternKind {
        case .noise:
            drawNoise(context: &context, size: size, step: step, strength: grainStrength, thickness: thickness)
        case .dots:
            drawDots(context: &context, size: size, step: step, strength: grainStrength, thickness: thickness)
        case .lines:
            drawLines(context: &context, size: size, step: step, strength: grainStrength, thickness: thickness, angle: angle)
        case .grid:
            drawGrid(context: &context, size: size, step: step, strength: grainStrength, thickness: thickness)
        case .weave:
            drawWeave(context: &context, size: size, step: step, strength: grainStrength, thickness: thickness)
        case .crosshatch:
            drawCrosshatch(context: &context, size: size, step: step, strength: grainStrength, thickness: thickness, angle: angle)
        }

        if grainStrength > 0.05 {
            drawFineGrain(context: &context, size: size, strength: grainStrength)
        }

        let overlay = Gradient(colors: [
            Color.white.opacity(0.18 * opacity),
            Color.clear,
            Color.black.opacity(0.22 * opacity)
        ])
        context.fill(
            Path(CGRect(origin: .zero, size: size)),
            with: .linearGradient(overlay, startPoint: .zero, endPoint: CGPoint(x: size.width, y: size.height))
        )
    }

    private func seededOpacity(_ x: Int, _ y: Int, base: Double) -> Double {
        let hash = (x * 73856093) ^ (y * 19349663)
        let unit = Double(abs(hash % 1000)) / 1000.0
        return base * (0.35 + unit * 0.65)
    }

    private func drawNoise(context: inout GraphicsContext, size: CGSize, step: Double, strength: Double, thickness: Double) {
        var x = 0.0
        while x < size.width {
            var y = 0.0
            while y < size.height {
                let ix = Int(x / step)
                let iy = Int(y / step)
                let alpha = seededOpacity(ix, iy, base: 0.35 * strength)
                let cell = step * (0.55 + thickness * 0.45)
                let rect = CGRect(x: x, y: y, width: cell, height: cell)
                context.fill(Path(ellipseIn: rect), with: .color(Color.white.opacity(alpha)))
                y += step
            }
            x += step
        }
    }

    private func drawDots(context: inout GraphicsContext, size: CGSize, step: Double, strength: Double, thickness: Double) {
        let radius = step * (0.16 + thickness * 0.22)
        var x = step / 2
        while x < size.width {
            var y = step / 2
            while y < size.height {
                let alpha = 0.25 + 0.45 * strength
                let rect = CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)
                context.fill(Path(ellipseIn: rect), with: .color(Color.black.opacity(alpha * 0.55)))
                context.fill(Path(ellipseIn: rect.insetBy(dx: radius * 0.25, dy: radius * 0.25)), with: .color(Color.white.opacity(alpha * 0.35)))
                y += step
            }
            x += step
        }
    }

    private func drawLines(context: inout GraphicsContext, size: CGSize, step: Double, strength: Double, thickness: Double, angle: Double) {
        let alpha = 0.18 + 0.4 * strength
        let width = max(1, step * (0.08 + thickness * 0.18))
        let cosA = cos(angle)
        let sinA = sin(angle)
        let diag = hypot(size.width, size.height)
        var offset = -diag
        while offset < diag {
            var path = Path()
            let x0 = offset * cosA - (-diag) * sinA + size.width / 2
            let y0 = offset * sinA + (-diag) * cosA + size.height / 2
            let x1 = offset * cosA - diag * sinA + size.width / 2
            let y1 = offset * sinA + diag * cosA + size.height / 2
            path.move(to: CGPoint(x: x0, y: y0))
            path.addLine(to: CGPoint(x: x1, y: y1))
            context.stroke(path, with: .color(Color.white.opacity(alpha)), lineWidth: width)
            offset += step
        }
    }

    private func drawGrid(context: inout GraphicsContext, size: CGSize, step: Double, strength: Double, thickness: Double) {
        let alpha = 0.16 + 0.35 * strength
        let width = max(1, 0.7 + thickness * 1.6)
        var x = 0.0
        while x < size.width {
            var path = Path()
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: size.height))
            context.stroke(path, with: .color(Color.black.opacity(alpha)), lineWidth: width)
            x += step
        }
        var y = 0.0
        while y < size.height {
            var path = Path()
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: size.width, y: y))
            context.stroke(path, with: .color(Color.white.opacity(alpha * 0.8)), lineWidth: width)
            y += step
        }
    }

    private func drawWeave(context: inout GraphicsContext, size: CGSize, step: Double, strength: Double, thickness: Double) {
        let alpha = 0.2 + 0.4 * strength
        var row = 0
        var y = 0.0
        let cellH = step * (0.35 + thickness * 0.25)
        while y < size.height {
            var x = row % 2 == 0 ? 0.0 : step / 2
            while x < size.width {
                let rect = CGRect(x: x, y: y, width: step * 0.85, height: cellH)
                context.fill(Path(roundedRect: rect, cornerRadius: 2), with: .color(Color.white.opacity(alpha * 0.55)))
                x += step
            }
            y += step * 0.55
            row += 1
        }
    }

    private func drawCrosshatch(context: inout GraphicsContext, size: CGSize, step: Double, strength: Double, thickness: Double, angle: Double) {
        let alpha = 0.14 + 0.35 * strength
        let width = max(1, 0.8 + thickness * 1.4)
        drawLines(context: &context, size: size, step: step, strength: strength, thickness: thickness, angle: angle)
        drawLines(context: &context, size: size, step: step, strength: strength * 0.85, thickness: thickness * 0.9, angle: angle + .pi / 2)
        _ = alpha
        _ = width
    }

    private func drawFineGrain(context: inout GraphicsContext, size: CGSize, strength: Double) {
        let count = Int(40 + strength * 90)
        for i in 0..<count {
            let hx = abs((i * 2654435761) % 997)
            let hy = abs((i * 2246822519) % 991)
            let x = Double(hx) / 997.0 * size.width
            let y = Double(hy) / 991.0 * size.height
            let rect = CGRect(x: x, y: y, width: 1.2, height: 1.2)
            context.fill(Path(ellipseIn: rect), with: .color(Color.white.opacity(0.12 * strength)))
        }
    }
}

struct TextureThumbnail: View {
    let item: TextureItem
    var size: CGFloat = 72

    var body: some View {
        TextureCanvasView(item: item, cornerRadius: 12)
            .frame(width: size, height: size)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color("AppAccent").opacity(0.35), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.3), radius: 6, y: 3)
    }
}

struct FullscreenTexturePreview: View {
    let item: TextureItem
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()
            TextureCanvasView(item: item, cornerRadius: 0)
                .scaleEffect(scale)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            scale = min(4, max(1, lastScale * value))
                        }
                        .onEnded { _ in
                            lastScale = scale
                        }
                )
                .onTapGesture(count: 2) {
                    withAnimation(.easeOut(duration: 0.2)) {
                        scale = 1
                        lastScale = 1
                    }
                }
                .ignoresSafeArea()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(20)
            }
        }
    }
}
