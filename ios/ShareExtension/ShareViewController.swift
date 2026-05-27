import UIKit
import UniformTypeIdentifiers

class ShareViewController: UIViewController {
  private let appScheme = "mediasaver://shared"
  private var didProcessShare = false

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground

    let activityIndicator = UIActivityIndicatorView(style: .large)
    activityIndicator.translatesAutoresizingMaskIntoConstraints = false
    activityIndicator.startAnimating()
    view.addSubview(activityIndicator)

    NSLayoutConstraint.activate([
      activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
    ])
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    guard !didProcessShare else { return }
    didProcessShare = true

    extractSharedText { [weak self] sharedText in
      guard let self else { return }

      guard let appURL = self.appURL(for: sharedText) else {
        self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        return
      }

      self.extensionContext?.open(appURL) { _ in
        self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
      }
    }
  }

  private func appURL(for sharedText: String?) -> URL? {
    var components = URLComponents(string: appScheme)
    if let sharedText, let urlText = firstURL(in: sharedText) ?? nonEmpty(sharedText) {
      components?.queryItems = [URLQueryItem(name: "text", value: urlText)]
    }
    return components?.url
  }

  private func nonEmpty(_ text: String) -> String? {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? nil : trimmed
  }

  private func firstURL(in text: String) -> String? {
    guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
      return nil
    }

    let range = NSRange(text.startIndex..<text.endIndex, in: text)
    return detector
      .firstMatch(in: text, options: [], range: range)?
      .url?
      .absoluteString
  }

  private func extractSharedText(completion: @escaping (String?) -> Void) {
    guard let item = extensionContext?.inputItems.first as? NSExtensionItem,
          let attachments = item.attachments else {
      completion(nil)
      return
    }

    if let provider = attachments.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.url.identifier) }) {
      provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { item, _ in
        DispatchQueue.main.async {
          completion((item as? URL)?.absoluteString ?? item as? String)
        }
      }
      return
    }

    if let provider = attachments.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) }) {
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
