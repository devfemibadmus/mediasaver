import 'package:flutter/services.dart';
import 'package:mediasaver/platforms/webMedia/models/webmedia.dart';

const platform = MethodChannel('com.blackstackhub.mediasaver');
// BULLET TRAIN

class MediaFiles {
  String url;
  String mimeType;

  MediaFiles({
    required this.url,
    required this.mimeType,
  });

  factory MediaFiles.fromJson(Map<String, dynamic> json) => MediaFiles(
        url: json['url'],
        mimeType: json['mimeType'],
      );
}

List<MediaFiles> parseMediaFiles(List<dynamic> files) => files
    .map((file) => MediaFiles.fromJson(Map<String, dynamic>.from(file)))
    .toList();

List<MediaFiles> filterByMimeType(List<MediaFiles> list, List<String> formats) {
  return list.where((fileInfo) {
    // Extract the format (e.g., 'jpeg' or 'mp4') from the MIME type
    String format = fileInfo.mimeType.split('/').last.toLowerCase();

    // Check if the format is in the provided formats list
    return formats.contains(format);
  }).toList();
}

Future<String> mediaFileAction(String filePath, String action) async =>
    await platform.invokeMethod(action, {'filePath': filePath}).catchError(
        (e) => "Error: ${e.message}");

bool listsAreEqual(List<MediaFiles> list1, List<MediaFiles> list2) {
  // Check if lengths are equal
  if (list1.length != list2.length) return false;

  // Compare each element by index
  for (int i = 0; i < list1.length; i++) {
    if (!mediaFilesEquals(list1[i], list2[i])) {
      return false;
    }
  }

  return true;
}

bool mediaFilesEquals(MediaFiles info1, MediaFiles info2) =>
    info1.url == info2.url && info1.mimeType == info2.mimeType;

List<String> images = ['jpg', 'jpeg', 'gif'];
List<String> videos = ['mp4', 'mov', 'mp4'];

List<MediaFiles> mergeVideoLists(
    List<MediaFiles> currentList, List<MediaFiles> newList) {
  Set<String> currentSet = {
    for (var fileInfo in currentList) '${fileInfo.url}_${fileInfo.mimeType}'
  };
  return newList.map((fileInfo) {
    if (currentSet.contains('${fileInfo.url}_${fileInfo.mimeType}')) {
      var currentIndex = currentList.indexWhere((currentFile) =>
          currentFile.url == fileInfo.url &&
          currentFile.mimeType == fileInfo.mimeType);
      if (currentIndex != -1) {
        fileInfo.url = currentList[currentIndex].mimeType;
      }
    }
    return fileInfo;
  }).toList();
}

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
