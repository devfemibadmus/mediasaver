import Social
import UIKit
import UniformTypeIdentifiers

class ShareViewController: SLComposeServiceViewController {
  private let appScheme = "mediasaver://shared"

  override func isContentValid() -> Bool {
    return true
  }

  override func didSelectPost() {
    extractSharedText { [weak self] sharedText in
      if let appURL = self?.appURL(for: sharedText) {
        self?.extensionContext?.open(appURL)
      }

      self?.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
  }

  private func appURL(for sharedText: String?) -> URL? {
    var components = URLComponents(string: appScheme)
    if let sharedText, !sharedText.isEmpty {
      components?.queryItems = [URLQueryItem(name: "text", value: sharedText)]
    }
    return components?.url
  }

  override func configurationItems() -> [Any]! {
    return []
  }

  private func extractSharedText(completion: @escaping (String?) -> Void) {
    if let typedText = contentText, !typedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      completion(typedText)
      return
    }

    guard let item = extensionContext?.inputItems.first as? NSExtensionItem,
          let attachments = item.attachments,
          let provider = attachments.first else {
      completion(nil)
      return
    }

    if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
      provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { item, _ in
        DispatchQueue.main.async {
          completion((item as? URL)?.absoluteString ?? item as? String)
        }
      }
      return
    }

    if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
      provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { item, _ in
        DispatchQueue.main.async {
          completion(item as? String)
        }
      }
      return
    }

    completion(nil)
  }
}
