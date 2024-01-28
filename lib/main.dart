import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:whatsappstatus/model.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('WhatsApp Status Saver'),
        ),
        body: const StatusGrid(),
      ),
    );
  }
}

class StatusGrid extends StatefulWidget {
  const StatusGrid({super.key});

  @override
  State<StatusGrid> createState() => _StatusGridState();
}

class _StatusGridState extends State<StatusGrid> {
  List<StatusFileInfo> files = [];
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    platform.invokeMethod("requestStoragePermission").then((value) {
      if (value) {
        print("GRANTED");
        getStatusFiles();
      }
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      platform.invokeMethod("checkStoragePermission").then((value) {
        if (value) {
          print("GRANTED");
          getStatusFiles();
        }
      });
    });
  }

  Future<void> getStatusFiles() async {
    var statusFilesInfo = await platform.invokeListMethod('getStatusFilesInfo');
    if (statusFilesInfo != null && statusFilesInfo.isNotEmpty) {
      setState(() {
        files = parseStatusFiles(statusFilesInfo);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return files.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8.0,
              mainAxisSpacing: 8.0,
            ),
            itemCount: files.length,
            itemBuilder: (context, index) {
              return StatusFileWidget(statusFileInfo: files[index]);
            },
          );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}

class StatusFileWidget extends StatelessWidget {
  final StatusFileInfo statusFileInfo;

  const StatusFileWidget({super.key, required this.statusFileInfo});

  @override
  Widget build(BuildContext context) {
    if (statusFileInfo.format == 'jpg' || statusFileInfo.format == 'png') {
      return Image.file(
        File(statusFileInfo.path),
        fit: BoxFit.cover,
      );
    } else {
      // Handle other file types as needed
      return Container();
    }
  }
}
