import 'dart:async';
import 'package:mediasaver/wws.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mediasaver/model.dart';
import 'package:mediasaver/platforms/whatsapp/models/whatsapp.dart';
import 'package:mediasaver/platforms/webMedia/webmedias.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    ThemeData buildThemeData(ColorScheme colorScheme, Color secondaryColor) {
      return ThemeData(
        primaryColor: colorScheme.primary,
        secondaryHeaderColor: secondaryColor,
        colorScheme: colorScheme,
      );
    }

    return MaterialApp(
      theme: buildThemeData(
        ColorScheme.fromSwatch(
          brightness: Brightness.light,
          primarySwatch: Colors.grey,
        ).copyWith(
          primary: Colors.black,
          secondary: Colors.white,
          surface: Colors.black,
          onPrimary: Colors.white,
        ),
        Colors.black,
      ),
      darkTheme: buildThemeData(
        ColorScheme.fromSwatch(
          brightness: Brightness.dark,
          primarySwatch: Colors.grey,
        ).copyWith(
          primary: Colors.white,
          secondary: Colors.black,
          surface: Colors.white,
          onPrimary: Colors.black,
          onSecondary: Colors.white,
        ),
        Colors.white,
      ),
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
  late Timer _timer;
  bool showedDialog = false;
  int currentDialogIndex = 0;

  late List _tabs;
  bool _dataNew = false;
  int _currentIndex = 0;
  bool _dataLoaded = false;
  bool _isProcessing = false;

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

  List<String> labels = ['Whatsapp', 'W4Business', 'Web Download', 'Saved'];
  @override
  void initState() {
    super.initState();
    _tabs = [
      for (var appType in ['WHATSAPP', 'WHATSAPP4B', 'WEBMEDIA', 'SAVED'])
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
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(10), // Optional: Adjust corner radius
                side:
                    BorderSide(color: Theme.of(context).primaryColor, width: 2),
              ),
              backgroundColor: Theme.of(context).colorScheme.secondary,
              title: Text(
                dialogTitle[currentDialogIndex],
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor),
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
                  style: TextStyle(color: Theme.of(context).primaryColor),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    SystemNavigator.pop();
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
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
                    child: Text(
                      'Back',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
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
                    child: Text(
                      'Next',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                if (currentDialogIndex == dialogContent.length - 1)
                  TextButton(
                    onPressed: () {
                      platform.invokeMethod("requestStoragePermission");
                    },
                    child: Text(
                      'Okay',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
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
    if (_tabs[_currentIndex]['appType'] != 'WEBMEDIA') {
      _isProcessing = true;
      await fetchAndUpdateData().then((_) async {
        await getVideoThumbnailAsync();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: theme.colorScheme.secondary,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(70.0),
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
          ),
        ),
        body: IndexedStack(
          index: _currentIndex,
          children: [
            DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  TabBar(
                    dividerColor: theme.colorScheme.secondary,
                    labelColor: theme.primaryColor,
                    unselectedLabelColor: theme.primaryColor,
                    indicatorColor: theme.primaryColor,
                    tabs: [
                      Center(
                        child: Text(
                            "${_tabs[_currentIndex]['whatsappFilesImages'].length} Images"),
                      ),
                      Center(
                        child: Text(
                            "${_tabs[_currentIndex]['whatsappFilesVideo'].length} Video"),
                      ),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        GridManager(
                          tabs: _tabs,
                          currentIndex: _currentIndex,
                          dataLoaded: _dataLoaded,
                          file: 'whatsappFilesImages',
                        ),
                        GridManager(
                          tabs: _tabs,
                          currentIndex: _currentIndex,
                          dataLoaded: _dataLoaded,
                          file: 'whatsappFilesVideo',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  TabBar(
                    dividerColor: theme.colorScheme.secondary,
                    labelColor: theme.primaryColor,
                    unselectedLabelColor: theme.primaryColor,
                    indicatorColor: theme.primaryColor,
                    tabs: [
                      Center(
                        child: Text(
                            "${_tabs[_currentIndex]['whatsappFilesImages'].length} Images"),
                      ),
                      Center(
                        child: Text(
                            "${_tabs[_currentIndex]['whatsappFilesVideo'].length} Video"),
                      ),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        GridManager(
                          tabs: _tabs,
                          currentIndex: _currentIndex,
                          dataLoaded: _dataLoaded,
                          file: 'whatsappFilesImages',
                        ),
                        GridManager(
                          tabs: _tabs,
                          currentIndex: _currentIndex,
                          dataLoaded: _dataLoaded,
                          file: 'whatsappFilesVideo',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  TabBar(
                    dividerColor: theme.colorScheme.secondary,
                    labelColor: theme.primaryColor,
                    unselectedLabelColor: theme.primaryColor,
                    indicatorColor: theme.primaryColor,
                    tabs: const [
                      Center(child: Text("Other Platform")),
                      Center(child: Text("How It Works")),
                    ],
                  ),
                  const Expanded(
                    child: TabBarView(
                      children: [
                        WebMedias(),
                        WebMedias(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  TabBar(
                    dividerColor: theme.colorScheme.secondary,
                    labelColor: theme.primaryColor,
                    unselectedLabelColor: theme.primaryColor,
                    indicatorColor: theme.primaryColor,
                    tabs: [
                      Center(
                        child: Text(
                            "${_tabs[_currentIndex]['whatsappFilesImages'].length} Images"),
                      ),
                      Center(
                        child: Text(
                            "${_tabs[_currentIndex]['whatsappFilesVideo'].length} Video"),
                      ),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        GridManager(
                          tabs: _tabs,
                          currentIndex: _currentIndex,
                          dataLoaded: _dataLoaded,
                          file: 'whatsappFilesImages',
                        ),
                        GridManager(
                          tabs: _tabs,
                          currentIndex: _currentIndex,
                          dataLoaded: _dataLoaded,
                          file: 'whatsappFilesVideo',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: theme.colorScheme.secondary,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          selectedItemColor: theme.primaryColor,
          unselectedItemColor: theme.primaryColor,
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

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}
