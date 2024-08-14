import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mediasaver/platforms/whatsapp/models/whatsapp.dart';
import 'package:mediasaver/platforms/whatsapp/pages/preview.dart';

class GridManager extends StatefulWidget {
  final List<dynamic> tabs;
  final int currentIndex;
  final bool dataLoaded;
  final String file;

  const GridManager({
    super.key,
    required this.tabs,
    required this.currentIndex,
    required this.dataLoaded,
    required this.file,
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

    return widget.dataLoaded
        ? currentFiles.isNotEmpty
            ? GridView.builder(
                cacheExtent: 9999,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 6.0,
                  mainAxisSpacing: 6.0,
                ),
                itemCount: currentFiles.length,
                itemBuilder: (context, index) {
                  final statusFile = currentFiles[index];
                  return InkWell(
                    onLongPress: () {
                      scaffold.hideCurrentSnackBar();
                      statusAction(statusFile.path, 'shareMedia').then(
                        (value) => scaffold.showSnackBar(
                          SnackBar(
                            content: Text(value),
                          ),
                        ),
                      );
                    },
                    onDoubleTap: () {
                      scaffold.hideCurrentSnackBar();
                      final action =
                          appType != 'SAVED' ? 'saveStatus' : 'deleteStatus';
                      statusAction(statusFile.path, action).then(
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
                            type: fileName == 'whatsappFilesVideo'
                                ? 'Video'
                                : 'Image',
                            theme: Theme.of(context),
                            saved: appType == 'SAVED',
                          ),
                        ),
                      );
                    },
                    child: fileName == 'whatsappFilesImages'
                        ? Image.file(
                            File(statusFile.path),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              color: Colors.grey.withOpacity(0.5),
                            ),
                          )
                        : Image.memory(
                            statusFile.mediaByte,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              color: Colors.grey.withOpacity(0.5),
                            ),
                          ),
                  );
                },
              )
            : Center(
                child: Text(
                    '${currentFiles.length} ${appType.toLowerCase()} status available',
                    style: TextStyle(color: Theme.of(context).primaryColor)),
              )
        : const Center(child: CircularProgressIndicator());
  }
}
