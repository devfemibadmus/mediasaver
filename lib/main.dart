import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mediasaver/utils/media_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'navigation.dart';
import 'screens/onboarding.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  var onboardingCompleted = false;

  try {
    final prefs = await SharedPreferences.getInstance().timeout(
      const Duration(seconds: 2),
    );
    onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
  } catch (e) {
    debugPrint('Failed to read onboarding state: $e');
  }

  runApp(MyApp(onboardingCompleted: onboardingCompleted));

  if (onboardingCompleted) {
    unawaited(MediaHelper.prepareForLaunch());
  }
}

class MyApp extends StatelessWidget {
  final bool onboardingCompleted;

  const MyApp({super.key, required this.onboardingCompleted});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Media Saver',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3F61D7)),
        useMaterial3: true,
      ),
      home: onboardingCompleted
          ? const MainNavigation()
          : const OnboardingScreen(),
    );
  }
}
