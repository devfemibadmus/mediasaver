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
        length: 3,
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
                dividerColor: theme.colorScheme.secondary,
                labelColor: theme.primaryColor,
                unselectedLabelColor: theme.primaryColor,
                indicatorColor: theme.primaryColor,
                tabs: [
                  Center(
                    child: Text("${widget.whatsappFilesImages.length} Images"),
                  ),
                  Center(
                    child: Text("${widget.whatsappFilesVideo.length} Video"),
                  ),
                  Center(
                    child: Text("${widget.whatsappFilesVideo.length} Saved"),
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
                              saveStatus(
                                widget.whatsappFilesImages[index].path,
                                'Whatsapp Status',
                              ).then(
                                (value) => scaffold.showSnackBar(
                                  const SnackBar(
                                    content: Text('saved to Gallery'),
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
                                    previewFile: widget.whatsappFilesImages,
                                    index: index,
                                    type: 'Image',
                                    theme: theme,
                                    savedto: 'Whatsapp Status',
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
                      color: theme.colorScheme.background,
                      padding: const EdgeInsets.all(6.0),
                      child: GridView.builder(
                        cacheExtent: 9999,
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
                              saveStatus(
                                widget.whatsappFilesVideo[index].path,
                                'Whatsapp Status',
                              ).then(
                                (value) => scaffold.showSnackBar(
                                  const SnackBar(
                                    content: Text('saved to Gallery'),
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
                                    type: 'video',
                                    savedto: 'Whatsapp Status',
                                    theme: theme,
                                  ),
                                ),
                              );
                            },
                            child: Image.memory(
                                widget.whatsappFilesVideo[index].mediaByte),
                          );
                        },
                      ),
                    )
                  : const Center(
                      child: Text("No whatsapp Video"),
                    ),
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
                              saveStatus(
                                widget.whatsappFilesImages[index].path,
                                'Whatsapp Status',
                              ).then(
                                (value) => scaffold.showSnackBar(
                                  const SnackBar(
                                    content: Text('saved to Gallery'),
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
                                    previewFile: widget.whatsappFilesImages,
                                    index: index,
                                    type: 'Image',
                                    theme: theme,
                                    savedto: 'Whatsapp Status',
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
                      child: Text("No Saved Status"),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
