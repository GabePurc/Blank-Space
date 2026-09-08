import BlankSpaceCore
import SwiftUI

/// A to-scale mock of the Top Widget over Widget 1, drawn with the same views the widgets use.
struct WidgetPreviewView: View {
    let apps: [AppEntry]
    let style: LauncherStyle
    let topWidget: TopWidgetContent

    private let corner: CGFloat = 22

    var body: some View {
        VStack(spacing: 16) {
            TopContentView(date: .now, content: topWidget, style: style)
                .padding(.horizontal, WidgetInsets.horizontal)
                .padding(.vertical, WidgetInsets.vertical)
                .frame(height: 150)
                .background(style.theme.background, in: RoundedRectangle(cornerRadius: corner, style: .continuous))

            LauncherRowsView(apps: apps, style: style)
                .padding(.horizontal, WidgetInsets.horizontal)
                .padding(.vertical, WidgetInsets.vertical)
                .frame(height: 330)
                .clipped()
                .background(style.theme.background, in: RoundedRectangle(cornerRadius: corner, style: .continuous))
        }
        .padding(16)
        .frame(maxWidth: 360)
        .frame(maxWidth: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    WidgetPreviewView(apps: LauncherDocument.starter.pages[0].apps, style: LauncherStyle(), topWidget: .date)
}
