import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerFromUrl extends StatefulWidget {
  @override
  _VideoPlayerFromUrlState createState() => _VideoPlayerFromUrlState();
}

class _VideoPlayerFromUrlState extends State<VideoPlayerFromUrl> {
  late VideoPlayerController _controller;
  late TextEditingController _textEditingController;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network('');
    _textEditingController = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    _textEditingController.dispose();
    super.dispose();
  }

  void _playVideoFromUrl(String url) {
    setState(() {
      _controller = VideoPlayerController.network(url)
        ..initialize().then((_) {
          _controller.play();
        });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        TextField(
          controller: _textEditingController,
          decoration: InputDecoration(
            hintText: 'Enter video URL',
            contentPadding: EdgeInsets.all(16.0),
          ),
        ),
        SizedBox(height: 16.0),
        ElevatedButton(
          onPressed: () {
            _playVideoFromUrl(_textEditingController.text);
          },
          child: Text('Play Video'),
        ),
        SizedBox(height: 16.0),
        _controller.value.isInitialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : Container(),
      ],
    );
  }
}
