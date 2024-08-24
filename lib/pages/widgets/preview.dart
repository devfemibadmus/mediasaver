import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mediasaver/model.dart';
import 'package:video_player/video_player.dart';
import 'package:mediasaver/pages/widgets/video.dart';

// EDIT: popup_menu.dart
// const double _kMenuMinWidth = 0.0 * _kMenuWidthStep;
// const double _kMenuScreenPadding = 0.0;

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
      ..initialize().then((_) => setState(() => _controller.play()));
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

class Preview extends StatefulWidget {
  const Preview({
    super.key,
    required this.previewFile,
    required this.index,
    required this.type,
    required this.theme,
    this.saved = false,
  });

  final List<MediaFiles> previewFile;
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
      backgroundColor: widget.theme.colorScheme.secondary,
      appBar: AppBar(
        foregroundColor: widget.theme.primaryColor,
        backgroundColor: widget.theme.colorScheme.secondary,
        centerTitle: true,
        title: Text(
            "${!move ? widget.index + 1 : currentIndex + 1} of ${widget.previewFile.length} ${widget.type}"),
        actions: [
          PopupMenuButton<String>(
            color: widget.theme.colorScheme.secondary,
            onSelected: (value) {
              final fileInfo =
                  widget.previewFile[!move ? widget.index : currentIndex];
              final actionMap = {
                "download": () => mediaFileAction(fileInfo.url, 'saveMedia'),
                "delete": () {
                  Navigator.pop(context);
                  return mediaFileAction(fileInfo.url, 'deleteStatus');
                },
                "share": () => mediaFileAction(fileInfo.url, 'shareMedia')
              };

              actionMap[value]!().then((result) => scaffold
                  .showSnackBar(SnackBar(content: Text(result.toString()))));
            },
            itemBuilder: (BuildContext context) => [
              if (widget.saved != true)
                PopupMenuItem<String>(
                  value: "download",
                  child: Icon(Icons.download_for_offline_sharp,
                      color: widget.theme.primaryColor),
                ),
              if (widget.saved)
                PopupMenuItem<String>(
                  value: "delete",
                  child: Icon(Icons.delete, color: widget.theme.primaryColor),
                ),
              PopupMenuItem<String>(
                value: "share",
                child: Icon(Icons.share, color: widget.theme.primaryColor),
              ),
            ],
          ),
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
          return Center(
            child: widget.type == "Image"
                ? Image.network(widget.previewFile[index].url,
                    fit: BoxFit.contain)
                : VideoWidget(
                    videoPath: widget.previewFile[index].url, shouldPlay: true),
          );
        },
      ),
    );
  }
}
