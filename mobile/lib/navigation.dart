import 'package:flutter/material.dart';
import 'dart:async';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'screens/home.dart';
import 'screens/history.dart';
import 'screens/feedback.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  final GlobalKey<HomeScreenState> _homeKey = GlobalKey<HomeScreenState>();
  final GlobalKey<HistoryScreenState> _historyKey =
      GlobalKey<HistoryScreenState>();
  StreamSubscription<List<SharedMediaFile>>? _shareSubscription;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeScreen(key: _homeKey),
      HistoryScreen(key: _historyKey),
      const FeedbackScreen(),
    ];
    _listenForSharedMedia();
  }

  @override
  void dispose() {
    _shareSubscription?.cancel();
    super.dispose();
  }

  void _listenForSharedMedia() {
    _shareSubscription = ReceiveSharingIntent.instance.getMediaStream().listen(
          _handleSharedMedia,
          onError: (err) => debugPrint('Share stream error: $err'),
        );

    ReceiveSharingIntent.instance.getInitialMedia().then((media) async {
      await _handleSharedMedia(media);
      await ReceiveSharingIntent.instance.reset();
    }).catchError((err) {
      debugPrint('Initial share error: $err');
    });
  }

  Future<void> _handleSharedMedia(List<SharedMediaFile> media) async {
    final text = _sharedTextFromMedia(media);
    if (text == null || text.trim().isEmpty) return;

    if (mounted && _currentIndex != 0) {
      setState(() => _currentIndex = 0);
      await Future<void>.delayed(Duration.zero);
    }

    await _homeKey.currentState?.applySharedText(text);
  }

  String? _sharedTextFromMedia(List<SharedMediaFile> media) {
    for (final item in media) {
      final fromPath = _extractFirstUrl(item.path) ?? item.path.trim();
      if (fromPath.isNotEmpty) return fromPath;

      final message = item.message;
      if (message != null) {
        final fromMessage = _extractFirstUrl(message) ?? message.trim();
        if (fromMessage.isNotEmpty) return fromMessage;
      }
    }

    return null;
  }

  String? _extractFirstUrl(String text) {
    final match = RegExp(r'https?://\S+').firstMatch(text);
    return match?.group(0)?.replaceAll(RegExp(r'[),.\]]+$'), '');
  }

  void _selectTab(int index) {
    if (index == 1) {
      _historyKey.currentState?.refresh();
    }
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Color(0xFFE0E0E0), width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          selectedItemColor: const Color(0xFF3F61D7),
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          onTap: _selectTab,
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home'),
            BottomNavigationBarItem(
                icon: Icon(Icons.folder_outlined),
                activeIcon: Icon(Icons.folder),
                label: 'History'),
            BottomNavigationBarItem(
                icon: Icon(Icons.error_outline),
                activeIcon: Icon(Icons.error),
                label: 'Feedback'),
          ],
        ),
      ),
    );
  }
}
