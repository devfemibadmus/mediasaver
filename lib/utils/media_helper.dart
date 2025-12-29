import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ffmpeg_kit_flutter_new_min_gpl/ffmpeg_kit.dart';
import 'package:path_provider/path_provider.dart';

class MediaHelper {
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
      final cleanedAudioUrl = cleanUrl(audioUrl);
      final audioResponse = await http.get(Uri.parse(cleanedAudioUrl));
      final audioBytes = audioResponse.bodyBytes;
      final appDir = await getApplicationDocumentsDirectory();

      final audioFileName =
          'audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final audioFile = File('${appDir.path}/$audioFileName');
      await audioFile.writeAsBytes(audioBytes);

      final mergedFile = File('${appDir.path}/$outputFileName');

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

  static Future<File> downloadMedia({
    required String url,
    required String fileName,
  }) async {
    final cleanedUrl = cleanUrl(url);
    final response = await http.get(Uri.parse(cleanedUrl));
    final bytes = response.bodyBytes;
    final appDir = await getApplicationDocumentsDirectory();
    final file = File('${appDir.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file;
  }
}
