import 'package:flutter/material.dart';
import 'package:mediasaver/utils/media_helper.dart';
import 'package:video_player/video_player.dart';

class MediaItemTile extends StatefulWidget {
  final String mediaUrl;
  final String? audioUrl;
  final bool isHistory;
  final bool onlyButton;
  final bool forceLargeView;
  final Function()? onDownloadComplete;

  const MediaItemTile({
    super.key,
    required this.mediaUrl,
    this.audioUrl,
    this.isHistory = false,
    this.onlyButton = false,
    this.forceLargeView = false,
    this.onDownloadComplete,
  });

  @override
  State<MediaItemTile> createState() => _MediaItemTileState();
}

class _MediaItemTileState extends State<MediaItemTile> {
  bool _isDownloading = false;

  bool get _isVideo => MediaHelper.isVideoUrl(widget.mediaUrl);

  Future<void> _downloadMedia() async {
    setState(() => _isDownloading = true);

    try {
      // Check if already downloaded
      final existingMedia = await MediaHelper.getMediaByUrl(widget.mediaUrl);
      if (existingMedia != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Already downloaded')),
          );
        }
        setState(() => _isDownloading = false);
        return;
      }

      final extension = MediaHelper.getFileExtension(widget.mediaUrl);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}$extension';

      final file = await MediaHelper.saveToGalleryAndStore(
        url: widget.mediaUrl,
        fileName: fileName,
      );

      if (widget.audioUrl != null && MediaHelper.isVideoUrl(widget.mediaUrl)) {
        final mergedFile = await MediaHelper.mergeAudioWithVideo(
          videoFile: file,
          audioUrl: widget.audioUrl!,
          outputFileName: 'merged_${DateTime.now().millisecondsSinceEpoch}.mp4',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(mergedFile != null
                  ? 'Video saved'
                  : 'Video saved (no audio)'),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Media saved')),
          );
        }
      }

      if (widget.onDownloadComplete != null) {
        widget.onDownloadComplete!();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed')),
        );
      }
    } finally {
      setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onlyButton) {
      return ElevatedButton(
        onPressed: _isDownloading ? null : _downloadMedia,
        style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3F61D7),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        child: _isDownloading
            ? const SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : const Text("Download", style: TextStyle(color: Colors.white)),
      );
    }

    final bool isLargeView = widget.forceLargeView;

    if (isLargeView) {
      return SizedBox(
        height: 250,
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                width: double.infinity,
                height: 250,
                child: _isVideo
                    ? _VideoThumbnailLarge(url: widget.mediaUrl)
                    : FutureBuilder<bool>(
                        future: MediaHelper.checkIfImageExists(widget.mediaUrl),
                        builder: (context, snapshot) {
                          if (snapshot.data == true) {
                            return Image.network(
                              MediaHelper.cleanUrl(widget.mediaUrl),
                              fit: BoxFit.cover,
                            );
                          }
                          return Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: Icon(Icons.image,
                                  size: 50, color: Colors.grey),
                            ),
                          );
                        },
                      ),
              ),
            ),
            Positioned(
              bottom: 15,
              right: 15,
              child: ElevatedButton(
                onPressed: _isDownloading ? null : _downloadMedia,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3F61D7),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isDownloading
                    ? const SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        "Download",
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: _isVideo
                      ? _VideoThumbnailSmall(url: widget.mediaUrl)
                      : FutureBuilder<bool>(
                          future:
                              MediaHelper.checkIfImageExists(widget.mediaUrl),
                          builder: (context, snapshot) {
                            if (snapshot.data == true) {
                              return Image.network(
                                MediaHelper.cleanUrl(widget.mediaUrl),
                                fit: BoxFit.cover,
                              );
                            }
                            return Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: Icon(Icons.image,
                                    size: 30, color: Colors.grey),
                              ),
                            );
                          },
                        ),
                ),
              ),
              if (_isVideo)
                const CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.white70,
                    child:
                        Icon(Icons.play_arrow, size: 16, color: Colors.black)),
            ],
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_isVideo ? "Video" : "Image",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(_isVideo ? "MP4 Content" : "JPG Content",
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 5),
                widget.isHistory
                    ? const Row(children: [
                        Icon(Icons.share_outlined, size: 18),
                        SizedBox(width: 20),
                        Icon(Icons.delete_outline, size: 18)
                      ])
                    : GestureDetector(
                        onTap: _isDownloading ? null : _downloadMedia,
                        child: _isDownloading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.file_download_outlined,
                                color: Colors.grey),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoThumbnailSmall extends StatefulWidget {
  final String url;
  const _VideoThumbnailSmall({required this.url});

  @override
  State<_VideoThumbnailSmall> createState() => __VideoThumbnailSmallState();
}

class __VideoThumbnailSmallState extends State<_VideoThumbnailSmall> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    final cleanedUrl = MediaHelper.cleanUrl(widget.url);
    _controller = VideoPlayerController.networkUrl(Uri.parse(cleanedUrl))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _initialized = true;
            _controller.setVolume(0);
          });
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _initialized
        ? VideoPlayer(_controller)
        : Container(
            color: Colors.grey[200],
            child: const Center(
              child: Icon(Icons.videocam, size: 30, color: Colors.grey),
            ),
          );
  }
}

class _VideoThumbnailLarge extends StatefulWidget {
  final String url;
  const _VideoThumbnailLarge({required this.url});

  @override
  State<_VideoThumbnailLarge> createState() => __VideoThumbnailLargeState();
}

class __VideoThumbnailLargeState extends State<_VideoThumbnailLarge> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    final cleanedUrl = MediaHelper.cleanUrl(widget.url);
    _controller = VideoPlayerController.networkUrl(Uri.parse(cleanedUrl))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _initialized = true;
            _controller.setVolume(0);
          });
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _initialized
        ? VideoPlayer(_controller)
        : Container(
            color: Colors.grey[200],
            child: const Center(
              child: Icon(Icons.videocam, size: 50, color: Colors.grey),
            ),
          );
  }
}
