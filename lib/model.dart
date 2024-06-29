import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

const platform = MethodChannel('com.blackstackhub.mediasaver');

// BULLET TRAIN
class StatusFileInfo {
  String name, path, format, source;
  int size;
  Uint8List mediaByte;

  StatusFileInfo({
    required this.name,
    required this.path,
    required this.size,
    required this.format,
    required this.source,
    required this.mediaByte,
  });

  factory StatusFileInfo.fromJson(Map<String, dynamic> json) => StatusFileInfo(
        name: json['name'],
        path: json['path'],
        size: json['size'],
        format: json['format'],
        source: json['source'],
        mediaByte: json['mediaByte'],
      );
}

List<StatusFileInfo> parseStatusFiles(List<dynamic> files) => files
    .map((file) => StatusFileInfo.fromJson(Map<String, dynamic>.from(file)))
    .toList();

List<StatusFileInfo> filterFilesByFormat(
        List<StatusFileInfo> files, List<String> formats, String source) =>
    files
        .where((file) => formats.contains(file.format) && file.source == source)
        .toList()
        .reversed
        .toList();

Future<String> statusAction(String filePath, String action) async =>
    await platform.invokeMethod(action, {'filePath': filePath}).catchError(
        (e) => "Error: ${e.message}");

bool listsAreEqual(List<StatusFileInfo> list1, List<StatusFileInfo> list2) =>
    list1.length == list2.length &&
    list1.every((fileInfo) =>
        statusFileInfoEquals(fileInfo, list2[list1.indexOf(fileInfo)]));

bool statusFileInfoEquals(StatusFileInfo info1, StatusFileInfo info2) =>
    info1.name == info2.name &&
    info1.path == info2.path &&
    info1.size == info2.size &&
    info1.format == info2.format &&
    info1.source == info2.source;

List<String> images = ['jpg', 'jpeg', 'gif'];
List<String> videos = ['mp4', 'mov', 'mp4'];

List<StatusFileInfo> mergeVideoLists(
    List<StatusFileInfo> currentList, List<StatusFileInfo> newList) {
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

bool isValidUrl(String value) {
  return value.startsWith('https://') || value.startsWith('http://');
}

Future<String> downloadYoutubeVideo(String videoUrl) async {
  const String apiUrl = 'http://192.168.209.103/youtube/';

  final response = await http.post(
    Uri.parse(apiUrl),
    headers: {'Content-Type': 'application/x-www-form-urlencoded'},
    body: {'url': videoUrl},
  );

  if (response.statusCode == 200) {
    final responseData = json.decode(response.body);
    if (responseData.containsKey('media_url')) {
      return responseData['media_url'];
    } else {
      return "Try again later";
    }
  } else {
    return "Private Video";
  }
}

class DownloadService {
  static Future<String> downloadFile(String url) async {
    final String result = await platform.invokeMethod('downloadFile', url);
    return result;
  }

  static void setDownloadProgressHandler(Function(double) handler) {
    platform.setMethodCallHandler((call) async {
      if (call.method == 'updateProgress') {
        handler(call.arguments);
      }
    });
  }
}
