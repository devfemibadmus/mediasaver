import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mediasaver/utils/startup_helper.dart';
import 'screens/onboarding.dart';
import 'navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Media Saver',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3F61D7)),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _shareChannel =
      MethodChannel('com.blackstackhub.mediasaver/share');

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    await Future.delayed(startupDelay);

    var onboardingCompleted = false;
    String? sharedText;

    try {
      final prefs = await SharedPreferences.getInstance();
      onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
      sharedText = await _getInitialSharedText();
      if (onboardingCompleted) {
        await initializeMediaStoreForStartup();
      }
    } catch (e) {
      debugPrint('Startup route check failed: $e');
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => onboardingCompleted
              ? MainNavigation(sharedText: sharedText)
              : const OnboardingScreen(),
        ),
      );
    }
  }

  Future<String?> _getInitialSharedText() async {
    try {
      final text = await _shareChannel.invokeMethod<String>(
        'getInitialSharedText',
      );
      return text?.trim().isEmpty ?? true ? null : text?.trim();
    } catch (e) {
      debugPrint('Initial shared text unavailable: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/icon-512.png', width: 200),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
