import 'package:flutter/material.dart';
import 'package:mediasaver/utils/media_helper.dart';
import 'screens/onboarding.dart';
import 'package:upgrader/upgrader.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await MediaHelper.initStore();
//   final tempDir = await getTemporaryDirectory();
//   final appDocumentsDir = await getApplicationDocumentsDirectory();
//   final downloadsDir = await getDownloadsDirectory();
//   await MediaHelper.initStore();
//   await MediaHelper.cleanDeleted();
//   runApp(const MediaSaverApp());
// }

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MediaHelper.initStore();
  await MediaHelper.cleanDeleted();
  runApp(const MediaSaverApp());
}

class MediaSaverApp extends StatelessWidget {
  const MediaSaverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        primaryColor: const Color(0xFF3F61D7),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
              color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      home: UpgradeAlert(
        child: const OnboardingScreen(),
      ),
    );
  }
}
