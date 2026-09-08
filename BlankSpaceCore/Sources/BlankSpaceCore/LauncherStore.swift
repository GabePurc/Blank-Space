import Foundation

public enum AppGroup {
    /// Shared container between the app and the widget extension.
    /// Must match both targets' entitlements.
    public static let identifier = "group.FactoryOne.Blank-Space"

    /// The shared container, or Application Support when entitlements are missing
    /// (an unsigned CI build, for example) so nothing crashes on startup.
    public static func containerURL(groupIdentifier: String = identifier) -> URL {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupIdentifier)
            ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    }
}

/// Reads and writes the launcher document in the App Group container.
///
/// The app is the only writer. After saving, the app asks WidgetKit to reload
/// timelines so the widgets pick up the change.
public struct LauncherStore: Sendable {
    public static let shared = LauncherStore()

    public let fileURL: URL

    public init(groupIdentifier: String = AppGroup.identifier, fileName: String = "launcher.json") {
        fileURL = AppGroup.containerURL(groupIdentifier: groupIdentifier).appendingPathComponent(fileName)
    }

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    /// Whether the user has saved anything yet.
    public var hasDocument: Bool {
        FileManager.default.fileExists(atPath: fileURL.path)
    }

    /// The saved document, or the starter document if nothing is saved or the file is unreadable.
    public func load() -> LauncherDocument {
        guard let data = try? Data(contentsOf: fileURL),
              let document = try? JSONDecoder().decode(LauncherDocument.self, from: data)
        else { return .starter }
        return document
    }

    public func save(_ document: LauncherDocument) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(document)
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try data.write(to: fileURL, options: .atomic)
    }
}
