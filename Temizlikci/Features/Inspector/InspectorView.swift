import SwiftUI

/// Details and actions for the selected item, or for the current folder when nothing is selected.
struct InspectorView: View {
    let scan: LocationScanModel?

    var body: some View {
        if let scan, scan.tree != nil, let node = scan.selection ?? scan.currentFolder {
            NodeDetailsView(scan: scan, node: node)
        } else {
            ContentUnavailableView {
                Label { Text(L10n.Inspector.noSelectionTitle) } icon: { Image(systemName: "info.circle") }
            } description: {
                Text(L10n.Inspector.noSelectionMessage)
            }
        }
    }
}

private struct NodeDetailsView: View {
    let scan: LocationScanModel
    let node: FileNode
    @Environment(\.undoManager) private var undoManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.large) {
                header
                details
                if let match = scan.cleanupMatch(for: node) {
                    VStack(alignment: .leading, spacing: Spacing.small) {
                        SafetyBadge(level: match.rule.safety)
                        Text(match.rule.reason)
                            .font(Typography.chartCaption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(Spacing.medium)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: CornerRadius.medium))
                }
                if node.kind == .unattributed, scan.location.isWholeVolume {
                    SpaceBreakdownView(breakdown: scan.spaceBreakdown)
                }
                if let explanation {
                    Text(explanation)
                        .font(Typography.chartCaption)
                        .foregroundStyle(.secondary)
                        .padding(Spacing.medium)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: CornerRadius.medium))
                }
                if scan.actionableURL(for: node) != nil {
                    VStack(spacing: Spacing.small) {
                        Button { scan.revealInFinder() } label: { Text(L10n.Details.revealInFinder).frame(maxWidth: .infinity) }
                        Button { scan.quickLook() } label: { Text(L10n.Details.quickLook).frame(maxWidth: .infinity) }
                        if scan.canMoveToTrash(node) {
                            Button { scan.moveToTrash(node, undoManager: undoManager) } label: {
                                Text(L10n.Trash.moveToTrash).frame(maxWidth: .infinity)
                            }
                        }
                    }
                    .controlSize(.large)
                }
            }
            .padding(Spacing.large)
        }
    }

    private var header: some View {
        HStack(spacing: Spacing.medium) {
            Image(systemName: symbol)
                .font(.title2)
                .foregroundStyle(.secondary)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                Text(scan.title(for: node))
                    .font(.headline)
                    .textSelection(.enabled)
                Text(kind)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            LabeledContent { Text(Formatting.bytes(node.allocatedSize)).monospacedDigit() } label: { Text(L10n.Details.size) }
            if let share = scan.share(of: node, in: scan.tree), node.id != scan.tree?.id {
                LabeledContent { Text(Formatting.percent(share)) } label: { Text(L10n.Details.shareOfScan) }
            }
            if let parent = scan.parent(of: node), let share = scan.share(of: node, in: parent) {
                LabeledContent { Text(Formatting.percent(share)) } label: { Text(L10n.Details.shareOfFolder) }
            }
            if let change = scan.growth(for: node), let report = scan.growth {
                LabeledContent { GrowthLabel(change: change) } label: {
                    Text(L10n.Growth.inspectorChange(report.previousDate.formatted(date: .abbreviated, time: .omitted)))
                }
            }
            if node.fileCount > 0 {
                LabeledContent { Text(Formatting.count(node.fileCount)) } label: { Text(L10n.Details.files) }
            }
            if let modified = node.modificationDate {
                LabeledContent { Text(modified.formatted(date: .abbreviated, time: .shortened)) } label: { Text(L10n.Details.modified) }
            }
            if let url = scan.actionableURL(for: node) {
                VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                    Text(L10n.Details.path).foregroundStyle(.secondary)
                    Text(url.path(percentEncoded: false))
                        .font(.caption.monospaced())
                        .textSelection(.enabled)
                }
            }
        }
    }

    private var symbol: String {
        switch node.kind {
        case .directory: "folder"
        case .file: "doc"
        case .smallerFiles: "doc.on.doc"
        case .inaccessible: "lock"
        case .unattributed: "internaldrive"
        case .pending: "hourglass"
        }
    }

    private var kind: String {
        switch node.kind {
        case .directory: String(localized: L10n.Nodes.folderKind)
        case .file: String(localized: L10n.Nodes.fileKind)
        case .smallerFiles: String(localized: L10n.Nodes.smallerFilesKind)
        case .inaccessible: String(localized: L10n.Nodes.protectedKind)
        case .unattributed: String(localized: L10n.Nodes.unattributedKind)
        case .pending: String(localized: L10n.Nodes.pendingKind)
        }
    }

    private var explanation: String? {
        switch node.kind {
        case .smallerFiles: String(localized: L10n.Details.smallerFilesExplanation)
        case .inaccessible: String(localized: L10n.Details.inaccessibleExplanation)
        case .unattributed: String(localized: L10n.Details.unattributedExplanation)
        case .pending: String(localized: L10n.Details.pendingExplanation)
        case .directory, .file: nil
        }
    }
}
