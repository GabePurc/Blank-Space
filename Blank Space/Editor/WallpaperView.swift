import BlankSpaceCore
import PhotosUI
import SwiftUI

/// Match the widgets to the wallpaper so the dock and widget edges disappear.
struct WallpaperView: View {
    @Environment(LauncherModel.self) private var model

    @State private var sourceItem: PhotosPickerItem?
    @State private var screenshotItem: PhotosPickerItem?
    @State private var sourceThumbnail: UIImage?
    @State private var slices: [WallpaperSlot: UIImage] = [:]
    @State private var errorMessage: String?
    @State private var statusMessage: String?
    @State private var busy = false

    private var calibrating: Bool { model.document.wallpaper.calibrating }

    private var wallpaperEnabled: Binding<Bool> {
        Binding(
            get: { model.document.wallpaper.enabled },
            set: { value in model.update { $0.wallpaper.enabled = value } }
        )
    }

    var body: some View {
        Form {
            Section {
                Text("Widgets can't be transparent, but they can draw the exact piece of wallpaper behind them. Blank Space finds where your widgets sit, crops your wallpaper to match, and the edges vanish.")
            }

            Section {
                PhotosPicker(selection: $sourceItem, matching: .images) {
                    Label(sourceThumbnail == nil ? "Choose your wallpaper photo" : "Choose a different photo",
                          systemImage: "photo")
                }
                if let sourceThumbnail {
                    Image(uiImage: sourceThumbnail)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 160)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            } header: {
                Text("Step 1: Wallpaper photo")
            } footer: {
                Text("Pick the same photo you set as your Home Screen wallpaper, set without pinching or moving it.")
            }

            Section {
                if calibrating {
                    Label("Widgets are pink", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.pink)
                    Text("Go to your Home Screen. Take a screenshot of the page with the widgets, then come back here.")
                    Button("Stop") {
                        model.update { $0.wallpaper.calibrating = false }
                    }
                } else {
                    Button("Turn widgets pink") {
                        errorMessage = nil
                        model.update { $0.wallpaper.calibrating = true }
                    }
                }
            } header: {
                Text("Step 2: Turn the widgets pink")
            } footer: {
                Text("Pink marks exactly where each widget sits. Your apps come back as soon as Step 3 is done.")
            }

            Section {
                PhotosPicker(selection: $screenshotItem, matching: .images) {
                    Label("Choose the screenshot", systemImage: "camera.viewfinder")
                }
                .disabled(sourceThumbnail == nil || busy)
                if busy {
                    ProgressView("Matching wallpaper…")
                }
            } header: {
                Text("Step 3: Screenshot")
            } footer: {
                if sourceThumbnail == nil {
                    Text("Choose your wallpaper photo first.")
                }
            }

            if let errorMessage {
                Section {
                    Text(errorMessage).foregroundStyle(.red)
                }
            }

            if !slices.isEmpty {
                Section {
                    HStack(alignment: .top, spacing: 12) {
                        slicePreview(.top, title: "Top Widget")
                        slicePreview(.large, title: "Widget")
                    }
                    Toggle("Show wallpaper behind widgets", isOn: wallpaperEnabled)
                    Button("Remove wallpaper slices", role: .destructive) {
                        WallpaperStore.shared.removeAll()
                        slices = [:]
                        model.update {
                            $0.wallpaper.enabled = false
                            $0.wallpaper.calibrating = false
                        }
                    }
                } header: {
                    Text("Result")
                } footer: {
                    Text("Text color still follows the widget background chosen in Style. Redo Steps 2 and 3 if you move the widgets or change wallpaper.")
                }
            }

            Section {
                ForEach(WallpaperProcessor.PlainWallpaper.allCases) { wallpaper in
                    Button {
                        savePlain(wallpaper)
                    } label: {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Color(wallpaper.color))
                                .strokeBorder(.secondary.opacity(0.4))
                                .frame(width: 22, height: 22)
                            Text("Save \(wallpaper.name) to Photos")
                        }
                    }
                    .tint(.primary)
                }
                if let statusMessage {
                    Text(statusMessage).foregroundStyle(.secondary)
                }
            } header: {
                Text("Plain wallpapers")
            } footer: {
                Text("Set one as your Home Screen wallpaper, then pick the matching widget background in Style. No slicing needed.")
            }

            Section("Before you screenshot") {
                Label("In Settings > Wallpaper, turn off Perspective Zoom.", systemImage: "arrow.up.left.and.arrow.down.right")
                Label("Don't use the wallpaper Blur or Tinted icons; both change how the wallpaper renders.", systemImage: "drop.fill")
                Label("Take the screenshot on the page where the widgets live.", systemImage: "rectangle.on.rectangle")
            }
        }
        .navigationTitle("Wallpaper")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if let data = WallpaperProcessor.loadSource() {
                sourceThumbnail = WallpaperProcessor.thumbnail(from: data)
            }
            slices = WallpaperProcessor.savedSlices()
        }
        .onChange(of: sourceItem) { _, item in
            guard let item else { return }
            Task { await loadSource(item) }
        }
        .onChange(of: screenshotItem) { _, item in
            guard let item else { return }
            Task { await runCalibration(item) }
        }
    }

    @ViewBuilder
    private func slicePreview(_ slot: WallpaperSlot, title: String) -> some View {
        VStack(spacing: 6) {
            if let image = slices[slot] {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: slot == .top ? 70 : 140)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            } else {
                Text("Not found")
                    .foregroundStyle(.secondary)
            }
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func loadSource(_ item: PhotosPickerItem) async {
        errorMessage = nil
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                throw WallpaperError.unreadableImage
            }
            try WallpaperProcessor.saveSource(data)
            sourceThumbnail = WallpaperProcessor.thumbnail(from: data)
        } catch {
            errorMessage = error.localizedDescription
        }
        sourceItem = nil
    }

    private func runCalibration(_ item: PhotosPickerItem) async {
        errorMessage = nil
        busy = true
        defer { busy = false; screenshotItem = nil }
        do {
            guard let screenshot = try await item.loadTransferable(type: Data.self),
                  let wallpaper = WallpaperProcessor.loadSource()
            else { throw WallpaperError.unreadableImage }
            let result = try await Task.detached(priority: .userInitiated) {
                try WallpaperProcessor.calibrate(wallpaperData: wallpaper, screenshotData: screenshot)
            }.value
            slices = result.slices
            model.update {
                $0.wallpaper.enabled = true
                $0.wallpaper.calibrating = false
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func savePlain(_ wallpaper: WallpaperProcessor.PlainWallpaper) {
        statusMessage = nil
        Task {
            do {
                guard let screen = WallpaperProcessor.currentScreen() else { throw WallpaperError.noScreen }
                let image = WallpaperProcessor.render(wallpaper, on: screen)
                try await WallpaperProcessor.saveToPhotos(image)
                statusMessage = "Saved \(wallpaper.name) to Photos. Set it as your Home Screen wallpaper and choose the \(wallpaper.theme.displayName) background in Style."
            } catch {
                statusMessage = error.localizedDescription
            }
        }
    }
}
