import SwiftUI

/// Explains what the selected item is: first from what the Mac already knows, and only for folders
/// nothing recognizes, from the on-device model — on request, clearly labelled, and without ever
/// touching the safety label or offering an action.
struct IdentityCard: View {
    let node: FileNode
    let identity: FolderIdentity?
    let explainer: FolderExplaining
    @State private var generated: String?
    @State private var failure: String?
    @State private var isWorking = false

    private var canAsk: Bool {
        identity == nil && node.kind == .directory && explainer.unavailable == nil
    }

    var body: some View {
        if identity != nil || node.kind == .directory {
            VStack(alignment: .leading, spacing: Spacing.small) {
                Text(L10n.Identity.sectionTitle).font(.headline)
                if let identity {
                    Text(identity.summary).fixedSize(horizontal: false, vertical: true)
                } else if let generated {
                    Text(generated).fixedSize(horizontal: false, vertical: true)
                    Text(L10n.Identity.generatedNote)
                        .font(Typography.chartCaption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Button { ask() } label: { Text(L10n.Identity.retry) }
                        .buttonStyle(.link)
                        .disabled(isWorking)
                } else if isWorking {
                    HStack(spacing: Spacing.xSmall) {
                        ProgressView().controlSize(.small)
                        Text(L10n.Identity.explaining)
                            .font(Typography.chartCaption)
                            .foregroundStyle(.secondary)
                    }
                } else if let failure {
                    Text(L10n.Identity.failed(failure))
                        .font(Typography.chartCaption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Button { ask() } label: { Text(L10n.Identity.retry) }
                        .buttonStyle(.link)
                } else if canAsk {
                    Button { ask() } label: { Text(L10n.Identity.explain) }
                } else if let reason = explainer.unavailable {
                    Text(reason.message)
                        .font(Typography.chartCaption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(Spacing.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: CornerRadius.medium))
            // A different item is a different question: never show one folder's answer for another.
            .onChange(of: node.id) { _, _ in
                generated = nil
                failure = nil
                isWorking = false
            }
        }
    }

    private func ask() {
        let description = FolderDescription.describing(node)
        let explainer = explainer
        isWorking = true
        failure = nil
        Task {
            do {
                let text = try await explainer.explain(description)
                guard !Task.isCancelled else { return }
                generated = text
            } catch {
                failure = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            }
            isWorking = false
        }
    }
}
