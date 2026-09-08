import BlankSpaceCore
import SwiftUI

/// Phase 0 placeholder. Shows what the widgets will render and proves the shared store works.
/// The real editor (search, add, reorder, style) lands in Phase 1.
struct ContentView: View {
    @Environment(LauncherModel.self) private var model

    var body: some View {
        NavigationStack {
            List {
                ForEach(Array(model.document.pages.enumerated()), id: \.element.id) { index, page in
                    Section("Widget \(index + 1)") {
                        ForEach(page.apps) { app in
                            LabeledContent(app.name, value: launchDescription(app))
                        }
                    }
                }

                Section("Style") {
                    LabeledContent("Theme", value: model.document.style.theme.rawValue)
                    LabeledContent("Alignment", value: model.document.style.alignment.rawValue)
                    LabeledContent("Top widget", value: model.document.topWidget.rawValue)
                }

                Section {
                    Button("Reset to starter", role: .destructive) { model.resetToStarter() }
                } footer: {
                    if let error = model.lastError {
                        Text(error).foregroundStyle(.red)
                    } else {
                        Text("Add the Top Widget and Widget 1 to your home screen to see these.")
                    }
                }
            }
            .navigationTitle("Blank Space")
        }
    }

    private func launchDescription(_ app: AppEntry) -> String {
        switch app.launch {
        case .urlScheme(let scheme): return scheme
        case .shortcut(let name): return "Shortcut: \(name)"
        }
    }
}

#Preview {
    ContentView()
        .environment(LauncherModel(store: LauncherStore(fileURL: FileManager.default.temporaryDirectory.appendingPathComponent("preview.json"))))
}
