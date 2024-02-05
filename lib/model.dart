import 'package:flutter/services.dart';

const platform = MethodChannel('com.blackstackhub.whatsappstatus');

class StatusFileInfo {
  String name;
  String path;
  int size;
  String format;
  String source;
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

List<StatusFileInfo> parseStatusFiles(List<dynamic> files) {
  return files
      .map((file) => StatusFileInfo.fromJson(Map<String, dynamic>.from(file)))
      .toList();
}

List<StatusFileInfo> filterFilesByFormat(
  List<StatusFileInfo> files,
  List<String> formats,
  String source,
) =>
    files
        .where((file) => formats.contains(file.format) && file.source == source)
        .toList()
        .reversed
        .toList();

Future<String> statusAction(String filePath, String action) async {
  try {
    return await platform.invokeMethod(action, {'filePath': filePath});
  } on PlatformException catch (e) {
    return "Error: ${e.message}";
  }
}

bool listsAreEqual(List<StatusFileInfo> list1, List<StatusFileInfo> list2) {
  if (list1.length != list2.length) {
    return false;
  }

  for (int i = 0; i < list1.length; i++) {
    if (!statusFileInfoEquals(list1[i], list2[i])) {
      return false;
    }
  }

  return true;
}

bool statusFileInfoEquals(StatusFileInfo info1, StatusFileInfo info2) {
  return info1.name == info2.name &&
      info1.path == info2.path &&
      info1.size == info2.size &&
      info1.format == info2.format &&
      info1.source == info2.source;
}

List<String> images = ['jpg', 'jpeg', 'gif'];
List<String> videos = ['mp4', 'mov', 'mp4'];

List<StatusFileInfo> mergeVideoLists(
  List<StatusFileInfo> currentList,
  List<StatusFileInfo> newList,
) {
  // Create a set to efficiently check duplicates based on path and size
  Set<String> currentSet = {};
  for (var fileInfo in currentList) {
    currentSet.add('${fileInfo.path}_${fileInfo.size}');
  }

  // Create a new list for the result
  List<StatusFileInfo> resultList = [];

  // Merge data from newList to resultList
  for (var fileInfo in newList) {
    if (currentSet.contains('${fileInfo.path}_${fileInfo.size}')) {
      // Keep the mediaByte from the current list
      var currentIndex = currentList.indexWhere((currentFile) =>
          currentFile.path == fileInfo.path &&
          currentFile.size == fileInfo.size);
      if (currentIndex != -1) {
        fileInfo.mediaByte = currentList[currentIndex].mediaByte;
      }
    }
    resultList.add(fileInfo);
  }
  print('resultList.length');
  print(resultList.length);
  return resultList;
}
