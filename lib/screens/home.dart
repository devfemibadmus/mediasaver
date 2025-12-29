import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mediasaver/screens/history.dart';
import 'package:mediasaver/screens/preview.dart';
import 'package:mediasaver/utils/media_helper.dart';
import 'dart:convert';
// import 'dart:io';
import '../widgets/media_item_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _urlController = TextEditingController();
  bool _isLoading = false;
  bool _downloadingAll = false;
  int _completedDownloads = 0;
  List<String> _results = [];

  // String get _baseUrl {
  //   if (Platform.isAndroid) return 'http://10.0.2.2:8080';
  //   return 'http://localhost:8080';
  // }

  String get _baseUrl {
    return 'https://mediasaver.link';
  }

  Future<void> _fetchMedia() async {
    if (_urlController.text.isEmpty) return;
    setState(() {
      _isLoading = true;
      _results = [];
    });

    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/api/?url=${_urlController.text}'));

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        final List<String> mediaList = List<String>.from(data['data'] ?? []);

        if (mediaList.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No media found'),
              backgroundColor: Colors.orange,
            ),
          );
          setState(() => _results = []);
        } else {
          setState(() => _results = mediaList);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ??
                data['error_message'] ??
                'Error: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _downloadAll() async {
    if (_results.isEmpty) return;
    setState(() {
      _downloadingAll = true;
      _completedDownloads = 0;
    });

    final videoUrls = MediaHelper.filterVideoUrls(_results);
    final audioUrl = MediaHelper.getAudioUrl(_results);

    for (int i = 0; i < videoUrls.length; i++) {
      final url = videoUrls[i];
      try {
        final extension = MediaHelper.getFileExtension(url);
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_$i$extension';

        final file = await MediaHelper.downloadMedia(
          url: url,
          fileName: fileName,
        );

        if (audioUrl != null && MediaHelper.isVideoUrl(url)) {
          final mergedFile = await MediaHelper.mergeAudioWithVideo(
            videoFile: file,
            audioUrl: audioUrl,
            outputFileName:
                'merged_${DateTime.now().millisecondsSinceEpoch}_$i.mp4',
          );

          if (mergedFile != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Merged video+audio: ${mergedFile.path}")),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Video saved (no audio): ${file.path}")),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Saved: ${file.path}")),
          );
        }
      } catch (e) {
        debugPrint(e.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error downloading: ${e.toString()}")),
        );
      }

      setState(() => _completedDownloads = i + 1);
      await Future.delayed(const Duration(milliseconds: 100));
    }

    setState(() => _downloadingAll = false);

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const HistoryScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: RichText(
          text: const TextSpan(
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
            children: [
              TextSpan(text: "Media "),
              TextSpan(
                  text: "Saver", style: TextStyle(color: Color(0xFF3F61D7)))
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("URL",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Text("Supports videos, images and audio",
                style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 10),
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                hintText: "Paste link here...",
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _fetchMedia,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3F61D7),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text("Preview",
                        style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
            if (_results.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Divider(),
              if (_results.length == 1)
                _buildSingleView(_results[0])
              else
                _buildListView(),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildSingleView(String url) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          MediaHelper.isVideoUrl(url) ? "Video" : "Image",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PreviewScreen(mediaUrl: url),
            ),
          ),
          child: SizedBox(
            height: 250,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: MediaItemTile(
                mediaUrl: url,
                audioUrl: MediaHelper.getAudioUrl(_results),
                forceLargeView: true,
                isHistory: false,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListView() {
    final videoUrls = MediaHelper.filterVideoUrls(_results);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Results",
                style: TextStyle(fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: _downloadingAll ? null : _downloadAll,
              child: _downloadingAll
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: const Color(0xFF3F61D7),
                        value: videoUrls.isNotEmpty
                            ? _completedDownloads / videoUrls.length
                            : 0,
                      ),
                    )
                  : const Text("Download all",
                      style: TextStyle(color: Color(0xFF3F61D7))),
            ),
          ],
        ),
        if (_downloadingAll)
          LinearProgressIndicator(
            value: videoUrls.isNotEmpty
                ? _completedDownloads / videoUrls.length
                : 0,
            backgroundColor: Colors.grey[300],
            color: const Color(0xFF3F61D7),
          ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: videoUrls.length,
          itemBuilder: (context, index) => GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PreviewScreen(mediaUrl: videoUrls[index]),
              ),
            ),
            child: MediaItemTile(
              mediaUrl: videoUrls[index],
              audioUrl: MediaHelper.getAudioUrl(_results),
              forceLargeView: false,
              onDownloadComplete: () {
                if (_downloadingAll) {
                  setState(() => _completedDownloads++);
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}
