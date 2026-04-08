import 'package:flutter/material.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  static const double _tabletBreakpoint = 768;
  static const double _contentMaxWidth = 640;
  final TextEditingController _reviewController = TextEditingController();
  int _rating = 4;

  Future<void> _submitFeedback() async {
    if (_rating == 0 || _reviewController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please rate and provide feedback")),
      );
      return;
    }

    try {
      await FlutterEmailSender.send(Email(
        subject: "Media Saver Feedback - Rating: $_rating/5",
        body: _reviewController.text,
        recipients: ["devfemibadmus@gmail.com"],
      ));

      if (mounted) {
        _reviewController.clear();
        setState(() => _rating = 0);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Thank you for your feedback!")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not send email.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isTablet = mediaQuery.size.width >= _tabletBreakpoint;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        appBar: AppBar(centerTitle: false, title: const Text("Feedback")),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              isTablet ? 32 : 20,
              20,
              isTablet ? 32 : 20,
              mediaQuery.viewInsets.bottom + 20,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Rate your experience",
                        style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 4,
                      children: List.generate(
                        5,
                        (index) => GestureDetector(
                          onTap: () => setState(() => _rating = index + 1),
                          child: Icon(
                            index < _rating ? Icons.star : Icons.star_border,
                            color: index < _rating
                                ? Colors.yellow[700]
                                : Colors.grey,
                            size: isTablet ? 42 : 36,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text("Write a review",
                        style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _reviewController,
                      maxLines: isTablet ? 8 : 6,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                    SizedBox(height: isTablet ? 32 : 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submitFeedback,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3F61D7),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Submit",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
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
