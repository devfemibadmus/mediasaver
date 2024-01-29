import 'dart:async';

import 'package:flutter/material.dart';
import 'package:whatsappstatus/model.dart';
import 'package:whatsappstatus/whatsapp.dart';
import 'package:whatsappstatus/whatsapp4b.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MyHomePage(),
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
  List<Widget> _tabs = [];
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
    var statusFilesInfo = await platform.invokeListMethod('getStatusFilesInfo');
    if (statusFilesInfo != null && statusFilesInfo.isNotEmpty) {
      if (files != parseStatusFiles(statusFilesInfo)) {
        setState(() {
          files = parseStatusFiles(statusFilesInfo);
          _tabs = [
            Whatsapp(
              whatsappFilesImages:
                  filterFilesByFormat(files, 'jpg', 'jpeg', 'gif', 'whatsapp'),
              whatsappFilesVideo:
                  filterFilesByFormat(files, 'mp4', 'mov', 'mp4', 'whatsapp'),
            ),
            Whatsapp4b(
              whatsapp4bFilesVideo:
                  filterFilesByFormat(files, 'mp4', 'mov', 'mp4', 'whatsapp4b'),
              whatsapp4bFilesImages: filterFilesByFormat(
                  files, 'jpg', 'jpeg', 'gif', 'whatsapp4b'),
            ),
          ];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _tabs.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : Scaffold(
            body: _tabs[_currentIndex],
            bottomNavigationBar: BottomNavigationBar(
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
