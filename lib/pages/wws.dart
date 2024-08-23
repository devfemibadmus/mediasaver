import 'package:flutter/material.dart';
import 'package:mediasaver/model.dart';
import 'package:mediasaver/widgets/preview.dart';

class GridManager extends StatefulWidget {
  final List<dynamic> tabs;
  final int currentIndex;
  final bool dataLoaded;
  final String file;
  final bool folderPermit;
  final Function() onRequestPermission;

  const GridManager({
    super.key,
    required this.tabs,
    required this.currentIndex,
    required this.dataLoaded,
    required this.file,
    required this.folderPermit,
    required this.onRequestPermission,
  });

  @override
  GridManagerState createState() => GridManagerState();
}

class GridManagerState extends State<GridManager> {
  @override
  Widget build(BuildContext context) {
    final scaffold = ScaffoldMessenger.of(context);
    final currentTab = widget.tabs[widget.currentIndex];
    final fileName = widget.file;
    final currentFiles = currentTab[fileName];
    final appType = currentTab['appType'];

    return widget.folderPermit
        ? widget.dataLoaded
            ? currentFiles.isNotEmpty
                ? GridView.builder(
                    cacheExtent: 9999,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 6.0,
                      mainAxisSpacing: 6.0,
                    ),
                    itemCount: currentFiles.length,
                    itemBuilder: (context, index) {
                      final mediaFile = currentFiles[index];
                      // print("${mediaFile.url}?getThumbnail");
                      return InkWell(
                        onLongPress: () {
                          scaffold.hideCurrentSnackBar();
                          mediaFileAction(mediaFile.url, 'shareMedia').then(
                            (value) => scaffold.showSnackBar(
                              SnackBar(
                                content: Text(value),
                              ),
                            ),
                          );
                        },
                        onDoubleTap: () {
                          scaffold.hideCurrentSnackBar();
                          final action = appType != 'SAVED'
                              ? 'saveStatus'
                              : 'deleteStatus';
                          mediaFileAction(mediaFile.url, action).then(
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
                            ? Image.network(
                                mediaFile.url,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  color: Colors.grey.withOpacity(0.5),
                                ),
                              )
                            : Image.network(
                                "${mediaFile.url}/getThumbnail",
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
                        '${currentFiles.length} ${appType.toLowerCase()} media available',
                        style:
                            TextStyle(color: Theme.of(context).primaryColor)),
                  )
            : const Center(child: CircularProgressIndicator())
        : TextButton(
            onPressed: () {
              widget.onRequestPermission();
            },
            child: const Text("Give Permission"));
  }
}
// getThumbnal