import QuickLook
import SwiftUI

/// A location's scan: empty state, progress, results (breadcrumb, chart, list), or failure.
struct OverviewView: View {
    @Bindable var model: LocationScanModel
    let main: MainViewModel
    @Environment(\.undoManager) private var undoManager
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        switch model.phase {
        case .idle:
            emptyState
        case .failed(let message, let suggestion):
            failure(message: message, suggestion: suggestion)
        case .scanning, .finished:
            results
                .searchable(text: $model.searchText, placement: .toolbar, prompt: Text(L10n.Navigation.searchPrompt))
                .searchFocused($isSearchFocused)
                .onChange(of: main.searchFocusRequest) { isSearchFocused = true }
                .quickLookPreview($model.previewURL)
                .overlay(alignment: .bottom) { trashConfirmation }
                .modifier(ActionErrorAlert(model: model))
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
            Button { Task { await main.chooseFolder() } } label: { Text(L10n.Sidebar.chooseFolder) }
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
            if model.hasResult && main.shouldShowAccessBanner(for: model) {
                AccessBanner(skippedCount: model.result?.inaccessibleCount ?? 0, main: main)
            }
            GeometryReader { proxy in
                let side = Self.chartSide(for: proxy.size)
                HStack(alignment: .top, spacing: Spacing.xLarge) {
                    VStack(spacing: Spacing.small) {
                        SunburstView(model: model)
                            .frame(width: side, height: side)
                        Text(L10n.Scan.chartHint)
                            .font(Typography.chartCaption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .frame(width: side)
                    }
                    ContentsTable(model: model)
                        .frame(minWidth: ChartMetrics.listMinimumWidth)
                }
            }
            footer
        }
        .padding(Spacing.large)
    }

    /// The chart takes what's left after the list's minimum width, within its size limits and the height.
    private static func chartSide(for size: CGSize) -> CGFloat {
        let hintHeight: CGFloat = 32
        let byWidth = size.width - ChartMetrics.listMinimumWidth - Spacing.xLarge
        let bySpace = min(byWidth, size.height - hintHeight)
        return min(ChartMetrics.maximumSide, max(ChartMetrics.minimumSide, bySpace))
    }

    private var trashConfirmation: some View {
        TrashConfirmation(model: model)
    }

    @ViewBuilder
    private var footer: some View {
        if let finishedAt = model.finishedAt, let result = model.result {
            HStack {
                if model.isOutdated {
                    Label { Text(L10n.Trash.rescanSuggestion) } icon: { Image(systemName: "arrow.clockwise") }
                }
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
                if index == model.path.count - 1 {
                    Text(model.title(for: folder))
                        .fontWeight(.semibold)
                } else {
                    Button { model.goToAncestor(at: index) } label: {
                        Text(model.title(for: folder)).foregroundStyle(.secondary)
                    }
                    .buttonStyle(.borderless)
                    .disabled(!model.hasResult)
                }
            }
        }
        .lineLimit(1)
        .accessibilityElement(children: .contain)
    }
}

/// Shown after a scan skipped protected folders: asks for Full Disk Access once, in context (HIG Privacy).
struct AccessBanner: View {
    let skippedCount: Int
    let main: MainViewModel

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.medium) {
            Image(systemName: "lock")
                .foregroundStyle(.tint)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                Text(L10n.Access.bannerTitle).fontWeight(.semibold)
                Text(L10n.Access.bannerMessage(Formatting.count(skippedCount)))
                    .foregroundStyle(.secondary)
                Text(L10n.Access.relaunchHint)
                    .font(Typography.chartCaption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: Spacing.medium)
            Button { main.isAccessBannerDismissed = true } label: { Text(L10n.Access.notNow) }
            Button { main.openPrivacySettings() } label: { Text(L10n.Access.openSettings) }
                .buttonStyle(.borderedProminent)
        }
        .padding(Spacing.medium)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: CornerRadius.medium))
        .accessibilityElement(children: .contain)
    }
}

/// The transient "Moved to the Trash" confirmation with Undo, shared by the overview and the Developer view.
struct TrashConfirmation: View {
    let model: LocationScanModel

    var body: some View {
        if let record = model.lastTrashed {
            HStack(spacing: Spacing.medium) {
                Text(L10n.Trash.moved(name: record.node.name, size: Formatting.bytes(record.node.allocatedSize)))
                    .lineLimit(2)
                Button { model.putBack(record) } label: { Text(L10n.Trash.undo) }
            }
            .padding(.horizontal, Spacing.large)
            .padding(.vertical, Spacing.small)
            .glassEffect(.regular, in: .capsule)
            .padding(.bottom, Spacing.xLarge)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .task(id: record.id) {
                // Sleep only fails on cancellation, when a newer confirmation replaces this one.
                try? await Task.sleep(for: .seconds(8))
                if model.lastTrashed?.id == record.id { model.dismissTrashConfirmation() }
            }
        }
    }
}

/// Shows a failed action's message and next step.
struct ActionErrorAlert: ViewModifier {
    @Bindable var model: LocationScanModel

    func body(content: Content) -> some View {
        content.alert(item: $model.actionError) { error in
            Alert(
                title: Text(error.message),
                message: error.suggestion.map(Text.init),
                dismissButton: .default(Text(L10n.Alerts.ok))
            )
        }
    }
}
