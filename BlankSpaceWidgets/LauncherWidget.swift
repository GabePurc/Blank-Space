import BlankSpaceCore
import SwiftUI
import WidgetKit

// MARK: - Timeline

struct LauncherEntry: TimelineEntry {
    let date: Date
    let page: Page
    let style: LauncherStyle
}

/// Reads one page from the shared store. The app reloads timelines after every save,
/// so a single entry with no refresh policy is enough.
struct LauncherProvider: TimelineProvider {
    let pageIndex: Int

    func placeholder(in context: Context) -> LauncherEntry {
        let starter = LauncherDocument.starter
        return LauncherEntry(date: .now, page: starter.page(at: 0), style: starter.style)
    }

    func getSnapshot(in context: Context, completion: @escaping (LauncherEntry) -> Void) {
        completion(current())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LauncherEntry>) -> Void) {
        completion(Timeline(entries: [current()], policy: .never))
    }

    private func current() -> LauncherEntry {
        let document = LauncherStore.shared.load()
        return LauncherEntry(date: .now, page: document.page(at: pageIndex), style: document.style)
    }
}

// MARK: - View

struct LauncherWidgetView: View {
    let entry: LauncherEntry

    var body: some View {
        let style = entry.style
        VStack(alignment: style.alignment.horizontalAlignment, spacing: style.lineSpacing) {
            if entry.page.apps.isEmpty {
                Text("Add apps")
                    .foregroundStyle(style.theme.foreground.opacity(0.4))
            } else {
                ForEach(entry.page.apps) { app in
                    // Widgets can only open their host app. The app receives this URL
                    // and redirects to the real target. See LaunchRouter.
                    Link(destination: LaunchRouter.widgetURL(for: app)) {
                        Text(app.name)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: style.alignment.frameAlignment)
                    }
                }
            }
        }
        .font(.system(size: style.textSize, weight: .medium, design: style.fontDesign.design))
        .foregroundStyle(style.theme.foreground)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .containerBackground(style.theme.background, for: .widget)
    }
}

// MARK: - Widgets

/// Each home screen page needs its own widget kind, so there are five thin wrappers.
private func launcherConfiguration(pageIndex: Int) -> some WidgetConfiguration {
    StaticConfiguration(
        kind: "com.blankspace.launcher.\(pageIndex + 1)",
        provider: LauncherProvider(pageIndex: pageIndex)
    ) { entry in
        LauncherWidgetView(entry: entry)
    }
    .configurationDisplayName("Widget \(pageIndex + 1)")
    .description("A text-only list of your apps.")
    .supportedFamilies([.systemLarge])
    .contentMarginsDisabled()
}

struct LauncherWidget1: Widget { var body: some WidgetConfiguration { launcherConfiguration(pageIndex: 0) } }
struct LauncherWidget2: Widget { var body: some WidgetConfiguration { launcherConfiguration(pageIndex: 1) } }
struct LauncherWidget3: Widget { var body: some WidgetConfiguration { launcherConfiguration(pageIndex: 2) } }
struct LauncherWidget4: Widget { var body: some WidgetConfiguration { launcherConfiguration(pageIndex: 3) } }
struct LauncherWidget5: Widget { var body: some WidgetConfiguration { launcherConfiguration(pageIndex: 4) } }

#Preview("Launcher", as: .systemLarge) {
    LauncherWidget1()
} timeline: {
    let starter = LauncherDocument.starter
    LauncherEntry(date: .now, page: starter.page(at: 0), style: starter.style)
    LauncherEntry(date: .now, page: starter.page(at: 0), style: LauncherStyle(alignment: .center, theme: .light))
}
