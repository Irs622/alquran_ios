import SwiftUI

extension Color {
    static let companionIvory = Color(red: 0.98, green: 0.96, blue: 0.91)
    static let companionBackground = Color(red: 0.96, green: 0.94, blue: 0.88)
    static let companionSurface = Color(red: 0.92, green: 0.89, blue: 0.80)
    static let companionCard = Color(red: 0.99, green: 0.98, blue: 0.95)
    static let companionEmerald = Color(red: 0.06, green: 0.43, blue: 0.36)
    static let companionTeal = Color(red: 0.05, green: 0.32, blue: 0.27)
    static let companionAccent = Color(red: 0.06, green: 0.43, blue: 0.36)
    static let companionGold = Color(red: 0.83, green: 0.69, blue: 0.22)
    static let companionText = Color(red: 0.08, green: 0.16, blue: 0.13)
    static let companionTextSecondary = Color(red: 0.33, green: 0.40, blue: 0.35)
    static let companionMuted = Color(red: 0.46, green: 0.51, blue: 0.45)
    static let companionShadow = Color.black.opacity(0.08)
}

extension Font {
    static func companionTitle() -> Font {
        .system(size: UIFont.preferredFont(forTextStyle: .largeTitle).pointSize, weight: .bold, design: .default)
    }

    static func companionHeading(_ style: Font.TextStyle = .title) -> Font {
        .system(size: UIFont.preferredFont(forTextStyle: style.toUIFontTextStyle).pointSize, weight: .bold, design: .default)
    }

    static func companionBody(_ style: Font.TextStyle = .body) -> Font {
        .system(size: UIFont.preferredFont(forTextStyle: style.toUIFontTextStyle).pointSize, weight: .regular, design: .default)
    }

    static func companionSubheadline() -> Font {
        .system(size: UIFont.preferredFont(forTextStyle: .subheadline).pointSize, weight: .medium, design: .default)
    }

    static func companionArabic(_ style: Font.TextStyle = .title) -> Font {
        .custom("UthmaniHafs", size: UIFont.preferredFont(forTextStyle: style.toUIFontTextStyle).pointSize, relativeTo: style)
    }
}

private extension Font.TextStyle {
    var toUIFontTextStyle: UIFont.TextStyle {
        switch self {
        case .largeTitle: return .largeTitle
        case .title: return .title1
        case .title2: return .title2
        case .title3: return .title3
        case .headline: return .headline
        case .subheadline: return .subheadline
        case .body: return .body
        case .callout: return .callout
        case .footnote: return .footnote
        case .caption: return .caption1
        case .caption2: return .caption2
        default: return .body
        }
    }
}

extension QuickAction {
    var tintColor: Color {
        switch tint {
        case .sage: return Color(red: 0.28, green: 0.48, blue: 0.36)
        case .gold: return .companionGold
        case .emerald: return .companionEmerald
        case .sand: return Color(red: 0.94, green: 0.87, blue: 0.72)
        }
    }
}
