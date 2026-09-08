import BlankSpaceCore
import Photos
import UIKit

enum WallpaperError: LocalizedError {
    case unreadableImage
    case noWidgetsFound
    case encodingFailed
    case photosDenied
    case noScreen

    var errorDescription: String? {
        switch self {
        case .unreadableImage:
            return "That image couldn't be read. Try a different photo."
        case .noWidgetsFound:
            return "No pink widgets were found in that screenshot. Make sure both widgets are on the page you captured and are solid pink, then try again."
        case .encodingFailed:
            return "The wallpaper slices couldn't be saved."
        case .photosDenied:
            return "Blank Space needs permission to add photos. Allow it in Settings, then try again."
        case .noScreen:
            return "Couldn't determine the screen size."
        }
    }
}

/// Image work for the wallpaper flow: reading photos upright, running calibration,
/// and making plain wallpapers.
enum WallpaperProcessor {
    private static var sourceURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("wallpaper-source")
    }

    /// The user's chosen wallpaper photo, kept so calibration can be redone later.
    static func loadSource() -> Data? {
        try? Data(contentsOf: sourceURL)
    }

    static func saveSource(_ data: Data) throws {
        try data.write(to: sourceURL, options: .atomic)
    }

    static func removeSource() {
        try? FileManager.default.removeItem(at: sourceURL)
    }

    /// A small preview of an image for the form.
    static func thumbnail(from data: Data, maxSide: CGFloat = 400) -> UIImage? {
        guard let image = UIImage(data: data) else { return nil }
        let scale = min(1, maxSide / max(image.size.width, image.size.height))
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        return image.preparingThumbnail(of: size)
    }

    /// Decodes and applies EXIF orientation so pixel rows run top to bottom.
    static func uprightImage(from data: Data) -> CGImage? {
        guard let image = UIImage(data: data) else { return nil }
        if image.imageOrientation == .up, let cg = image.cgImage { return cg }
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }.cgImage
    }

    struct CalibrationResult {
        let frames: [WallpaperSlot: CGRect]
        let slices: [WallpaperSlot: UIImage]
    }

    /// Finds the pink widgets in the screenshot, crops the wallpaper to match, and saves the slices.
    static func calibrate(
        wallpaperData: Data,
        screenshotData: Data,
        store: WallpaperStore = .shared
    ) throws -> CalibrationResult {
        guard let wallpaper = uprightImage(from: wallpaperData),
              let screenshot = uprightImage(from: screenshotData)
        else { throw WallpaperError.unreadableImage }

        let frames = WidgetFrameDetector.assign(WidgetFrameDetector.detect(in: screenshot))
        guard !frames.isEmpty else { throw WallpaperError.noWidgetsFound }

        let slices = WallpaperSlicer.slices(
            wallpaper: wallpaper,
            screenPixelSize: CGSize(width: screenshot.width, height: screenshot.height),
            frames: frames
        )

        store.removeAll()
        var images: [WallpaperSlot: UIImage] = [:]
        for (slot, cg) in slices {
            guard let png = ImageCoding.png(from: cg) else { throw WallpaperError.encodingFailed }
            try store.save(png, for: slot)
            images[slot] = UIImage(cgImage: cg)
        }
        return CalibrationResult(frames: frames, slices: images)
    }

    static func savedSlices(store: WallpaperStore = .shared) -> [WallpaperSlot: UIImage] {
        var result: [WallpaperSlot: UIImage] = [:]
        for slot in WallpaperSlot.allCases {
            if let data = store.imageData(for: slot), let image = UIImage(data: data) {
                result[slot] = image
            }
        }
        return result
    }

    // MARK: Plain wallpapers

    enum PlainWallpaper: String, CaseIterable, Identifiable {
        case black, graphite, white, paper

        var id: String { rawValue }

        var name: String { rawValue.capitalized }

        var color: UIColor {
            switch self {
            case .black: return .black
            case .graphite: return UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1)
            case .white: return .white
            case .paper: return UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1)
            }
        }

        /// The widget background that matches this wallpaper.
        var theme: WidgetTheme {
            switch self {
            case .black: return .black
            case .graphite: return .dark
            case .white, .paper: return .light
            }
        }
    }

    static func currentScreen() -> UIScreen? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        return (scenes.first { $0.activationState == .foregroundActive } ?? scenes.first)?.screen
    }

    static func render(_ wallpaper: PlainWallpaper, on screen: UIScreen) -> UIImage {
        let size = screen.bounds.size
        let format = UIGraphicsImageRendererFormat()
        format.scale = screen.scale
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            wallpaper.color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }

    static func saveToPhotos(_ image: UIImage) async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else { throw WallpaperError.photosDenied }
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }
    }
}
