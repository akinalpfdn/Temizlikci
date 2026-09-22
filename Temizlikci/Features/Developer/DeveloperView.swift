import Charts
import SwiftUI

/// Developer artifacts found by the cleanup rules, grouped by ecosystem, plus simulator management.
struct DeveloperView: View {
    let main: MainViewModel

    var body: some View {
        if let scan = main.developerScan {
            DeveloperResults(main: main, scan: scan)
        } else {
            ContentUnavailableView {
                Label { Text(L10n.Insights.notScannedTitle) } icon: { Image(systemName: "hammer") }
            } description: {
                Text(L10n.Cleanup.scanFirst)
            } actions: {
                Button { main.scanHome() } label: { Text(L10n.Cleanup.scanHome) }
                    .buttonStyle(.borderedProminent)
            }
        }
    }
}

private struct DeveloperResults: View {
    let main: MainViewModel
    let scan: LocationScanModel
    @Environment(\.undoManager) private var undoManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var runtimeToDelete: SimulatorRuntime?
    @State private var isConfirmingUnavailable = false

    private static let simulatorsAnchor = "simulators"

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xLarge) {
                    summary
                    StaleProjectsSection(scan: scan)
                    ForEach(Ecosystem.allCases, id: \.self) { ecosystem in
                        let matches = scan.cleanupMatches.filter { $0.rule.ecosystem == ecosystem }
                        if !matches.isEmpty {
                            group(ecosystem, matches: matches) { proxy.scrollTo(Self.simulatorsAnchor, anchor: .top) }
                        }
                    }
                    simulatorSection.id(Self.simulatorsAnchor)
                }
                .padding(Spacing.large)
            }
        }
        .overlay(alignment: .bottom) { TrashConfirmation(model: scan) }
        .modifier(ActionErrorAlert(model: scan))
        .task { if !main.simulators.hasLoaded { await main.simulators.load() } }
        .onChange(of: main.simulators.didChangeDisk) { _, changed in
            if changed { main.simulatorsDidChangeDisk() }
        }
        .alert(item: Binding(get: { main.simulators.error }, set: { main.simulators.error = $0 })) { error in
            Alert(title: Text(error.message), message: error.suggestion.map(Text.init), dismissButton: .default(Text(L10n.Alerts.ok)))
        }
    }

    // MARK: Summary

    private var summary: some View {
        let totals = SafetyLevel.allCases.map { level in
            (level: level, bytes: scan.cleanupMatches.filter { $0.rule.safety == level }.reduce(Int64(0)) { $0 + $1.node.allocatedSize })
        }
        return VStack(alignment: .leading, spacing: Spacing.small) {
            Text(L10n.Cleanup.summaryTitle).font(.title2.weight(.semibold))
            Text(L10n.Cleanup.sourceScan(scan.location.displayName)).foregroundStyle(.secondary)
            Chart(totals.filter { $0.bytes > 0 }, id: \.level) { item in
                BarMark(x: .value(String(localized: L10n.Chart.sizeAxis), item.bytes), stacking: .standard)
                    .foregroundStyle(ChartPalette.color(for: .safety(item.level), colorScheme: colorScheme) ?? ChartPalette.neutral)
                    .accessibilityLabel(Text(item.level.title))
                    .accessibilityValue(Text(Formatting.bytes(item.bytes)))
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .frame(height: 16)
            .clipShape(Capsule())
            HStack(spacing: Spacing.xLarge) {
                ForEach(totals, id: \.level) { item in
                    HStack(spacing: Spacing.xSmall) {
                        SafetyBadge(level: item.level)
                        Text(Formatting.bytes(item.bytes)).font(Typography.listSize)
                    }
                }
            }
        }
    }

    // MARK: Groups

    private func group(_ ecosystem: Ecosystem, matches: [CleanupMatch], showSimulators: @escaping () -> Void) -> some View {
        let reclaimable = matches.filter { $0.rule.safety != .keep }.reduce(Int64(0)) { $0 + $1.node.allocatedSize }
        return VStack(alignment: .leading, spacing: Spacing.small) {
            HStack {
                Text(ecosystem.title).font(.headline)
                Spacer()
                if reclaimable > 0 {
                    Text(L10n.Cleanup.reclaimable(Formatting.bytes(reclaimable))).foregroundStyle(.secondary)
                }
            }
            VStack(spacing: 0) {
                ForEach(Array(matches.enumerated()), id: \.element.id) { index, match in
                    if index > 0 { Divider() }
                    row(match, showSimulators: showSimulators)
                }
            }
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: CornerRadius.medium))
        }
    }

    private func row(_ match: CleanupMatch, showSimulators: @escaping () -> Void) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.medium) {
            VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                Text(match.node.name)
                Text(match.node.url.path(percentEncoded: false))
                    .font(Typography.chartCaption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text(match.rule.reason)
                    .font(Typography.chartCaption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: Spacing.medium)
            SafetyBadge(level: match.rule.safety)
            Text(Formatting.bytes(match.node.allocatedSize))
                .font(Typography.listSize)
                .frame(minWidth: 72, alignment: .trailing)
            action(for: match, showSimulators: showSimulators)
                .frame(minWidth: 150, alignment: .trailing)
        }
        .padding(Spacing.medium)
    }

    @ViewBuilder
    private func action(for match: CleanupMatch, showSimulators: @escaping () -> Void) -> some View {
        switch match.rule.action {
        case .moveToTrash:
            Button { scan.moveToTrash(match, undoManager: undoManager) } label: { Text(L10n.Trash.moveToTrash) }
        case .manageSimulators:
            Button(action: showSimulators) { Text(L10n.Cleanup.manageSimulators) }
        case .openAndroidStudio:
            Button { main.openAndroidStudio() } label: { Text(L10n.Cleanup.openAndroidStudio) }
                .disabled(!main.isAndroidStudioInstalled)
        case .none:
            EmptyView()
        }
    }

    // MARK: Simulators

    private var simulatorSection: some View {
        let simulators = main.simulators
        return VStack(alignment: .leading, spacing: Spacing.small) {
            HStack {
                Text(L10n.Cleanup.ecosystemSimulators).font(.headline)
                if simulators.isWorking {
                    ProgressView().controlSize(.small)
                    Text(L10n.Simulators.working).foregroundStyle(.secondary)
                }
                Spacer()
                if simulators.didChangeDisk {
                    Text(L10n.Simulators.rescanHint).foregroundStyle(.secondary)
                }
            }
            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                        Text(L10n.Simulators.unavailableTitle)
                        Text(L10n.Simulators.unavailableDetail(Formatting.count(simulators.unavailable.count), size: Formatting.bytes(simulators.unavailable.dataSize)))
                            .font(Typography.chartCaption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button { isConfirmingUnavailable = true } label: { Text(L10n.Simulators.deleteUnavailable) }
                        .disabled(simulators.unavailable.count == 0 || simulators.isWorking)
                }
                .padding(Spacing.medium)
                ForEach(simulators.runtimes) { runtime in
                    Divider()
                    HStack {
                        VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                            Text(L10n.Simulators.runtimeName(runtime.platform, version: runtime.version))
                            if let lastUsed = runtime.lastUsedAt {
                                Text(L10n.Simulators.lastUsed(lastUsed.formatted(date: .abbreviated, time: .omitted)))
                                    .font(Typography.chartCaption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Text(Formatting.bytes(runtime.sizeBytes)).font(Typography.listSize)
                        Button { runtimeToDelete = runtime } label: { Text(L10n.Simulators.deleteRuntime) }
                            .disabled(!runtime.isDeletable || simulators.isWorking)
                    }
                    .padding(Spacing.medium)
                }
            }
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: CornerRadius.medium))
        }
        .alert(Text(L10n.Simulators.deleteUnavailableTitle), isPresented: $isConfirmingUnavailable) {
            Button(role: .cancel) {} label: { Text(L10n.Alerts.cancel) }
            Button { Task { await simulators.deleteUnavailableDevices() } } label: { Text(L10n.Simulators.deleteUnavailableConfirm) }
        } message: {
            Text(L10n.Simulators.deleteUnavailableMessage(Formatting.count(simulators.unavailable.count), size: Formatting.bytes(simulators.unavailable.dataSize)))
        }
        .alert(
            Text(L10n.Simulators.deleteRuntimeTitle(runtimeToDelete.map { String(localized: L10n.Simulators.runtimeName($0.platform, version: $0.version)) } ?? "")),
            isPresented: Binding(get: { runtimeToDelete != nil }, set: { if !$0 { runtimeToDelete = nil } }),
            presenting: runtimeToDelete
        ) { runtime in
            Button(role: .cancel) {} label: { Text(L10n.Alerts.cancel) }
            Button { Task { await simulators.delete(runtime) } } label: { Text(L10n.Simulators.deleteRuntimeConfirm) }
        } message: { runtime in
            Text(L10n.Simulators.deleteRuntimeMessage(Formatting.bytes(runtime.sizeBytes)))
        }
    }
}
