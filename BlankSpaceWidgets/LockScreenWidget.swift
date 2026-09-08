import AppIntents
import BlankSpaceCore
import SwiftUI
import WidgetKit

// MARK: - App picker

/// One launcher entry, exposed so the user can pick it in the widget's settings.
struct LauncherAppEntity: AppEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "App")
    static let defaultQuery = LauncherAppQuery()

    let id: UUID
    let name: String

    init(entry: AppEntry) {
        id = entry.id
        name = entry.name
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

struct LauncherAppQuery: EntityQuery {
    func entities(for identifiers: [UUID]) async throws -> [LauncherAppEntity] {
        let document = LauncherStore.shared.load()
        return identifiers.compactMap { document.entry(id: $0) }.map(LauncherAppEntity.init)
    }

    func suggestedEntities() async throws -> [LauncherAppEntity] {
        LauncherStore.shared.load().allEntries.map(LauncherAppEntity.init)
    }

    func defaultResult() async -> LauncherAppEntity? {
        LauncherStore.shared.load().allEntries.first.map(LauncherAppEntity.init)
    }
}

struct LockScreenAppIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Lock Screen App"
    static let description = IntentDescription("Choose which app this shortcut opens.")

    @Parameter(title: "App")
    var app: LauncherAppEntity?
}

// MARK: - Timeline

struct LockEntry: TimelineEntry {
    let date: Date
    let name: String
    let url: URL?
}

struct LockProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> LockEntry {
        LockEntry(date: .now, name: "Messages", url: nil)
    }

    func snapshot(for configuration: LockScreenAppIntent, in context: Context) async -> LockEntry {
        entry(for: configuration)
    }

    func timeline(for configuration: LockScreenAppIntent, in context: Context) async -> Timeline<LockEntry> {
        Timeline(entries: [entry(for: configuration)], policy: .never)
    }

    private func entry(for configuration: LockScreenAppIntent) -> LockEntry {
        let document = LauncherStore.shared.load()
        let chosen = configuration.app.flatMap { document.entry(id: $0.id) } ?? document.allEntries.first
        guard let chosen else {
            return LockEntry(date: .now, name: "Choose app", url: nil)
        }
        return LockEntry(date: .now, name: chosen.name, url: LaunchRouter.widgetURL(for: chosen))
    }
}

// MARK: - View

struct LockScreenWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: LockEntry

    var body: some View {
        Group {
            switch family {
            case .accessoryInline:
                Text(entry.name)
            case .accessoryCircular:
                ZStack {
                    AccessoryWidgetBackground()
                    Text(String(entry.name.prefix(1)))
                        .font(.title2.weight(.semibold))
                }
            default:
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.name)
                        .font(.headline)
                        .lineLimit(1)
                    Text("Tap to open")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .widgetURL(entry.url)
        .containerBackground(for: .widget) { Color.clear }
    }
}

struct LockScreenWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: "com.blankspace.lock",
            intent: LockScreenAppIntent.self,
            provider: LockProvider()
        ) { entry in
            LockScreenWidgetView(entry: entry)
        }
        .configurationDisplayName("Lock Screen App")
        .description("Opens one of your apps from the Lock Screen.")
        .supportedFamilies([.accessoryRectangular, .accessoryInline, .accessoryCircular])
    }
}

#Preview("Lock", as: .accessoryRectangular) {
    LockScreenWidget()
} timeline: {
    LockEntry(date: .now, name: "Messages", url: nil)
}
