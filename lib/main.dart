import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/onboarding.dart';
import 'navigation.dart';
import 'package:upgrader/upgrader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MediaSaverApp());
}

class MediaSaverApp extends StatelessWidget {
  const MediaSaverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Media Saver',
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

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    await Future.delayed(const Duration(milliseconds: 300));

    final prefs = await SharedPreferences.getInstance();
    final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

    debugPrint('Onboarding completed: $onboardingCompleted');

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => onboardingCompleted
              ? const MainNavigation()
              : const OnboardingScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/logo.png', width: 200),
            const SizedBox(height: 24),
            const CircularProgressIndicator(
              color: Color(0xFF3F61D7),
            ),
          ],
        ),
      ),
    );
  }
}
