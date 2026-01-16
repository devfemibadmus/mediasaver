import 'package:flutter/material.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
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
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        appBar: AppBar(centerTitle: false, title: const Text("Feedback")),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Rate your experience",
                  style: TextStyle(fontSize: 16)),
              const SizedBox(height: 12),
              Row(
                children: List.generate(
                  5,
                  (index) => GestureDetector(
                    onTap: () => setState(() => _rating = index + 1),
                    child: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      color: index < _rating ? Colors.yellow[700] : Colors.grey,
                      size: 36,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text("Write a review", style: TextStyle(fontSize: 16)),
              const SizedBox(height: 10),
              TextField(
                controller: _reviewController,
                maxLines: 6,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
              const Spacer(),
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
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
