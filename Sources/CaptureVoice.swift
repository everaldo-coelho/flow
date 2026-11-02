import SwiftUI
import AVFoundation

@MainActor final class CaptureVoice: ObservableObject {
    @Published var recording = false
    @Published var error = ""
    @Published var levels: [Float] = Array(repeating: 0, count: 48)
    @Published var elapsed: TimeInterval = 0
    private var meteringTask: Task<Void, Never>?
    private var recorder: AVAudioRecorder?
    private var url: URL?
    private var requestID = UUID()
    func begin() async {
        guard !recording else { return }
        error = ""
        let request = UUID(); requestID = request
        let allowed = await AVCaptureDevice.requestAccess(for: .audio)
        guard requestID == request else { return }
        guard allowed else {
            error = FlowSubtaskWords.text("Microphone access wasn’t allowed. You can type instead.", "O acesso ao microfone não foi permitido. Você pode digitar.", "No se permitió el micrófono. Puedes escribir.")
            return
        }
        do {
            #if os(iOS)
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetoothHFP])
            try AVAudioSession.sharedInstance().setActive(true)
            #endif
            let file = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".m4a")
            let recorder = try AVAudioRecorder(url: file, settings: [AVFormatIDKey: kAudioFormatMPEG4AAC, AVSampleRateKey: 44100, AVNumberOfChannelsKey: 1, AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue])
            recorder.isMeteringEnabled = true
            guard recorder.record() else { throw CaptureFailure("Couldn’t start recording.") }
            self.recorder = recorder; url = file; recording = true
            levels = Array(repeating: 0, count: 48); elapsed = 0
            meteringTask?.cancel()
            meteringTask = Task { [weak self] in
                while !Task.isCancelled {
                    guard let self, let recorder = self.recorder, self.recording else { return }
                    recorder.updateMeters()
                    let level = min(1, max(0, pow(10, recorder.averagePower(forChannel: 0) / 35)))
                    self.levels.removeFirst(); self.levels.append(level)
                    self.elapsed = recorder.currentTime
                    do { try await Task.sleep(for: .milliseconds(70)) } catch { return }
                }
            }
        } catch { self.error = error.localizedDescription }
    }
    func finishForTranscription() -> URL? {
        requestID = UUID()
        meteringTask?.cancel(); meteringTask = nil
        recorder?.stop(); recorder = nil; recording = false
        let finishedURL = url
        url = nil
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        #endif
        return finishedURL
    }
    func finish(keep: Bool) {
        if let file = finishForTranscription() {
            if keep { RichCaptureModel.shared.addRecording(file) }
            try? FileManager.default.removeItem(at: file)
        }
    }
}

struct CaptureRecordingMeter: View {
    @ObservedObject var voice: CaptureVoice
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(FlowL.text("Recording…"), systemImage: "record.circle.fill").foregroundStyle(.red)
                Spacer()
                Text(String(format: "%02d:%02d", Int(voice.elapsed) / 60, Int(voice.elapsed) % 60))
                    .monospacedDigit().foregroundStyle(.secondary)
            }.font(.flowCallout)
            Canvas { context, size in
                let count = voice.levels.count
                let step = size.width / CGFloat(max(1, count))
                for (index, level) in voice.levels.enumerated() {
                    let height = max(3, CGFloat(level) * size.height)
                    let rect = CGRect(x: CGFloat(index) * step, y: (size.height - height) / 2, width: max(2, step * 0.55), height: height)
                    context.fill(Path(roundedRect: rect, cornerRadius: 2), with: .color(.accentColor))
                }
            }.frame(height: 50).accessibilityHidden(true)
        }.padding(14)
            .background(Color.accentColor.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
            .accessibilityElement(children: .combine)
    }
}

struct CaptureVoiceView: View {
    @StateObject private var voice = CaptureVoice()
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: voice.recording ? "waveform" : "mic").font(.largeTitle).foregroundStyle(Color.accentColor).accessibilityHidden(true)
            Text(FlowL.text("Speak freely. FLOW will suggest tasks from what you say.")).multilineTextAlignment(.center)
            Text(FlowL.text("The spoken language is detected automatically. The recording is removed after processing.")).font(.flowCaption).foregroundStyle(.secondary).multilineTextAlignment(.center)
            if voice.recording {
                Label(FlowL.text("Recording…"), systemImage: "record.circle").foregroundStyle(.red)
                Button(FlowL.text("Stop and find tasks")) { voice.finish(keep: true) }.buttonStyle(FlowGlassButtonStyle(prominent: true))
                Button(FlowL.text("Cancel")) { voice.finish(keep: false) }
            } else {
                Button(FlowL.text("Start recording")) { Task { await voice.begin() } }.buttonStyle(FlowGlassButtonStyle(prominent: true))
            }
            if !voice.error.isEmpty { Text(voice.error).font(.flowCaption).foregroundStyle(.secondary) }
        }.frame(maxWidth: .infinity).worldSurface()
            .onDisappear { voice.finish(keep: false) }
    }
}
