import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:whatsappstatus/model.dart';
import 'package:whatsappstatus/preview.dart';

class Whatsapp extends StatefulWidget {
  const Whatsapp({
    super.key,
    required this.appType,
    required this.channel,
  });
  final String appType;
  final String channel;
  @override
  State<Whatsapp> createState() => _WhatsappState();
}

class _WhatsappState extends State<Whatsapp>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  late List<StatusFileInfo> whatsappFilesVideo;
  late List<StatusFileInfo> whatsappFilesImages;
  late Future<List<dynamic>> fetchData;

  @override
  void initState() {
    super.initState();
    fetchData = platform.invokeListMethod(
      'getStatusFilesInfo',
      {'appType': widget.appType},
    ).then((data) => data as List<dynamic>);
    fetchData.then((data) {
      setState(() {
        whatsappFilesImages =
            filterFilesByFormat(parseStatusFiles(data), images, widget.channel);
        whatsappFilesVideo =
            filterFilesByFormat(parseStatusFiles(data), videos, widget.channel);
      });
    });
  }

  Future<void> fetchAndRefreshData() async {
    List? newData = await platform
        .invokeListMethod('getStatusFilesInfo', {'appType': widget.appType});
    setState(() {
      whatsappFilesImages = filterFilesByFormat(
          parseStatusFiles(newData!), images, widget.channel);
      whatsappFilesVideo = filterFilesByFormat(
          parseStatusFiles(newData), videos, widget.channel);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final scaffold = ScaffoldMessenger.of(context);
    final ThemeData theme = Theme.of(context);
    return DefaultTabController(
      length: 2,
      child: FutureBuilder<List<dynamic>>(
        future: fetchData,
        builder: (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {
          whatsappFilesImages = filterFilesByFormat(
              parseStatusFiles(snapshot.data!), images, widget.channel);
          whatsappFilesVideo = filterFilesByFormat(
              parseStatusFiles(snapshot.data!), videos, widget.channel);
          return Scaffold(
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
                      child: Text("${whatsappFilesImages.length} Images"),
                    ),
                    Center(
                      child: Text("${whatsappFilesVideo.length} Video"),
                    ),
                  ],
                ),
              ),
            ),
            body: TabBarView(
              children: [
                whatsappFilesImages.isNotEmpty
                    ? Container(
                        color: theme.colorScheme.background,
                        padding: const EdgeInsets.all(6.0),
                        child: RefreshIndicator(
                          color: Colors.white,
                          backgroundColor: Colors.blue,
                          onRefresh: () async {
                            return await fetchAndRefreshData();
                          },
                          notificationPredicate:
                              (ScrollNotification notification) {
                            return notification.depth == 1;
                          },
                          child: GridView.builder(
                            // cacheExtent: 9999,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 6.0,
                              mainAxisSpacing: 6.0,
                            ),
                            itemCount: whatsappFilesImages.length,
                            itemBuilder: (context, index) {
                              return InkWell(
                                onDoubleTap: () {
                                  if (widget.appType != 'Saved Status') {
                                    saveStatus(
                                      whatsappFilesImages[index].path,
                                      widget.appType,
                                    ).then(
                                      (value) => scaffold.showSnackBar(
                                        const SnackBar(
                                          content: Text('saved to Gallery'),
                                          duration: Duration(seconds: 2),
                                        ),
                                      ),
                                    );
                                  }
                                },
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => Preview(
                                        previewFile: whatsappFilesImages,
                                        index: index,
                                        type: 'Image',
                                        theme: theme,
                                        savedto: widget.appType,
                                      ),
                                    ),
                                  );
                                },
                                child: Image.file(
                                  File(whatsappFilesImages[index].path),
                                  fit: BoxFit.cover,
                                ),
                              );
                            },
                          ),
                        ),
                      )
                    : const Center(child: Text("No Status")),
                whatsappFilesVideo.isNotEmpty
                    ? Container(
                        color: theme.colorScheme.background,
                        padding: const EdgeInsets.all(6.0),
                        child: RefreshIndicator(
                          color: Colors.white,
                          backgroundColor: Colors.blue,
                          onRefresh: () async {
                            return await fetchAndRefreshData();
                          },
                          notificationPredicate:
                              (ScrollNotification notification) {
                            return notification.depth == 1;
                          },
                          child: GridView.builder(
                            cacheExtent: 9999,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 6.0,
                              mainAxisSpacing: 6.0,
                            ),
                            itemCount: whatsappFilesVideo.length,
                            itemBuilder: (context, index) {
                              return InkWell(
                                onDoubleTap: () {
                                  saveStatus(
                                    whatsappFilesImages[index].path,
                                    widget.appType,
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
                                        previewFile: whatsappFilesVideo,
                                        index: index,
                                        type: 'video',
                                        savedto: widget.appType,
                                        theme: theme,
                                      ),
                                    ),
                                  );
                                },
                                child: Image.memory(
                                    whatsappFilesVideo[index].mediaByte),
                              );
                            },
                          ),
                        ),
                      )
                    : const Center(child: Text("No Status")),
              ],
            ),
          );
        },
      ),
    );
  }
}
