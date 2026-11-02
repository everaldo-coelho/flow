import SwiftUI
import AVFoundation
import Speech
import NaturalLanguage
import UniformTypeIdentifiers

struct CaptureFailure: LocalizedError {
    let message: String
    init(_ message: String) { self.message = message }
    var errorDescription: String? { message }
}
struct CaptureReading {
    var text: String
    var images: [LampImage] = []
    var warning: String?
}

@MainActor enum CaptureReader {
    static func read(_ url: URL, language: String, progress: @escaping (String) -> Void) async throws -> CaptureReading {
        let type = (try? url.resourceValues(forKeys: [.contentTypeKey]).contentType) ?? UTType(filenameExtension: url.pathExtension) ?? .data
        if type.conforms(to: .audio) || type.conforms(to: .movie) || type.conforms(to: .video) {
            return try await media(url, language: language, progress: progress)
        }
        if url.pathExtension.lowercased() == "webloc", let data = try? Data(contentsOf: url),
           let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
           let value = plist["URL"] as? String, let link = URL(string: value) { return try await web(link) }
        if ["eml", "emlx"].contains(url.pathExtension.lowercased()) {
            let data = try Data(contentsOf: url)
            let raw = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) ?? ""
            return bounded(CaptureReading(text: MailCaptureText.decode(raw), warning: "Email text only. Embedded attachments aren’t analysed; drop them separately."))
        }
        progress("Reading text and pictures…")
        let text = await LampText.read(url)
        var images: [LampImage] = []
        if type.conforms(to: .image), let image = (try? Data(contentsOf: url)).flatMap { LampImage(data: $0) } { images = [thumbnail(image)] }
        return bounded(CaptureReading(text: text, images: images))
    }
    static func bounded(_ reading: CaptureReading) -> CaptureReading {
        var result = reading
        if result.text.count > 120000 {
            result.text = String(result.text.prefix(120000))
            result.warning = [result.warning, "Only the first 120,000 characters were analysed. The full original is kept."].compactMap { $0 }.joined(separator: "\n")
        }
        return result
    }
    static func thumbnail(_ image: LampImage) -> LampImage {
        let scale = min(1, 1600 / max(image.size.width, image.size.height, 1))
        let size = CGSize(width: max(1, image.size.width * scale), height: max(1, image.size.height * scale))
        return FlowRaster.canvas(size: size) { context in
            if let cg = FlowRaster.cgImage(image) { context.draw(cg, in: CGRect(origin: .zero, size: size)) }
        }
    }
    static func web(_ url: URL) async throws -> CaptureReading {
        guard ["https", "http"].contains(url.scheme?.lowercased() ?? "") else { throw CaptureFailure("Paste the page text for this kind of link.") }
        var request = URLRequest(url: url, timeoutInterval: 40)
        request.setValue("text/html,text/plain,application/pdf,image/*", forHTTPHeaderField: "Accept")
        let (bytes, response) = try await URLSession.shared.bytes(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else { throw CaptureFailure("That page couldn’t be opened. Paste its text or drop an exported copy; signed-in pages may need this.") }
        var data = Data()
        for try await byte in bytes {
            guard data.count < 8_000_000 else { throw CaptureFailure("This download is too large to read as a link. Download it and drop the file here.") }
            data.append(byte)
        }
        let mime = response.mimeType ?? "text/plain"
        if mime.contains("html") {
            let document = try NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil)
            return bounded(CaptureReading(text: "Page: \(url.absoluteString)\n" + document.string, warning: "Public page text only. Content loaded after sign-in or by scripts may be missing."))
        }
        if mime.hasPrefix("text/") || mime.contains("json") {
            return bounded(CaptureReading(text: String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) ?? ""))
        }
        let ext = UTType(mimeType: mime)?.preferredFilenameExtension ?? "data"
        try FileManager.default.createDirectory(at: RichCaptureModel.folder, withIntermediateDirectories: true)
        let temporary = RichCaptureModel.folder.appendingPathComponent("web-\(UUID().uuidString).\(ext)")
        try data.write(to: temporary)
        defer { try? FileManager.default.removeItem(at: temporary) }
        return try await read(temporary, language: "en-US", progress: { _ in })
    }
    static func detectSpeech(in asset: AVAsset, duration: Double) async throws -> SFSpeechRecognizer {
        guard let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
            throw CaptureFailure("This recording cannot be read. Try an M4A recording or a transcript.")
        }
        let sample = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".m4a")
        defer { try? FileManager.default.removeItem(at: sample) }
        exporter.outputURL = sample; exporter.outputFileType = .m4a
        exporter.timeRange = CMTimeRange(start: .zero, duration: CMTime(seconds: min(10, duration), preferredTimescale: 600))
        await withTaskCancellationHandler { await exporter.export() } onCancel: { exporter.cancelExport() }
        try Task.checkCancellation()
        guard exporter.status == .completed else { throw CaptureFailure("Could not read a speech sample.") }
        // Compare locally recognised samples against their detected text language.
        let candidates = Array(Set(Locale.preferredLanguages + ["en-US", "pt-BR", "es-ES", "fr-FR", "de-DE", "it-IT", "ja-JP", "zh-CN"]))
        var best: (SFSpeechRecognizer, Double)?
        for identifier in candidates.sorted() {
            try Task.checkCancellation()
            guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: identifier)), recognizer.isAvailable, recognizer.supportsOnDeviceRecognition else { continue }
            let job = CaptureSpeechJob()
            do {
                let text = try await job.transcribe(sample, recognizer: recognizer)
                guard !text.isEmpty else { continue }
                let detector = NLLanguageRecognizer()
                detector.processString(text)
                let code = String(identifier.prefix(2))
                let probability = detector.languageHypotheses(withMaximum: 10).first { $0.key.rawValue == code }?.value ?? 0
                let score = probability * Double(job.confidence)
                if score > (best?.1 ?? 0) { best = (recognizer, score) }
            } catch { try Task.checkCancellation() }
        }
        guard let best, best.1 > 0.12 else {
            throw CaptureFailure("The spoken language could not be detected confidently with installed offline speech support. Add a transcript instead.")
        }
        return best.0
    }
    static func media(_ url: URL, language: String, progress: @escaping (String) -> Void) async throws -> CaptureReading {
        let asset = AVURLAsset(url: url)
        let duration = try await asset.load(.duration).seconds
        guard duration.isFinite, duration > 0 else { throw CaptureFailure("This recording couldn’t be read. Try exporting it as M4A or MP4.") }
        let audio = try await asset.loadTracks(withMediaType: .audio)
        let video = try await asset.loadTracks(withMediaType: .video)
        var result = CaptureReading(text: "")
        var warnings: [String] = []
        if !video.isEmpty {
            progress("Looking at a few moments from the video…")
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            generator.maximumSize = CGSize(width: 1200, height: 1200)
            let count = min(8, max(1, Int(ceil(duration / 15))))
            var timestamps: [String] = []
            for i in 0..<count {
                try Task.checkCancellation()
                let time = duration * (Double(i) + 0.5) / Double(count)
                if let frame = try? await generator.image(at: CMTime(seconds: time, preferredTimescale: 600)) {
                    result.images.append(FlowRaster.image(frame.image))
                    timestamps.append(String(format: "%.1f seconds", time))
                }
            }
            result.text = "Video frame samples in order: \(timestamps.joined(separator: ", ")).\n"
            warnings.append("Video visuals are sampled at up to eight moments; unsampled visual tasks can be missed.")
        }
        if !audio.isEmpty {
            do {
                let permission = await withCheckedContinuation { continuation in
                    SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0) }
                }
                guard permission == .authorized else { throw CaptureFailure("Speech recognition wasn’t allowed. Add a transcript to find spoken tasks.") }
                progress("Detecting spoken language on this device…")
                let recognizer = try await detectSpeech(in: asset, duration: duration)
                warnings.append("Automatically detected speech: \(recognizer.locale.localizedString(forIdentifier: recognizer.locale.identifier) ?? recognizer.locale.identifier). Language detection can be uncertain; check the transcript.")
                let end = min(duration, 1200)
                if duration > end { warnings.append("Only the first 20 minutes of speech were transcribed. Split longer recordings to cover the rest.") }
                let chunks = Int(ceil(end / 45))
                for index in 0..<chunks {
                    try Task.checkCancellation()
                    progress("Listening locally · part \(index + 1) of \(chunks)")
                    let start = Double(index) * 45
                    guard let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else { throw CaptureFailure("The audio format can’t be transcribed. Export it as M4A and try again.") }
                    let file = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".m4a")
                    defer { try? FileManager.default.removeItem(at: file) }
                    exporter.outputURL = file; exporter.outputFileType = .m4a
                    exporter.timeRange = CMTimeRange(start: CMTime(seconds: start, preferredTimescale: 600), duration: CMTime(seconds: min(45, end - start), preferredTimescale: 600))
                    await withTaskCancellationHandler {
                        await exporter.export()
                    } onCancel: { exporter.cancelExport() }
                    try Task.checkCancellation()
                    guard exporter.status == .completed else { throw CaptureFailure(exporter.error?.localizedDescription ?? "Couldn’t read this audio segment.") }
                    do {
                        let transcript = try await CaptureSpeechJob().transcribe(file, recognizer: recognizer)
                        result.text += "\n[Speech at \(Int(start)) seconds]\n\(transcript)\n"
                    } catch {
                        try Task.checkCancellation()
                        warnings.append("Speech at \(Int(start))–\(Int(min(start + 45, end))) seconds wasn’t readable: \(error.localizedDescription)") }
                }
                warnings.append("Speech was transcribed on this device. Check quoted words before keeping tasks.")
            } catch { try Task.checkCancellation(); warnings.append(error.localizedDescription) }
        }
        result.warning = warnings.joined(separator: "\n")
        guard !result.images.isEmpty || result.text.contains("[Speech at") else { throw CaptureFailure(result.warning ?? "No readable speech or pictures were found.") }
        return bounded(result)
    }
}

