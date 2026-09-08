import Foundation

/// Pure edits on the document. The app wraps these in a save + widget reload.
extension LauncherDocument {
    public mutating func add(_ entry: AppEntry, toPage index: Int) {
        guard pages.indices.contains(index) else { return }
        pages[index].apps.append(entry)
    }

    public mutating func removeApps(at offsets: IndexSet, fromPage index: Int) {
        guard pages.indices.contains(index) else { return }
        pages[index].apps.remove(atOffsets: offsets)
    }

    public mutating func moveApps(from source: IndexSet, to destination: Int, inPage index: Int) {
        guard pages.indices.contains(index) else { return }
        pages[index].apps.move(fromOffsets: source, toOffset: destination)
    }

    /// Replaces the entry with the same id, wherever it lives.
    public mutating func replace(_ entry: AppEntry) {
        for p in pages.indices {
            if let a = pages[p].apps.firstIndex(where: { $0.id == entry.id }) {
                pages[p].apps[a] = entry
                return
            }
        }
    }

    public mutating func remove(id: UUID) {
        for p in pages.indices {
            pages[p].apps.removeAll { $0.id == id }
        }
    }

    /// Adds an empty page if there is room. Returns false at the five-page limit.
    @discardableResult
    public mutating func addPage() -> Bool {
        guard pages.count < Self.maxPages else { return false }
        pages.append(Page())
        return true
    }

    /// Removes the last page. Always keeps at least one.
    public mutating func removeLastPage() {
        guard pages.count > 1 else { return }
        pages.removeLast()
    }

    /// Sorts one page's apps alphabetically.
    public mutating func sortPage(_ index: Int) {
        guard pages.indices.contains(index) else { return }
        pages[index].apps.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}
