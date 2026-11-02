import Foundation
import CoreGraphics
import Vision
import CoreVideo

// Optical flow supplies actual intermediate positions, rather than showing two
// transparent portraits on top of each other. Work stays off the UI thread.
enum CompanionMotion {
    private struct Raster {
        let image: CGImage
        let bytes: [UInt8]
        let width: Int
        let height: Int
    }

    static func sequences(_ images: [LampImage]) -> [[LampImage]] {
        guard images.count == 24 else { return [] }
        let rasters = images.compactMap(raster)
        guard rasters.count == 24 else { return [] }
        return (0..<4).map { row in
            let indices = [0] + Array((row * 6)..<(row * 6 + 6)) + [0]
            var result: [LampImage] = []
            for pair in 0..<(indices.count - 1) {
                if Task.isCancelled { return [] }
                let a = rasters[indices[pair]], b = rasters[indices[pair + 1]]
                guard let forward = flow(a.image, b.image), let backward = flow(b.image, a.image) else {
                    // Never pretend duplicated holds are additional motion frames.
                    return []
                }
                for step in 0..<6 {
                    let t = Float(step) / 6
                    if let image = tween(a, b, forward: forward, backward: backward, t: t) {
                        result.append(image)
                    }
                }
            }
            result.append(images[0])
            return result
        }
    }

    private static func raster(_ image: LampImage) -> Raster? {
        let width = 160
        let height = max(1, Int(CGFloat(width) * image.size.height / image.size.width))
        var bytes = [UInt8](repeating: 0, count: width * height * 4)
        guard let cg = FlowRaster.cgImage(image),
              let context = CGContext(data: &bytes, width: width, height: height,
                bitsPerComponent: 8, bytesPerRow: width * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        context.interpolationQuality = .high
        context.draw(cg, in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let normalized = context.makeImage() else { return nil }
        return Raster(image: normalized, bytes: bytes, width: width, height: height)
    }

    private static func flow(_ source: CGImage, _ target: CGImage) -> [Float]? {
        let request = VNGenerateOpticalFlowRequest(targetedCGImage: target, options: [:])
        request.computationAccuracy = .high
        request.outputPixelFormat = kCVPixelFormatType_TwoComponent32Float
        do {
            try VNImageRequestHandler(cgImage: source, options: [:]).perform([request])
            guard let buffer = request.results?.first?.pixelBuffer else { return nil }
            CVPixelBufferLockBaseAddress(buffer, .readOnly)
            defer { CVPixelBufferUnlockBaseAddress(buffer, .readOnly) }
            guard let base = CVPixelBufferGetBaseAddress(buffer) else { return nil }
            let width = CVPixelBufferGetWidth(buffer), height = CVPixelBufferGetHeight(buffer)
            guard width == source.width, height == source.height else { return nil }
            let stride = CVPixelBufferGetBytesPerRow(buffer) / MemoryLayout<Float>.size
            let pointer = base.assumingMemoryBound(to: Float.self)
            var values = [Float](repeating: 0, count: width * height * 2)
            for y in 0..<height {
                for x in 0..<(width * 2) { values[y * width * 2 + x] = pointer[y * stride + x] }
            }
            return values
        } catch {
            print("Character intermediate motion unavailable: \(error.localizedDescription)")
            return nil
        }
    }

    private static func tween(_ a: Raster, _ b: Raster, forward: [Float], backward: [Float], t: Float) -> LampImage? {
        let w = a.width, h = a.height
        var output = [UInt8](repeating: 0, count: w * h * 4)
        func sample(_ raster: Raster, _ x: Float, _ y: Float, _ channel: Int) -> Float {
            guard x >= 0, y >= 0, x <= Float(w - 1), y <= Float(h - 1) else { return 0 }
            let ix = Int(x), iy = Int(y), nx = min(ix + 1, w - 1), ny = min(iy + 1, h - 1)
            let dx = x - Float(ix), dy = y - Float(iy)
            func value(_ px: Int, _ py: Int) -> Float { Float(raster.bytes[(py * w + px) * 4 + channel]) }
            return (value(ix, iy) * (1 - dx) + value(nx, iy) * dx) * (1 - dy)
                + (value(ix, ny) * (1 - dx) + value(nx, ny) * dx) * dy
        }
        func origin(_ x: Int, _ y: Int, _ field: [Float], _ amount: Float) -> (Float, Float) {
            var sx = Float(x), sy = Float(y)
            for _ in 0..<3 {
                let px = min(w - 1, max(0, Int(sx))), py = min(h - 1, max(0, Int(sy)))
                let i = (py * w + px) * 2
                let fx = field[i].isFinite ? field[i] : 0
                let fy = field[i + 1].isFinite ? field[i + 1] : 0
                sx = Float(x) - amount * fx
                sy = Float(y) - amount * fy
            }
            return (sx, sy)
        }
        for y in 0..<h {
            for x in 0..<w {
                let p = origin(x, y, forward, t), q = origin(x, y, backward, 1 - t)
                for channel in 0..<4 {
                    let value = sample(a, p.0, p.1, channel) * (1 - t) + sample(b, q.0, q.1, channel) * t
                    output[(y * w + x) * 4 + channel] = UInt8(max(0, min(255, value)))
                }
            }
        }
        guard let provider = CGDataProvider(data: Data(output) as CFData),
              let image = CGImage(width: w, height: h, bitsPerComponent: 8, bitsPerPixel: 32,
                bytesPerRow: w * 4, space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                provider: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent) else { return nil }
        return FlowRaster.image(image, size: CGSize(width: w, height: h))
    }
}
