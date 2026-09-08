import SwiftUI

/// The text-only app list. Used by the large widget and by the in-app preview,
/// so what the user sees while editing is exactly what the widget draws.
public struct LauncherRowsView: View {
    public let apps: [AppEntry]
    public let style: LauncherStyle
    /// When set, each row becomes a link. Widgets pass the deep link into the app.
    public let destination: ((AppEntry) -> URL)?

    public init(apps: [AppEntry], style: LauncherStyle, destination: ((AppEntry) -> URL)? = nil) {
        self.apps = apps
        self.style = style
        self.destination = destination
    }

    public var body: some View {
        VStack(alignment: style.alignment.horizontalAlignment, spacing: style.lineSpacing) {
            if apps.isEmpty {
                Text("Add apps")
                    .foregroundStyle(style.theme.foreground.opacity(0.35))
            } else {
                ForEach(apps) { app in
                    row(app)
                }
            }
        }
        .font(style.font)
        .foregroundStyle(style.theme.foreground)
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: Alignment(horizontal: style.alignment.horizontalAlignment, vertical: .top)
        )
    }

    @ViewBuilder
    private func row(_ app: AppEntry) -> some View {
        let label = Text(app.name)
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: style.alignment.frameAlignment)
        if let destination {
            Link(destination: destination(app)) { label }
        } else {
            label
        }
    }
}

/// The medium widget's content: blank, the date, or the weekday, bottom-aligned.
public struct TopContentView: View {
    public let date: Date
    public let content: TopWidgetContent
    public let style: LauncherStyle

    public init(date: Date, content: TopWidgetContent, style: LauncherStyle) {
        self.date = date
        self.content = content
        self.style = style
    }

    public var body: some View {
        Group {
            switch content {
            case .blank:
                Color.clear
            case .date:
                Text(date, format: .dateTime.weekday(.wide).month(.abbreviated).day())
            case .weekday:
                Text(date, format: .dateTime.weekday(.wide))
            }
        }
        .font(style.font)
        .foregroundStyle(style.theme.foreground)
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: Alignment(horizontal: style.alignment.horizontalAlignment, vertical: .bottom)
        )
    }
}

/// Padding that keeps text off the widget edge. Content margins are disabled on the
/// widgets so the background can later be a wallpaper slice that runs edge to edge.
public enum WidgetInsets {
    public static let horizontal: CGFloat = 20
    public static let vertical: CGFloat = 18
}
