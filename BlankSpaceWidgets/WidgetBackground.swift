import BlankSpaceCore
import SwiftUI
import UIKit

/// What a widget paints behind its text.
enum WidgetBackground {
    case theme(WidgetTheme)
    /// Solid pink so a screenshot reveals the widget's exact frame.
    case calibration
    case image(UIImage)

    static func current(for slot: WallpaperSlot, document: LauncherDocument) -> WidgetBackground {
        if document.wallpaper.calibrating {
            return .calibration
        }
        if document.wallpaper.enabled,
           let data = WallpaperStore.shared.imageData(for: slot),
           let image = UIImage(data: data) {
            return .image(image)
        }
        return .theme(document.style.theme)
    }

    var isCalibration: Bool {
        if case .calibration = self { return true }
        return false
    }
}

struct WidgetBackgroundView: View {
    let background: WidgetBackground

    var body: some View {
        switch background {
        case .theme(let theme):
            theme.background
        case .calibration:
            CalibrationColor.swiftUIColor
        case .image(let image):
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        }
    }
}
