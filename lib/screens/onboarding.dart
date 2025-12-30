import 'package:flutter/material.dart';
import '../navigation.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

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
            onPressed: () {
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
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          children: [
            const Spacer(),
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
            const SizedBox(height: 50),
            Image.asset(
              'assets/icon-512.png',
              width: MediaQuery.of(context).size.width,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 35),
            const Text(
              "Organize your favorite links and media!",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 35, fontWeight: FontWeight.w800, height: 1.2),
            ),
            const Text(
              "Manage and view your personal media collections easily",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 60),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: SizedBox(
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
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
