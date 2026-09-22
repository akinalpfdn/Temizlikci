import SwiftUI

/// The biggest changes between the two latest scans of a location.
struct WhatGrewView: View {
    let main: MainViewModel

    var body: some View {
        content.task { main.loadSavedGrowth() }
    }

    @ViewBuilder
    private var content: some View {
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

    private var grew: [GrowthChange] { changes.filter { $0.delta >= 0 } }
    private var shrank: [GrowthChange] { changes.filter { $0.delta < 0 } }
    private var largest: Int64 { changes.map { abs($0.delta) }.max() ?? 0 }
    private var net: Int64 { changes.reduce(0) { $0 + $1.delta } }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text(L10n.Growth.header(scan.location.displayName, date: WhatGrewView.date(report.previousDate)))
                .font(.title2.weight(.semibold))
            Text(L10n.Growth.net(signed(net)))
                .foregroundStyle(.secondary)
            if scan.growthIsFromSavedScans {
                Text(L10n.Growth.fromSavedScans(WhatGrewView.date(report.currentDate)))
                    .font(Typography.chartCaption)
                    .foregroundStyle(.secondary)
            }
            List {
                section(L10n.Growth.grewSection, symbol: "arrow.up.right", ink: GrowthPalette.upInk, items: grew)
                section(L10n.Growth.shrankSection, symbol: "arrow.down.right", ink: GrowthPalette.downInk, items: shrank)
            }
        }
        .padding(Spacing.large)
    }

    @ViewBuilder
    private func section(_ title: LocalizedStringResource, symbol: String, ink: Color, items: [GrowthChange]) -> some View {
        if !items.isEmpty {
            Section {
                ForEach(items) { change in row(change) }
            } header: {
                HStack(spacing: Spacing.xSmall) {
                    Image(systemName: symbol)
                    Text(title)
                    Spacer()
                    Text(signed(items.reduce(0) { $0 + $1.delta })).monospacedDigit()
                }
                .font(Typography.badge)
                .foregroundStyle(ink)
            }
        }
    }

    private func row(_ change: GrowthChange) -> some View {
        HStack(spacing: Spacing.medium) {
            VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                Text((change.path as NSString).lastPathComponent)
                Text(change.path)
                    .font(Typography.chartCaption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                GrowthBar(change: change, largest: largest)
                    .padding(.top, Spacing.xxSmall)
            }
            Spacer(minLength: Spacing.medium)
            detail(for: change)
            GrowthLabel(change: change)
                .frame(minWidth: 108, alignment: .trailing)
            Button { main.show(change, in: scan) } label: { Text(L10n.Growth.showInChart) }
                .disabled(change.kind == .removed || !scan.hasResult)
        }
        .padding(.vertical, Spacing.xxSmall)
    }

    private func signed(_ bytes: Int64) -> String {
        (bytes >= 0 ? "+" : "−") + Formatting.bytes(abs(bytes))
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
