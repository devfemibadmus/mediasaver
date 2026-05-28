import UIKit
import UniformTypeIdentifiers

final class ShareViewController: UIViewController {
  private let defaultsMediaKey = "ShareKey"
  private let defaultsMessageKey = "ShareMessageKey"
  private var didHandleShare = false

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    guard !didHandleShare else { return }
    didHandleShare = true

    extractSharedText { [weak self] value in
      guard let self = self else { return }
      self.saveAndOpenHostApp(value)
    }
  }

  private func extractSharedText(completion: @escaping (String?) -> Void) {
    let providers = extensionContext?.inputItems
      .compactMap { $0 as? NSExtensionItem }
      .flatMap { $0.attachments ?? [] } ?? []

    guard !providers.isEmpty else {
      completion(nil)
      return
    }

    if let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.url.identifier) }) {
      provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { item, _ in
        completion(Self.stringValue(from: item))
      }
      return
    }

    if let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.text.identifier) }) {
      provider.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { item, _ in
        completion(Self.stringValue(from: item))
      }
      return
    }

    completion(nil)
  }

  private static func stringValue(from item: NSSecureCoding?) -> String? {
    if let url = item as? URL {
      return url.absoluteString
    }

    if let text = item as? String {
      return text
    }

    return nil
  }

  private func saveAndOpenHostApp(_ value: String?) {
    guard let value = value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      finish()
      return
    }

    let appGroupId = Bundle.main.object(forInfoDictionaryKey: "AppGroupId") as? String
    let hostBundleId = hostAppBundleIdentifier()
    let defaults = UserDefaults(suiteName: appGroupId ?? "group.\(hostBundleId)")
    let mediaType = value.hasPrefix("http://") || value.hasPrefix("https://") ? "url" : "text"

    let media = SharedMediaFile(path: value, mimeType: "text/plain", type: mediaType)
    if let data = try? JSONEncoder().encode([media]) {
      defaults?.set(data, forKey: defaultsMediaKey)
      defaults?.removeObject(forKey: defaultsMessageKey)
      defaults?.synchronize()
    }

    DispatchQueue.main.async {
      self.openHostApp(bundleIdentifier: hostBundleId)
    }
  }

  private func openHostApp(bundleIdentifier: String) {
    guard let url = URL(string: "ShareMedia-\(bundleIdentifier):share") else {
      finish()
      return
    }

    extensionContext?.open(url) { [weak self] opened in
      guard let self = self else { return }

      if !opened {
        self.openWithResponderChain(url)
      }

      self.finish()
    }
  }

  private func openWithResponderChain(_ url: URL) {
    let selector = sel_registerName("openURL:")
    var responder: UIResponder? = self

    while let currentResponder = responder {
      if currentResponder.responds(to: selector) {
        _ = currentResponder.perform(selector, with: url)
        return
      }

      responder = currentResponder.next
    }
  }

  private func finish() {
    DispatchQueue.main.async {
      self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
  }

  private func hostAppBundleIdentifier() -> String {
    guard let bundleIdentifier = Bundle.main.bundleIdentifier,
          let lastDot = bundleIdentifier.lastIndex(of: ".") else {
      return "com.blackstackhub.mediasaver"
    }

    return String(bundleIdentifier[..<lastDot])
  }
}

private struct SharedMediaFile: Encodable {
  let path: String
  let mimeType: String?
  let thumbnail: String? = nil
  let duration: Double? = nil
  let message: String? = nil
  let type: String
}
