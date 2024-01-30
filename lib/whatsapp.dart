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
    final ThemeData theme = Theme.of(context);
    return MaterialApp(
      home: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(90.0),
            child: AppBar(
              elevation: 0.0,
              foregroundColor: theme.primaryColor,
              backgroundColor: theme.colorScheme.secondary,
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
                padding: const EdgeInsets.all(10),
                dividerColor: Theme.of(context).colorScheme.secondary,
                labelColor: Theme.of(context).primaryColor,
                unselectedLabelColor: Theme.of(context).primaryColor,
                indicatorColor: Theme.of(context).primaryColor,
                indicatorPadding: const EdgeInsets.only(top: 20),
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
          ),
          body: TabBarView(
            children: [
              widget.whatsappFilesImages.isNotEmpty
                  ? Container(
                      color: theme.colorScheme.background,
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
                              print(theme.colorScheme.background);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => Preview(
                                    previewFile: widget.whatsappFilesImages,
                                    index: index,
                                    type: 'Image',
                                    theme: theme,
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
                                    type: 'Video',
                                    theme: Theme.of(context),
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
