import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:whatsapp/model.dart';

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
  List<StatusFileInfo> whatsappFilesImages = [];
  List<StatusFileInfo> whatsappFilesVideo = [];
  List<StatusFileInfo> whatsapp4bFilesImages = [];
  List<StatusFileInfo> whatsapp4bFilesVideo = [];
  late Timer _timer;
  bool permitted = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      platform.invokeMethod("checkStoragePermission").then((value) {
        if (value) {
          setState(() {
            permitted = true;
          });
          getStatusFiles();
        } else {
          platform.invokeMethod("requestStoragePermission").then((value) {
            if (value) {
              print("GRANTED");
              getStatusFiles();
            }
          });
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
          whatsappFilesVideo =
              filterFilesByFormat(files, 'mp4', 'mp4', 'whatsapp');
          whatsappFilesImages =
              filterFilesByFormat(files, 'jpg', 'png', 'whatsapp');
          whatsapp4bFilesVideo =
              filterFilesByFormat(files, 'mp4', 'mp4', 'whatsapp4b');
          whatsapp4bFilesImages =
              filterFilesByFormat(files, 'jpg', 'png', 'whatsapp4b');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return files.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : Container(
            padding: const EdgeInsets.all(6.0),
            child: GridView.builder(
              cacheExtent: 9999,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 6.0,
                mainAxisSpacing: 6.0,
              ),
              itemCount: whatsappFilesImages.length,
              itemBuilder: (context, index) {
                return StatusFileWidget(
                    statusFileInfo: whatsappFilesImages[index]);
              },
            ),
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
    return Image.file(
      File(statusFileInfo.path),
      fit: BoxFit.cover,
    );
  }
}
