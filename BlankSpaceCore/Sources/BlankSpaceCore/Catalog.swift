import Foundation

/// An app the user can add by name. Shipped as `Resources/catalog.json` and editable by anyone.
public struct CatalogApp: Codable, Identifiable, Hashable, Sendable {
    public let name: String
    /// A full URL that opens the app, e.g. `instagram://`. Nil when the app has no public scheme.
    public let scheme: String?
    public let category: String

    public var id: String { name }

    /// Apps with no scheme (Phone, Settings) are opened through an Apple Shortcut instead.
    public var needsShortcut: Bool { scheme == nil }

    /// The Shortcut name we ask the user to create for scheme-less apps.
    public var suggestedShortcutName: String { "Open \(name)" }

    public func makeEntry() -> AppEntry {
        if let scheme {
            return AppEntry(name: name, launch: .urlScheme(scheme))
        }
        return AppEntry(name: name, launch: .shortcut(name: suggestedShortcutName))
    }
}

public enum Catalog {
    /// Every catalog app, sorted by name.
    public static let apps: [CatalogApp] = load()

    /// Category names in display order: Apple first, then the rest alphabetically.
    public static let categories: [String] = {
        let names = Set(apps.map(\.category)).subtracting(["Apple"]).sorted()
        return ["Apple"] + names
    }()

    public static func apps(in category: String) -> [CatalogApp] {
        apps.filter { $0.category == category }
    }

    /// Case- and diacritic-insensitive prefix-or-contains search. Prefix matches rank first.
    public static func search(_ query: String) -> [CatalogApp] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return apps }
        let options: String.CompareOptions = [.caseInsensitive, .diacriticInsensitive]
        let prefix = apps.filter { $0.name.range(of: trimmed, options: [options, .anchored]) != nil }
        let contains = apps.filter { app in
            !prefix.contains(app) && app.name.range(of: trimmed, options: options) != nil
        }
        return prefix + contains
    }

    private static func load() -> [CatalogApp] {
        guard let url = Bundle.module.url(forResource: "catalog", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([CatalogApp].self, from: data)
        else { return [] }
        return decoded.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}
