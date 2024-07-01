import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mediasaver/model.dart';
import 'package:mediasaver/preview.dart';

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

  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  /*
  final _formKey = GlobalKey<FormState>();
  String _selectedQuality = 'default';
  */
  double downloadPercentage = 0.0;
  bool linkready = false;
  bool validlink = false;
  String? thumbnailUrl;
  String? errorMessage;
  String pastebtn = "Paste";

  List<String> labels = [
    'Whatsapp',
    'W4Business',
    'Other Platform',
    'Saved Media'
  ];
  @override
  void initState() {
    super.initState();

    DownloadService.setDownloadProgressHandler((progress) {
      setState(() {
        downloadPercentage = progress;
      });
    });

    _tabs = [
      for (var appType in ['WHATSAPP', 'WHATSAPP4B', '', 'SAVED'])
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
    if (currentDate.year >= 2024 &&
        currentDate.month >= 7 &&
        currentDate.day >= 10) {
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
                child: const FittedBox(
                    fit: BoxFit.fitWidth, child: Text('Media Saver'))),
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
                if ([0, 1, 3].contains(_currentIndex))
                  Center(
                      child: Text(
                          "${_tabs[_currentIndex]['whatsappFilesImages'].length} Images")),
                if ([0, 1, 3].contains(_currentIndex))
                  Center(
                      child: Text(
                          "${_tabs[_currentIndex]['whatsappFilesVideo'].length} Video")),
                if (_currentIndex == 2)
                  const Center(child: Text("Other Platform")),
                if (_currentIndex == 2) const Center(child: Text("Quotes")),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [
            if ([0, 1, 3].contains(_currentIndex))
              _buildTabContent('whatsappFilesImages', scaffold),
            if ([0, 1, 3].contains(_currentIndex))
              _buildTabContent('whatsappFilesVideo', scaffold),
            if (_currentIndex == 2) _buildTabContent('otherplatform', scaffold),
            if (_currentIndex == 2) _buildTabContent('quotes', scaffold),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: theme.colorScheme.background,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          selectedItemColor: Theme.of(context).colorScheme.onPrimary,
          unselectedItemColor: Theme.of(context).secondaryHeaderColor,
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.chat),
              label: labels[0],
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.business),
              label: labels[1],
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.link_rounded),
              label: labels[2],
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.download),
              label: labels[3],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(String files, scaffold) {
    if (_currentIndex == 2) {
      return files == "quotes"
          ? Center(
              child: Text("No Quotes",
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary)))
          : platformMediaDownloaderWidget(scaffold);
    }
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

  Widget platformMediaDownloaderWidget(scaffold) {
    return StatefulBuilder(
      builder: (context, setState) {
        return Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextFormField(
                      onChanged: ((value) {
                        setState(() {
                          if (isValidUrl(value)) {
                            _textController.text = value;
                            errorMessage = null;
                            if (_focusNode.hasFocus) pastebtn = "Search";
                          } else {
                            errorMessage = 'Not a valid URL';
                            pastebtn = "Paste";
                          }
                        });
                      }),
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary),
                      controller: _textController,
                      focusNode: _focusNode,
                      cursorColor: Theme.of(context).colorScheme.onPrimary,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        errorText: errorMessage,
                        labelText: 'Media url',
                        labelStyle: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary),
                        contentPadding: const EdgeInsets.all(5.0),
                        isDense: true,
                        enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color:
                                    Theme.of(context).colorScheme.onPrimary)),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.secondary),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  ElevatedButton(
                    // handle the button text to know wether search or paste
                    onPressed: () {
                      _focusNode.unfocus();
                      fetchClipboardContent().then(
                        (value) => setState(() {
                          if (pastebtn == "Paste") {
                            _textController.text = value;
                          }
                          if (isValidUrl(_textController.text)) {
                            linkready = true;
                            errorMessage = null;
                            fecthMediaFromServer(_textController.text).then(
                              (value) {
                                linkready = false;
                                if (isValidUrl(value[0])) {
                                  thumbnailUrl = value[1];
                                  DownloadService.downloadFile(value[0])
                                      .then((result) {
                                    print('Download result: $result');
                                  });
                                } else {
                                  errorMessage = value[0];
                                  pastebtn = "Paste";
                                }
                              },
                            );
                          } else {
                            errorMessage = 'Not a valid URL';
                            linkready = false;
                          }
                        }),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(6),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      pastebtn,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 20),
              if (linkready && thumbnailUrl == null)
                const CircularProgressIndicator(),
              if (thumbnailUrl != null)
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.network(thumbnailUrl!),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox.square(
                      dimension: 70,
                      child: CircularProgressIndicator(
                        value: downloadPercentage,
                        color: Theme.of(context).colorScheme.secondary,
                        strokeWidth: 10.0,
                      ),
                    ),
                    Text(
                      '${(downloadPercentage * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ],
                ),
              /*
              Form(
                key: _formKey,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: _selectedQuality,
                        decoration: InputDecoration(
                          labelText: 'Video Quality',
                          labelStyle: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                          border: InputBorder.none,
                        ),
                        items: [
                          'default',
                          '144p',
                          '240p',
                          '360p',
                          '480p',
                          '720p',
                          '1080p'
                        ]
                            .map((quality) => DropdownMenuItem(
                                  value: quality,
                                  child: Text(quality),
                                ))
                            .toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _selectedQuality = newValue!;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a video quality';
                          }
                          return null;
                        },
                      ),
                    ),
                    // Adjust the space between the dropdown and the button
                    Flexible(
                      flex: 5,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            print('Video url is: ${_textController.text}');
                            print('Selected video quality: $_selectedQuality');
                          }
                        },
                        child: Text(
                          'Download',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              */
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
