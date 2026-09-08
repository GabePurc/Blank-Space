import BlankSpaceCore
import SwiftUI

/// Widget appearance. Edits a local copy and saves once on Done.
struct StyleView: View {
    @Environment(LauncherModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    @State private var style: LauncherStyle
    @State private var topWidget: TopWidgetContent
    @State private var slices: [WallpaperSlot: UIImage] = [:]

    init(style: LauncherStyle, topWidget: TopWidgetContent) {
        _style = State(initialValue: style)
        _topWidget = State(initialValue: topWidget)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    WidgetPreviewView(
                        apps: model.document.page(at: 0).apps,
                        style: style,
                        topWidget: topWidget,
                        topImage: slices[.top],
                        largeImage: slices[.large]
                    )
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }

                Section {
                    Picker("Background", selection: $style.theme) {
                        ForEach(WidgetTheme.allCases, id: \.self) { Text($0.displayName).tag($0) }
                    }
                    .pickerStyle(.segmented)

                    Picker("Alignment", selection: $style.alignment) {
                        ForEach(TextAlignmentOption.allCases, id: \.self) {
                            Image(systemName: $0.symbolName).tag($0)
                        }
                    }
                    .pickerStyle(.segmented)

                    Picker("Font", selection: $style.fontDesign) {
                        ForEach(FontDesignOption.allCases, id: \.self) { Text($0.displayName).tag($0) }
                    }

                    sliderRow("Size", value: $style.textSize, range: LauncherStyle.textSizeRange)
                    sliderRow("Spacing", value: $style.lineSpacing, range: LauncherStyle.lineSpacingRange)
                } header: {
                    Text("Widget")
                } footer: {
                    if !slices.isEmpty {
                        Text("Wallpaper slices are on, so Background only sets the text color.")
                    }
                }

                Section("Top widget") {
                    Picker("Shows", selection: $topWidget) {
                        ForEach(TopWidgetContent.allCases, id: \.self) { Text($0.displayName).tag($0) }
                    }
                }

                Section {
                    Button("Reset to defaults") {
                        style = LauncherStyle()
                        topWidget = .date
                    }
                }
            }
            .navigationTitle("Style")
            .task {
                if model.document.wallpaper.enabled {
                    slices = WallpaperProcessor.savedSlices()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        model.update {
                            $0.style = style
                            $0.topWidget = topWidget
                        }
                        dismiss()
                    }
                }
            }
        }
    }

    private func sliderRow(_ title: String, value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                Spacer()
                Text(value.wrappedValue, format: .number.precision(.fractionLength(0)))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Slider(value: value, in: range, step: 1)
        }
    }
}
