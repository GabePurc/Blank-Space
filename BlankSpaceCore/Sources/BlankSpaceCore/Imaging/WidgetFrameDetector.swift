import CoreGraphics
import Foundation

/// The color the widgets paint while calibrating. Chosen because it almost never
/// appears in wallpapers and survives screenshot compression cleanly.
public enum CalibrationColor {
    public static let red: Double = 1
    public static let green: Double = 0
    public static let blue: Double = 1

    @inline(__always)
    static func matches(r: UInt8, g: UInt8, b: UInt8) -> Bool {
        r >= 200 && g <= 90 && b >= 200
    }
}

/// Finds the solid-pink widget rectangles in a Home Screen screenshot.
public enum WidgetFrameDetector {
    /// Rectangles in normalized coordinates (0...1, origin top-left), sorted top to bottom.
    /// Empty when nothing pink and widget-sized is on screen.
    public static func detect(in image: CGImage) -> [CGRect] {
        guard let pixels = PixelBuffer(image: image) else { return [] }
        let w = pixels.width
        let h = pixels.height

        // Rows that contain a widget-wide run of pink.
        var rowCounts = [Int](repeating: 0, count: h)
        for y in 0..<h {
            var count = 0
            for x in 0..<w {
                let p = pixels.rgb(x: x, y: y)
                if CalibrationColor.matches(r: p.r, g: p.g, b: p.b) { count += 1 }
            }
            rowCounts[y] = count
        }
        let rowThreshold = max(3, w / 10)

        var runs: [ClosedRange<Int>] = []
        var start: Int?
        for y in 0..<h {
            let on = rowCounts[y] >= rowThreshold
            if on, start == nil { start = y }
            if !on, let s = start {
                runs.append(s...(y - 1))
                start = nil
            }
        }
        if let s = start { runs.append(s...(h - 1)) }

        // Ignore specks: a widget is at least a few percent of the screen tall.
        let minHeight = max(4, h / 40)
        runs = runs.filter { $0.count >= minHeight }

        return runs.compactMap { run -> CGRect? in
            let height = run.count
            var minX = w
            var maxX = -1
            for x in 0..<w {
                var count = 0
                for y in run {
                    let p = pixels.rgb(x: x, y: y)
                    if CalibrationColor.matches(r: p.r, g: p.g, b: p.b) { count += 1 }
                }
                if count >= height / 2 {
                    minX = min(minX, x)
                    maxX = max(maxX, x)
                }
            }
            guard maxX >= minX else { return nil }
            return CGRect(
                x: CGFloat(minX) / CGFloat(w),
                y: CGFloat(run.lowerBound) / CGFloat(h),
                width: CGFloat(maxX - minX + 1) / CGFloat(w),
                height: CGFloat(height) / CGFloat(h)
            )
        }
    }

    /// Splits detected frames into the two slots. The shorter frame is the medium
    /// top widget; the taller is the large launcher. Either can be missing.
    public static func assign(_ frames: [CGRect]) -> [WallpaperSlot: CGRect] {
        var result: [WallpaperSlot: CGRect] = [:]
        switch frames.count {
        case 0:
            break
        case 1:
            let f = frames[0]
            result[f.height / f.width < 0.75 ? .top : .large] = f
        default:
            let top = frames.min { $0.height < $1.height }!
            let large = frames.max { $0.height < $1.height }!
            result[.top] = top
            result[.large] = large
        }
        return result
    }
}
