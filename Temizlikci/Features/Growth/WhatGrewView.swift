import SwiftUI

/// The biggest changes between the two latest scans of a location.
struct WhatGrewView: View {
    let main: MainViewModel

    var body: some View {
        if let scan = main.growthScan, let report = scan.growth {
            let changes = report.biggestChanges()
            if changes.isEmpty {
                ContentUnavailableView {
                    Label { Text(L10n.Growth.noChangesTitle) } icon: { Image(systemName: "checkmark.circle") }
                } description: {
                    Text(L10n.Growth.noChangesMessage(Self.date(report.previousDate)))
                }
            } else {
                GrowthList(main: main, scan: scan, report: report, changes: changes)
            }
        } else {
            ContentUnavailableView {
                Label { Text(L10n.Growth.emptyTitle) } icon: { Image(systemName: "chart.line.uptrend.xyaxis") }
            } description: {
                Text(L10n.Growth.emptyMessage)
            }
        }
    }

    static func date(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .shortened)
    }
}

private struct GrowthList: View {
    let main: MainViewModel
    let scan: LocationScanModel
    let report: GrowthReport
    let changes: [GrowthChange]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Text(L10n.Growth.header(scan.location.displayName, date: WhatGrewView.date(report.previousDate)))
                .font(.title2.weight(.semibold))
            List(changes) { change in
                HStack(spacing: Spacing.medium) {
                    VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                        Text((change.path as NSString).lastPathComponent)
                        Text(change.path)
                            .font(Typography.chartCaption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    Spacer(minLength: Spacing.medium)
                    detail(for: change)
                    GrowthLabel(change: change)
                        .frame(minWidth: 96, alignment: .trailing)
                    Button { main.show(change, in: scan) } label: { Text(L10n.Growth.showInChart) }
                        .disabled(change.kind == .removed)
                }
                .padding(.vertical, Spacing.xxSmall)
            }
        }
        .padding(Spacing.large)
    }

    @ViewBuilder
    private func detail(for change: GrowthChange) -> some View {
        switch change.kind {
        case .removed:
            Text(L10n.Growth.removed).foregroundStyle(.secondary)
        case .grew, .shrank, .appeared:
            if let previous = change.previous {
                Text(L10n.Growth.previous(Formatting.bytes(previous)))
                    .font(Typography.chartCaption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
