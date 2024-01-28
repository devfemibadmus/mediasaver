import 'package:flutter/services.dart';

const platform = MethodChannel('com.blackstackhub.whatsappstatus');

class StatusFileInfo {
  String name;
  String path;
  int size;
  String format;
  String source;

  StatusFileInfo({
    required this.name,
    required this.path,
    required this.size,
    required this.format,
    required this.source,
  });

  factory StatusFileInfo.fromJson(Map<String, dynamic> json) {
    return StatusFileInfo(
      name: json['name'],
      path: json['path'],
      size: json['size'],
      format: json['format'],
      source: json['source'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'path': path,
      'size': size,
      'format': format,
      'source': source,
    };
  }
}

class StatusFilesList {
  List<StatusFileInfo> statusFiles;

  StatusFilesList({required this.statusFiles});

  factory StatusFilesList.fromJson(List<dynamic> jsonList) {
    List<StatusFileInfo> files =
        jsonList.map((json) => StatusFileInfo.fromJson(json)).toList();
    return StatusFilesList(statusFiles: files);
  }
}

List<StatusFileInfo> parseStatusFiles(List<dynamic> files) {
  return files
      .map((file) => StatusFileInfo.fromJson(Map<String, dynamic>.from(file)))
      .toList();
}
