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

Future<void> saveStatus(String imagePath) async {
  await platform.invokeMethod('saveStatus', {
    'imagePath': imagePath,
    'folder': 'Status Saver',
  });
}

List<String> images = ['jpg', 'jpeg', 'gif'];
List<String> videos = ['mp4', 'mov', 'mp4'];

//