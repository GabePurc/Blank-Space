import CoreGraphics
import Foundation
import Testing
@testable import BlankSpaceCore

/// Draws a synthetic image: a horizontal gradient with optional solid rectangles.
private func makeImage(width: Int, height: Int, rects: [(CGRect, CGColor)]) -> CGImage {
    let context = CGContext(
        data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
    )!
    // Gradient background: blue on the left, green on the right.
    for x in 0..<width {
        let t = CGFloat(x) / CGFloat(max(1, width - 1))
        context.setFillColor(CGColor(red: 0, green: t, blue: 1 - t, alpha: 1))
        context.fill(CGRect(x: x, y: 0, width: 1, height: height))
    }
    for (rect, color) in rects {
        context.setFillColor(color)
        // Convert from top-left origin to CoreGraphics' bottom-left origin.
        let flipped = CGRect(x: rect.minX, y: CGFloat(height) - rect.maxY, width: rect.width, height: rect.height)
        context.fill(flipped)
    }
    return context.makeImage()!
}

private let pink = CGColor(red: 1, green: 0, blue: 1, alpha: 1)

@Suite struct WidgetFrameDetectorTests {
    @Test func findsTwoStackedWidgets() {
        let top = CGRect(x: 40, y: 120, width: 320, height: 150)
        let large = CGRect(x: 40, y: 300, width: 320, height: 330)
        let image = makeImage(width: 400, height: 800, rects: [(top, pink), (large, pink)])

        let frames = WidgetFrameDetector.detect(in: image)
        #expect(frames.count == 2)

        let expectedTop = CGRect(x: 0.1, y: 0.15, width: 0.8, height: 0.1875)
        let expectedLarge = CGRect(x: 0.1, y: 0.375, width: 0.8, height: 0.4125)
        #expect(approxEqual(frames[0], expectedTop))
        #expect(approxEqual(frames[1], expectedLarge))

        let assigned = WidgetFrameDetector.assign(frames)
        #expect(approxEqual(assigned[.top]!, expectedTop))
        #expect(approxEqual(assigned[.large]!, expectedLarge))
    }

    @Test func ignoresNoiseAndEmptyScreens() {
        let speck = CGRect(x: 10, y: 10, width: 4, height: 4)
        let image = makeImage(width: 400, height: 800, rects: [(speck, pink)])
        #expect(WidgetFrameDetector.detect(in: image).isEmpty)

        let plain = makeImage(width: 400, height: 800, rects: [])
        #expect(WidgetFrameDetector.detect(in: plain).isEmpty)
        #expect(WidgetFrameDetector.assign([]).isEmpty)
    }

    @Test func singleFrameGoesToTheRightSlot() {
        let wide = [CGRect(x: 0.1, y: 0.1, width: 0.8, height: 0.2)]
        #expect(WidgetFrameDetector.assign(wide)[.top] != nil)
        let tall = [CGRect(x: 0.1, y: 0.1, width: 0.8, height: 0.8)]
        #expect(WidgetFrameDetector.assign(tall)[.large] != nil)
    }

    private func approxEqual(_ a: CGRect, _ b: CGRect, tolerance: CGFloat = 0.01) -> Bool {
        abs(a.minX - b.minX) < tolerance && abs(a.minY - b.minY) < tolerance
            && abs(a.width - b.width) < tolerance && abs(a.height - b.height) < tolerance
    }
}

@Suite struct WallpaperSlicerTests {
    @Test func aspectFillCentersAndCrops() {
        // A 2:1 image into a 1:2 screen must scale by height and crop the sides.
        let image = makeImage(width: 800, height: 400, rects: [])
        let filled = WallpaperSlicer.aspectFill(image, to: CGSize(width: 200, height: 400))!
        #expect(filled.width == 200 && filled.height == 400)

        // The center of the source gradient is mid-blend; the filled image's center matches.
        let pixels = PixelBuffer(image: filled)!
        let center = pixels.rgb(x: 100, y: 200)
        #expect(abs(Int(center.g) - Int(center.b)) < 40)
    }

    @Test func slicesMatchFrames() {
        let red = CGColor(red: 1, green: 0, blue: 0, alpha: 1)
        let band = CGRect(x: 0, y: 0, width: 400, height: 200)
        let wallpaper = makeImage(width: 400, height: 800, rects: [(band, red)])
        let frames: [WallpaperSlot: CGRect] = [
            .top: CGRect(x: 0.1, y: 0.05, width: 0.8, height: 0.15),
            .large: CGRect(x: 0.1, y: 0.5, width: 0.8, height: 0.4),
        ]
        let slices = WallpaperSlicer.slices(wallpaper: wallpaper, screenPixelSize: CGSize(width: 400, height: 800), frames: frames)
        #expect(slices.count == 2)
        #expect(slices[.top]!.width == 320 && slices[.top]!.height == 120)
        #expect(slices[.large]!.width == 320 && slices[.large]!.height == 320)

        // The top slice sits inside the red band; the large one does not.
        let topPixels = PixelBuffer(image: slices[.top]!)!
        #expect(topPixels.rgb(x: 10, y: 10).r > 200)
        let largePixels = PixelBuffer(image: slices[.large]!)!
        #expect(largePixels.rgb(x: 10, y: 10).r < 50)
    }

    @Test func pngRoundTrips() {
        let image = makeImage(width: 50, height: 30, rects: [])
        let data = ImageCoding.png(from: image)!
        let decoded = ImageCoding.image(from: data)!
        #expect(decoded.width == 50 && decoded.height == 30)
    }
}

@Suite struct DocumentCompatibilityTests {
    @Test func decodesDocumentsWithoutNewerKeys() throws {
        let json = """
        {"pages":[{"id":"\(UUID().uuidString)","apps":[]}],"style":{"alignment":"leading","fontDesign":"standard","lineSpacing":6,"textSize":22,"theme":"black"},"topWidget":"date"}
        """
        let doc = try JSONDecoder().decode(LauncherDocument.self, from: Data(json.utf8))
        #expect(doc.wallpaper == WallpaperSettings())
    }

    @Test func wallpaperStoreRoundTrips() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = WallpaperStore(directory: dir)
        #expect(!store.hasSlices)
        try store.save(Data([1, 2, 3]), for: .top)
        #expect(store.hasSlices)
        #expect(store.imageData(for: .top) == Data([1, 2, 3]))
        #expect(store.imageData(for: .large) == nil)
        store.removeAll()
        #expect(!store.hasSlices)
    }
}
