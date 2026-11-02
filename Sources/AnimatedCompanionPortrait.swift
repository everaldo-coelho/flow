import SwiftUI


@MainActor enum CompanionFrames {
    nonisolated private static let decodingQueue = DispatchQueue(label: "flow.character-decoding", qos: .utility)
    static var cache: [String: [LampImage]] = [:]
    static var motionCache: [String: [[LampImage]]] = [:]
    static var preparing: [String: Task<[LampImage], Never>] = [:]
    static func motion(for animal: FlowAssistant) async -> [[LampImage]] {
        let key = animal.picture
        if let cached = motionCache[key] { return cached }
        let originals = await prepare(for: animal)
        guard originals.count == 24 else { return [] }
        let sequences = (0..<4).map { row in
            ([originals[0]] + Array(originals[(row * 6)..<(row * 6 + 6)]) + [originals[0]])
                .flatMap { Array(repeating: $0, count: 3) }
        }
        motionCache[key] = sequences
        return sequences
    }
    private static func names(for animal: FlowAssistant, celebration: Bool) -> [(String, Int, Int)] {
        if celebration && animal.animal == .cat {
            return (1...4).map { ("juno-bow-\($0).png", 3, 2) }
        }
        return [(animal.picture.replacingOccurrences(of: ".png", with: celebration ? "-celebration-24.png" : "-animations.png"), 6, 4)]
    }
    static func frames(for animal: FlowAssistant, celebration: Bool = false) -> [LampImage] {
        names(for: animal, celebration: celebration).flatMap { cache[$0.0] ?? [] }
    }
    static func prepare(for animal: FlowAssistant, celebration: Bool = false) async -> [LampImage] {
        var result: [LampImage] = []
        for (name, columns, rows) in names(for: animal, celebration: celebration) {
            if let ready = cache[name] { result += ready; continue }
            let worker: Task<[LampImage], Never>
            if let pending = preparing[name] { worker = pending }
            else {
                worker = Task.detached(priority: .utility) {
                    await withCheckedContinuation { continuation in
                        decodingQueue.async {
                            continuation.resume(returning: decodeAtlas(named: name, columns: columns, rows: rows))
                        }
                    }
                }
                preparing[name] = worker
            }
            let ready = await worker.value
            cache[name] = ready // Cache failures too; never retry decoding on every redraw.
            preparing[name] = nil
            result += ready
        }
        return result
    }

    nonisolated private static func decodeAtlas(named name: String, columns: Int, rows: Int) -> [LampImage] {
        guard let sheet = LampAssets.image(name),
              let cg = FlowRaster.cgImage(sheet) else { return [] }
        // Extract each isolated silhouette; never copy neighbouring artwork.
        let w = cg.width, h = cg.height
        var pixels = [UInt8](repeating: 0, count: w * h * 4)
        guard let context = CGContext(data: &pixels, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return [] }
        context.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
        var visited = [Bool](repeating: false, count: w * h)
        var objects: [(rect: CGRect, points: [Int])] = []
        for seed in 0..<(w * h) where !visited[seed] && pixels[seed * 4 + 3] > 8 {
            var queue = [seed], cursor = 0
            visited[seed] = true
            var left = seed % w, right = left, top = seed / w, bottom = top
            while cursor < queue.count {
                let p = queue[cursor]; cursor += 1
                let x = p % w, y = p / w
                left = min(left, x); right = max(right, x)
                top = min(top, y); bottom = max(bottom, y)
                for (nx, ny) in [(x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)] {
                    guard nx >= 0, nx < w, ny >= 0, ny < h else { continue }
                    let next = ny * w + nx
                    if !visited[next] && pixels[next * 4 + 3] > 8 {
                        visited[next] = true; queue.append(next)
                    }
                }
            }
            if queue.count > 100 && bottom - top > h / 9 && right - left > w / 18 {
                objects.append((CGRect(x: left, y: top, width: right - left + 1, height: bottom - top + 1), queue))
            }
        }
        let silhouettes = objects
        guard silhouettes.count == columns * rows else {
            print("Character atlas could not isolate all silhouettes: " + name)
            return []
        }
        let vertical = silhouettes.sorted { $0.rect.midY < $1.rect.midY }
        var cropped: [CGImage] = []
        var anchors: [CGFloat] = []
        for row in 0..<rows {
            let ordered = vertical[(row * columns)..<(row * columns + columns)].sorted(by: { $0.rect.midX < $1.rect.midX })
            func complete(_ rect: CGRect) -> Bool {
                if (name.contains("celebration") && !name.hasPrefix("cockatiel-")) || name.hasPrefix("juno-bow-") { return true }
                return rect.minX > 1 && rect.minY > 1 && rect.maxX < CGFloat(w - 1) && rect.maxY < CGFloat(h - 1)
            }
            let safe = ordered.filter { complete($0.rect) }
            guard !safe.isEmpty else { return [] }
            for (column, candidate) in ordered.enumerated() {
                // Artwork touching the atlas boundary is already clipped in the
                // source. Padding cannot restore it: use the nearest intact pose.
                let object = complete(candidate.rect) ? candidate : safe.min {
                    abs($0.rect.midX - candidate.rect.midX) < abs($1.rect.midX - candidate.rect.midX)
                } ?? ordered[column]
                let rect = object.rect
                let tw = Int(rect.width), th = Int(rect.height)
                var isolated = [UInt8](repeating: 0, count: tw * th * 4)
                var feetX: Double = 0, feetCount: Double = 0
                for point in object.points {
                    let x = point % w - Int(rect.minX), y = point / w - Int(rect.minY)
                    for channel in 0..<4 { isolated[(y * tw + x) * 4 + channel] = pixels[point * 4 + channel] }
                    if y > th * 4 / 5 { feetX += Double(x); feetCount += 1 }
                }
                guard let provider = CGDataProvider(data: Data(isolated) as CFData),
                      let tile = CGImage(width: tw, height: th, bitsPerComponent: 8, bitsPerPixel: 32,
                        bytesPerRow: tw * 4, space: CGColorSpaceCreateDeviceRGB(),
                        bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                        provider: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent) else { return [] }
                cropped.append(tile)
                anchors.append(feetCount > 0 ? CGFloat(feetX / feetCount) : CGFloat(tw) / 2)
            }
        }
        let extent = cropped.enumerated().map { index, tile in
            max(anchors[index], CGFloat(tile.width) - anchors[index])
        }.max() ?? 1
        let canvasW = extent * 2.4
        let canvasH = CGFloat(cropped.map(\.height).max() ?? 1) * 1.45
        let renderScale = min(1, 384 / max(canvasW, canvasH))
        let frames = cropped.enumerated().map { index, tile in
            let size = CGSize(width: canvasW * renderScale, height: canvasH * renderScale)
            return FlowRaster.canvas(size: size) { context in
                context.scaleBy(x: renderScale, y: renderScale)
                context.draw(tile, in: CGRect(x: canvasW / 2 - anchors[index], y: canvasH * 0.15,
                    width: CGFloat(tile.width), height: CGFloat(tile.height)))
            }
        }
        guard frames.count == columns * rows else { return [] }
        return frames
    }
}

