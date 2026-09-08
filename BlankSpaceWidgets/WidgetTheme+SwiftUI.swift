import BlankSpaceCore
import SwiftUI

extension WidgetTheme {
    var background: Color {
        switch self {
        case .light: return .white
        case .dark: return Color(red: 0.11, green: 0.11, blue: 0.12)
        case .black: return .black
        }
    }

    var foreground: Color {
        self == .light ? .black : .white
    }
}

extension TextAlignmentOption {
    var horizontalAlignment: HorizontalAlignment {
        switch self {
        case .leading: return .leading
        case .center: return .center
        case .trailing: return .trailing
        }
    }

    var frameAlignment: Alignment {
        switch self {
        case .leading: return .leading
        case .center: return .center
        case .trailing: return .trailing
        }
    }
}

extension FontDesignOption {
    var design: Font.Design {
        switch self {
        case .standard: return .default
        case .rounded: return .rounded
        case .serif: return .serif
        case .monospaced: return .monospaced
        }
    }
}
