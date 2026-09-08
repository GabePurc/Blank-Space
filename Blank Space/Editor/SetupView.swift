import SwiftUI

/// Every manual step iOS needs from the user, in order.
struct SetupView: View {
    var body: some View {
        List {
            Section {
                step(1, "Touch and hold an empty spot on your Home Screen, tap Edit, then Add Widget.")
                step(2, "Search for Blank Space. Add Top Widget, then Widget 1.")
                step(3, "Drag Top Widget to the top of the page and Widget 1 directly below it.")
            } header: {
                Text("Add the widgets")
            } footer: {
                Text("Widgets 2 to 5 are extra pages. Add them only if you've made those pages in Blank Space.")
            }

            Section {
                step(1, "Touch and hold the Home Screen, tap Edit, then Customize.")
                step(2, "Choose Large. Labels under widgets and apps disappear.")
            } header: {
                Text("Hide the label under the widgets")
            } footer: {
                Text("Requires iOS 18 or later. Keep icons in Default or Dark, not Tinted.")
            }

            Section {
                step(1, "Touch and hold the Home Screen, then tap the row of dots at the bottom.")
                step(2, "Uncheck every page except the one with the widgets, then tap Done.")
            } header: {
                Text("Hide your other pages")
            } footer: {
                Text("Your apps are still in the App Library. Swipe left past the last page or pull down to search.")
            }

            Section {
                NavigationLink {
                    WallpaperView()
                } label: {
                    Label("Match the wallpaper", systemImage: "photo")
                }
            } header: {
                Text("Hide the dock and widget edges")
            } footer: {
                Text("The widgets draw the wallpaper behind them so their edges vanish. Use a plain wallpaper and the matching widget background for the cleanest result.")
            }

            Section {
                step(1, "Lock your iPhone, then touch and hold the Lock Screen and tap Customize.")
                step(2, "Tap the widget area, find Blank Space, and add Lock Screen App.")
                step(3, "Tap the widget to choose which app it opens.")
            } header: {
                Text("Lock Screen shortcut")
            }

            Section {
                step(1, "In Settings, open Focus and create or pick a Focus.")
                step(2, "Under Customize Screens, choose the Home Screen page with the widgets.")
            } header: {
                Text("Optional: tie it to a Focus")
            } footer: {
                Text("Turning that Focus on shows only the Blank Space page. Turning it off brings your normal Home Screen back.")
            }
        }
        .navigationTitle("Setup guide")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func step(_ number: Int, _ text: String) -> some View {
        Label {
            Text(text)
        } icon: {
            Image(systemName: "\(number).circle")
        }
    }
}