// Settings portraits blink occasionally and respond immediately to selection.
// Row zero of the existing atlas is the blink; other portraits keep all four actions.
struct ClickBlinkPortrait: View {
    let animal: FlowAssistant
    let trigger: UUID?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var phase
    @State private var playingImage: LampImage?
    @State private var lastPlayed: UUID?
    var body: some View {
        Canvas { context, size in
            if let image = playingImage ?? CompanionFrames.frames(for: animal).first ?? LampAssets.image(animal.picture) {
                let scale = min(size.width / image.size.width, size.height / image.size.height)
                let width = image.size.width * scale, height = image.size.height * scale
                context.draw(Image(flowImage: image), in: CGRect(x: (size.width - width) / 2, y: (size.height - height) / 2, width: width, height: height))
            }
        }.accessibilityHidden(true)
            .task(id: "\(trigger?.uuidString ?? "idle")-\(reduceMotion)-\(phase)") {
                playingImage = nil
                guard !reduceMotion, phase == .active else { return }
                let sequences = await CompanionFrames.motion(for: animal)
                guard !Task.isCancelled, let blink = sequences.first else { return }
                do {
                    if trigger == nil { try await Task.sleep(for: .seconds(Double.random(in: 4...8))) }
                    while !Task.isCancelled {
                    let start = ContinuousClock.now
                    for (index, frame) in blink.enumerated() {
                        try Task.checkCancellation()
                        playingImage = frame
                        try await ContinuousClock().sleep(until: start + .milliseconds((index + 1) * 33))
                    }
                    playingImage = nil
                    try await Task.sleep(for: .seconds(Double.random(in: 4...8)))
                    }
                } catch { playingImage = nil }
            }
    }
}

struct AnimatedCompanionPortrait: View {
    let animal: FlowAssistant
    var still = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var phase
    @State private var request = UUID()
    @State private var remaining: [Int] = []
    @State private var requestedRow = 0
    @State private var motion: [[LampImage]] = []
    @State private var playingImage: LampImage?
    private var lifecycle: String { "\(animal.picture)-\(reduceMotion)-\(still)-\(phase)" }

    var body: some View {
        Button {
            if remaining.isEmpty { remaining = Array(1..<4).shuffled() }
            requestedRow = remaining.removeFirst()
            request = UUID()
        } label: {
                Canvas { context, size in
                    let frames = CompanionFrames.frames(for: animal)
                    if let image = playingImage, !reduceMotion, !still {
                        draw(image, in: &context, size: size)
                    } else if let idle = frames.first {
                        draw(idle, in: &context, size: size)
                    } else if let image = LampAssets.image(animal.picture) {
                        draw(image, in: &context, size: size)
                    }
                }
                .contentShape(Rectangle())
        }.buttonStyle(.plain)
            .accessibilityLabel("Animate " + animal.displayName)
            .help("Play a little character animation")
            .task(id: lifecycle) {
                playingImage = nil
                motion = []
                remaining = []
                guard !reduceMotion, !still, phase == .active else { return }
                let generated = await CompanionFrames.motion(for: animal)
                guard !Task.isCancelled else { return }
                motion = generated
                requestedRow = 0
                request = UUID()
                do {
                    while !Task.isCancelled {
                        try await Task.sleep(for: .seconds(Double.random(in: 4...8)))
                        if phase == .active, playingImage == nil {
                            requestedRow = 0
                            request = UUID()
                        }
                    }
                } catch { }
            }
            .task(id: request) {
                guard !reduceMotion, !still, phase == .active, motion.count == 4 else { playingImage = nil; return }
                let row = requestedRow
                do {
                    let start = ContinuousClock.now
                    for (index, image) in motion[row].enumerated() {
                        try Task.checkCancellation()
                        playingImage = image
                        try await ContinuousClock().sleep(until: start + .milliseconds((index + 1) * 33))
                    }
                    playingImage = nil
                } catch { playingImage = nil }
            }
    }

    private func draw(_ image: LampImage, in context: inout GraphicsContext, size: CGSize) {
        let scale = min(size.width / image.size.width, size.height / image.size.height)
        let width = image.size.width * scale, height = image.size.height * scale
        context.draw(Image(flowImage: image), in: CGRect(x: (size.width - width) / 2,
            y: (size.height - height) / 2, width: width, height: height))
    }
}
