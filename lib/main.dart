import 'dart:async';
import 'dart:io';
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
        appBarTheme: const AppBarTheme(color: Colors.teal),
        colorScheme: colorScheme.copyWith(secondary: Colors.teal[700]),
      );
    }

    return MaterialApp(
      theme: buildThemeData(
          ColorScheme.fromSwatch().copyWith(background: Colors.white)),
      darkTheme: buildThemeData(
          ColorScheme.fromSwatch().copyWith(background: Colors.black)),
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
  final List<Map<String, dynamic>> _tabs = [
    {
      'appType': 'WHATSAPP',
      'whatsappFilesImages': filterFilesByFormat(
        parseStatusFiles([]),
        images,
        'Whatsapp Status',
      ),
      'whatsappFilesVideo': filterFilesByFormat(
        parseStatusFiles([]),
        videos,
        'Whatsapp Status',
      ),
    },
    {
      'appType': 'WHATSAPP4B',
      'whatsappFilesImages': filterFilesByFormat(
        parseStatusFiles([]),
        images,
        'Whatsapp4b Status',
      ),
      'whatsappFilesVideo': filterFilesByFormat(
        parseStatusFiles([]),
        videos,
        'Whatsapp4b Status',
      ),
    },
    {
      'appType': 'SAVED',
      'whatsappFilesImages': filterFilesByFormat(
        parseStatusFiles([]),
        images,
        'Whatsapp4b Status',
      ),
      'whatsappFilesVideo': filterFilesByFormat(
        parseStatusFiles([]),
        videos,
        'Whatsapp4b Status',
      ),
    },
  ];
  late Timer _timer;

  @override
  void initState() {
    super.initState();
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
  }

  Future<void> fetchAndRefreshData() async {
    for (int i = 0; i < _tabs.length; i++) {
      List? newData = await platform.invokeListMethod(
          'getStatusFilesInfo', {'appType': _tabs[i]['appType']});
      setState(() {
        _tabs[i]['whatsappFilesImages'] = filterFilesByFormat(
            parseStatusFiles(newData!), images, _tabs[i]['appType']);
        _tabs[i]['whatsappFilesVideo'] = filterFilesByFormat(
            parseStatusFiles(newData), videos, _tabs[i]['appType']);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final scaffold = ScaffoldMessenger.of(context);
    return Scaffold(
      body: DefaultTabController(
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
                    fetchAndRefreshData();
                  },
                  icon: const Icon(Icons.refresh),
                )
              ],
              bottom: TabBar(
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
            ),
          ),
          body: TabBarView(
            children: [
              _buildTabContent('whatsappFilesImages', theme, scaffold),
              _buildTabContent('whatsappFilesVideo', theme, scaffold),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        selectedItemColor: Theme.of(context).secondaryHeaderColor,
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
    );
  }

  Widget _buildTabContent(String files, ThemeData theme, scaffold) {
    return _tabs[_currentIndex][files].isNotEmpty
        ? GridView.builder(
            cacheExtent: 9999,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 6.0,
              mainAxisSpacing: 6.0,
            ),
            itemCount: _tabs[_currentIndex][files].length,
            itemBuilder: (context, index) {
              return InkWell(
                onDoubleTap: () {
                  if (_tabs[_currentIndex]['appType'] != 'SAVED') {
                    statusAction(_tabs[_currentIndex][files][index].path,
                            'statusAction')
                        .then(
                      (value) => scaffold.showSnackBar(
                        SnackBar(
                          content: Text(value),
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
                        previewFile: _tabs[_currentIndex][files],
                        index: index,
                        type: files == 'whatsappFilesVideo' ? 'Video' : 'Image',
                        theme: theme,
                        saved: _tabs[_currentIndex]['appType'] == 'SAVED',
                      ),
                    ),
                  );
                },
                child: files == 'whatsappFilesImages'
                    ? Image.file(
                        File(_tabs[_currentIndex][files][index].path),
                        fit: BoxFit.cover,
                      )
                    : Image.memory(
                        _tabs[_currentIndex][files][index].mediaByte,
                        fit: BoxFit.cover,
                      ),
              );
            },
          )
        : Center(
            child: Text(
                '${_tabs[_currentIndex][files].length} ${_tabs[_currentIndex]['appType'].toLowerCase()} status available'),
          );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}
