import BlankSpaceCore
import SwiftUI

/// Rename an entry, change how it opens, or remove it.
struct EditAppView: View {
    @Environment(LauncherModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    private let original: AppEntry
    @State private var name: String
    @State private var kind: LaunchKind
    @State private var scheme: String
    @State private var shortcutName: String

    init(app: AppEntry) {
        original = app
        _name = State(initialValue: app.name)
        switch app.launch {
        case .urlScheme(let s):
            _kind = State(initialValue: .scheme)
            _scheme = State(initialValue: s)
            _shortcutName = State(initialValue: "")
        case .shortcut(let n):
            _kind = State(initialValue: .shortcut)
            _scheme = State(initialValue: "")
            _shortcutName = State(initialValue: n)
        }
    }

    private var trimmedName: String { name.trimmingCharacters(in: .whitespaces) }
    private var trimmedScheme: String { scheme.trimmingCharacters(in: .whitespaces) }
    private var trimmedShortcut: String { shortcutName.trimmingCharacters(in: .whitespaces) }

    private var launch: LaunchMethod? {
        switch kind {
        case .scheme:
            return LaunchRouter.isValidSchemeURL(trimmedScheme) ? .urlScheme(trimmedScheme) : nil
        case .shortcut:
            return trimmedShortcut.isEmpty ? nil : .shortcut(name: trimmedShortcut)
        }
    }

    private var canSave: Bool { !trimmedName.isEmpty && launch != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name in widget") {
                    TextField("Name", text: $name)
                }
                Section("Opens with") {
                    Picker("Opens with", selection: $kind) {
                        ForEach(LaunchKind.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    switch kind {
                    case .scheme:
                        TextField("appname://", text: $scheme)
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    case .shortcut:
                        TextField("Shortcut name", text: $shortcutName)
                    }
                    Button("Test launch") {
                        if let launch,
                           let url = LaunchRouter.targetURL(for: AppEntry(name: trimmedName, launch: launch)) {
                            openURL(url)
                        }
                    }
                    .disabled(launch == nil)
                }
                Section {
                    Button("Remove from widget", role: .destructive) {
                        model.update { $0.remove(id: original.id) }
                        dismiss()
                    }
                }
            }
            .navigationTitle(original.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                }
            }
        }
    }

    private func save() {
        guard let launch else { return }
        var updated = original
        updated.name = trimmedName
        updated.launch = launch
        model.update { $0.replace(updated) }
        dismiss()
    }
}
