import SwiftUI

struct DetailView: View {
    let model: MainViewModel

    var body: some View {
        switch model.selection {
        case .developer:
            DeveloperView(main: model)
        case .largeFiles:
            InsightEmptyView(systemImage: "doc", message: L10n.Insights.largeFilesMessage)
        case .trash:
            if model.trashLedger.records.isEmpty {
                InsightEmptyView(systemImage: "trash", message: L10n.Insights.trashMessage)
            } else {
                TrashListView(main: model)
            }
        case .startupDisk, .home, .chosenFolder, nil:
            if let scan = model.currentScan {
                OverviewView(model: scan, main: model)
                    .id(scan.location.url)
            }
        }
    }
}

struct InsightEmptyView: View {
    let systemImage: String
    let message: LocalizedStringResource

    var body: some View {
        ContentUnavailableView {
            Label { Text(L10n.Insights.notScannedTitle) } icon: { Image(systemName: systemImage) }
        } description: {
            Text(message)
        }
    }
}
