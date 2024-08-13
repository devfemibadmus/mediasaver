import 'package:mediasaver/model/variable.dart';
import 'package:mediasaver/model/webmedia.dart';

// BULLET TRAIN

Future<String> fetchClipboardContent() async {
  String clipboardContent = await platform.invokeMethod('getClipboardContent');
  return clipboardContent;
}

bool isValidUrl(String value) {
  return value.startsWith('https://') || value.startsWith('http://');
}

Future<List> downloadFile(String fileUrl, String fileId) async {
  final String result = await platform
      .invokeMethod('downloadFile', {'fileUrl': fileUrl, 'fileId': fileId});
  // print('Download result: $result');
  if (result.contains("Already Saved")) {
    return ["Already Saved", result.replaceFirst("Already Saved: ", "")];
  } else if (result.contains("/storage/emulated/0")) {
    return [true, result];
  } else {
    return [false, result];
  }
}

Future<Map<String, dynamic>?> fetchMediaFromServer(String url) async {
  final api =
      Api(apiUrl: 'https://devfemibadmus.blackstackhub.com/webmedia/api/');

  if (api.isValidUrl(url)) {
    final video = await api.fetchMedia(url);
    // print(video);
    if (video != null && video['success']) {
      return {
        'success': true,
        'type': 'image',
        'data': WebMedia.fromJson(video['data'])
      };
    }
  } else {
    // print('Unsupported URL format.');
    return {
      'error': 'Unsupported URL format.',
    };
  }
  // print("null ooo");
  return null;
}
