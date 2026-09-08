import Foundation
import Testing
@testable import BlankSpaceCore

@Suite struct LauncherStoreTests {
    @Test func roundTripsDocument() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = LauncherStore(fileURL: dir.appendingPathComponent("launcher.json"))
        #expect(!store.hasDocument)

        let document = LauncherDocument.starter
        try store.save(document)
        #expect(store.hasDocument)
        #expect(store.load() == document)
    }

    @Test func fallsBackToStarterWhenMissing() {
        let store = LauncherStore(fileURL: URL(fileURLWithPath: "/nonexistent/\(UUID().uuidString).json"))
        #expect(store.load().pages.count == 1)
        #expect(store.load().pages[0].apps.count == 8)
    }
}

@Suite struct LaunchRouterTests {
    @Test func widgetURLRoundTrips() {
        let entry = AppEntry(name: "Notes", launch: .urlScheme("mobilenotes://"))
        let url = LaunchRouter.widgetURL(for: entry)
        #expect(url.scheme == "blankspace")
        #expect(LaunchRouter.entryID(from: url) == entry.id)
    }

    @Test func rejectsForeignURLs() {
        #expect(LaunchRouter.entryID(from: URL(string: "https://example.com/open/abc")!) == nil)
        #expect(LaunchRouter.entryID(from: URL(string: "blankspace://other/\(UUID().uuidString)")!) == nil)
    }

    @Test func buildsTargets() {
        let scheme = AppEntry(name: "Maps", launch: .urlScheme("maps://"))
        #expect(LaunchRouter.targetURL(for: scheme)?.absoluteString == "maps://")

        let shortcut = AppEntry(name: "Phone", launch: .shortcut(name: "Open Phone"))
        #expect(LaunchRouter.targetURL(for: shortcut)?.absoluteString == "shortcuts://run-shortcut?name=Open%20Phone")
    }

    @Test func validatesSchemes() {
        #expect(LaunchRouter.isValidSchemeURL("maps://"))
        #expect(!LaunchRouter.isValidSchemeURL("not a url"))
        #expect(!LaunchRouter.isValidSchemeURL("blankspace://open/x"))
    }
}
