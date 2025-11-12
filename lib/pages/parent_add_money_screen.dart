import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class ParentAddMoneyScreen extends StatefulWidget {
  final int parentId;
  const ParentAddMoneyScreen({super.key, required this.parentId});

  @override
  State<ParentAddMoneyScreen> createState() => _ParentAddMoneyScreenState();
}

class _ParentAddMoneyScreenState extends State<ParentAddMoneyScreen> {
  final TextEditingController _amountController = TextEditingController();
  bool _loading = false;
  String? _errorMessage;

  Future<void> _createPayment() async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty || double.tryParse(amountText) == null) {
      setState(() => _errorMessage = "Please enter a valid amount.");
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse("http://10.0.2.2:3000/api/create-payment"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "amount": double.parse(amountText),
          "parentId": widget.parentId,
        }),
      );

      final data = jsonDecode(response.body);
      print("💬 Create Payment Response: $data");

      if (response.statusCode == 200 && data['transactionUrl'] != null) {
        final url = Uri.parse(data['transactionUrl']);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          setState(() => _errorMessage = "Could not open payment page.");
        }
      } else {
        setState(
          () => _errorMessage = data['message'] ?? "Failed to create payment.",
        );
      }
    } catch (e) {
      print("❌ Error: $e");
      setState(
        () => _errorMessage = "An error occurred while creating the payment.",
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Money"),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Enter amount to add:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: "e.g. 100",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 14),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _createPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.payment),
                label: Text(_loading ? "Processing..." : "Proceed to Payment"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
