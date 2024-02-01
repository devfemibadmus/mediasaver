import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:whatsappstatus/model.dart';
import 'package:whatsappstatus/preview.dart';
import 'package:whatsappstatus/whatsapp.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    //Brightness platformBrightness = MediaQuery.of(context).platformBrightness;
    return MaterialApp(
      theme: ThemeData.light().copyWith(
        primaryColor: Colors.white,
        secondaryHeaderColor: Colors.teal,
        appBarTheme: const AppBarTheme(
          color: Colors.teal,
        ),
        colorScheme: ColorScheme.fromSwatch()
            .copyWith(background: Colors.white)
            .copyWith(secondary: Colors.teal[700]),
      ),
      darkTheme: ThemeData.dark().copyWith(
        primaryColor: Colors.white,
        secondaryHeaderColor: Colors.teal,
        appBarTheme: const AppBarTheme(
          color: Colors.teal,
        ),
        colorScheme: ColorScheme.fromSwatch()
            .copyWith(background: Colors.grey[900])
            .copyWith(secondary: Colors.teal[700]),
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
  int _currentIndex = 0;
  List<Widget> _tabs = [
    const Center(child: CircularProgressIndicator()),
    const Center(child: CircularProgressIndicator()),
    const Center(child: CircularProgressIndicator())
  ];
  late Timer _timer;
  bool permitted = false;

  @override
  void initState() {
    super.initState();
    platform.invokeMethod("checkStoragePermission").then((value) {
      if (value == false) {
        platform.invokeMethod("requestStoragePermission");
      }
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      platform.invokeMethod("checkStoragePermission").then((value) {
        if (value) {
          _timer.cancel();
          setState(() {
            _tabs = [
              const Whatsapp(
                  appType: 'WHATSAPP',
                  channel: 'Whatsapp Status',
                  key: PageStorageKey('WHATSAPP')),
              const Whatsapp(
                  appType: 'WHATSAPP4B',
                  channel: 'Whatsapp4b Status',
                  key: PageStorageKey('WHATSAPP4B')),
              const Center(child: CircularProgressIndicator())
            ];
          });
        }
      });
    });
  }

  Future<void> getStatusFiles() async {
    await platform.invokeListMethod(
      'getStatusFilesInfo',
      {'appType': "SAVED"},
    ).then((value) {
      setState(() {
        if (value!.isNotEmpty) {
          _tabs[2] = Container(
            color: Theme.of(context).colorScheme.background,
            padding: const EdgeInsets.all(6.0),
            child: GridView.builder(
              // cacheExtent: 9999,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 6.0,
                mainAxisSpacing: 6.0,
              ),
              itemCount: parseStatusFiles(value).length,
              itemBuilder: (context, index) {
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Preview(
                          previewFile: parseStatusFiles(value),
                          index: index,
                          type: 'Image',
                          theme: Theme.of(context),
                          savedto: 'nosave',
                        ),
                      ),
                    );
                  },
                  child: Image.file(
                    File(parseStatusFiles(value)[index].path),
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_currentIndex],
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

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}
