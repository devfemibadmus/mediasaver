import 'dart:convert';
import 'package:http/http.dart' as http;

class WebMedia {
  final String id;
  final String desc;
  final String cover;
  final String platform;
  final List<Media>? medias;

  WebMedia({
    required this.id,
    required this.desc,
    required this.cover,
    required this.platform,
    this.medias,
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
    final response = await http.post(
      Uri.parse(apiUrl),
      body: {'url': url, 'cut': 'True'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      //print(data);
      return data;
    } else {
      // print(response.body);
      // print("response.body");
      return null;
    }
  }

  bool isValidUrl(String url) {
    // TODO: url validator
    return true;
  }
}
