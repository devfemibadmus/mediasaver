import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:whatsappstatus/model.dart';
import 'package:whatsappstatus/video.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoPath;

  const VideoPlayerWidget({super.key, required this.videoPath});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.videoPath))
      ..initialize().then((_) {
        setState(() {
          _controller.play();
        });
      });
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: _controller.value.aspectRatio,
      child: VideoPlayer(_controller),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
//

class Preview extends StatefulWidget {
  const Preview({
    super.key,
    required this.previewFile,
    required this.index,
    required this.type,
    required this.theme,
    this.saved = false,
  });
  final List<StatusFileInfo> previewFile;
  final int index;
  final String type;
  final ThemeData theme;
  final bool saved;

  @override
  State<Preview> createState() => _PreviewState();
}

class _PreviewState extends State<Preview> {
  int currentIndex = 0;
  bool move = false;
  @override
  Widget build(BuildContext context) {
    final scaffold = ScaffoldMessenger.of(context);
    return Scaffold(
      backgroundColor: widget.theme.colorScheme.background,
      appBar: AppBar(
        foregroundColor: widget.theme.primaryColor,
        backgroundColor: widget.theme.colorScheme.secondary,
        centerTitle: true,
        title: Text(
            "${!move ? widget.index + 1 : currentIndex + 1} of ${widget.previewFile.length} ${widget.type}"),
        actions: [
          widget.saved != true
              ? IconButton(
                  onPressed: () {
                    saveStatus(widget.previewFile[currentIndex].path).then(
                      (value) => scaffold.showSnackBar(
                        const SnackBar(
                          content: Text("saved to Gallery"),
                          duration: Duration(seconds: 2),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.download),
                )
              : const SizedBox(),
        ],
      ),
      body: PageView.builder(
        itemCount: widget.previewFile.length,
        controller: PageController(initialPage: widget.index),
        onPageChanged: (index) {
          setState(() {
            currentIndex = index;
            move = true;
          });
        },
        itemBuilder: (context, index) {
          return InkWell(
            onLongPress: () {
              saveStatus(widget.previewFile[currentIndex].path).then(
                (value) => scaffold.showSnackBar(
                  const SnackBar(
                    content: Text('saved to Gallery'),
                    duration: Duration(seconds: 2),
                  ),
                ),
              );
            },
            child: widget.type == "Image"
                ? Image.file(
                    File(widget.previewFile[index].path),
                    fit: BoxFit.contain,
                  )
                : VideoWidget(
                    videoPath: File(widget.previewFile[index].path),
                    shouldPlay: true,
                  ),
          );
        },
      ),
    );
  }
}
//