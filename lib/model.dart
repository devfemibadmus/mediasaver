import 'package:flutter/services.dart';
import 'package:mediasaver/pages/webmedia/models/webmedia.dart';

const platform = MethodChannel('com.blackstackhub.mediasaver');

// BULLET TRAIN
class MediaFileInfo {
  String name, path, format, source;
  int size;
  Uint8List mediaByte;

  MediaFileInfo({
    required this.name,
    required this.path,
    required this.size,
    required this.format,
    required this.source,
    required this.mediaByte,
  });

  factory MediaFileInfo.fromJson(Map<String, dynamic> json) => MediaFileInfo(
        name: json['name'],
        path: json['path'],
        size: json['size'],
        format: json['format'],
        source: json['source'],
        mediaByte: json['mediaByte'],
      );
}

List<MediaFileInfo> parseMediaFiles(List<dynamic> files) => files
    .map((file) => MediaFileInfo.fromJson(Map<String, dynamic>.from(file)))
    .toList();

List<MediaFileInfo> filterByMimeType(
        List<MediaFileInfo> files, List<String> formats, String source) =>
    files
        .where((file) => formats.contains(file.format) && file.source == source)
        .toList()
        .reversed
        .toList();

Future<String> mediaAction(String filePath, String action) async =>
    await platform.invokeMethod(action, {'filePath': filePath}).catchError(
        (e) => "Error: ${e.message}");

bool listsAreEqual(List<MediaFileInfo> list1, List<MediaFileInfo> list2) =>
    list1.length == list2.length &&
    list1.every((fileInfo) =>
        mediaFileInfoEquals(fileInfo, list2[list1.indexOf(fileInfo)]));

bool mediaFileInfoEquals(MediaFileInfo info1, MediaFileInfo info2) =>
    info1.name == info2.name &&
    info1.path == info2.path &&
    info1.size == info2.size &&
    info1.format == info2.format &&
    info1.source == info2.source;

List<String> images = ['jpg', 'jpeg', 'gif'];
List<String> videos = ['mp4', 'mov', 'mp4'];

List<MediaFileInfo> mergeVideoLists(
    List<MediaFileInfo> currentList, List<MediaFileInfo> newList) {
  Set<String> currentSet = {
    for (var fileInfo in currentList) '${fileInfo.path}_${fileInfo.size}'
  };
  return newList.map((fileInfo) {
    if (currentSet.contains('${fileInfo.path}_${fileInfo.size}')) {
      var currentIndex = currentList.indexWhere((currentFile) =>
          currentFile.path == fileInfo.path &&
          currentFile.size == fileInfo.size);
      if (currentIndex != -1) {
        fileInfo.mediaByte = currentList[currentIndex].mediaByte;
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
  // print("data: $data");
  if (data != null && data['success'] != null) {
    return {
      'success': true,
      'data': WebMedia.fromJson(data['data']),
    };
  } else {
    return data;
  }
}
