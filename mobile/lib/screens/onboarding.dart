import 'package:flutter/material.dart';
import 'package:mediasaver/utils/startup_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../navigation.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  static const double _tabletBreakpoint = 768;
  static const double _contentMaxWidth = 560;

  void _showComplianceDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Policy Compliance",
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          "This app is strictly for non-copyrighted media only. Downloading copyrighted or protected material is not supported and is blocked to comply with platform policies.",
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('onboarding_completed', true);
              await initializeMediaStoreForStartup();

              if (!context.mounted) return;
              Navigator.pop(context);

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const MainNavigation()),
              );
            },
            child: const Text("I UNDERSTAND",
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Color(0xFF3F61D7))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;
    final isTablet = size.width >= _tabletBreakpoint;
    final horizontalPadding = isTablet ? 32.0 : 20.0;
    final titleFontSize = isTablet ? 44.0 : 35.0;
    final subtitleFontSize = isTablet ? 18.0 : 16.0;
    final logoSize = isTablet ? 240.0 : (size.width * 0.6).clamp(180.0, 260.0);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: isTablet ? 32 : 20,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: size.height -
                      mediaQuery.padding.top -
                      mediaQuery.padding.bottom -
                      (isTablet ? 64 : 40),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black),
                        children: [
                          TextSpan(text: "Media "),
                          TextSpan(
                              text: "Saver",
                              style: TextStyle(color: Color(0xFF3F61D7))),
                        ],
                      ),
                    ),
                    SizedBox(height: isTablet ? 40 : 28),
                    Image.asset(
                      'assets/icon-512.png',
                      width: logoSize,
                      fit: BoxFit.contain,
                    ),
                    SizedBox(height: isTablet ? 32 : 24),
                    Text(
                      "Organize your favorite links and media!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Manage and view your personal media collections easily",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: subtitleFontSize,
                      ),
                    ),
                    SizedBox(height: isTablet ? 48 : 36),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () => _showComplianceDialog(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3F61D7),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)),
                        ),
                        child: const Text("Continue",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
