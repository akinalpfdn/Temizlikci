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
    static let minimumSize = CGSize(width: 1100, height: 640)
    static let defaultSize = CGSize(width: 1380, height: 820)
    static let sidebarWidth = (minimum: CGFloat(200), ideal: CGFloat(232), maximum: CGFloat(300))
    static let inspectorWidth = (minimum: CGFloat(220), ideal: CGFloat(240), maximum: CGFloat(320))
}

enum ChartMetrics {
    static let minimumSide: CGFloat = 240
    static let maximumSide: CGFloat = 520
    /// The list keeps at least this width; the chart shrinks first (developer feedback: the list scrolled sideways).
    static let listMinimumWidth: CGFloat = 380
    /// Ring-1 segments at least this wide (radians) get a text label.
    static let labelMinimumSweep = 0.42
}
