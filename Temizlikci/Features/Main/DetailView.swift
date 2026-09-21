import SwiftUI

struct DetailView: View {
    let model: MainViewModel

    var body: some View {
        switch model.selection {
        case .developer:
            InsightEmptyView(systemImage: "hammer", message: L10n.Insights.developerMessage)
        case .largeFiles:
            InsightEmptyView(systemImage: "doc", message: L10n.Insights.largeFilesMessage)
        case .trash:
            InsightEmptyView(systemImage: "trash", message: L10n.Insights.trashMessage)
        case .startupDisk, .home, .chosenFolder, nil:
            if let scan = model.currentScan {
                OverviewView(model: scan, onChooseFolder: { Task { await model.chooseFolder() } })
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
