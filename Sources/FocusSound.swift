import SwiftUI
import AVFoundation

struct FocusSoundChoices: Codable {
    var muted = false
    var completion = true
    var ambience = "off"
    var volume: Double = 0.35
}

@MainActor final class FocusSound: ObservableObject {
    static let shared = FocusSound()
    @Published var choices = LampStore.load(FocusSoundChoices.self, from: "focusSounds") ?? FocusSoundChoices() {
        didSet {
            LampStore.save(choices, to: "focusSounds")
            if choices.muted { bell?.stop() }
            update(running: running)
        }
    }
    @Published private(set) var error = false
    private var running = false
    private var current = ""
    private var ambient: AVAudioPlayer?
    private var bell: AVAudioPlayer?
    private var cache: [String: Data] = [:]
    static let options = [("off", "Silence"), ("tick", "Clock"), ("rain", "Soft rain"), ("ocean", "Ocean"), ("fire", "Fireplace")]

    init() {
        if !Self.options.contains(where: { $0.0 == choices.ambience }) {
            choices.ambience = "off"
            LampStore.save(choices, to: "focusSounds")
        }
    }

    func update(running: Bool) {
        self.running = running
        let wanted = running && !choices.muted ? choices.ambience : "off"
        if current == wanted { ambient?.volume = Float(choices.volume); return }
        ambient?.stop(); ambient = nil; current = wanted
        guard wanted != "off" else { return }
        do {
            let player = try AVAudioPlayer(data: audio(wanted))
            player.numberOfLoops = -1
            player.volume = Float(choices.volume)
            guard player.play() else { error = true; return }
            ambient = player; error = false
        } catch { self.error = true; print("FLOW focus: ambient audio unavailable") }
    }

    func finished() {
        update(running: false)
        guard !choices.muted, choices.completion else { return }
        playBell()
    }

    func playBell() {
        guard !choices.muted else { return }
        do {
            bell = try AVAudioPlayer(data: audio("bell"))
            bell?.volume = Float(choices.volume)
            error = bell?.play() != true
        } catch { self.error = true; print("FLOW focus: completion audio unavailable") }
    }

