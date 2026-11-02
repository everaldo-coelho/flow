import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

extension Color {
    static var flowInputBackground: Color {
        #if os(macOS)
        Color(nsColor: .textBackgroundColor)
        #else
        Color(uiColor: .secondarySystemBackground)
        #endif
    }
    static var flowWindowBackground: Color {
        #if os(macOS)
        Color(nsColor: .windowBackgroundColor)
        #else
        Color(uiColor: .systemBackground)
        #endif
    }
    static func flowAdaptive(light: (Double, Double, Double), dark: (Double, Double, Double)) -> Color {
        #if os(macOS)
        return Color(nsColor: NSColor(name: nil) { appearance in
            let rgb = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? dark : light
            return NSColor(srgbRed: rgb.0, green: rgb.1, blue: rgb.2, alpha: 1)
        })
        #else
        return Color(uiColor: UIColor { traits in
            let rgb = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: rgb.0, green: rgb.1, blue: rgb.2, alpha: 1)
        })
        #endif
    }
}

extension Image {
    init(flowImage: LampImage) {
        #if os(macOS)
        self.init(nsImage: flowImage)
        #else
        self.init(uiImage: flowImage)
        #endif
    }
}

enum FlowRaster {
    static func cgImage(_ image: LampImage) -> CGImage? {
        #if os(macOS)
        return image.cgImage(forProposedRect: nil, context: nil, hints: nil)
        #else
        return image.cgImage
        #endif
    }
    static func image(_ cg: CGImage, size: CGSize? = nil) -> LampImage {
        #if os(macOS)
        return NSImage(cgImage: cg, size: size ?? .zero)
        #else
        return UIImage(cgImage: cg)
        #endif
    }
    static func canvas(size: CGSize, draw: (CGContext) -> Void) -> LampImage {
        let width = max(1, Int(ceil(size.width))), height = max(1, Int(ceil(size.height)))
        let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8,
            bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        draw(context)
        return image(context.makeImage()!, size: size)
    }
}

extension View {
    @ViewBuilder func flowSheetSize(width: CGFloat, minimumWidth: CGFloat? = nil, height: CGFloat, minimumHeight: CGFloat? = nil) -> some View {
        #if os(macOS)
        self.frame(minWidth: minimumWidth ?? width, idealWidth: width, maxWidth: .infinity,
                   minHeight: minimumHeight ?? height, idealHeight: height, maxHeight: .infinity)
        #else
        self.frame(maxWidth: .infinity, maxHeight: .infinity)
        #endif
    }
    @ViewBuilder func flowToolbarMaterial() -> some View {
        #if os(macOS)
        self.toolbarBackground(.ultraThinMaterial, for: .windowToolbar)
            .toolbarBackground(.visible, for: .windowToolbar)
        #else
        self
        #endif
    }
}
