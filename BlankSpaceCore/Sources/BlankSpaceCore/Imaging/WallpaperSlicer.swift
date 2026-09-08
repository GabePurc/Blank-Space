import CoreGraphics
import Foundation
import ImageIO

/// Crops the pieces of wallpaper that sit behind each widget.
public enum WallpaperSlicer {
    /// Scales the image to fill `size` and center-crops, the way iOS fits a
    /// wallpaper to the screen when Perspective Zoom is off and it hasn't been pinched.
    public static func aspectFill(_ image: CGImage, to size: CGSize) -> CGImage? {
        let width = Int(size.width.rounded())
        let height = Int(size.height.rounded())
        guard width > 0, height > 0 else { return nil }

        let scale = max(size.width / CGFloat(image.width), size.height / CGFloat(image.height))
        let drawnWidth = CGFloat(image.width) * scale
        let drawnHeight = CGFloat(image.height) * scale
        let origin = CGPoint(x: (size.width - drawnWidth) / 2, y: (size.height - drawnHeight) / 2)

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        ) else { return nil }
        context.interpolationQuality = .high
        context.draw(image, in: CGRect(origin: origin, size: CGSize(width: drawnWidth, height: drawnHeight)))
        return context.makeImage()
    }

    /// Crops a normalized rectangle (0...1, origin top-left) out of the image.
    public static func crop(_ image: CGImage, normalized rect: CGRect) -> CGImage? {
        let pixelRect = CGRect(
            x: (rect.minX * CGFloat(image.width)).rounded(),
            y: (rect.minY * CGFloat(image.height)).rounded(),
            width: (rect.width * CGFloat(image.width)).rounded(),
            height: (rect.height * CGFloat(image.height)).rounded()
        )
        return image.cropping(to: pixelRect)
    }

    /// Fits the wallpaper to the screen and crops one slice per frame.
    public static func slices(
        wallpaper: CGImage,
        screenPixelSize: CGSize,
        frames: [WallpaperSlot: CGRect]
    ) -> [WallpaperSlot: CGImage] {
        guard let screen = aspectFill(wallpaper, to: screenPixelSize) else { return [:] }
        var result: [WallpaperSlot: CGImage] = [:]
        for (slot, frame) in frames {
            if let slice = crop(screen, normalized: frame) {
                result[slot] = slice
            }
        }
        return result
    }
}

/// PNG encoding and decoding without UIKit, so it works in tests on macOS too.
public enum ImageCoding {
    public static func png(from image: CGImage) -> Data? {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, "public.png" as CFString, 1, nil) else {
            return nil
        }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return data as Data
    }

    /// Decodes without applying EXIF orientation. Screenshots are always upright;
    /// the app normalizes photos before handing them here.
    public static func image(from data: Data) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }
}
