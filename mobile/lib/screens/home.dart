import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:io' show Platform;
import 'package:mediasaver/screens/history.dart';
import 'package:mediasaver/screens/preview.dart';
import 'package:mediasaver/utils/media_helper.dart';
import 'dart:convert';
import '../widgets/media_item_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  static const double _tabletBreakpoint = 768;
  static const double _contentMaxWidth = 720;
  final TextEditingController _urlController = TextEditingController();
  bool _isLoading = false;
  bool _downloadingAll = false;
  int _completedDownloads = 0;
  List<String> _results = [];
  String _lastClipboard = '';
  DateTime? _lastShareHandledAt;
  int _fetchSerial = 0;

  String get _baseUrl {
    return 'https://mediasaver.link';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _autoFillFromClipboard();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _urlController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _autoFillFromClipboard();
    }
  }

  Future<void> _pasteFromClipboard() async {
    await _autoFillFromClipboard();
  }

  Future<void> applySharedText(String text) async {
    _lastShareHandledAt = DateTime.now();
    await _fillUrl(text);
  }

  Future<void> _autoFillFromClipboard() async {
    try {
      String? clipboardText;

      final lastShareHandledAt = _lastShareHandledAt;
      if (lastShareHandledAt != null &&
          DateTime.now().difference(lastShareHandledAt) <
              const Duration(seconds: 2)) {
        return;
      }

      final data = await Clipboard.getData(Clipboard.kTextPlain);
      clipboardText = data?.text;

      if (clipboardText != null &&
          clipboardText.isNotEmpty &&
          clipboardText != _lastClipboard &&
          (clipboardText.startsWith('http://') ||
              clipboardText.startsWith('https://'))) {
        await _fillUrl(clipboardText);
      }
    } catch (e) {
      debugPrint('Clipboard error: $e');
    }
  }

  Future<void> _fillUrl(String text, {bool shouldFetch = true}) async {
    final url = _extractFirstUrl(text) ?? text.trim();
    _lastClipboard = url;
    setState(() {
      _urlController.text = url;
      _results = [];
    });

    if (!shouldFetch) return;

    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted && !_isLoading) {
      _fetchMedia();
    }
  }

  String? _extractFirstUrl(String text) {
    final match = RegExp(r'https?://\S+').firstMatch(text);
    return match?.group(0)?.replaceAll(RegExp(r'[),.\]]+$'), '');
  }

  Future<void> _fetchMedia() async {
    final requestUrl = _urlController.text.trim();
    if (requestUrl.isEmpty) return;
    if (MediaHelper.isUnsupportedSocialUrl(requestUrl)) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('This link is not supported'),
          backgroundColor: Colors.grey[800],
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final requestId = ++_fetchSerial;
    setState(() {
      _isLoading = true;
      _results = [];
    });

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/?url=$requestUrl'),
        headers: MediaHelper.buildRequestHeaders(
          extraHeaders: {
            'X-Media-Source-Url': requestUrl,
          },
        ),
      );

      final data = json.decode(response.body);

      if (!mounted) return;
      if (requestId != _fetchSerial ||
          requestUrl != _urlController.text.trim()) {
        return;
      }

      if (response.statusCode == 200) {
        final List<String> mediaList = List<String>.from(data['data'] ?? []);

        if (mediaList.isEmpty) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('No media found'),
              backgroundColor: Colors.grey[800],
              duration: const Duration(seconds: 2),
            ),
          );
          setState(() => _results = []);
        } else {
          setState(() => _results = mediaList);
        }
      } else {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ??
                data['error_message'] ??
                'Error: ${response.statusCode}'),
            backgroundColor: Colors.grey[800],
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      if (requestId != _fetchSerial ||
          requestUrl != _urlController.text.trim()) {
        return;
      }
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error: $e'),
          backgroundColor: Colors.grey[800],
          duration: const Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted &&
          requestId == _fetchSerial &&
          requestUrl == _urlController.text.trim()) {
        setState(() => _isLoading = false);
      }
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
    int successCount = 0;
    int skippedCount = 0;

    for (int i = 0; i < videoUrls.length; i++) {
      final url = videoUrls[i];

      // Check if already downloaded
      final existingMedia = await MediaHelper.getMediaByUrl(url);
      if (existingMedia != null) {
        skippedCount++;
        setState(() => _completedDownloads = i + 1);
        continue;
      }

      try {
        final extension = MediaHelper.getFileExtension(url);
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_$i$extension';

        final file = await MediaHelper.saveToGalleryAndStore(
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
            successCount++;
          }
        } else {
          successCount++;
        }
      } catch (e) {
        debugPrint(e.toString());
      }

      setState(() => _completedDownloads = i + 1);
      await Future.delayed(const Duration(milliseconds: 100));
    }

    setState(() => _downloadingAll = false);

    if (mounted) {
      String message = '';
      if (successCount > 0) {
        message = '$successCount media saved';
      }
      if (skippedCount > 0) {
        message += message.isNotEmpty
            ? ', $skippedCount already downloaded'
            : '$skippedCount already downloaded';
      }
      if (message.isEmpty) {
        message = 'Download failed';
      }

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.grey[800],
          duration: const Duration(seconds: 2),
        ),
      );

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const HistoryScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isTablet = width >= _tabletBreakpoint;

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
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
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          FocusManager.instance.primaryFocus?.unfocus();
        },
        behavior: HitTestBehavior.opaque,
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 32 : 20,
            vertical: 20,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("URL",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Text("Supports videos, images and audio",
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _urlController,
                    decoration: InputDecoration(
                      hintText: "Paste link here...",
                      suffixIcon: Platform.isIOS
                          ? null
                          : IconButton(
                              onPressed: _pasteFromClipboard,
                              icon: const Icon(Icons.content_paste),
                              tooltip: 'Paste',
                            ),
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
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ),
                  if (_results.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Divider(),
                    if (_results.length == 1)
                      _buildSingleView(_results[0], isTablet)
                    else
                      _buildListView(),
                  ]
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSingleView(String url, bool isTablet) {
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
            height: isTablet ? 320 : 250,
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
