import 'package:flutter/material.dart';
import 'screens/onboarding.dart';
import 'package:upgrader/upgrader.dart';

void main() {
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
