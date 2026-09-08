import BlankSpaceCore
import SwiftUI

/// Walks the user through creating an "Open App" Shortcut for apps with no URL scheme.
struct ShortcutSetupView: View {
    let app: CatalogApp
    let onAdd: (AppEntry) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var shortcutName: String

    init(app: CatalogApp, onAdd: @escaping (AppEntry) -> Void) {
        self.app = app
        self.onAdd = onAdd
        _shortcutName = State(initialValue: app.suggestedShortcutName)
    }

    private var trimmed: String { shortcutName.trimmingCharacters(in: .whitespaces) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("\(app.name) has no link other apps can open, so Blank Space opens it through a Shortcut. This takes about a minute and only needs doing once.")
                }
                Section("Steps") {
                    Label("Open Shortcuts and tap the + button.", systemImage: "1.circle")
                    Label("Add the “Open App” action and pick \(app.name).", systemImage: "2.circle")
                    Label("Name the shortcut exactly “\(trimmed)” and tap Done.", systemImage: "3.circle")
                    Button {
                        openURL(URL(string: "shortcuts://create-shortcut")!)
                    } label: {
                        Label("Open Shortcuts", systemImage: "arrow.up.forward.app")
                    }
                }
                Section("Shortcut name") {
                    TextField("Shortcut name", text: $shortcutName)
                }
                Section {
                    Button("Add to widget") {
                        onAdd(AppEntry(name: app.name, launch: .shortcut(name: trimmed)))
                    }
                    .disabled(trimmed.isEmpty)
                } footer: {
                    Text("Launching through a Shortcut briefly shows the Shortcuts app before \(app.name) opens.")
                }
            }
            .navigationTitle(app.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
