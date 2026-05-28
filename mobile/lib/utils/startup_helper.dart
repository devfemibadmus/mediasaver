import 'package:flutter/material.dart';
import 'package:mediasaver/utils/media_helper.dart';

const Duration startupDelay = Duration(milliseconds: 300);
const Duration startupInitTimeout = Duration(seconds: 4);

Future<void> initializeMediaStoreForStartup() async {
  try {
    await MediaHelper.initStore().timeout(startupInitTimeout);
    await MediaHelper.cleanDeleted().timeout(startupInitTimeout);
  } catch (e) {
    debugPrint('Startup media store initialization skipped: $e');
  }
}