    // Locally synthesised, band-limited textures: no recordings or network access.
    private func audio(_ kind: String) -> Data {
        let cacheKey = kind == "tick" ? "soft-mechanical-clock-v3" : (kind == "rain" ? "rain-window-thunder-v2" : kind)
        if let data = cache[cacheKey] { return data }
        let rate = 22050
        let duration = kind == "bell" ? 2 : (kind == "tick" ? 2 : (kind == "rain" ? 96 : 24))
        let thunderStarts = [Double.random(in: 12...23), Double.random(in: 41...54), Double.random(in: 74...84)]
        let count = rate * duration
        var samples = [Double](repeating: 0, count: count)
        var seed: UInt64 = 1234567
        var low = 0.0, slow = 0.0
        var dropAge = 1.0, dropPitch = 1600.0
        var crackle = 0.0, crackleBody = 0.0
        for i in 0..<count {
            let t = Double(i) / Double(rate)
            seed = seed &* 6364136223846793005 &+ 1
            let white = Double(seed >> 32) / Double(UInt32.max) * 2 - 1
            low = low * 0.97 + white * 0.03
            slow = slow * 0.997 + white * 0.003
            let edge = min(1, min(t / 0.04, (Double(duration) - t) / 0.04))
            let value: Double
            switch kind {
            case "bell":
                let a = sin(2 * .pi * 523.25 * t) * exp(-2.8 * t)
                let u = max(0, t - 0.32)
                let b = t > 0.32 ? sin(2 * .pi * 659.25 * u) * exp(-2.8 * u) : 0
                value = (a + b) * 0.3
            case "tick":
                // A pendulum's alternating tick/tock, with a wooden case and escapement rattle.
                let beat = Int(floor((t + 0.4) / 0.5))
                let phase = (t + 0.4).truncatingRemainder(dividingBy: 0.5)
                let tick = beat.isMultiple(of: 2)
                let pitch = tick ? 460.0 : 350.0
                let attack = min(1, phase / 0.0018)
                let click = (low * 2.4 + white * 0.12) * exp(-phase * 320) * 0.22
                let wood = sin(2 * .pi * pitch * phase) * exp(-phase * 180) * 0.10
                let caseResonance = sin(2 * .pi * pitch * 1.73 * phase) * exp(-phase * 240) * 0.04
                let latch = max(0, phase - 0.014)
                let mechanism = phase > 0.014 ? (low * 0.5 + white * 0.035) * exp(-latch * 280) : 0
                value = (click + wood + caseResonance + mechanism) * attack * 0.7
            case "ocean":
                // Three long, gentle swells, with foam brightening as each wave arrives.
                let swell = pow(0.5 - 0.5 * cos(2 * .pi * t / 8), 1.5)
                value = slow * 2.2 + low * (0.45 + 2.3 * swell) + (white - low) * 0.045 * swell
            case "fire":
                // Low flame movement with small, irregular wood crackles; no loud pops.
                if white > 0.9997 { crackle = 0.12; crackleBody = 0.08 }
                crackle *= 0.988
                crackleBody *= 0.998
                let flame = slow * 1.7 * (0.8 + 0.2 * sin(t * 0.7))
                let ember = white * crackle + low * crackleBody * 2
                value = flame + low * 0.6 + ember
            default:
                // Distant rolling thunder fades in gently above a continuous rain bed.
                var rumble = 0.0
                if kind == "rain" {
                    for start in thunderStarts {
                        let age = t - start
                        if age > 0, age < 8 {
                            let envelope = pow(sin(.pi * age / 8), 2) * exp(-age * 0.12)
                            let rolling = 0.75 + 0.25 * sin(age * 5.3)
                            rumble += (slow * 4 + low * 0.45) * envelope * rolling
                        }
                    }
                }
                // Sparse tiny impacts on glass, softly resonant rather than sharp clicks.
                if white > 0.99992 {
                    dropAge = 0
                    dropPitch = 1100 + Double(seed % 900)
                }
                dropAge += 1 / Double(rate)
                var droplet = 0.0
                if dropAge < 0.09 {
                    let envelope = min(1, dropAge / 0.0015) * exp(-dropAge * 95)
                    let glass = sin(2 * .pi * dropPitch * dropAge)
                    droplet = (glass * 0.065 + white * 0.025) * envelope
                }
                value = low * 1.35 + (white - low) * 0.075 + rumble + droplet
            }
            samples[i] = max(-0.9, min(0.9, value * edge))
        }
        // Overlap the tail into the head so ambient loops have no silent seam.
        if kind == "rain" || kind == "ocean" || kind == "fire" {
            let overlap = rate
            for i in 0..<overlap {
                let blend = Double(i) / Double(overlap)
                samples[i] = samples[count - overlap + i] * (1 - blend) + samples[i] * blend
            }
            samples.removeLast(overlap)
        }
        let byteCount = samples.count * 2
        var data = Data()
        func word<T: FixedWidthInteger>(_ number: T) {
            var little = number.littleEndian
            withUnsafeBytes(of: &little) { data.append(contentsOf: $0) }
        }
        data.append(contentsOf: "RIFF".utf8); word(UInt32(36 + byteCount))
        data.append(contentsOf: "WAVEfmt ".utf8); word(UInt32(16)); word(UInt16(1)); word(UInt16(1))
        word(UInt32(rate)); word(UInt32(rate * 2)); word(UInt16(2)); word(UInt16(16))
        data.append(contentsOf: "data".utf8); word(UInt32(byteCount))
        for sample in samples { word(Int16(sample * 32767)) }
        cache[cacheKey] = data
        return data
    }
}

struct FocusSoundSettings: View {
    @ObservedObject private var sound = FocusSound.shared
    @ObservedObject private var language = FlowLanguageSettings.shared
    private func soundName(_ name: String) -> String {
        if name == "Clock" { return language.code == "pt-BR" ? "Tique-taque" : language.code == "es" ? "Tictac" : "Tick-tock" }
        if name == "Ocean" { return language.code == "pt-BR" ? "Oceano" : language.code == "es" ? "Océano" : "Ocean" }
        if name == "Fireplace" { return language.code == "pt-BR" ? "Lareira" : language.code == "es" ? "Chimenea" : "Fireplace" }
        return FlowL.text(name)
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(FlowL.text("Focus sounds")).font(.headline)
            Toggle(FlowL.text("Mute focus sounds"), isOn: $sound.choices.muted)
            Group {
                Toggle(FlowL.text("Chime when time ends"), isOn: $sound.choices.completion)
                Picker(FlowL.text("During focus"), selection: $sound.choices.ambience) {
                    ForEach(FocusSound.options, id: \.0) { option in Text(soundName(option.1)).tag(option.0) }
                }
                HStack {
                    Text(FlowL.text("Volume"))
                    Slider(value: $sound.choices.volume, in: 0...1).accessibilityLabel(FlowL.text("Volume"))
                    Button(FlowL.text("Try chime")) { sound.playBell() }
                }
            }.disabled(sound.choices.muted)
            Text(FlowL.text("Choose what feels comfortable. Background sound stops when you pause or close focus.")).font(.flowCaption).foregroundStyle(.secondary)
            if sound.error { Text(FlowL.text("Sound could not play. Try selecting it again.")).font(.flowCaption).foregroundStyle(.secondary) }
        }
    }
}
