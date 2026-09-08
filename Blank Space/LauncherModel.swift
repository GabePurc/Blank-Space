import BlankSpaceCore
import Foundation
import Observation
import WidgetKit

/// The app's single source of truth. Wraps the shared store and refreshes widgets on every save.
@Observable
final class LauncherModel {
    private let store: LauncherStore
    private(set) var document: LauncherDocument
    private(set) var lastError: String?

    init(store: LauncherStore = .shared) {
        self.store = store
        self.document = store.load()
        // Persist the starter on first launch so widgets and app agree from the start.
        if !store.hasDocument {
            save()
        }
    }

    func update(_ change: (inout LauncherDocument) -> Void) {
        change(&document)
        save()
    }

    func resetToStarter() {
        document = .starter
        save()
    }

    private func save() {
        do {
            try store.save(document)
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
}
