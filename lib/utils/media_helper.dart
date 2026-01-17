import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ffmpeg_kit_flutter_new_min_gpl/ffmpeg_kit.dart';
import 'package:saver_gallery/saver_gallery.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class MediaHelper {
  static Future<void> initStore() async {
    Directory dir;

    try {
      dir = await getApplicationSupportDirectory();
    } catch (e) {
      await Future.delayed(const Duration(milliseconds: 300));
      dir = await getApplicationSupportDirectory();
    }

    Hive.init(dir.path);
    await Hive.openBox('mediaBox');
    await Hive.openBox('urlBox');

    if (Platform.isAndroid) {
      if (!await Permission.storage.isGranted) {
        await Permission.storage.request();
      }
    } else if (Platform.isIOS) {
      if (!await Permission.photosAddOnly.isGranted) {
        await Permission.photosAddOnly.request();
      }
    }
  }

  static String cleanUrl(String url) {
    return url.replaceAll('&amp;', '&');
  }

  static bool isVideoUrl(String url) {
    final cleanedUrl = cleanUrl(url);
    return cleanedUrl.toLowerCase().contains('.mp4') ||
        cleanedUrl.toLowerCase().contains('.mov') ||
        cleanedUrl.contains('/play/') ||
        cleanedUrl.contains('/video/') ||
        cleanedUrl.contains('video_id=') ||
        cleanedUrl.contains('.27.IRZXSOY') ||
        cleanedUrl.contains('.1034.IRZXSOY') ||
        cleanedUrl.contains('aweme/v1/play');
  }

  static String getFileExtension(String url) {
    if (isVideoUrl(url)) return '.mp4';
    final cleanedUrl = cleanUrl(url);
    if (cleanedUrl.toLowerCase().contains('.jpg') ||
        cleanedUrl.toLowerCase().contains('.jpeg')) {
      return '.jpg';
    }
    if (cleanedUrl.toLowerCase().contains('.png')) return '.png';
    if (cleanedUrl.toLowerCase().contains('.gif')) return '.gif';
    return '.jpg';
  }

  static Future<bool> checkIfImageExists(String url) async {
    try {
      final cleanedUrl = cleanUrl(url);
      final response = await http.head(Uri.parse(cleanedUrl));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static List<String> filterVideoUrls(List<String> urls) {
    return urls.where((url) => !url.contains('audio===')).toList();
  }

  static String? getAudioUrl(List<String> urls) {
    final audio =
        urls.firstWhere((url) => url.contains('audio==='), orElse: () => '');
    return audio.isNotEmpty ? audio.replaceAll('audio===', '') : null;
  }

  static Future<File?> mergeAudioWithVideo({
    required File videoFile,
    required String audioUrl,
    required String outputFileName,
  }) async {
    try {
      final dir = await getTemporaryDirectory();
      final cleanedAudioUrl = cleanUrl(audioUrl);
      final audioResponse = await http.get(Uri.parse(cleanedAudioUrl));
      final audioBytes = audioResponse.bodyBytes;
      final audioFile =
          File('${dir.path}/a${DateTime.now().millisecondsSinceEpoch}.m4a');
      await audioFile.writeAsBytes(audioBytes);

      final mergedFile = File('${dir.path}/$outputFileName');

      await FFmpegKit.execute(
          '-i "${videoFile.path}" -i "${audioFile.path}" -c:v copy -c:a aac -map 0:v:0 -map 1:a:0 -shortest "${mergedFile.path}"');

      await videoFile.delete();
      await audioFile.delete();

      return mergedFile;
    } catch (e) {
      debugPrint("Audio merge failed: $e");
      return null;
    }
  }

  static Future<File> saveToGalleryAndStore({
    required String url,
    required String fileName,
  }) async {
    final cleanedUrl = cleanUrl(url);
    final response = await http.get(Uri.parse(cleanedUrl));
    final bytes = response.bodyBytes;
    Directory dir;
    try {
      dir = await getTemporaryDirectory();
    } catch (e) {
      dir = await getTemporaryDirectory();
    }
    final tempFile = File('${dir.path}/$fileName');
    await tempFile.writeAsBytes(bytes);

    final box = Hive.box('mediaBox');
    final urlBox = Hive.box('urlBox');

    await SaverGallery.saveFile(
      filePath: tempFile.path,
      fileName: fileName,
      skipIfExists: false,
    );

    box.add(tempFile.path);
    urlBox.put(url, tempFile.path);

    return tempFile;
  }

  static Future<bool> saveToGallery({
    required String path,
    required String fileName,
  }) async {
    final result = await SaverGallery.saveFile(
      filePath: path,
      fileName: fileName,
      skipIfExists: false,
    );
    if (result.isSuccess) {
      return true;
    } else {
      return false;
    }
  }

  static Future<List<FileSystemEntity>> getSavedPaths(String extension) async {
    final box = Hive.box('mediaBox');
    final paths = box.values.where((p) => p.toString().endsWith(extension));
    return paths
        .map((p) => File(p.toString()))
        .where((f) => f.existsSync())
        .toList();
  }

  static Future<void> cleanDeleted() async {
    final box = Hive.box('mediaBox');
    final urlBox = Hive.box('urlBox');
    final toRemove = <int>[];
    final urlsToRemove = <String>[];

    for (var i = 0; i < box.length; i++) {
      final p = box.getAt(i);
      if (!File(p).existsSync()) toRemove.add(i);
    }

    for (final i in toRemove.reversed) {
      box.deleteAt(i);
    }

    for (var entry in urlBox.toMap().entries) {
      if (!File(entry.value).existsSync()) {
        urlsToRemove.add(entry.key);
      }
    }

    for (final url in urlsToRemove) {
      urlBox.delete(url);
    }
  }

  static Future<String?> getMediaByUrl(String url) async {
    final urlBox = Hive.box('urlBox');
    return urlBox.get(url);
  }
}
