import 'package:mediasaver/model/variable.dart';
import 'package:mediasaver/model/tiktok.dart';

// BULLET TRAIN

Future<String> fetchClipboardContent() async {
  String clipboardContent = await platform.invokeMethod('getClipboardContent');
  return clipboardContent;
}

bool isValidUrl(String value) {
  return value.startsWith('https://') || value.startsWith('http://');
}

Future<List> downloadFile(String fileUrl) async {
  final String result =
      await platform.invokeMethod('downloadFile', {'fileUrl': fileUrl});
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
  final bot = TikTokBot(apiUrl: 'http://172.31.176.1/api/');

  if (bot.isVideoUrl(url)) {
    final video = await bot.fetchMedia(url);
    if (video != null && video['is_video'] == true) {
      return {'type': 'video', 'data': TikTokVideo.fromJson(video)};
    }
  } else if (bot.isImageUrl(url)) {
    final image = await bot.fetchMedia(url);
    if (image != null && image['is_image'] == true) {
      return {'type': 'image', 'data': TikTokImage.fromJson(image)};
    }
  } else {
    print('Unsupported URL format.');
  }
  return null;
}
