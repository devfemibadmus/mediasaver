import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mediasaver/model.dart';
import 'package:mediasaver/preview.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    ThemeData buildThemeData(ColorScheme colorScheme, Color secondaryColor) {
      return ThemeData(
        primaryColor: Colors.white,
        secondaryHeaderColor: Colors.black,
        colorScheme: colorScheme.copyWith(secondary: secondaryColor),
      );
    }

    return MaterialApp(
      theme: buildThemeData(
          ColorScheme.fromSwatch()
              .copyWith(background: Colors.white, onPrimary: Colors.black),
          Colors.black),
      darkTheme: buildThemeData(
          ColorScheme.fromSwatch()
              .copyWith(background: Colors.black, onPrimary: Colors.white),
          Colors.white),
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
  bool downloadBtnClicked = false;
  bool downloaded = false;
  bool showedDialog = false;
  String? medialPath;
  String? medialUrl;
  String? thumbnailUrl;
  String? errorMessage;
  String pastebtn = "Paste";
  List<String> dialogContent = [
    'Opensource free for all 100% secured and trusted. Click here to see.',
    'Download any media(video/image) from any platform, website, TikTok, Instagram, Youtube, Facebook, X...\n\nDouble tap to save status or to delete existing ones.\n\nHold to share saved or not saved status.\n\nMany more functions, click on the bulb to request features.',
    'This app requires access to storage permission. Click here for more information.',
  ];
  List<String> dialogTitle = [
    'About App',
    'Features',
    'Storage Access Required',
  ];
  int currentDialogIndex = 0;

  List<String> labels = [
    'Whatsapp',
    'W4Business',
    'Other Platform',
    'Saved Media'
  ];
  @override
  void initState() {
    super.initState();
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
        _showDialog();
        setState(() {
          showedDialog = true;
        });
      }
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      platform.invokeMethod("checkStoragePermission").then((value) async {
        // print("checkStoragePermission $value");
        if (value) {
          _timer.cancel();
          if (showedDialog) {
            setState(() {
              showedDialog = false;
              Navigator.of(context).pop();
            });
          }
        } else {
          if (!showedDialog) {
            // print("showing new Dialog");
            _showDialog();
            setState(() {
              showedDialog = true;
            });
          }
        }
        // print("showedDialog $showedDialog");
      });
    });
    Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!_isProcessing) {
        _continuousMethods();
      }
    });
  }

  void _showDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              title: Text(
                dialogTitle[currentDialogIndex],
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white),
              ),
              content: GestureDetector(
                onTap: (() async {
                  if (currentDialogIndex == dialogContent.length - 1) {
                    await platform.invokeMethod('launchPrivacyPolicy');
                  }
                  if (currentDialogIndex == dialogContent.length - 3) {
                    await platform.invokeMethod('launchDemo');
                  }
                }),
                child: Text(
                  dialogContent[currentDialogIndex],
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    SystemNavigator.pop();
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
                if (currentDialogIndex != 0)
                  TextButton(
                    onPressed: currentDialogIndex > 0
                        ? () {
                            setState(() {
                              currentDialogIndex--;
                            });
                          }
                        : null,
                    child: const Text(
                      'Back',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                if (currentDialogIndex != dialogContent.length - 1)
                  TextButton(
                    onPressed: currentDialogIndex < dialogContent.length - 1
                        ? () {
                            setState(() {
                              currentDialogIndex++;
                            });
                          }
                        : null,
                    child: const Text(
                      'Next',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                if (currentDialogIndex == dialogContent.length - 1)
                  TextButton(
                    onPressed: () {
                      platform.invokeMethod("requestStoragePermission");
                    },
                    child: const Text(
                      'Okay',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
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
        // print("whatsappFilesImages dataNew");
      });
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
    if (_tabs[_currentIndex]['appType'] != '') {
      _isProcessing = true;
      await fetchAndUpdateData().then((_) async {
        await getVideoThumbnailAsync();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    DateTime currentDate = DateTime.now();
    final ThemeData theme = Theme.of(context);
    final scaffold = ScaffoldMessenger.of(context);
    if (currentDate.year >= 2024 &&
        currentDate.month >= 7 &&
        currentDate.day >= 20) {
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
            backgroundColor: theme.secondaryHeaderColor,
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
          backgroundColor: Colors.transparent,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          selectedItemColor: Theme.of(context).colorScheme.secondary,
          unselectedItemColor: Theme.of(context).colorScheme.secondary,
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
                        color: Theme.of(context).colorScheme.secondary)),
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
                      cursorColor: Theme.of(context).colorScheme.secondary,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        errorText: errorMessage,
                        labelText: 'Media url',
                        labelStyle: TextStyle(
                            color: Theme.of(context).colorScheme.secondary),
                        contentPadding: const EdgeInsets.all(5.0),
                        isDense: true,
                        enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color:
                                    Theme.of(context).colorScheme.secondary)),
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
                      // print("clicked");
                      _focusNode.unfocus();
                      setState(() {
                        downloadPercentage = 0.0;
                        linkready = false;
                        downloadBtnClicked = false;
                        downloaded = false;
                        medialPath = null;
                        medialUrl = null;
                        thumbnailUrl = null;
                        errorMessage = null;
                      });
                      fetchClipboardContent().then((value) {
                        setState(() {
                          if (pastebtn == "Paste") {
                            _textController.text = value;
                            _textController.value =
                                TextEditingValue(text: value);
                            // print("pasted");
                          }
                          if (isValidUrl(_textController.text)) {
                            linkready = true;
                            errorMessage = null;
                            thumbnailUrl = null;
                            // print("linkready $linkready");
                          } else {
                            errorMessage = 'Not a valid URL';
                            linkready = false;
                          }
                        });

                        if (isValidUrl(value)) {
                          fecthMediaFromServer(value).then(
                            (value) {
                              setState(() {
                                linkready = false;
                                // print("linkready $linkready");
                                if (isValidUrl(value[0])) {
                                  thumbnailUrl = value[1];
                                  medialUrl = value[0];
                                } else {
                                  errorMessage = value[0];
                                  pastebtn = "Paste";
                                }
                              });
                            },
                          );
                        }
                      });
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
              if (linkready) const CircularProgressIndicator(),
              if (thumbnailUrl != null)
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Image.network(thumbnailUrl!),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.network(
                        thumbnailUrl!,
                        fit: BoxFit.cover,
                        height: MediaQuery.of(context).size.height / 1.7,
                        width: MediaQuery.of(context).size.width,
                      ),
                    ),
                    /*
                    if (downloadBtnClicked)
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          shape: BoxShape.circle,
                        ),
                      ),
                    if (downloadBtnClicked)
                      SizedBox.square(
                        dimension: 70,
                        child: CircularProgressIndicator(
                          value: downloadPercentage,
                          color: Theme.of(context).colorScheme.secondary,
                          strokeWidth: 10.0,
                        ),
                      ),
                    if (downloadBtnClicked)
                      Text(
                        '${(downloadPercentage * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    */
                    if (!downloaded && !downloadBtnClicked)
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            downloadBtnClicked = true;
                          });
                          downloadFile(medialUrl!).then((result) {
                            if (result[0] == true) {
                              setState(() {
                                downloadBtnClicked = false;
                                downloaded = true;
                                medialPath = result[1];
                              });
                            } else if (result[0] == "Already Saved") {
                              setState(() {
                                downloadBtnClicked = false;
                                downloaded = true;
                                medialPath = result[1];
                              });
                              scaffold.showSnackBar(
                                SnackBar(
                                  content: Text(result[0]),
                                ),
                              );
                            } else if (result[0] == false) {
                              setState(() {
                                downloadBtnClicked = false;
                                downloaded = false;
                              });
                              scaffold.showSnackBar(
                                SnackBar(
                                  content: Text(result[1]),
                                ),
                              );
                            }
                          });
                        },
                        icon: Icon(
                          Icons.download,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        label: Text(
                          "Download",
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.secondary,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    if (downloadBtnClicked) const CircularProgressIndicator(),
                    if (downloaded)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimary
                                .withOpacity(0.4),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(25),
                              bottomLeft: Radius.circular(25),
                            ),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                color: Theme.of(context).colorScheme.secondary,
                                onPressed: (() {
                                  statusAction(medialPath!, 'deleteStatus')
                                      .then((value) {
                                    scaffold.showSnackBar(
                                        SnackBar(content: Text(value)));
                                    setState(() {
                                      downloadPercentage = 0.0;
                                      linkready = false;
                                      downloadBtnClicked = false;
                                      downloaded = false;
                                      medialUrl = null;
                                      thumbnailUrl = null;
                                      errorMessage = null;
                                      pastebtn = "Paste";
                                      _textController.text = '';
                                    });
                                  });
                                }),
                                icon: const Icon(Icons.delete),
                              ),
                              IconButton(
                                color: Theme.of(context).colorScheme.secondary,
                                onPressed: (() {
                                  statusAction(medialPath!, 'shareMedia').then(
                                      (value) => scaffold.showSnackBar(
                                          SnackBar(content: Text(value))));
                                }),
                                icon: const Icon(Icons.share),
                              ),
                              IconButton(
                                color: Theme.of(context).colorScheme.secondary,
                                onPressed: (() {
                                  _focusNode.requestFocus();
                                  setState(() {
                                    downloadPercentage = 0.0;
                                    linkready = false;
                                    downloadBtnClicked = false;
                                    downloaded = false;
                                    medialUrl = null;
                                    thumbnailUrl = null;
                                    errorMessage = null;
                                    pastebtn = "Paste";
                                    _textController.text = '';
                                  });
                                }),
                                icon: const Icon(Icons.close),
                              )
                            ],
                          ),
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
