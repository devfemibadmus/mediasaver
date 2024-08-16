import 'package:flutter/services.dart';
import 'package:mediasaver/platforms/webMedia/models/webmedia.dart';

const platform = MethodChannel('com.blackstackhub.mediasaver');
// BULLET TRAIN

Future<String> fetchClipboardContent() async {
  String clipboardContent = await platform.invokeMethod('getClipboardContent');
  return clipboardContent;
}

bool isSupportUrl(String url) {
  final tiktokPattern =
      RegExp(r'tiktok\.com/.*/video/(\d+)|tiktok\.com/.*/photo/(\d+)');
  final facebookPattern = RegExp(r'facebook\.com/.+');
  final instagramPattern = RegExp(r'instagram\.com/.+');

  return tiktokPattern.hasMatch(url) ||
      facebookPattern.hasMatch(url) ||
      instagramPattern.hasMatch(url);
}

Future<String> downloadFile(
    String? fileUrl, String? fileUrl2, String fileId) async {
  if (fileUrl == null) {
    return "something went wrong, try again!";
  }
  if (fileUrl2 != null) {
    // TODO: API please do ffmpeg in server so app will be less size
    const String result =
        "Try another video"; // await platform.invokeMethod('downloadVideoAudio', {'videoUrl': fileUrl, 'audioUrl': fileUrl2, 'fileId': fileId});
    return result;
  }
  final String result = await platform
      .invokeMethod('downloadFile', {'fileUrl': fileUrl, 'fileId': fileId});
  return result;
}

Future<Map<String, dynamic>?> fetchMediaFromServer(String url) async {
  final api =
      Api(apiUrl: 'https://devfemibadmus.blackstackhub.com/webmedia/api/');

  final data = await api.fetchMedia(url);
  if (data != null && data['success']) {
    return {
      'success': true,
      'data': WebMedia.fromJson(data['data']),
    };
  } else {
    return data;
  }
}
