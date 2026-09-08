import BlankSpaceCore
import SwiftUI

enum LaunchKind: String, CaseIterable, Identifiable {
    case scheme = "URL scheme"
    case shortcut = "Shortcut"
    var id: String { rawValue }
}

/// Add an app that isn't in the catalog, by URL scheme or by Shortcut name.
struct CustomAppView: View {
    let pageIndex: Int
    let onAdded: () -> Void

    @Environment(LauncherModel.self) private var model
    @Environment(\.openURL) private var openURL
    @State private var kind: LaunchKind = .scheme
    @State private var name: String
    @State private var scheme = ""
    @State private var shortcutName = ""

    init(pageIndex: Int, initialName: String = "", onAdded: @escaping () -> Void) {
        self.pageIndex = pageIndex
        self.onAdded = onAdded
        _name = State(initialValue: initialName)
    }

    private var trimmedName: String { name.trimmingCharacters(in: .whitespaces) }
    private var trimmedScheme: String { scheme.trimmingCharacters(in: .whitespaces) }
    private var trimmedShortcut: String { shortcutName.trimmingCharacters(in: .whitespaces) }
    private var schemeIsValid: Bool { LaunchRouter.isValidSchemeURL(trimmedScheme) }

    private var canAdd: Bool {
        guard !trimmedName.isEmpty else { return false }
        switch kind {
        case .scheme: return schemeIsValid
        case .shortcut: return !trimmedShortcut.isEmpty
        }
    }

    var body: some View {
        Form {
            Section {
                Picker("Opens with", selection: $kind) {
                    ForEach(LaunchKind.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
            }

            Section("Name in widget") {
                TextField("Name", text: $name)
            }

            switch kind {
            case .scheme:
                Section {
                    TextField("appname://", text: $scheme)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Button("Test") {
                        if let url = URL(string: trimmedScheme) { openURL(url) }
                    }
                    .disabled(!schemeIsValid)
                } header: {
                    Text("URL scheme")
                } footer: {
                    Text("Search the web for “<app name> URL scheme”. If Test does nothing, the app isn't installed or the scheme is wrong.")
                }
            case .shortcut:
                Section {
                    TextField("Shortcut name", text: $shortcutName)
                    Button {
                        openURL(URL(string: "shortcuts://create-shortcut")!)
                    } label: {
                        Label("Open Shortcuts", systemImage: "arrow.up.forward.app")
                    }
                } header: {
                    Text("Shortcut")
                } footer: {
                    Text("In Shortcuts, make a new shortcut with the “Open App” action, name it, and type that exact name here. Launching this way briefly shows the Shortcuts app.")
                }
            }

            Section {
                Button("Add to Widget \(pageIndex + 1)") { add() }
                    .disabled(!canAdd)
            }
        }
        .navigationTitle("Custom app")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func add() {
        let launch: LaunchMethod = kind == .scheme
            ? .urlScheme(trimmedScheme)
            : .shortcut(name: trimmedShortcut)
        model.update { $0.add(AppEntry(name: trimmedName, launch: launch), toPage: pageIndex) }
        onAdded()
    }
}
