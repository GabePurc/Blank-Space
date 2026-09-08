import BlankSpaceCore
import SwiftUI
import WidgetKit

// MARK: - Timeline

struct LauncherEntry: TimelineEntry {
    let date: Date
    let page: Page
    let style: LauncherStyle
    let background: WidgetBackground
}

/// Reads one page from the shared store. The app reloads timelines after every save,
/// so a single entry with no refresh policy is enough.
struct LauncherProvider: TimelineProvider {
    let pageIndex: Int

    func placeholder(in context: Context) -> LauncherEntry {
        let starter = LauncherDocument.starter
        return LauncherEntry(date: .now, page: starter.page(at: 0), style: starter.style, background: .theme(starter.style.theme))
    }

    func getSnapshot(in context: Context, completion: @escaping (LauncherEntry) -> Void) {
        completion(current())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LauncherEntry>) -> Void) {
        completion(Timeline(entries: [current()], policy: .never))
    }

    private func current() -> LauncherEntry {
        let document = LauncherStore.shared.load()
        return LauncherEntry(
            date: .now,
            page: document.page(at: pageIndex),
            style: document.style,
            background: .current(for: .large, document: document)
        )
    }
}

// MARK: - View

struct LauncherWidgetView: View {
    let entry: LauncherEntry

    var body: some View {
        Group {
            if entry.background.isCalibration {
                // Text would confuse frame detection; show the solid color alone.
                Color.clear
            } else {
                // Widgets can only open their host app. Each row links into the app,
                // which redirects to the real target. See LaunchRouter.
                LauncherRowsView(apps: entry.page.apps, style: entry.style) { app in
                    LaunchRouter.widgetURL(for: app)
                }
                .padding(.horizontal, WidgetInsets.horizontal)
                .padding(.vertical, WidgetInsets.vertical)
            }
        }
        .containerBackground(for: .widget) {
            WidgetBackgroundView(background: entry.background)
        }
    }
}

// MARK: - Widgets

/// Each home screen page needs its own widget kind, so there are five thin wrappers.
private func launcherConfiguration(pageIndex: Int) -> some WidgetConfiguration {
    // Plain String values, not interpolated literals: WidgetKit asserts on a
    // LocalizedStringKey with arguments here, which kills the whole extension.
    let kind = "com.blankspace.launcher.\(pageIndex + 1)"
    let name = "Widget \(pageIndex + 1)"
    return StaticConfiguration(kind: kind, provider: LauncherProvider(pageIndex: pageIndex)) { entry in
        LauncherWidgetView(entry: entry)
    }
    .configurationDisplayName(name)
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
    LauncherEntry(date: .now, page: starter.page(at: 0), style: starter.style, background: .theme(.black))
    LauncherEntry(date: .now, page: starter.page(at: 0), style: LauncherStyle(alignment: .center, theme: .light), background: .theme(.light))
    LauncherEntry(date: .now, page: starter.page(at: 0), style: starter.style, background: .calibration)
}
