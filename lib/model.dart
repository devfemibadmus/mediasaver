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

List<StatusFileInfo> filterFilesByFormat(
    List<StatusFileInfo> files,
    String targetFormat,
    String targetFormat2,
    String targetFormat3,
    String source) {
  List<StatusFileInfo> filteredFiles = files
      .where((file) =>
          (file.format == targetFormat ||
              file.format == targetFormat2 ||
              file.format == targetFormat3) &&
          file.source == source)
      .toList();
  return filteredFiles.reversed.toList();
}

Future<void> saveImage(String imagePath, String folder) async {
  await platform.invokeMethod('saveStatus', {
    'imagePath': imagePath,
    'folder': folder,
  });
}



//