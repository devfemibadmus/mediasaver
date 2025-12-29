import 'package:flutter/material.dart';
import '../navigation.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

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
              'assets/group.png',
              width: MediaQuery.of(context).size.width,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 35),
            const Text(
              "Download your fav contents with a tap!",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 35, fontWeight: FontWeight.w800, height: 1.2),
            ),
            const Text(
              "Simply paste your url and download\nyour favourite contents",
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
                  onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const MainNavigation())),
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
