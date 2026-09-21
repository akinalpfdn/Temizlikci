import Foundation

/// A place that can be scanned, as the person sees it.
struct ScanLocation: Equatable {
    let url: URL
    let displayName: String
    /// True for the startup disk: its results include the volume's unattributed space.
    let isWholeVolume: Bool
}
