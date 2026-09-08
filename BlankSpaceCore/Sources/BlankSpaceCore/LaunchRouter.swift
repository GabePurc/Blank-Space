import Foundation

/// Builds and parses the URLs that connect a widget tap to an app launch.
///
/// Widgets can only open their own app. A row in the widget is a link to
/// `blankspace://open/<entry id>`. The app receives that URL and immediately
/// opens the entry's real target, which is either a URL scheme or a Shortcut.
public enum LaunchRouter {
    /// Registered in the app's Info.plist under CFBundleURLTypes.
    public static let scheme = "blankspace"
    static let openHost = "open"

    /// The URL a widget row links to.
    public static func widgetURL(for entry: AppEntry) -> URL {
        URL(string: "\(scheme)://\(openHost)/\(entry.id.uuidString)")!
    }

    /// Extracts the entry id from a URL the app received, or nil if it isn't one of ours.
    public static func entryID(from url: URL) -> UUID? {
        guard url.scheme?.lowercased() == scheme,
              url.host()?.lowercased() == openHost
        else { return nil }
        let id = url.lastPathComponent
        return UUID(uuidString: id)
    }

    /// The URL that actually opens the target app.
    public static func targetURL(for entry: AppEntry) -> URL? {
        switch entry.launch {
        case .urlScheme(let raw):
            return URL(string: raw)
        case .shortcut(let name):
            var components = URLComponents()
            components.scheme = "shortcuts"
            components.host = "run-shortcut"
            components.queryItems = [URLQueryItem(name: "name", value: name)]
            return components.url
        }
    }

    /// Quick sanity check for user-entered schemes: must parse and have a scheme.
    public static func isValidSchemeURL(_ raw: String) -> Bool {
        guard let url = URL(string: raw), let scheme = url.scheme, !scheme.isEmpty else { return false }
        return scheme.lowercased() != LaunchRouter.scheme
    }
}
