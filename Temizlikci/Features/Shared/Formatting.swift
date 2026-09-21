import Foundation

/// System formatters for sizes and shares, so every number reads the same way across the app.
enum Formatting {
    static func bytes(_ value: Int64) -> String {
        value.formatted(.byteCount(style: .file))
    }

    static func percent(_ fraction: Double) -> String {
        fraction.formatted(.percent.precision(.fractionLength(fraction < 0.01 ? 1 : 0)))
    }

    static func count(_ value: Int) -> String {
        value.formatted()
    }
}
