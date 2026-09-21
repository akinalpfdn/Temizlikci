import SwiftUI

struct InspectorView: View {
    var body: some View {
        ContentUnavailableView {
            Label { Text(L10n.Inspector.noSelectionTitle) } icon: { Image(systemName: "info.circle") }
        } description: {
            Text(L10n.Inspector.noSelectionMessage)
        }
    }
}
