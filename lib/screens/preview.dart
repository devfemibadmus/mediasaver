import 'package:flutter/material.dart';
import 'package:mediasaver/utils/media_helper.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';

class PreviewScreen extends StatelessWidget {
  final String mediaUrl;
  final bool isLocalFile;

  const PreviewScreen({
    super.key,
    required this.mediaUrl,
    this.isLocalFile = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(mediaUrl.split('/').last),
        actions: [
          if (isLocalFile)
            IconButton(
              onPressed: () => _downloadToGallery(context),
              icon: const Icon(Icons.download),
            ),
        ],
      ),
      body: MediaHelper.isVideoUrl(mediaUrl)
          ? _VideoPreview(videoUrl: mediaUrl, isLocalFile: isLocalFile)
          : _ImagePreview(imageUrl: mediaUrl, isLocalFile: isLocalFile),
    );
  }

  void _downloadToGallery(BuildContext context) async {
    final fileName = mediaUrl.split('/').last;
    final success = await MediaHelper.saveToGallery(
      path: mediaUrl,
      fileName: fileName,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Saved to gallery' : 'Failed to save'),
      ),
    );
  }
}

class _VideoPreview extends StatefulWidget {
  final String videoUrl;
  final bool isLocalFile;

  const _VideoPreview({required this.videoUrl, required this.isLocalFile});

  @override
  State<_VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<_VideoPreview> {
  VideoPlayerController? _controller;
  bool _isPlaying = false;
  bool _isInitialized = false;

  String _cleanUrl(String url) {
    return url.replaceAll('&amp;', '&');
  }

  @override
  void initState() {
    super.initState();
    if (widget.isLocalFile) {
      _controller = VideoPlayerController.file(File(widget.videoUrl));
    } else {
      final cleanedUrl = _cleanUrl(widget.videoUrl);
      _controller = VideoPlayerController.networkUrl(Uri.parse(cleanedUrl));
    }

    _controller!.initialize().then((_) {
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: _isInitialized
                ? AspectRatio(
                    aspectRatio: _controller!.value.aspectRatio,
                    child: VideoPlayer(_controller!),
                  )
                : const CircularProgressIndicator(),
          ),
        ),
        if (_isInitialized)
          VideoProgressIndicator(
            _controller!,
            allowScrubbing: true,
            colors: const VideoProgressColors(
              playedColor: Color(0xFF3F61D7),
              bufferedColor: Colors.grey,
              backgroundColor: Colors.grey,
            ),
          ),
        if (_isInitialized)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () {
                    final position = _controller!.value.position -
                        const Duration(seconds: 10);
                    _controller!.seekTo(position);
                  },
                  icon: const Icon(Icons.replay_10, size: 30),
                ),
                IconButton(
                  onPressed: () {
                    if (_isPlaying) {
                      _controller!.pause();
                    } else {
                      _controller!.play();
                    }
                    setState(() => _isPlaying = !_isPlaying);
                  },
                  icon: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    size: 40,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    final position = _controller!.value.position +
                        const Duration(seconds: 10);
                    _controller!.seekTo(position);
                  },
                  icon: const Icon(Icons.forward_10, size: 30),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ImagePreview extends StatelessWidget {
  final String imageUrl;
  final bool isLocalFile;

  const _ImagePreview({required this.imageUrl, required this.isLocalFile});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: isLocalFile
          ? Image.file(
              File(imageUrl),
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(Icons.error, size: 80),
            )
          : Image.network(
              MediaHelper.cleanUrl(imageUrl),
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(Icons.error, size: 80),
            ),
    );
  }
}
