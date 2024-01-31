import 'dart:async';

import 'package:flutter/material.dart';
import 'package:whatsappstatus/model.dart';
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
  List<String> images = ['jpg', 'jpeg', 'gif'];
  List<String> videos = ['mp4', 'mov', 'mp4'];
  int _currentIndex = 0;
  final List<Widget> _tabs = [
    const Center(child: CircularProgressIndicator()),
    const Center(child: CircularProgressIndicator()),
    const Center(child: CircularProgressIndicator())
  ];
  List<StatusFileInfo> files = [];
  late Timer _timer;
  bool permitted = false;

  @override
  void initState() {
    super.initState();
    platform.invokeMethod("checkStoragePermission").then((value) {
      if (value) {
        setState(() {
          permitted = true;
        });
      } else {
        platform.invokeMethod("requestStoragePermission").then((value) {
          if (value) {
            print("GRANTED");
          }
        });
      }
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      platform.invokeMethod("checkStoragePermission").then((value) {
        if (value) {
          _timer.cancel();
          setState(() {
            permitted = true;
          });
          print("object");
          getStatusFiles();
        }
      });
    });
  }

  Future<void> getStatusFiles() async {
    // WHATSAPP
    await platform.invokeListMethod(
      'getStatusFilesInfo',
      {'appType': "WHATSAPP"},
    ).then((value) async {
      setState(() {
        _tabs[0] = Whatsapp(
          whatsappFilesImages:
              filterFilesByFormat(parseStatusFiles(value!), images, 'whatsapp'),
          whatsappFilesVideo:
              filterFilesByFormat(parseStatusFiles(value), videos, 'whatsapp'),
        );
      });
    });
    // WHATSAPP4B
    await platform.invokeListMethod(
      'getStatusFilesInfo',
      {'appType': "WHATSAPP4B"},
    ).then((value) {
      setState(() {
        _tabs[1] = Whatsapp(
          whatsappFilesImages:
              filterFilesByFormat(parseStatusFiles(value!), images, 'whatsapp'),
          whatsappFilesVideo:
              filterFilesByFormat(parseStatusFiles(value), videos, 'whatsapp'),
        );
      });
    });
    // SAVED
    await platform.invokeListMethod(
      'getStatusFilesInfo',
      {'appType': "SAVED"},
    ).then((value) {
      setState(() {
        _tabs[2] = Whatsapp(
          whatsappFilesImages:
              filterFilesByFormat(parseStatusFiles(value!), images, 'whatsapp'),
          whatsappFilesVideo:
              filterFilesByFormat(parseStatusFiles(value), videos, 'whatsapp'),
        );
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
