import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var sharedText: String?
  private var shareChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    guard let messenger = registrar(forPlugin: "ClipboardChannelPlugin")?.messenger() else {
      GeneratedPluginRegistrant.register(with: self)
      return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    let clipboardChannel = FlutterMethodChannel(name: "com.blackstackhub.mediasaver/clipboard",
                                                binaryMessenger: messenger)
    
    clipboardChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if call.method == "getClipboard" {
        let clipboardString = UIPasteboard.general.string ?? ""
        result(clipboardString)
      } else {
        result(FlutterMethodNotImplemented)
      }
    })

    shareChannel = FlutterMethodChannel(name: "com.blackstackhub.mediasaver/share",
                                        binaryMessenger: messenger)

    shareChannel?.setMethodCallHandler({
      [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if call.method == "getInitialSharedText" {
        result(self?.sharedText)
        self?.sharedText = nil
      } else {
        result(FlutterMethodNotImplemented)
      }
    })
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    sharedText = URLComponents(url: url, resolvingAgainstBaseURL: false)?
      .queryItems?
      .first(where: { $0.name == "text" })?
      .value
    shareChannel?.invokeMethod("sharedTextReceived", arguments: sharedText)

    return true
  }
}
