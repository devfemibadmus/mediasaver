import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mediasaver/utils/startup_helper.dart';
import 'package:upgrader/upgrader.dart';
import 'screens/onboarding.dart';
import 'navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final Upgrader _upgrader;

  @override
  void initState() {
    super.initState();
    _upgrader = Upgrader(durationUntilAlertAgain: Duration.zero);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Media Saver',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3F61D7)),
        useMaterial3: true,
        dialogTheme: DialogThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          backgroundColor: Colors.white,
          titleTextStyle: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
          contentTextStyle: const TextStyle(
            color: Colors.black87,
            fontSize: 14,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF3F61D7),
          ),
        ),
      ),
      builder: (context, child) {
        final data = MediaQuery.of(context);
        return UpgradeAlert(
          upgrader: _upgrader,
          barrierDismissible: false,
          shouldPopScope: () => false,
          showIgnore: false,
          showLater: false,
          showReleaseNotes: false,
          child: MediaQuery(
            data: data.copyWith(boldText: false),
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
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
  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    await Future.delayed(startupDelay);

    var onboardingCompleted = false;

    try {
      final prefs = await SharedPreferences.getInstance();
      onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
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
            Image.asset('assets/icon-512.png', width: 200),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
