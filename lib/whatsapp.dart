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

class _WhatsappState extends State<Whatsapp> {
  //
  late List<StatusFileInfo> whatsappFilesVideo;
  late List<StatusFileInfo> whatsappFilesImages;

  @override
  void initState() {
    super.initState();
    platform.invokeListMethod(
      'getStatusFilesInfo',
      {'appType': widget.appType},
    ).then((value) {
      setState(() {
        whatsappFilesImages = filterFilesByFormat(
            parseStatusFiles(value!), images, widget.channel);
        whatsappFilesVideo = filterFilesByFormat(
            parseStatusFiles(value), videos, widget.channel);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final scaffold = ScaffoldMessenger.of(context);
    final ThemeData theme = Theme.of(context);
    return DefaultTabController(
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
                  )
                : const Center(child: Text("No Status")),
            whatsappFilesVideo.isNotEmpty
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
                          child:
                              Image.memory(whatsappFilesVideo[index].mediaByte),
                        );
                      },
                    ),
                  )
                : const Center(child: Text("No Status")),
          ],
        ),
      ),
    );
  }
}

class StreamBuilderExampleApp extends StatelessWidget {
  const StreamBuilderExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: StreamBuilderExample(),
    );
  }
}

class StreamBuilderExample extends StatefulWidget {
  const StreamBuilderExample({super.key});

  @override
  State<StreamBuilderExample> createState() => _StreamBuilderExampleState();
}

class _StreamBuilderExampleState extends State<StreamBuilderExample> {
  final Stream<int> _bids = (() {
    late final StreamController<int> controller;
    controller = StreamController<int>(
      onListen: () async {
        await Future<void>.delayed(const Duration(seconds: 1));
        controller.add(1);
        await Future<void>.delayed(const Duration(seconds: 1));
        await controller.close();
      },
    );
    return controller.stream;
  })();

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: Theme.of(context).textTheme.displayMedium!,
      textAlign: TextAlign.center,
      child: Container(
        alignment: FractionalOffset.center,
        color: Colors.white,
        child: StreamBuilder<int>(
          stream: _bids,
          builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
            List<Widget> children;
            if (snapshot.hasError) {
              children = <Widget>[
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 60,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text('Error: ${snapshot.error}'),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('Stack trace: ${snapshot.stackTrace}'),
                ),
              ];
            } else {
              switch (snapshot.connectionState) {
                case ConnectionState.none:
                  children = const <Widget>[
                    Icon(
                      Icons.info,
                      color: Colors.blue,
                      size: 60,
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Text('Select a lot'),
                    ),
                  ];
                case ConnectionState.waiting:
                  children = const <Widget>[
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Text('Awaiting bids...'),
                    ),
                  ];
                case ConnectionState.active:
                  children = <Widget>[
                    const Icon(
                      Icons.check_circle_outline,
                      color: Colors.green,
                      size: 60,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text('\$${snapshot.data}'),
                    ),
                  ];
                case ConnectionState.done:
                  children = <Widget>[
                    const Icon(
                      Icons.info,
                      color: Colors.blue,
                      size: 60,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text('\$${snapshot.data} (closed)'),
                    ),
                  ];
              }
            }

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: children,
            );
          },
        ),
      ),
    );
  }
}
