import SwiftUI

/// A quiet notice above the content when a newer version is out. Download opens the disk image in
/// the browser; nothing is installed without the person doing it.
struct UpdateBanner: View {
    let updates: UpdateModel

    var body: some View {
        if let release = updates.available {
            HStack(alignment: .center, spacing: Spacing.medium) {
                Image(systemName: "arrow.down.circle")
                    .foregroundStyle(.tint)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                    Text(L10n.Updates.available(release.version.description)).fontWeight(.semibold)
                    Text(L10n.Updates.current(updates.current.description))
                        .font(Typography.chartCaption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: Spacing.medium)
                Button { updates.dismiss() } label: { Text(L10n.Updates.notNow) }
                Button { updates.openReleaseNotes() } label: { Text(L10n.Updates.releaseNotes) }
                Button { updates.download() } label: { Text(L10n.Updates.download) }
                    .buttonStyle(.borderedProminent)
            }
            .padding(Spacing.medium)
            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: CornerRadius.medium))
            .padding(.horizontal, Spacing.large)
            .padding(.top, Spacing.small)
            .accessibilityElement(children: .contain)
        }
    }
}

/// The answer to Check for Updates…, which the person asked for, so it always says something.
struct UpdateResultAlert: ViewModifier {
    @Bindable var updates: UpdateModel

    func body(content: Content) -> some View {
        content.alert(item: $updates.manualResult) { result in
            switch result {
            case .upToDate(let version):
                Alert(
                    title: Text(L10n.Updates.upToDateTitle),
                    message: Text(L10n.Updates.upToDateMessage(version)),
                    dismissButton: .default(Text(L10n.Alerts.ok))
                )
            case .newer(let release):
                Alert(
                    title: Text(L10n.Updates.available(release.version.description)),
                    message: Text(L10n.Updates.newerMessage(updates.current.description)),
                    primaryButton: .default(Text(L10n.Updates.download)) { updates.download() },
                    secondaryButton: .cancel(Text(L10n.Updates.notNow))
                )
            case .failed:
                Alert(
                    title: Text(L10n.Updates.failedTitle),
                    message: Text(L10n.Updates.failedMessage),
                    dismissButton: .default(Text(L10n.Alerts.ok))
                )
            }
        }
    }
}
