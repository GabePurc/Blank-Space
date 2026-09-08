import Foundation
import Testing
@testable import BlankSpaceCore

@Suite struct CatalogTests {
    @Test func loadsALargeCatalog() {
        #expect(Catalog.apps.count >= 150)
    }

    @Test func namesAreUnique() {
        let names = Catalog.apps.map(\.name)
        #expect(Set(names).count == names.count)
    }

    @Test func everySchemeIsAValidURL() {
        for app in Catalog.apps {
            guard let scheme = app.scheme else { continue }
            #expect(LaunchRouter.isValidSchemeURL(scheme), "\(app.name): \(scheme)")
        }
    }

    @Test func schemelessAppsBecomeShortcuts() {
        let phone = Catalog.apps.first { $0.name == "Phone" }
        #expect(phone?.needsShortcut == true)
        #expect(phone?.makeEntry().launch == .shortcut(name: "Open Phone"))
    }

    @Test func searchRanksPrefixFirst() {
        let results = Catalog.search("ma")
        #expect(results.first?.name.lowercased().hasPrefix("ma") == true)
        #expect(results.contains { $0.name == "Gmail" })
        #expect(Catalog.search("").count == Catalog.apps.count)
        #expect(Catalog.search("zzzzqq").isEmpty)
    }

    @Test func appleIsFirstCategory() {
        #expect(Catalog.categories.first == "Apple")
        #expect(!Catalog.apps(in: "Social").isEmpty)
    }
}

@Suite struct DocumentEditingTests {
    @Test func addRemoveMove() {
        var doc = LauncherDocument(pages: [Page()])
        let a = AppEntry(name: "A", launch: .urlScheme("a://"))
        let b = AppEntry(name: "B", launch: .urlScheme("b://"))
        doc.add(a, toPage: 0)
        doc.add(b, toPage: 0)
        #expect(doc.pages[0].apps.map(\.name) == ["A", "B"])

        doc.moveApps(from: IndexSet(integer: 1), to: 0, inPage: 0)
        #expect(doc.pages[0].apps.map(\.name) == ["B", "A"])

        doc.removeApps(at: IndexSet(integer: 0), fromPage: 0)
        #expect(doc.pages[0].apps.map(\.name) == ["A"])

        var renamed = a
        renamed.name = "Alpha"
        doc.replace(renamed)
        #expect(doc.pages[0].apps[0].name == "Alpha")

        doc.remove(id: a.id)
        #expect(doc.pages[0].apps.isEmpty)
    }

    @Test func pageLimits() {
        var doc = LauncherDocument(pages: [Page()])
        for _ in 0..<10 { doc.addPage() }
        #expect(doc.pages.count == LauncherDocument.maxPages)
        for _ in 0..<10 { doc.removeLastPage() }
        #expect(doc.pages.count == 1)
    }

    @Test func sortsAlphabetically() {
        var doc = LauncherDocument(pages: [Page(apps: [
            AppEntry(name: "zoom", launch: .urlScheme("z://")),
            AppEntry(name: "Apple", launch: .urlScheme("a://")),
        ])])
        doc.sortPage(0)
        #expect(doc.pages[0].apps.map(\.name) == ["Apple", "zoom"])
    }
}
