import 'package:flutter/material.dart';

class CustomOverlay {
  CustomOverlay._privateConstructor();

  static final CustomOverlay _instance = CustomOverlay._privateConstructor();

  factory CustomOverlay() {
    return _instance;
  }

  OverlayEntry? _overlayEntry;

  void showOverlayLoader(BuildContext context) {
    final overlay = Overlay.of(context);
    if (_overlayEntry != null) {
      _overlayEntry?.remove();
    }
    _overlayEntry = OverlayEntry(
      builder: (context) => const Positioned.fill(
        child: Align(
          alignment: Alignment.center,
          child: CircularProgressIndicator(),
        ),
      ),
    );
    overlay.insert(_overlayEntry!);
  }

  void removeOverlayLoader() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}
