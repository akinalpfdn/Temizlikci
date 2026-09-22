import SwiftUI

/// The app's only settings: how old a saved scan may get before it refreshes itself.
struct SettingsView: View {
    @AppStorage("refreshPeriod") private var refreshPeriod = RefreshPeriod.threeDays.rawValue

    var body: some View {
        Form {
            Picker(selection: $refreshPeriod) {
                ForEach(RefreshPeriod.allCases) { period in
                    Text(period.title).tag(period.rawValue)
                }
            } label: {
                Text(L10n.Settings.refreshLabel)
            }
            Text(L10n.Settings.refreshExplanation)
                .font(Typography.chartCaption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .formStyle(.grouped)
        .frame(width: 460)
        .navigationTitle(Text(L10n.Settings.title))
    }
}

extension RefreshPeriod {
    var title: LocalizedStringResource {
        switch self {
        case .day: L10n.Settings.refreshDay
        case .threeDays: L10n.Settings.refreshThreeDays
        case .week: L10n.Settings.refreshWeek
        case .never: L10n.Settings.refreshNever
        }
    }
}
