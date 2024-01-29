import 'dart:io';

import 'package:flutter/material.dart';
import 'package:whatsappstatus/model.dart';

class Whatsapp4b extends StatefulWidget {
  const Whatsapp4b({
    super.key,
    required this.whatsapp4bFilesVideo,
    required this.whatsapp4bFilesImages,
  });
  final List<StatusFileInfo> whatsapp4bFilesVideo;
  final List<StatusFileInfo> whatsapp4bFilesImages;
  @override
  State<Whatsapp4b> createState() => _Whatsapp4bState();
}

class _Whatsapp4bState extends State<Whatsapp4b> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Status saver no-ads'),
            bottom: const TabBar(
              tabs: [
                Center(
                  child: Text("whatsapp4B Images"),
                ),
                Center(
                  child: Text("whatsapp4B Video"),
                ),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              widget.whatsapp4bFilesImages.isNotEmpty
                  ? Container(
                      padding: const EdgeInsets.all(6.0),
                      child: GridView.builder(
                        cacheExtent: 9999,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 6.0,
                          mainAxisSpacing: 6.0,
                        ),
                        itemCount: widget.whatsapp4bFilesImages.length,
                        itemBuilder: (context, index) {
                          return Image.file(
                            File(widget.whatsapp4bFilesImages[index].path),
                            fit: BoxFit.cover,
                          );
                        },
                      ),
                    )
                  : const Center(
                      child: Text("No whatsapp business images"),
                    ),
              widget.whatsapp4bFilesVideo.isNotEmpty
                  ? Container(
                      padding: const EdgeInsets.all(6.0),
                      child: GridView.builder(
                        cacheExtent: 9999,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 6.0,
                          mainAxisSpacing: 6.0,
                        ),
                        itemCount: widget.whatsapp4bFilesVideo.length,
                        itemBuilder: (context, index) {
                          return Image.file(
                            File(widget.whatsapp4bFilesVideo[index].path),
                            fit: BoxFit.cover,
                          );
                        },
                      ),
                    )
                  : const Center(
                      child: Text("No whatsapp business video"),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
