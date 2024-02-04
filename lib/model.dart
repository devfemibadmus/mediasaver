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

List<StatusFileInfo> parseStatusFiles(List<dynamic> files) =>
    List.of(files.map((file) => StatusFileInfo.fromJson(file))).toList();

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
    print("Error: ${e.message}");
    return "Error: ${e.message}";
  }
}

Future<bool> shareMedia(String filePath) async {
  try {
    return await platform.invokeMethod('shareMedia', {'filePath': filePath});
  } on PlatformException catch (e) {
    print("Error: ${e.message}");
    return false;
  }
}

List<String> images = ['jpg', 'jpeg', 'gif'];
List<String> videos = ['mp4', 'mov', 'mp4'];
