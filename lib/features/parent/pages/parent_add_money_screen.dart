import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ParentAddMoneyScreen extends StatefulWidget {
  final int parentId;
  final String token;

  const ParentAddMoneyScreen({
    super.key,
    required this.parentId,
    required this.token,
  });

  @override
  State<ParentAddMoneyScreen> createState() => _ParentAddMoneyScreenState();
}

class _ParentAddMoneyScreenState extends State<ParentAddMoneyScreen> {
  final TextEditingController _amountController = TextEditingController();
  bool _loading = false;
  String? _errorMessage;
  String? token;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString("token");
  }

  Future<void> _createPayment() async {
    final amountText = _amountController.text.trim();

    if (amountText.isEmpty || double.tryParse(amountText) == null) {
      setState(() => _errorMessage = "Please enter a valid amount.");
      return;
    }

    if (token == null) {
      setState(
        () => _errorMessage = "Authentication error. Please log in again.",
      );
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    const backendUrl = "https://2025gp24-production.up.railway.app";

    try {
      final response = await http.post(
        Uri.parse("$backendUrl/api/parent/${widget.parentId}/create-payment"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.token}",
        },
        body: jsonEncode({"amount": double.parse(amountText)}),
      );

      final responseBody = jsonDecode(response.body);
      print("🟣 Payment creation response: $responseBody");
      launchUrl(
        Uri.parse(responseBody["redirectUrl"]),
        mode: LaunchMode.externalApplication,
      );

      if (response.statusCode == 200 && responseBody["redirectUrl"] != null) {
        final url = Uri.parse(responseBody["redirectUrl"]);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          setState(() => _errorMessage = "Could not open payment page.");
        }
        return;
      } else {
        setState(() {
          _errorMessage = responseBody["message"] ?? "Payment creation failed.";
        });
      }
    } catch (e) {
      print("❌ Error creating payment: $e");
      setState(() => _errorMessage = "An unexpected error occurred.");
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
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),

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
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
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
