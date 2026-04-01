import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mediasaver/utils/media_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'navigation.dart';
import 'screens/onboarding.dart';

Future<void> main() async {
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
      home: const AppLaunchGate(),
    );
  }
}

class AppLaunchGate extends StatefulWidget {
  const AppLaunchGate({super.key});

  @override
  State<AppLaunchGate> createState() => _AppLaunchGateState();
}

class _AppLaunchGateState extends State<AppLaunchGate> {
  bool? _onboardingCompleted;

  @override
  void initState() {
    super.initState();
    _loadOnboardingState();
  }

  Future<void> _loadOnboardingState() async {
    var completed = false;

    try {
      final prefs = await SharedPreferences.getInstance();
      completed = prefs.getBool('onboarding_completed') ?? false;
    } catch (e) {
      debugPrint('Failed to read onboarding state: $e');
    }

    if (completed) {
      unawaited(MediaHelper.prepareForLaunch());
    }

    if (!mounted) return;
    setState(() {
      _onboardingCompleted = completed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final onboardingCompleted = _onboardingCompleted;

    if (onboardingCompleted == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return onboardingCompleted
        ? const MainNavigation()
        : const OnboardingScreen();
  }
}
