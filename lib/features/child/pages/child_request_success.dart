import 'package:flutter/material.dart';

class ChildRequestSuccessScreen extends StatelessWidget {
  final int childId;
  final String baseUrl;
  final String token;

  const ChildRequestSuccessScreen({
    super.key,
    required this.childId,
    required this.baseUrl,
    required this.token,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 90),
            const SizedBox(height: 20),
            const Text(
              "Money Request\nSubmitted Successfully",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: () {
                // Ensure child homepage receives childId, token, baseUrl
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                minimumSize: const Size(160, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Done"),
            ),
          ],
        ),
      ),
    );
  }
}
