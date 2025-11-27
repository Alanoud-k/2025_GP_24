import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ChildCardScreen extends StatefulWidget {
  final int childId;
  final String token;
  final String baseUrl;

  const ChildCardScreen({
    super.key,
    required this.childId,
    required this.token,
    required this.baseUrl,
  });

  @override
  State<ChildCardScreen> createState() => _ChildCardScreenState();
}

class _ChildCardScreenState extends State<ChildCardScreen> {
  final TextEditingController amountController = TextEditingController();
  final TextEditingController merchantController = TextEditingController();
  final TextEditingController mccController = TextEditingController();

  bool isLoading = false;
  String? lastCategory;

  Future<void> _simulatePayment() async {
    final amountText = amountController.text.trim();
    final merchant = merchantController.text.trim();
    final mccText = mccController.text.trim();

    if (amountText.isEmpty || merchant.isEmpty || mccText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    final double? amount = double.tryParse(amountText);
    final int? mcc = int.tryParse(mccText);

    if (amount == null || mcc == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid amount or MCC")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final uri = Uri.parse(
        "${widget.baseUrl}/api/transaction/simulate-card",
      );

      final res = await http.post(
        uri,
        headers: {
          "Content-Type": "application/json",
          // إذا API عندكم يحتاج توكن:
          // "Authorization": "Bearer ${widget.token}",
        },
        body: jsonEncode({
          "childId": widget.childId,
          "amount": amount,
          "merchantName": merchant,
          "mcc": mcc,
        }),
      );

      if (res.statusCode != 200) {
        throw Exception("Failed with status ${res.statusCode}");
      }

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final category = body["data"]?["transactioncategory"] ?? "Unknown";

      setState(() {
        lastCategory = category;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Transaction saved. Category: $category")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    amountController.dispose();
    merchantController.dispose();
    mccController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Card"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: merchantController,
              decoration: const InputDecoration(
                labelText: "Merchant name",
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: mccController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "MCC",
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Amount",
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : _simulatePayment,
                child: Text(isLoading ? "Processing..." : "Simulate payment"),
              ),
            ),
            const SizedBox(height: 16),
            if (lastCategory != null)
              Text("Last category: $lastCategory"),
          ],
        ),
      ),
    );
  }
}
