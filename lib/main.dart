import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mediasaver/model.dart';
import 'package:mediasaver/pages/wws.dart';
import 'package:mediasaver/pages/webMedia/webmedias.dart';

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
  bool permissions = false;

  int _currentIndex = 0;
  bool _dataLoaded = false;
  int currentDialogIndex = 0;

  final List<String> dialogContent = [
    'Download videos and photos from Instagram, Facebook, and TikTok.\n\nDouble tap to save status or to delete existing ones.\n\nHold to share saved or not saved status.\n\nMany more functions, click on the bulb to request features.',
    'This app requires access to storage permission. Click here for more information.',
  ];
  final List<String> dialogTitle = [
    'About App',
    'Features',
    'Storage Access Required',
  ];

  List tabs = [
    for (var appType in ['WHATSAPP', 'WHATSAPP4B', 'WEBMEDIA', 'SAVED'])
      {
        'appType': appType,
        'whatsappFilesImages': filterByMimeType(parseMediaFiles([]), images),
        'whatsappFilesVideo': filterByMimeType(parseMediaFiles([]), videos),
      }
  ];
  final List<String> labels = [
    'Whatsapp',
    'W4Business',
    'Web Download',
    'Saved'
  ];

  @override
  void initState() {
    super.initState();
    checkPermissions().then((value) {
      if (value == true) {
        fetchAndUpdateData(true);
      }
    });
  }

  Future<bool> checkPermissions() async {
    bool a = await platform.invokeMethod("hasPermission");
    setState(() {
      permissions = a;
    });
    print("Permission: $a");
    return a;
  }

  void _showFolderDialog() {
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
                  if (currentDialogIndex == dialogContent.length - 2) {
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
                      platform
                          .invokeMethod("requestAccessToMedia")
                          .then((value) async {
                        await checkPermissions().then((permission) {
                          if (permission == true) {
                            fetchAndUpdateData(true);
                          }
                        });
                      });
                      Navigator.of(context).pop();
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

  Future<void> fetchAndUpdateData(bool refresh) async {
    if (tabs[_currentIndex]['appType'] != 'WEBMEDIA' && permissions == true) {
      List? newWhatsappData = await platform.invokeListMethod('getMedias',
          {'appType': tabs[_currentIndex]['appType'], 'refresh': refresh});
      var whatsappFilesImages =
          filterByMimeType(parseMediaFiles(newWhatsappData!), images);
      var whatsappFilesVideo =
          filterByMimeType(parseMediaFiles(newWhatsappData), videos);
      if (!listsAreEqual(
          tabs[_currentIndex]['whatsappFilesImages'], whatsappFilesImages)) {
        setState(() {
          tabs[_currentIndex]['whatsappFilesImages'] = whatsappFilesImages;
        });
      }
      if (!listsAreEqual(
          tabs[_currentIndex]['whatsappFilesVideo'], whatsappFilesVideo)) {
        setState(() {
          tabs[_currentIndex]['whatsappFilesVideo'] = whatsappFilesVideo;
        });
      }
      setState(() {
        _dataLoaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    DateTime currentDate = DateTime.now();
    if (currentDate.year >= 2024 &&
        currentDate.month >= 8 &&
        currentDate.day >= 30) {
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
                            "${tabs[_currentIndex]['whatsappFilesImages'].length} Images"),
                      ),
                      Center(
                        child: Text(
                            "${tabs[_currentIndex]['whatsappFilesVideo'].length} Video"),
                      ),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        GridManager(
                          folderPermit: permissions,
                          tabs: tabs,
                          currentIndex: _currentIndex,
                          dataLoaded: _dataLoaded,
                          file: 'whatsappFilesImages',
                          onRequestPermission: () {
                            _showFolderDialog();
                          },
                        ),
                        GridManager(
                          folderPermit: permissions,
                          tabs: tabs,
                          currentIndex: _currentIndex,
                          dataLoaded: _dataLoaded,
                          file: 'whatsappFilesVideo',
                          onRequestPermission: () {
                            _showFolderDialog();
                          },
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
                            "${tabs[_currentIndex]['whatsappFilesImages'].length} Images"),
                      ),
                      Center(
                        child: Text(
                            "${tabs[_currentIndex]['whatsappFilesVideo'].length} Video"),
                      ),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        GridManager(
                          tabs: tabs,
                          currentIndex: _currentIndex,
                          dataLoaded: _dataLoaded,
                          file: 'whatsappFilesImages',
                          folderPermit: permissions,
                          onRequestPermission: () {
                            _showFolderDialog();
                          },
                        ),
                        GridManager(
                          tabs: tabs,
                          currentIndex: _currentIndex,
                          dataLoaded: _dataLoaded,
                          file: 'whatsappFilesVideo',
                          folderPermit: permissions,
                          onRequestPermission: () {
                            _showFolderDialog();
                          },
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
                            "${tabs[_currentIndex]['whatsappFilesImages'].length} Images"),
                      ),
                      Center(
                        child: Text(
                            "${tabs[_currentIndex]['whatsappFilesVideo'].length} Video"),
                      ),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        GridManager(
                          folderPermit: true,
                          tabs: tabs,
                          currentIndex: _currentIndex,
                          dataLoaded: _dataLoaded,
                          file: 'whatsappFilesImages',
                          onRequestPermission: () {
                            _showFolderDialog();
                          },
                        ),
                        GridManager(
                          folderPermit: true,
                          tabs: tabs,
                          currentIndex: _currentIndex,
                          dataLoaded: _dataLoaded,
                          file: 'whatsappFilesVideo',
                          onRequestPermission: () {
                            _showFolderDialog();
                          },
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
              //fetchAndUpdateData(false);
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
    super.dispose();
  }
}
