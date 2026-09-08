import BlankSpaceCore
import SwiftUI
import WidgetKit

struct TopEntry: TimelineEntry {
    let date: Date
    let content: TopWidgetContent
    let style: LauncherStyle
}

/// The medium widget that fills the top of the screen. Refreshes at midnight so the date stays right.
struct TopProvider: TimelineProvider {
    func placeholder(in context: Context) -> TopEntry {
        TopEntry(date: .now, content: .date, style: LauncherStyle())
    }

    func getSnapshot(in context: Context, completion: @escaping (TopEntry) -> Void) {
        completion(current(at: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TopEntry>) -> Void) {
        let now = Date.now
        let midnight = Calendar.current.startOfDay(for: now).addingTimeInterval(24 * 60 * 60)
        completion(Timeline(entries: [current(at: now), current(at: midnight)], policy: .after(midnight)))
    }

    private func current(at date: Date) -> TopEntry {
        let document = LauncherStore.shared.load()
        return TopEntry(date: date, content: document.topWidget, style: document.style)
    }
}

struct TopWidgetView: View {
    let entry: TopEntry

    var body: some View {
        TopContentView(date: entry.date, content: entry.content, style: entry.style)
            .padding(.horizontal, WidgetInsets.horizontal)
            .padding(.vertical, WidgetInsets.vertical)
            .containerBackground(entry.style.theme.background, for: .widget)
    }
}

struct TopWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "com.blankspace.top", provider: TopProvider()) { entry in
            TopWidgetView(entry: entry)
        }
        .configurationDisplayName("Top Widget")
        .description("Blank space, the date, or the day of the week.")
        .supportedFamilies([.systemMedium])
        .contentMarginsDisabled()
    }
}

#Preview("Top", as: .systemMedium) {
    TopWidget()
} timeline: {
    TopEntry(date: .now, content: .date, style: LauncherStyle())
    TopEntry(date: .now, content: .weekday, style: LauncherStyle(theme: .light))
}
