import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoWidget extends StatefulWidget {
  const VideoWidget({
    super.key,
    this.shouldPlay = true,
    required this.videoPath,
  });
  final bool shouldPlay;
  final String videoPath;

  @override
  State<VideoWidget> createState() => _VideoWidgetState();
}

class _VideoWidgetState extends State<VideoWidget> {
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoPath));
    _initializeVideoPlayerFuture = _controller.initialize();
    _controller.setLooping(widget.shouldPlay);
    _controller.addListener(() {
      if (_controller.value.hasError) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Status Gone')));
        Navigator.pop(context);
      }
      if (mounted) {
        setState(() {});
      }
    });
  }

  bool isHover = true;
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (event) {
        if (mounted) {
          setState(() {
            isHover = true;
          });
          Future.delayed(const Duration(seconds: 3), () {
            mounted
                ? setState(() {
                    isHover = false;
                  })
                : null;
          });
        }
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          FutureBuilder(
            future: _initializeVideoPlayerFuture,
            builder: (context, snapshot) {
              return AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              );
            },
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _controller.value.isPlaying
                    ? _controller.pause()
                    : _controller.play();
              });
            },
            child: Opacity(
              opacity: isHover ? 1 : 0,
              child: Icon(
                _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                size: 80.0,
                color: Colors.white,
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius:
                    const BorderRadius.only(topLeft: Radius.circular(10)),
                color: Colors.black.withOpacity(0.5),
              ),
              child: Text(
                "${(_controller.value.duration - _controller.value.position).toString().substring(2).split('.').first} / ${_controller.value.duration.toString().substring(2).split('.').first}",
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PausedVideoPlayer extends StatefulWidget {
  final String videoUrl;

  const PausedVideoPlayer({super.key, required this.videoUrl});

  @override
  PausedVideoPlayerState createState() => PausedVideoPlayerState();
}

class PausedVideoPlayerState extends State<PausedVideoPlayer> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.videoUrl))
      ..initialize().then((_) {
        setState(() {});
        _controller.pause(); // Automatically pause the video
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          )
        : const Center(child: CircularProgressIndicator());
  }
}
