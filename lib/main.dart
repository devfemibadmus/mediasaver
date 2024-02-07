import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:whatsappstatus/model.dart';
import 'package:whatsappstatus/preview.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    ThemeData buildThemeData(ColorScheme colorScheme) {
      return ThemeData(
        primaryColor: Colors.white,
        secondaryHeaderColor: Colors.teal,
        colorScheme: colorScheme.copyWith(secondary: Colors.teal[700]),
      );
    }

    return MaterialApp(
      theme: buildThemeData(ColorScheme.fromSwatch()
          .copyWith(background: Colors.white, onPrimary: Colors.black)),
      darkTheme: buildThemeData(ColorScheme.fromSwatch()
          .copyWith(background: Colors.black, onPrimary: Colors.white)),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _currentIndex = 0;
  late Timer _timer;
  bool _dataLoaded = false;
  bool _dataNew = false;
  late List _tabs;
  bool _isProcessing = false;
  @override
  void initState() {
    super.initState();
    _tabs = [
      for (var appType in ['WHATSAPP', 'WHATSAPP4B', 'SAVED'])
        {
          'appType': appType,
          'whatsappFilesImages':
              filterFilesByFormat(parseStatusFiles([]), images, appType),
          'whatsappFilesVideo':
              filterFilesByFormat(parseStatusFiles([]), videos, appType),
        }
    ];
    platform.invokeMethod("checkStoragePermission").then((value) {
      if (value == false) {
        platform.invokeMethod("requestStoragePermission");
      }
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      platform.invokeMethod("checkStoragePermission").then((value) async {
        if (value) {
          _timer.cancel();
        }
      });
    });
    Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!_isProcessing) {
        _continuousMethods();
      }
    });
  }

  Future<void> fetchAndUpdateData() async {
    // print("fetchAndUpdateData");
    // print(_isProcessing);
    setState(() {
      _dataNew = false;
    });
    List? newWhatsappData = await platform.invokeListMethod(
        'getStatusFilesInfo', {'appType': _tabs[_currentIndex]['appType']});
    var whatsappFilesImages = filterFilesByFormat(
        parseStatusFiles(newWhatsappData!),
        images,
        _tabs[_currentIndex]['appType']);
    var whatsappFilesVideo = filterFilesByFormat(
        parseStatusFiles(newWhatsappData),
        videos,
        _tabs[_currentIndex]['appType']);
    if (!listsAreEqual(
        _tabs[_currentIndex]['whatsappFilesImages'], whatsappFilesImages)) {
      setState(() {
        _tabs[_currentIndex]['whatsappFilesImages'] = whatsappFilesImages;
        _dataNew = true;
      });
      // print("whatsappFilesImages dataNew");
    }

    if (!listsAreEqual(
        _tabs[_currentIndex]['whatsappFilesVideo'], whatsappFilesVideo)) {
      setState(() {
        // print("updating videos");
        _tabs[_currentIndex]['whatsappFilesVideo'] = mergeVideoLists(
          _tabs[_currentIndex]['whatsappFilesVideo'],
          whatsappFilesVideo,
        );
        _dataNew = true;
      });
      // print("whatsappFilesVideo dataNew");
    }
  }

  Future<void> getVideoThumbnailAsync() async {
    if (_dataNew) {
      // print("_dataNew");
      for (int i = 0;
          i < _tabs[_currentIndex]['whatsappFilesVideo'].length;
          i++) {
        if (_tabs[_currentIndex]['whatsappFilesVideo'][i].mediaByte.isEmpty) {
          Uint8List? mediaByte = await platform.invokeMethod(
              'getVideoThumbnailAsync', {
            'absolutePath': _tabs[_currentIndex]['whatsappFilesVideo'][i].path
          });
          setState(() {
            _tabs[_currentIndex]['whatsappFilesVideo'][i].mediaByte = mediaByte;
            if (_tabs[_currentIndex]['whatsappFilesVideo'].length - i == 1) {}
          });
        }
      }
    }
    setState(() {
      _isProcessing = false;
      _dataLoaded = true;
    });
    // print("getVideoThumbnailAsync");
    // print(_isProcessing);
  }

  Future<void> _continuousMethods() async {
    _isProcessing = true;
    await fetchAndUpdateData().then((_) async {
      await getVideoThumbnailAsync();
    });
  }

  @override
  Widget build(BuildContext context) {
    DateTime currentDate = DateTime.now();
    final ThemeData theme = Theme.of(context);
    final scaffold = ScaffoldMessenger.of(context);
    if (currentDate.year == 2024 &&
        currentDate.month == 3 &&
        currentDate.day == 1) {
      return Center(
        child: GestureDetector(
            onTap: () async => await platform.invokeMethod('launchUpdate'),
            child: const Center(
                child: Text(
              'Update your app',
              style: TextStyle(fontSize: 24),
            ))),
      );
    }
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(90.0),
          child: AppBar(
            elevation: 0.0,
            foregroundColor: theme.primaryColor,
            backgroundColor: theme.colorScheme.secondary,
            title: GestureDetector(
                onTap: () async => await platform.invokeMethod('launchDemo'),
                child: const Text('Status saver no-ads')),
            actions: [
              IconButton(
                  onPressed: () async =>
                      await platform.invokeMethod('sendEmail'),
                  icon: const Icon(
                    Icons.lightbulb,
                    color: Colors.yellow,
                  )),
              IconButton(
                  onPressed: () async =>
                      await platform.invokeMethod('shareApp'),
                  icon: const Icon(Icons.share))
            ],
            bottom: TabBar(
              dividerColor: theme.colorScheme.secondary,
              labelColor: theme.primaryColor,
              unselectedLabelColor: theme.primaryColor,
              indicatorColor: theme.primaryColor,
              tabs: [
                Center(
                    child: Text(
                        "${_tabs[_currentIndex]['whatsappFilesImages'].length} Images")),
                Center(
                    child: Text(
                        "${_tabs[_currentIndex]['whatsappFilesVideo'].length} Video")),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _buildTabContent('whatsappFilesImages', scaffold),
            _buildTabContent('whatsappFilesVideo', scaffold),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: Theme.of(context).colorScheme.background,
          selectedItemColor: Theme.of(context).colorScheme.onPrimary,
          unselectedItemColor: Theme.of(context).secondaryHeaderColor,
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.chat),
              label: 'Whatsapp',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.business),
              label: 'Whatsapp Business',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.business),
              label: 'All Saved',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(String files, scaffold) {
    final currentTab = _tabs[_currentIndex];
    final currentFiles = currentTab[files];
    final appType = currentTab['appType'];

    return _dataLoaded
        ? currentFiles.isNotEmpty
            ? GridView.builder(
                cacheExtent: 9999,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 6.0,
                    mainAxisSpacing: 6.0),
                itemCount: currentFiles.length,
                itemBuilder: (context, index) {
                  final statusFile = currentFiles[index];
                  return InkWell(
                    onLongPress: () =>
                        statusAction(statusFile.path, 'shareMedia').then(
                            (value) => scaffold
                                .showSnackBar(SnackBar(content: Text(value)))),
                    onDoubleTap: () {
                      final action =
                          appType != 'SAVED' ? 'saveStatus' : 'deleteStatus';
                      statusAction(statusFile.path, action).then((value) =>
                          scaffold
                              .showSnackBar(SnackBar(content: Text(value))));
                    },
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => Preview(
                                previewFile: currentFiles,
                                index: index,
                                type: files == 'whatsappFilesVideo'
                                    ? 'Video'
                                    : 'Image',
                                theme: Theme.of(context),
                                saved: appType == 'SAVED')),
                      );
                    },
                    child: files == 'whatsappFilesImages'
                        ? Image.file(File(statusFile.path),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(color: Colors.grey.withOpacity(0.5)))
                        : Image.memory(statusFile.mediaByte,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(color: Colors.grey.withOpacity(0.5))),
                  );
                },
              )
            : Center(
                child: Text(
                    '${currentFiles.length} ${appType.toLowerCase()} status available',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary)),
              )
        : const Center(child: CircularProgressIndicator());
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}
