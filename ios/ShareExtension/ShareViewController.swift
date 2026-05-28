import receive_sharing_intent

class ShareViewController: RSIShareViewController {
  override func shouldAutoRedirect() -> Bool {
    return false
  }

  override func presentationAnimationDidFinish() {
    super.presentationAnimationDidFinish()
    navigationController?.navigationBar.topItem?.rightBarButtonItem?.title = "Send"
  }
}
