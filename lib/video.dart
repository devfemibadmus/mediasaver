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
  final File videoPath;

  @override
  State<VideoWidget> createState() => _VideoWidgetState();
}

class _VideoWidgetState extends State<VideoWidget> {
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.file(widget.videoPath);

    _initializeVideoPlayerFuture = _controller.initialize();
    _controller.setLooping(widget.shouldPlay);
    _controller.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  bool isHover = false;
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
            setState(() {
              isHover = false;
            });
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
                if (_controller.value.isPlaying) {
                  _controller.pause();
                } else {
                  _controller.play();
                }
              });
            },
            child: Container(
              color: Colors.transparent,
              child: Opacity(
                opacity: isHover ? 1 : 0,
                child: Icon(
                  _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                  size: 80.0,
                  color: Colors.white,
                ),
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
                color: Colors.white.withOpacity(0.2),
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
