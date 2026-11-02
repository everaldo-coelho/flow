import SwiftUI


@MainActor private enum VictoryFrames {
    static var cache: [String: [LampImage]] = [:]

    static func frames(for animal: FlowAssistant) -> [LampImage] {
        let name = animal.animal == .cat ? "juno-bow-v1" : animal.picture.replacingOccurrences(of: ".png", with: "-celebration-24.png")
        if let ready = cache[name] { return ready }
        var result = CompanionFrames.frames(for: animal, celebration: true)
        guard result.count == 24 else { return [] }
        if animal.animal == .cat {
            let size = CGSize(width: result.map { $0.size.width }.max() ?? 1,
                              height: result.map { $0.size.height }.max() ?? 1)
            result = result.map { frame in
                FlowRaster.canvas(size: size) { context in
                    if let cg = FlowRaster.cgImage(frame) {
                        context.draw(cg, in: CGRect(x: (size.width - frame.size.width) / 2,
                            y: (size.height - frame.size.height) * 0.15,
                            width: frame.size.width, height: frame.size.height))
                    }
                }
            }
        }
        cache[name] = result
        return result
    }
}

/// Achievements has its own celebratory pose; other portraits keep their usual gestures.
struct VictoryPortrait: View {
    var still = false
    @ObservedObject private var preferences = FlowPreferences.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var phase
    @State private var frameIndex = 0
    @State private var request = UUID()
    @State private var preparedFrames: [LampImage] = []

    private var animal: FlowAssistant { preferences.assistant.animal }

    var body: some View {
        Button { request = UUID() } label: {
            Group {
                if let image = currentImage {
                    Image(flowImage: image).resizable().scaledToFit()
                        .scaleEffect(x: -1, y: 1)
                }
            }
            .padding(10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(FlowL.text("Achievements") + ": " + animal.displayName)
        .task(id: "\(request)-\(animal.picture)-\(still)-\(reduceMotion)-\(phase)") {
            frameIndex = 0
            _ = await CompanionFrames.prepare(for: animal, celebration: true)
            guard !Task.isCancelled else { return }
            preparedFrames = VictoryFrames.frames(for: animal)
            guard !still, !reduceMotion, phase == .active else { return }
            guard preparedFrames.count == 24 else { return }
            do {
                let start = ContinuousClock.now
                for index in 0..<24 {
                    try Task.checkCancellation()
                    frameIndex = index
                    try await ContinuousClock().sleep(until: start + .milliseconds((index + 1) * 83))
                }
                frameIndex = 0
            } catch { frameIndex = 0 }
        }
    }

    private var currentImage: LampImage? {
        let frames = preparedFrames
        return frames.indices.contains(frameIndex) ? frames[frameIndex] : LampAssets.image(animal.picture)
    }
}
