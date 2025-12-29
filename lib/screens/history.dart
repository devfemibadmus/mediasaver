import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mediasaver/screens/preview.dart';
import 'dart:io';

import 'package:video_player/video_player.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final Map<String, VideoPlayerController> _videoControllers = {};
  late Future<List<FileSystemEntity>> _videosFuture;
  late Future<List<FileSystemEntity>> _imagesFuture;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  void _loadFiles() {
    setState(() {
      _videosFuture = _getFiles('.mp4');
      _imagesFuture = _getFiles('.jpg');
    });
  }

  Future<VideoPlayerController> _createVideoController(String path) async {
    if (_videoControllers.containsKey(path)) {
      return _videoControllers[path]!;
    }

    final controller = VideoPlayerController.file(File(path));
    _videoControllers[path] = controller;
    await controller.initialize();
    return controller;
  }

  Future<List<FileSystemEntity>> _getFiles(String extension) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final dir = Directory(appDir.path);
      final allFiles = await dir.list().toList();
      return allFiles
          .where((file) => file.path.toLowerCase().endsWith(extension))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> _deleteFile(FileSystemEntity file) async {
    try {
      await file.delete();
      _loadFiles();
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("History"),
          bottom: const TabBar(
            indicatorColor: Color(0xFF3F61D7),
            labelColor: Color(0xFF3F61D7),
            unselectedLabelColor: Colors.grey,
            tabs: [Tab(text: "Video"), Tab(text: "Image")],
          ),
        ),
        body: TabBarView(
          children: [
            _buildTab(_videosFuture, Icons.videocam_off_outlined, "No video"),
            _buildTab(
                _imagesFuture, Icons.image_not_supported_outlined, "No image"),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(
      Future<List<FileSystemEntity>> future, IconData icon, String txt) {
    return FutureBuilder<List<FileSystemEntity>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final files = snapshot.data ?? [];
        if (files.isEmpty) {
          return _empty(icon, txt);
        }
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: files.length,
          itemBuilder: (context, index) {
            final file = files[index];
            final isVideo = file.path.toLowerCase().endsWith('.mp4');
            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PreviewScreen(
                    mediaUrl: file.path,
                    isLocalFile: true,
                  ),
                ),
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[100],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: isVideo
                          ? FutureBuilder<VideoPlayerController>(
                              future: _createVideoController(file.path),
                              builder: (context, snapshot) {
                                if (snapshot.hasData &&
                                    snapshot.data!.value.isInitialized) {
                                  return VideoPlayer(snapshot.data!);
                                }
                                return Container(
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: Icon(Icons.videocam,
                                        size: 40, color: Colors.grey),
                                  ),
                                );
                              },
                            )
                          : Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                image: DecorationImage(
                                  image: FileImage(File(file.path)),
                                  fit: BoxFit.cover,
                                  onError: (_, __) => Container(
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.image, size: 40),
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),
                  if (isVideo)
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.center,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          child:
                              const Icon(Icons.play_arrow, color: Colors.white),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: () => _deleteFile(file),
                        icon: const Icon(Icons.delete_outline,
                            size: 18, color: Colors.white),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _empty(IconData icon, String txt) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 100, color: Colors.grey[200]),
          Text(txt,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey)),
          const Text("Your downloaded items will appear here",
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    for (final controller in _videoControllers.values) {
      controller.dispose();
    }
    _videoControllers.clear();
    super.dispose();
  }
}
