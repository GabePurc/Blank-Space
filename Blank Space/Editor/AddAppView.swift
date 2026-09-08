import BlankSpaceCore
import SwiftUI

/// Searchable catalog picker. Tapping an app adds it to the page and closes the sheet.
struct AddAppView: View {
    let pageIndex: Int

    @Environment(LauncherModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var shortcutApp: CatalogApp?

    private var namesOnPage: Set<String> {
        Set(model.document.page(at: pageIndex).apps.map(\.name))
    }

    var body: some View {
        NavigationStack {
            List {
                if query.trimmingCharacters(in: .whitespaces).isEmpty {
                    Section {
                        customLink(initialName: "")
                    }
                    ForEach(Catalog.categories, id: \.self) { category in
                        Section(category) {
                            ForEach(Catalog.apps(in: category)) { app in
                                row(app)
                            }
                        }
                    }
                } else {
                    let results = Catalog.search(query)
                    if results.isEmpty {
                        Section {
                            ContentUnavailableView.search(text: query)
                        }
                    } else {
                        Section {
                            ForEach(results) { app in
                                row(app)
                            }
                        }
                    }
                    Section {
                        customLink(initialName: query)
                    } footer: {
                        Text("Any app with a URL scheme can be added, even if it isn't in the list.")
                    }
                }
            }
            .searchable(text: $query, prompt: "Search apps")
            .navigationTitle("Add to Widget \(pageIndex + 1)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(item: $shortcutApp) { app in
                ShortcutSetupView(app: app) { entry in
                    shortcutApp = nil
                    add(entry)
                }
            }
        }
    }

    private func customLink(initialName: String) -> some View {
        NavigationLink {
            CustomAppView(pageIndex: pageIndex, initialName: initialName) {
                dismiss()
            }
        } label: {
            Label(initialName.isEmpty ? "Custom app or URL scheme" : "Add “\(initialName)” as a custom app",
                  systemImage: "link")
        }
    }

    private func row(_ app: CatalogApp) -> some View {
        Button {
            if app.needsShortcut {
                shortcutApp = app
            } else {
                add(app.makeEntry())
            }
        } label: {
            HStack {
                Text(app.name)
                Spacer()
                if app.needsShortcut {
                    Text("via Shortcut")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if namesOnPage.contains(app.name) {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .tint(.primary)
    }

    private func add(_ entry: AppEntry) {
        model.update { $0.add(entry, toPage: pageIndex) }
        dismiss()
    }
}
