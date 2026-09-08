import BlankSpaceCore
import SwiftUI

/// A to-scale mock of the Top Widget over Widget 1, drawn with the same views the widgets use.
struct WidgetPreviewView: View {
    let apps: [AppEntry]
    let style: LauncherStyle
    let topWidget: TopWidgetContent
    var topImage: UIImage? = nil
    var largeImage: UIImage? = nil

    private let corner: CGFloat = 22

    var body: some View {
        VStack(spacing: 16) {
            TopContentView(date: .now, content: topWidget, style: style)
                .padding(.horizontal, WidgetInsets.horizontal)
                .padding(.vertical, WidgetInsets.vertical)
                .frame(height: 150)
                .background { background(topImage) }

            LauncherRowsView(apps: apps, style: style)
                .padding(.horizontal, WidgetInsets.horizontal)
                .padding(.vertical, WidgetInsets.vertical)
                .frame(height: 330)
                .clipped()
                .background { background(largeImage) }
        }
        .padding(16)
        .frame(maxWidth: 360)
        .frame(maxWidth: .infinity)
        .background(Color(.systemGroupedBackground))
    }

    @ViewBuilder
    private func background(_ image: UIImage?) -> some View {
        let shape = RoundedRectangle(cornerRadius: corner, style: .continuous)
        if let image {
            Color.clear
                .overlay { Image(uiImage: image).resizable().scaledToFill() }
                .clipShape(shape)
        } else {
            shape.fill(style.theme.background)
        }
    }
}

#Preview {
    WidgetPreviewView(apps: LauncherDocument.starter.pages[0].apps, style: LauncherStyle(), topWidget: .date)
}
