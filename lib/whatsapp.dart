import 'dart:io';

import 'package:flutter/material.dart';
import 'package:whatsappstatus/model.dart';
import 'package:whatsappstatus/preview.dart';

class Whatsapp extends StatefulWidget {
  const Whatsapp({
    super.key,
    required this.whatsappFilesVideo,
    required this.whatsappFilesImages,
  });
  final List<StatusFileInfo> whatsappFilesVideo;
  final List<StatusFileInfo> whatsappFilesImages;
  @override
  State<Whatsapp> createState() => _WhatsappState();
}

class _WhatsappState extends State<Whatsapp> {
  @override
  Widget build(BuildContext context) {
    final scaffold = ScaffoldMessenger.of(context);
    return MaterialApp(
      home: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Status saver no-ads'),
            actions: [
              IconButton(
                onPressed: () {
                  //
                },
                icon: const Icon(Icons.more_vert),
              )
            ],
            bottom: TabBar(
              tabs: [
                Center(
                  child: Text("${widget.whatsappFilesImages.length} Images"),
                ),
                Center(
                  child: Text("${widget.whatsappFilesVideo.length} Video"),
                ),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              widget.whatsappFilesImages.isNotEmpty
                  ? Container(
                      padding: const EdgeInsets.all(6.0),
                      child: GridView.builder(
                        // cacheExtent: 9999,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 6.0,
                          mainAxisSpacing: 6.0,
                        ),
                        itemCount: widget.whatsappFilesImages.length,
                        itemBuilder: (context, index) {
                          return InkWell(
                            onDoubleTap: () {
                              saveImage(
                                widget.whatsappFilesImages[index].path,
                                'Status/Whatsapp Images',
                              ).then(
                                (value) => scaffold.showSnackBar(
                                  const SnackBar(
                                    content: Text('Image saved to Gallery'),
                                    duration: Duration(seconds: 2),
                                  ),
                                ),
                              );
                            },
                            onTap: () {
                              print(index);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => Preview(
                                    previewFile: widget.whatsappFilesImages,
                                    index: index,
                                  ),
                                ),
                              );
                            },
                            child: Image.file(
                              File(widget.whatsappFilesImages[index].path),
                              fit: BoxFit.cover,
                            ),
                          );
                        },
                      ),
                    )
                  : const Center(
                      child: Text("No whatsapp Images"),
                    ),
              widget.whatsappFilesVideo.isNotEmpty
                  ? Container(
                      padding: const EdgeInsets.all(6.0),
                      child: GridView.builder(
                        // cacheExtent: 9999,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 6.0,
                          mainAxisSpacing: 6.0,
                        ),
                        itemCount: widget.whatsappFilesVideo.length,
                        itemBuilder: (context, index) {
                          return InkWell(
                            onDoubleTap: () {
                              saveImage(
                                widget.whatsappFilesVideo[index].path,
                                'Status/Whatsapp Video',
                              ).then(
                                (value) => scaffold.showSnackBar(
                                  const SnackBar(
                                    content: Text('Video saved to Gallery'),
                                    duration: Duration(seconds: 2),
                                  ),
                                ),
                              );
                            },
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => Preview(
                                    previewFile: widget.whatsappFilesVideo,
                                    index: index,
                                  ),
                                ),
                              );
                            },
                            child: Image.file(
                              File(widget.whatsappFilesVideo[index].path),
                              fit: BoxFit.cover,
                            ),
                          );
                        },
                      ),
                    )
                  : const Center(
                      child: Text("No whatsapp Video"),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
