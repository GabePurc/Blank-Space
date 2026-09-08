import SwiftUI

extension WidgetTheme {
    public var background: Color {
        switch self {
        case .light: return .white
        case .dark: return Color(red: 0.11, green: 0.11, blue: 0.12)
        case .black: return .black
        }
    }

    public var foreground: Color {
        self == .light ? .black : .white
    }

    public var displayName: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .black: return "Black"
        }
    }
}

extension TextAlignmentOption {
    public var horizontalAlignment: HorizontalAlignment {
        switch self {
        case .leading: return .leading
        case .center: return .center
        case .trailing: return .trailing
        }
    }

    public var frameAlignment: Alignment {
        switch self {
        case .leading: return .leading
        case .center: return .center
        case .trailing: return .trailing
        }
    }

    public var displayName: String {
        switch self {
        case .leading: return "Left"
        case .center: return "Center"
        case .trailing: return "Right"
        }
    }

    public var symbolName: String {
        switch self {
        case .leading: return "text.alignleft"
        case .center: return "text.aligncenter"
        case .trailing: return "text.alignright"
        }
    }
}

extension FontDesignOption {
    public var design: Font.Design {
        switch self {
        case .standard: return .default
        case .rounded: return .rounded
        case .serif: return .serif
        case .monospaced: return .monospaced
        }
    }

    public var displayName: String {
        switch self {
        case .standard: return "SF Pro"
        case .rounded: return "Rounded"
        case .serif: return "Serif"
        case .monospaced: return "Mono"
        }
    }
}

extension TopWidgetContent {
    public var displayName: String {
        switch self {
        case .blank: return "Blank"
        case .date: return "Date"
        case .weekday: return "Day of week"
        }
    }
}

extension LauncherStyle {
    public var font: Font {
        .system(size: textSize, weight: .medium, design: fontDesign.design)
    }

    public static let textSizeRange: ClosedRange<Double> = 14...34
    public static let lineSpacingRange: ClosedRange<Double> = 0...18
}

extension CalibrationColor {
    /// Solid pink drawn by the widgets while calibrating.
    public static var swiftUIColor: Color {
        Color(red: red, green: green, blue: blue)
    }
}
