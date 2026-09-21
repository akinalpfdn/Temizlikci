import QuickLook
import SwiftUI

/// A location's scan: empty state, progress, results (breadcrumb, chart, list), or failure.
struct OverviewView: View {
    @Bindable var model: LocationScanModel
    let onChooseFolder: () -> Void

    var body: some View {
        switch model.phase {
        case .idle:
            emptyState
        case .failed(let message, let suggestion):
            failure(message: message, suggestion: suggestion)
        case .scanning, .finished:
            results
                .searchable(text: $model.searchText, placement: .toolbar, prompt: Text(L10n.Navigation.searchPrompt))
                .quickLookPreview($model.previewURL)
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label { Text(L10n.Overview.emptyTitle) } icon: { Image(systemName: "chart.pie") }
        } description: {
            Text(L10n.Overview.emptyMessage)
        } actions: {
            Button { model.startScan() } label: { Text(L10n.Scan.scanLocation(model.location.displayName)) }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            Button(action: onChooseFolder) { Text(L10n.Sidebar.chooseFolder) }
        }
    }

    private func failure(message: String, suggestion: String?) -> some View {
        ContentUnavailableView {
            Label { Text(L10n.Scan.failedTitle) } icon: { Image(systemName: "exclamationmark.triangle") }
        } description: {
            Text([message, suggestion].compactMap { $0 }.joined(separator: " "))
        } actions: {
            Button { model.startScan() } label: { Text(L10n.Scan.tryAgain) }
        }
    }

    private var results: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            BreadcrumbBar(model: model)
            HStack(alignment: .top, spacing: Spacing.xLarge) {
                VStack(spacing: Spacing.small) {
                    SunburstView(model: model)
                        .frame(minWidth: ChartMetrics.minimumSide, maxWidth: ChartMetrics.maximumSide,
                               minHeight: ChartMetrics.minimumSide, maxHeight: ChartMetrics.maximumSide)
                    Text(L10n.Scan.chartHint)
                        .font(Typography.chartCaption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: ChartMetrics.maximumSide)
                ContentsTable(model: model)
            }
            footer
        }
        .padding(Spacing.large)
    }

    @ViewBuilder
    private var footer: some View {
        if let finishedAt = model.finishedAt, let result = model.result {
            HStack {
                Text(L10n.Scan.scannedFooter(
                    date: finishedAt.formatted(date: .abbreviated, time: .shortened),
                    duration: result.duration.formatted(.units(allowed: [.minutes, .seconds], width: .wide))
                ))
                Spacer()
                Text(L10n.Scan.sizesFooter)
            }
            .font(Typography.chartCaption)
            .foregroundStyle(.secondary)
        }
    }
}

/// The path from the scanned location to the folder shown in the chart. Each part opens that folder.
struct BreadcrumbBar: View {
    let model: LocationScanModel

    var body: some View {
        HStack(spacing: Spacing.xSmall) {
            ForEach(Array(model.path.enumerated()), id: \.element.id) { index, folder in
                if index > 0 {
                    Image(systemName: "chevron.right")
                        .font(Typography.chartCaption)
                        .foregroundStyle(.tertiary)
                        .accessibilityHidden(true)
                }
                let isCurrent = index == model.path.count - 1
                Button { model.goToAncestor(at: index) } label: {
                    Text(model.title(for: folder))
                        .fontWeight(isCurrent ? .semibold : .regular)
                        .foregroundStyle(isCurrent ? .primary : .secondary)
                }
                .buttonStyle(.borderless)
                .disabled(isCurrent || !model.hasResult)
            }
        }
        .lineLimit(1)
        .accessibilityElement(children: .contain)
    }
}
