import 'package:mediasaver/models/webmedia.dart';
import 'package:flutter/services.dart';

const platform = MethodChannel('github.devfemibadmus.mediasaver');
// BULLET TRAIN

Future<String> fetchClipboardContent() async {
  String clipboardContent = await platform.invokeMethod('getClipboardContent');
  return clipboardContent;
}

bool isValidUrl(String value) {
  return value.startsWith('https://') || value.startsWith('http://');
}

Future<String> downloadFile(String fileUrl, String fileId) async {
  final String result = await platform
      .invokeMethod('downloadFile', {'fileUrl': fileUrl, 'fileId': fileId});
  return result;
}

Future<Map<String, dynamic>?> fetchMediaFromServer(String url) async {
  final api =
      Api(apiUrl: 'https://devfemibadmus.blackstackhub.com/webmedia/api/');

  if (api.isValidUrl(url)) {
    final video = await api.fetchMedia(url);
    if (video != null && video['success']) {
      return {
        'success': true,
        'type': 'image',
        'data': WebMedia.fromJson(video['data'])
      };
    }
  } else {
    return {
      'error': 'Unsupported URL format.',
    };
  }
  return null;
}
