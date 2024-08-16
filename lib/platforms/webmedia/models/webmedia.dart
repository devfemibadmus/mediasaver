import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class WebMedia {
  final String id;
  final String desc;
  final String cover;
  final String platform;
  final String? audioUrl;
  final String? videoUrl;
  final List<Media>? medias;

  WebMedia({
    required this.id,
    required this.desc,
    required this.cover,
    required this.platform,
    this.medias,
    this.audioUrl,
    this.videoUrl,
  });

  factory WebMedia.fromJson(Map<String, dynamic> json) {
    List<Media> mediaList = [];

    if (json.containsKey('videos')) {
      mediaList = (json['videos'] as List).map((video) {
        final videoData = video.values.first;
        return Media.fromJson(videoData);
      }).toList();
    } else if (json.containsKey('media')) {
      mediaList = (json['media'] as List)
          .map((media) => Media.fromJson(media))
          .toList();
    }
    if (mediaList.isEmpty) {
      mediaList = [Media.fromCover(json['content']['cover'])];
    }

    return WebMedia(
      id: json['content']['id'],
      desc: json['content']['desc'],
      cover: json['content']['cover'],
      platform: json['platform'],
      medias: mediaList,
      audioUrl: json['deaf_media']?['audio_url'] as String?,
      videoUrl: json['deaf_media']?['video_url'] as String?,
    );
  }
}

class Media {
  final String? size;
  final String address;
  final String? cover;

  Media({
    this.size,
    required this.address,
    this.cover,
  });
  factory Media.fromCover(String coverUrl) {
    return Media(
      cover: coverUrl,
      address: coverUrl,
      size: null,
    );
  }

  factory Media.fromJson(Map<String, dynamic> json) {
    return Media(
      size: json['size'] as String?,
      address: json['address'] as String,
      cover: json['cover'] as String?,
    );
  }
}

class Api {
  final String apiUrl;

  Api({required this.apiUrl});

  Future<Map<String, dynamic>?> fetchMedia(String url) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {'url': url, 'cut': 'True'},
      );
      final isJson =
          response.headers['content-type']?.contains('application/json') ??
              false;
      if (isJson) {
        final data = jsonDecode(response.body);
        return data;
      }
      return null;
    } on SocketException {
      return {
        'error': true,
        'message': 'No Internet connection. Please check your network settings.'
      };
    } on HttpException {
      return {
        'error': true,
        'message': 'Could not complete the request. Server error.'
      };
    } catch (e) {
      return {'error': true, 'message': 'An unexpected error occurred'};
    }
  }
}
