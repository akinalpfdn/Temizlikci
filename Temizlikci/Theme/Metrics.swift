import SwiftUI

enum Spacing {
    static let xxSmall: CGFloat = 2
    static let xSmall: CGFloat = 4
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let xLarge: CGFloat = 24
}

enum CornerRadius {
    static let small: CGFloat = 6
    static let medium: CGFloat = 12
}

enum WindowMetrics {
    static let minimumSize = CGSize(width: 900, height: 600)
    static let defaultSize = CGSize(width: 1260, height: 780)
    static let sidebarWidth = (minimum: CGFloat(200), ideal: CGFloat(232), maximum: CGFloat(300))
    static let inspectorWidth = (minimum: CGFloat(240), ideal: CGFloat(260), maximum: CGFloat(340))
}

enum ChartMetrics {
    static let minimumSide: CGFloat = 300
    static let maximumSide: CGFloat = 520
    /// Ring-1 segments at least this wide (radians) get a text label.
    static let labelMinimumSweep = 0.42
}
