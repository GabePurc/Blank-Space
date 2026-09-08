import BlankSpaceCore
import SwiftUI
import UIKit

@main
struct Blank_SpaceApp: App {
    @State private var model = LauncherModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(model)
                .onOpenURL { url in
                    handle(url)
                }
        }
    }

    /// A widget tap arrives here as `blankspace://open/<id>`. Redirect to the real app at once.
    private func handle(_ url: URL) {
        guard let id = LaunchRouter.entryID(from: url),
              let entry = model.document.entry(id: id),
              let target = LaunchRouter.targetURL(for: entry)
        else { return }
        UIApplication.shared.open(target)
    }
}
