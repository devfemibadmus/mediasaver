import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mediasaver/model.dart';
import 'package:mediasaver/widgets/wws.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:mediasaver/pages/admob/models.dart';
import 'package:mediasaver/pages/webmedia/webmedias.dart';

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
  final adManager = AdManager();
  late Timer _timer;
  bool showedDialog = false;
  int currentDialogIndex = 0;
  bool haspermission = true;
  bool _dataNew = false;
  int _currentIndex = 0;
  bool _dataLoaded = false;
  bool _isProcessing = false;

  List<String> dialogContent = [
    'Download videos and photos from Instagram, Facebook, and TikTok.\n\nDouble tap to save status or to delete existing ones.\n\nHold to share saved or not saved status.\n\nMany more functions, click on the bulb to request features.',
    'This app requires access to Android\\media folder. so it can fetch your whatsapp and whatsapp business statuses.\n\nClick here for more information.',
  ];
  List<String> dialogTitle = [
    'Features',
    'WhatsApp Statuses',
  ];
  List tabs = [
    for (var appType in ['WHATSAPP', 'WHATSAPP4B', 'WEBMEDIA', 'SAVED'])
      {
        'appType': appType,
        'whatsappFilesImages':
            filterByMimeType(parseMediaFiles([]), images, appType),
        'whatsappFilesVideo':
            filterByMimeType(parseMediaFiles([]), videos, appType),
      }
  ];
  List<String> labels = ['Whatsapp', 'W4Business', 'Others', 'Saved'];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      platform.invokeMethod("checkStoragePermission").then((value) async {
        setState(() {
          haspermission = value;
        });
        if (value) {
          _timer.cancel();
          if (!_isProcessing) {
            _continuousMethods();
          }
          startService();
        }
      });
    });
    Timer.periodic(const Duration(seconds: 15), (timer) {
      if (!_isProcessing && haspermission == true) {
        _continuousMethods();
      }
    });
    _preloadAds();
  }

  void _preloadAds() {
    adManager.loadRewardedAd();
    adManager.loadInterstitialAd();
  }

  void _showAds() {
    final Random random = Random();
    if (random.nextBool()) {
      if (adManager.isRewardedAdReady()) {
        adManager.showRewardedAd(
          onAdDismissed: () {
            //
          },
          onUserEarnedReward: () {
            //
          },
        );
      } else if (adManager.isInterstitialAdReady()) {
        adManager.showInterstitialAd();
      }
    } else {
      if (adManager.isInterstitialAdReady()) {
        adManager.showInterstitialAd();
      } else if (adManager.isRewardedAdReady()) {
        adManager.showRewardedAd(
          onAdDismissed: () {
            //
          },
          onUserEarnedReward: () {
            //
          },
        );
      }
    }
  }

  void _requestReview() async {
    final int result = await platform.invokeMethod('getTimeUsed');
    if (result % 5 == 0) {
      final InAppReview inAppReview = InAppReview.instance;
      if (await inAppReview.isAvailable()) {
        inAppReview.requestReview();
      }
    }
  }

  void showPermissionDialog() {
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

  Future<void> fetchAndUpdateData() async {
    setState(() {
      _dataNew = false;
    });
    List? newWhatsappData = await platform.invokeListMethod(
        'getMediaFilesInfo', {'appType': tabs[_currentIndex]['appType']});
    var whatsappFilesImages = filterByMimeType(
        parseMediaFiles(newWhatsappData!),
        images,
        tabs[_currentIndex]['appType']);
    var whatsappFilesVideo = filterByMimeType(parseMediaFiles(newWhatsappData),
        videos, tabs[_currentIndex]['appType']);
    if (!listsAreEqual(
        tabs[_currentIndex]['whatsappFilesImages'], whatsappFilesImages)) {
      setState(() {
        tabs[_currentIndex]['whatsappFilesImages'] = whatsappFilesImages;
        _dataNew = true;
      });
    }

    if (!listsAreEqual(
        tabs[_currentIndex]['whatsappFilesVideo'], whatsappFilesVideo)) {
      setState(() {
        tabs[_currentIndex]['whatsappFilesVideo'] = mergeVideoLists(
          tabs[_currentIndex]['whatsappFilesVideo'],
          whatsappFilesVideo,
        );
        _dataNew = true;
      });
    }
  }

  Future<void> getVideoThumbnailAsync() async {
    if (_dataNew) {
      for (int i = 0;
          i < tabs[_currentIndex]['whatsappFilesVideo'].length;
          i++) {
        if (tabs[_currentIndex]['whatsappFilesVideo'][i].mediaByte.isEmpty) {
          Uint8List? mediaByte = await platform.invokeMethod(
              'getVideoThumbnailAsync', {
            'absolutePath': tabs[_currentIndex]['whatsappFilesVideo'][i].path
          });
          setState(() {
            tabs[_currentIndex]['whatsappFilesVideo'][i].mediaByte = mediaByte;
            if (tabs[_currentIndex]['whatsappFilesVideo'].length - i == 1) {}
          });
        }
      }
    }
    setState(() {
      _isProcessing = false;
      _dataLoaded = true;
    });
    // print("_dataLoaded: $_dataLoaded");
  }

  Future<void> _continuousMethods() async {
    // print("_continuousMethods");
    if (tabs[_currentIndex]['appType'] != 'WEBMEDIA') {
      setState(() {
        _isProcessing = true;
      });
      await fetchAndUpdateData().then((_) async {
        await getVideoThumbnailAsync();
      });
    }
  }

  Future<void> startService() async {
    await platform.invokeMethod('startService').then((value) {
      if (!_isProcessing) {
        _continuousMethods();
      }
    });
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
                          haspermission: haspermission,
                          onRequestPermission: showPermissionDialog,
                          onrefresh: _continuousMethods,
                          currentIndex: _currentIndex,
                          dataLoaded: _dataLoaded,
                          file: 'whatsappFilesImages',
                        ),
                        GridManager(
                          tabs: tabs,
                          haspermission: haspermission,
                          onRequestPermission: showPermissionDialog,
                          onrefresh: _continuousMethods,
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
                          haspermission: haspermission,
                          onRequestPermission: showPermissionDialog,
                          onrefresh: _continuousMethods,
                          currentIndex: _currentIndex,
                          dataLoaded: _dataLoaded,
                          file: 'whatsappFilesImages',
                        ),
                        GridManager(
                          tabs: tabs,
                          haspermission: haspermission,
                          onRequestPermission: showPermissionDialog,
                          onrefresh: _continuousMethods,
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
              length: 1,
              child: Column(
                children: [
                  TabBar(
                    dividerColor: theme.colorScheme.secondary,
                    labelColor: theme.primaryColor,
                    unselectedLabelColor: theme.primaryColor,
                    indicatorColor: theme.primaryColor,
                    tabs: const [
                      Center(child: Text("Other Platforms")),
                    ],
                  ),
                  const Expanded(
                    child: TabBarView(
                      children: [
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
                          tabs: tabs,
                          haspermission: haspermission,
                          onRequestPermission: showPermissionDialog,
                          onrefresh: _continuousMethods,
                          currentIndex: _currentIndex,
                          dataLoaded: _dataLoaded,
                          file: 'whatsappFilesImages',
                        ),
                        GridManager(
                          tabs: tabs,
                          haspermission: haspermission,
                          onRequestPermission: showPermissionDialog,
                          onrefresh: _continuousMethods,
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
            if (index == 2) {
              _showAds();
            } else {
              _requestReview();
            }
            if (!_isProcessing && haspermission == true) {
              _continuousMethods();
            }
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
