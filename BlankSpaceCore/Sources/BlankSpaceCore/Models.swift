import Foundation

/// How a launcher row opens its target app.
public enum LaunchMethod: Codable, Hashable, Sendable {
    /// A full URL using the target app's custom scheme, e.g. `mobilenotes://`.
    case urlScheme(String)
    /// The name of an Apple Shortcut that runs an "Open App" action.
    /// Used for apps with no public URL scheme, such as Phone.
    case shortcut(name: String)
}

/// One row in a launcher widget.
public struct AppEntry: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID
    public var name: String
    public var launch: LaunchMethod

    public init(id: UUID = UUID(), name: String, launch: LaunchMethod) {
        self.id = id
        self.name = name
        self.launch = launch
    }
}

/// One launcher widget's worth of apps. Page 0 is "Widget 1" on the home screen.
public struct Page: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID
    public var apps: [AppEntry]

    public init(id: UUID = UUID(), apps: [AppEntry] = []) {
        self.id = id
        self.apps = apps
    }
}

public enum TextAlignmentOption: String, Codable, CaseIterable, Sendable {
    case leading, center, trailing
}

/// Widget background. Text color follows: light gets dark text, the others get light text.
public enum WidgetTheme: String, Codable, CaseIterable, Sendable {
    case light, dark, black
}

public enum FontDesignOption: String, Codable, CaseIterable, Sendable {
    case standard, rounded, serif, monospaced
}

public struct LauncherStyle: Codable, Hashable, Sendable {
    public var alignment: TextAlignmentOption
    public var fontDesign: FontDesignOption
    public var textSize: Double
    public var lineSpacing: Double
    public var theme: WidgetTheme

    public init(
        alignment: TextAlignmentOption = .leading,
        fontDesign: FontDesignOption = .standard,
        textSize: Double = 22,
        lineSpacing: Double = 6,
        theme: WidgetTheme = .black
    ) {
        self.alignment = alignment
        self.fontDesign = fontDesign
        self.textSize = textSize
        self.lineSpacing = lineSpacing
        self.theme = theme
    }
}

/// What the medium widget at the top of the screen shows.
public enum TopWidgetContent: String, Codable, CaseIterable, Sendable {
    case blank, date, weekday
}

/// Everything the widgets need, stored as one JSON document in the App Group.
public struct LauncherDocument: Codable, Hashable, Sendable {
    public static let maxPages = 5

    public var pages: [Page]
    public var style: LauncherStyle
    public var topWidget: TopWidgetContent

    public init(pages: [Page], style: LauncherStyle = LauncherStyle(), topWidget: TopWidgetContent = .date) {
        self.pages = pages
        self.style = style
        self.topWidget = topWidget
    }

    /// Returns the page at `index`, or an empty page if the user hasn't made one yet.
    public func page(at index: Int) -> Page {
        pages.indices.contains(index) ? pages[index] : Page()
    }

    /// Finds an entry by id across all pages.
    public func entry(id: UUID) -> AppEntry? {
        for page in pages {
            if let entry = page.apps.first(where: { $0.id == id }) { return entry }
        }
        return nil
    }

    /// A sensible first home screen using Apple apps with public URL schemes.
    public static var starter: LauncherDocument {
        LauncherDocument(pages: [
            Page(apps: [
                AppEntry(name: "Messages", launch: .urlScheme("messages://")),
                AppEntry(name: "Mail", launch: .urlScheme("message://")),
                AppEntry(name: "Maps", launch: .urlScheme("maps://")),
                AppEntry(name: "Notes", launch: .urlScheme("mobilenotes://")),
                AppEntry(name: "Calendar", launch: .urlScheme("calshow://")),
                AppEntry(name: "Camera", launch: .urlScheme("camera://")),
                AppEntry(name: "Photos", launch: .urlScheme("photos-redirect://")),
                AppEntry(name: "Music", launch: .urlScheme("music://")),
            ]),
        ])
    }
}
