import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mediasaver/model.dart';
import 'package:mediasaver/pages/preview.dart';

class GridManager extends StatefulWidget {
  final List<dynamic> tabs;
  final int currentIndex;
  final bool dataLoaded;
  final String file;
  final Function() onrefresh;
  final Function() onRequestPermission;
  final bool haspermission;

  const GridManager({
    super.key,
    required this.tabs,
    required this.currentIndex,
    required this.dataLoaded,
    required this.file,
    required this.onrefresh,
    required this.haspermission,
    required this.onRequestPermission,
  });

  @override
  WhatsappState createState() => WhatsappState();
}

class WhatsappState extends State<GridManager> {
  @override
  Widget build(BuildContext context) {
    final scaffold = ScaffoldMessenger.of(context);
    final currentTab = widget.tabs[widget.currentIndex];
    final fileName = widget.file;
    final currentFiles = currentTab[fileName];
    final appType = currentTab['appType'];
    if (appType != "SAVED" && widget.haspermission == false) {
      return TextButton(
          onPressed: () {
            widget.onRequestPermission();
          },
          child: const Text("Give Permission"));
    } else if (widget.dataLoaded == false) {
      return const Center(child: CircularProgressIndicator());
    } else if (currentFiles.isNotEmpty == false) {
      late String message;
      if (fileName.toLowerCase().contains('image')) {
        message = "images available";
      } else {
        message = "videos available";
      }
      return Center(
        child: Text('${currentFiles.length} ${appType.toLowerCase()} $message',
            style: TextStyle(color: Theme.of(context).primaryColor)),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await widget.onrefresh();
      },
      child: GridView.builder(
        cacheExtent: 9999,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 6.0,
          mainAxisSpacing: 6.0,
        ),
        itemCount: currentFiles.length,
        itemBuilder: (context, index) {
          final mediaFile = currentFiles[index];
          return InkWell(
            onLongPress: () {
              scaffold.hideCurrentSnackBar();
              mediaAction(mediaFile.path, 'shareMedia').then(
                (value) => scaffold.showSnackBar(
                  SnackBar(
                    content: Text(value),
                  ),
                ),
              );
            },
            onDoubleTap: () {
              scaffold.hideCurrentSnackBar();
              final action = appType != 'SAVED' ? 'saveMedia' : 'deleteMedia';
              mediaAction(mediaFile.path, action).then(
                (value) => scaffold.showSnackBar(
                  SnackBar(
                    content: Text(value),
                  ),
                ),
              );
            },
            onTap: () {
              scaffold.hideCurrentSnackBar();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Preview(
                    previewFile: currentFiles,
                    index: index,
                    type: fileName == 'whatsappFilesVideo' ? 'Video' : 'Image',
                    theme: Theme.of(context),
                    saved: appType == 'SAVED',
                  ),
                ),
              );
            },
            child: fileName == 'whatsappFilesImages'
                ? Image.file(
                    File(mediaFile.path),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey.withOpacity(0.5),
                    ),
                  )
                : Image.memory(
                    mediaFile.mediaByte,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey.withOpacity(0.5),
                    ),
                  ),
          );
        },
      ),
    );
  }
}