@MainActor final class CaptureSpeechJob {
    private var task: SFSpeechRecognitionTask?
    private var timeout: Task<Void, Never>?
    private var continuation: CheckedContinuation<String, Error>?
    private var partial = ""
    private(set) var confidence: Float = 0
    func transcribe(_ url: URL, recognizer: SFSpeechRecognizer) async throws -> String {
        try Task.checkCancellation()
        return try await withTaskCancellationHandler {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            let request = SFSpeechURLRecognitionRequest(url: url)
            request.requiresOnDeviceRecognition = true
            request.shouldReportPartialResults = true
            task = recognizer.recognitionTask(with: request) { result, error in
                Task { @MainActor in
                    if let result { self.confidence = result.bestTranscription.segments.isEmpty ? 0 : result.bestTranscription.segments.map(\.confidence).reduce(0, +) / Float(result.bestTranscription.segments.count); self.partial = result.bestTranscription.formattedString; if result.isFinal { self.finish(.success(self.partial)); return } }
                    if let error { self.finish(.failure(error)) }
                }
            }
            timeout = Task {
                try? await Task.sleep(for: .seconds(65))
                guard !Task.isCancelled else { return }
                self.finish(.failure(CaptureFailure("Speech took too long. Try a shorter clip.")))
            }
        }
        } onCancel: { Task { @MainActor in self.finish(.failure(CancellationError())) } }
    }
    private func finish(_ result: Result<String, Error>) {
        guard let continuation else { return }
        self.continuation = nil; timeout?.cancel(); task?.cancel(); task = nil
        continuation.resume(with: result)
    }
}

