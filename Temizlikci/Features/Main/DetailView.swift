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
            OverviewEmptyView(onChooseFolder: { Task { await model.chooseFolder() } })
        }
    }
}

struct OverviewEmptyView: View {
    let onChooseFolder: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label { Text(L10n.Overview.emptyTitle) } icon: { Image(systemName: "chart.pie") }
        } description: {
            Text(L10n.Overview.emptyMessage)
        } actions: {
            Button(action: onChooseFolder) { Text(L10n.Sidebar.chooseFolder) }
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
