import UIKit
import UniformTypeIdentifiers

/// Does as little work as possible: receive the shared payload, extract a Candidate,
/// save a PendingImport, hand off to the main app. Never resolves Places, never saves
/// Places, never performs long-running network work. See IMPORT_PIPELINE.md
/// "Share Extension Responsibilities".
final class ShareViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        Task { await handleSharedItem() }
    }

    private func handleSharedItem() async {
        guard let item = extensionContext?.inputItems.first as? NSExtensionItem,
              let attachments = item.attachments, !attachments.isEmpty
        else {
            completeAndOpenApp(title: nil, text: nil, url: nil)
            return
        }

        let sharedTitle = item.attributedContentText?.string
        let url = await Self.loadURL(from: attachments)
        let text = await Self.loadText(from: attachments)

        completeAndOpenApp(title: sharedTitle, text: text, url: url)
    }

    private static func loadURL(from attachments: [NSItemProvider]) async -> URL? {
        guard let provider = attachments.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.url.identifier) }) else {
            return nil
        }
        return await withCheckedContinuation { continuation in
            provider.loadItem(forTypeIdentifier: UTType.url.identifier) { item, _ in
                continuation.resume(returning: item as? URL)
            }
        }
    }

    private static func loadText(from attachments: [NSItemProvider]) async -> String? {
        guard let provider = attachments.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) }) else {
            return nil
        }
        return await withCheckedContinuation { continuation in
            provider.loadItem(forTypeIdentifier: UTType.plainText.identifier) { item, _ in
                continuation.resume(returning: item as? String)
            }
        }
    }

    private func completeAndOpenApp(title: String?, text: String?, url: URL?) {
        let candidate = CandidateExtractor.extractSearchText(title: title, text: text, url: url)

        let pendingImport = PendingImport(
            sourceURL: url,
            sharedTitle: title,
            sharedText: text,
            suggestedSearchText: candidate
        )
        PendingImportStore.save(pendingImport)

        extensionContext?.completeRequest(returningItems: nil) { [weak self] _ in
            self?.openMainApp()
        }
    }

    /// Share extensions cannot call UIApplication.open directly; walk the responder chain
    /// to find it, matching the standard extension → host app hand-off pattern.
    private func openMainApp() {
        guard let url = URL(string: "placepick://import") else { return }
        var responder: UIResponder? = self
        while let current = responder {
            if let application = current as? UIApplication {
                application.perform(#selector(UIApplication.open(_:options:completionHandler:)), with: url, with: nil)
                return
            }
            responder = current.next
        }
    }
}
