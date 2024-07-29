import 'dart:convert';
import 'package:http/http.dart' as http;

class TikTokVideo {
  final String id;
  final String desc;
  final int views;
  final int likes;
  final int comments;
  final int saves;
  final int shares;
  final String cover;
  final Author author;
  final List<VideoQuality> videos;
  final Music music;

  TikTokVideo({
    required this.id,
    required this.desc,
    required this.views,
    required this.likes,
    required this.comments,
    required this.saves,
    required this.shares,
    required this.cover,
    required this.author,
    required this.videos,
    required this.music,
  });

  factory TikTokVideo.fromJson(Map<String, dynamic> json) {
    return TikTokVideo(
      id: json['content']['id'],
      desc: json['content']['desc'],
      views: json['content']['views'],
      likes: json['content']['likes'],
      comments: json['content']['comments'],
      saves: json['content']['saves'],
      shares: json['content']['share'],
      cover: json['content']['cover'],
      author: Author.fromJson(json['author']),
      videos: (json['videos'] as List)
          .map((video) => VideoQuality.fromJson(video))
          .toList(),
      music: Music.fromJson(json['music']),
    );
  }
}

class Author {
  final String name;
  final String username;
  final bool verified;
  final String image;
  final int videos;
  final int likes;
  final int friends;
  final int followers;
  final int following;

  Author({
    required this.name,
    required this.username,
    required this.verified,
    required this.image,
    required this.videos,
    required this.likes,
    required this.friends,
    required this.followers,
    required this.following,
  });

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      name: json['name'],
      username: json['username'],
      verified: json['verified'],
      image: json['image'],
      videos: json['videos'],
      likes: json['likes'],
      friends: json['friends'],
      followers: json['followers'],
      following: json['following'],
    );
  }
}

class VideoQuality {
  final String quality;
  final int size;
  final String address;

  VideoQuality({
    required this.quality,
    required this.size,
    required this.address,
  });

  factory VideoQuality.fromJson(Map<String, dynamic> json) {
    return VideoQuality(
      quality: json.keys.first,
      size: json.values.first['size'],
      address: json.values.first['address'],
    );
  }
}

class Music {
  final String author;
  final String title;
  final String cover;
  final int duration;
  final String src;

  Music({
    required this.author,
    required this.title,
    required this.cover,
    required this.duration,
    required this.src,
  });

  factory Music.fromJson(Map<String, dynamic> json) {
    return Music(
      author: json['author'],
      title: json['title'],
      cover: json['cover'],
      duration: json['duration'],
      src: json['src'],
    );
  }
}

class TikTokImage {
  final String id;
  final String desc;
  final String title;
  final int views;
  final int likes;
  final int comments;
  final int saves;
  final int shares;
  final Author author;
  final List<String> images;
  final Music music;

  TikTokImage({
    required this.id,
    required this.desc,
    required this.title,
    required this.views,
    required this.likes,
    required this.comments,
    required this.saves,
    required this.shares,
    required this.author,
    required this.images,
    required this.music,
  });

  factory TikTokImage.fromJson(Map<String, dynamic> json) {
    return TikTokImage(
      id: json['content']['id'],
      desc: json['content']['desc'],
      title: json['content']['title'],
      views: json['content']['views'],
      likes: json['content']['likes'],
      comments: json['content']['comments'],
      saves: json['content']['saves'],
      shares: json['content']['share'],
      author: Author.fromJson(json['author']),
      images: List<String>.from(json['images']),
      music: Music.fromJson(json['music']),
    );
  }
}

class TikTokBot {
  final String apiUrl;

  TikTokBot({required this.apiUrl});

  Future<Map<String, dynamic>?> fetchMedia(String url) async {
    final response = await http.post(
      Uri.parse(apiUrl),
      body: {'url': url},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      //print(data);
      return data;
    } else {
      print(response.body);
      print("response.body");
      return null;
    }
  }

  bool isVideoUrl(String url) {
    final videoPattern = RegExp(r'tiktok\.com/.*/video/(\d+)');
    return videoPattern.hasMatch(url);
  }

  bool isImageUrl(String url) {
    final imagePattern = RegExp(r'tiktok\.com/.*/photo/(\d+)');
    return imagePattern.hasMatch(url);
  }
}
