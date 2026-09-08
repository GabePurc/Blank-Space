import Foundation

/// Which widget a wallpaper slice sits behind.
public enum WallpaperSlot: String, CaseIterable, Sendable {
    /// The medium widget at the top of the screen.
    case top
    /// The large launcher widget. Every page uses the same slice, since each
    /// page's widget sits in the same place on its own Home Screen page.
    case large
}

/// Wallpaper slices as PNG files in the App Group, read by the widgets.
public struct WallpaperStore: Sendable {
    public static let shared = WallpaperStore()

    public let directory: URL

    public init(groupIdentifier: String = AppGroup.identifier) {
        directory = AppGroup.containerURL(groupIdentifier: groupIdentifier).appendingPathComponent("wallpaper")
    }

    public init(directory: URL) {
        self.directory = directory
    }

    public func url(for slot: WallpaperSlot) -> URL {
        directory.appendingPathComponent("\(slot.rawValue).png")
    }

    public func imageData(for slot: WallpaperSlot) -> Data? {
        try? Data(contentsOf: url(for: slot))
    }

    public var hasSlices: Bool {
        WallpaperSlot.allCases.contains { FileManager.default.fileExists(atPath: url(for: $0).path) }
    }

    public func save(_ data: Data, for slot: WallpaperSlot) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try data.write(to: url(for: slot), options: .atomic)
    }

    public func removeAll() {
        try? FileManager.default.removeItem(at: directory)
    }
}