enum MailCaptureText {
    static func decode(_ raw: String, depth: Int = 0) -> String {
        guard depth < 10 else { return "" }
        var text = raw.replacingOccurrences(of: "\r\n", with: "\n")
        if let newline = text.firstIndex(of: "\n"), Int(text[..<newline]) != nil { text = String(text[text.index(after: newline)...]) }
        guard let split = text.range(of: "\n\n") else { return text }
        let headers = String(text[..<split.lowerBound]).replacingOccurrences(of: "\n\t", with: " ").replacingOccurrences(of: "\n ", with: " ")
        let body = String(text[split.upperBound...])
        let lines = headers.components(separatedBy: "\n")
        func header(_ name: String) -> String { lines.first { $0.lowercased().hasPrefix(name.lowercased() + ":") }.map { String($0.dropFirst(name.count + 1)).trimmingCharacters(in: .whitespaces) } ?? "" }
        let type = header("Content-Type")
        if type.lowercased().contains("multipart/"), let range = type.range(of: "boundary=", options: .caseInsensitive) {
            let boundary = String(type[range.upperBound...]).components(separatedBy: ";")[0].trimmingCharacters(in: CharacterSet(charactersIn: " \""))
            if !boundary.isEmpty {
                let parts = body.components(separatedBy: "--" + boundary).dropFirst().filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("--") }
                return [headers, parts.map { decode($0.trimmingCharacters(in: .whitespacesAndNewlines), depth: depth + 1) }.joined(separator: "\n")].joined(separator: "\n")
            }
        }
        if header("Content-Disposition").lowercased().contains("attachment") || (!type.isEmpty && !type.lowercased().hasPrefix("text/")) { return "" }
        var decoded = body
        if header("Content-Transfer-Encoding").lowercased() == "base64", let data = Data(base64Encoded: body, options: .ignoreUnknownCharacters) {
            decoded = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) ?? ""
        } else if header("Content-Transfer-Encoding").lowercased() == "quoted-printable" {
            let bytes = Array(body.replacingOccurrences(of: "=\n", with: "").utf8)
            var output: [UInt8] = []; var i = 0
            while i < bytes.count {
                if bytes[i] == 61, i + 2 < bytes.count, let value = UInt8(String(bytes: bytes[(i + 1)...(i + 2)], encoding: .ascii) ?? "", radix: 16) { output.append(value); i += 3 }
                else { output.append(bytes[i]); i += 1 }
            }
            decoded = String(bytes: output, encoding: .utf8) ?? String(bytes: output, encoding: .isoLatin1) ?? body
        }
        // Keep HTML email as source data; the AI can interpret the markup without executing it.
        return headers + "\n\n" + decoded
    }
}
