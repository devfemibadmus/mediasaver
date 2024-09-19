import 'package:flutter/material.dart';

class HowItWorks extends StatelessWidget {
  const HowItWorks({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "1. Copy the link of the video you want to download.",
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                "2. Open the 'Media Saver' app and click the 'Web Downloads' tab at the bottom.",
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                "3. Paste the link into the input field or click the 'Paste' button to automatically insert the copied link.",
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                "4. The app will fetch all videos from the provided link. You will then be able to see the media on your screen and download them.",
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                "Supported Platforms:",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                "- Instagram (Reels, Videos, Photos, Posts)",
                style: TextStyle(fontSize: 16),
              ),
              Text(
                "- Facebook (Videos, Reels)",
                style: TextStyle(fontSize: 16),
              ),
              Text(
                "- TikTok (All Videos)",
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                "If you encounter any issues, tap the lightbulb icon at the top of the app bar to send an email to the developer.",
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                "Support the app by sharing it with friends and family using the share icon in the app bar.",
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
