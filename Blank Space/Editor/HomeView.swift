import BlankSpaceCore
import SwiftUI

/// Identifies which page an "Add app" sheet targets.
struct PageTarget: Identifiable {
    let index: Int
    var id: Int { index }
}

/// The main editor: one section per widget page, plus page management.
struct HomeView: View {
    @Environment(LauncherModel.self) private var model
    @State private var addingTo: PageTarget?
    @State private var editing: AppEntry?
    @State private var showingStyle = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(Array(model.document.pages.enumerated()), id: \.element.id) { index, page in
                    pageSection(index: index, page: page)
                }
                pagesSection
                setupSection
                if let error = model.lastError {
                    Section { Text(error).foregroundStyle(.red) }
                }
            }
            .navigationTitle("Blank Space")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { EditButton() }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingStyle = true
                    } label: {
                        Label("Style", systemImage: "paintbrush")
                    }
                }
            }
            .sheet(item: $addingTo) { target in
                AddAppView(pageIndex: target.index)
            }
            .sheet(item: $editing) { app in
                EditAppView(app: app)
            }
            .sheet(isPresented: $showingStyle) {
                StyleView(style: model.document.style, topWidget: model.document.topWidget)
            }
        }
    }

    private func pageSection(index: Int, page: Page) -> some View {
        Section {
            ForEach(page.apps) { app in
                Button {
                    editing = app
                } label: {
                    HStack {
                        Text(app.name)
                        Spacer()
                        Text(subtitle(for: app))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                .tint(.primary)
            }
            .onDelete { offsets in
                model.update { $0.removeApps(at: offsets, fromPage: index) }
            }
            .onMove { from, to in
                model.update { $0.moveApps(from: from, to: to, inPage: index) }
            }

            Button {
                addingTo = PageTarget(index: index)
            } label: {
                Label("Add app", systemImage: "plus.circle.fill")
            }
        } header: {
            HStack {
                Text("Widget \(index + 1)")
                Spacer()
                if page.apps.count > 1 {
                    Button("Sort A to Z") {
                        model.update { $0.sortPage(index) }
                    }
                    .font(.caption)
                    .textCase(nil)
                }
            }
        } footer: {
            if index == 0 {
                Text("Tap a row to rename it or change how it opens. Drag to reorder in Edit mode.")
            }
        }
    }

    private var pagesSection: some View {
        let count = model.document.pages.count
        return Section {
            if count < LauncherDocument.maxPages {
                Button {
                    model.update { $0.addPage() }
                } label: {
                    Label("Add Widget \(count + 1)", systemImage: "plus.rectangle.on.rectangle")
                }
            }
            if count > 1 {
                Button(role: .destructive) {
                    model.update { $0.removeLastPage() }
                } label: {
                    Label("Remove Widget \(count)", systemImage: "minus.rectangle")
                }
            }
        } header: {
            Text("Pages")
        } footer: {
            Text("Each page is its own large widget. Up to \(LauncherDocument.maxPages) pages.")
        }
    }

    private var setupSection: some View {
        Section {
            NavigationLink {
                SetupView()
            } label: {
                Label("Setup guide", systemImage: "list.number")
            }
            NavigationLink {
                WallpaperView()
            } label: {
                Label("Wallpaper", systemImage: "photo")
            }
        } header: {
            Text("Home Screen")
        } footer: {
            Text("The widgets read this list. Changes here show up on the Home Screen right away.")
        }
    }

    private func subtitle(for app: AppEntry) -> String {
        switch app.launch {
        case .urlScheme(let scheme): return scheme
        case .shortcut(let name): return "Shortcut: \(name)"
        }
    }
}

#Preview {
    HomeView()
        .environment(LauncherModel(store: LauncherStore(
            fileURL: FileManager.default.temporaryDirectory.appendingPathComponent("preview-home.json")
        )))
}
