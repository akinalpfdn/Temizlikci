import SwiftUI

/// Text roles from the approved design. All are system text styles so they follow
/// the person's text size settings; sizes that line up in columns use monospaced digits.
enum Typography {
    static let chartCenterName = Font.callout.weight(.semibold)
    static let chartCenterValue = Font.title.weight(.semibold).monospacedDigit()
    static let chartCaption = Font.caption
    static let listSize = Font.body.monospacedDigit()
    static let badge = Font.caption2.weight(.semibold)
}
