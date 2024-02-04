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

  factory StatusFileInfo.fromJson(Map<String, dynamic> json) {
    return StatusFileInfo(
      name: json['name'],
      path: json['path'],
      size: json['size'],
      format: json['format'],
      source: json['source'],
      mediaByte: json['mediaByte'],
    );
  }
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
) {
  List<StatusFileInfo> filteredFiles = files
      .where((file) => (formats.contains(file.format)) && file.source == source)
      .toList();
  return filteredFiles.reversed.toList();
}

Future<String> statusAction(String filePath, String action) async {
  try {
    final String result = await platform.invokeMethod(action, {
      'filePath': filePath,
    });
    return result;
  } on PlatformException catch (e) {
    print("Error: ${e.message}");
    return "Error: ${e.message}";
  }
}

Future<String> shareMedia(String filePath) async {
  try {
    final String result =
        await platform.invokeMethod('shareMedia', {'filePath': filePath});
    return result;
  } on PlatformException catch (e) {
    print("Error: ${e.message}");
    return "Error: ${e.message}";
  }
}

List<String> images = ['jpg', 'jpeg', 'gif'];
List<String> videos = ['mp4', 'mov', 'mp4'];

//