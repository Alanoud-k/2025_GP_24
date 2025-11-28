import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ChildCardScreen extends StatefulWidget {
  final int childId;
  final int receiverAccountId; // child spending account id
  final String token;
  final String baseUrl;

  const ChildCardScreen({
    super.key,
    required this.childId,
    required this.receiverAccountId,
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
  double? lastAmount;
  String? lastMerchant;

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
          // Add token header if backend requires it
          // "Authorization": "Bearer ${widget.token}",
        },
        body: jsonEncode({
          "childId": widget.childId,
          "receiverAccountId": widget.receiverAccountId,
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
        lastAmount = amount;
        lastMerchant = merchant;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Transaction saved. Category: $category")),
      );

      // Optional: clear fields after success
      amountController.clear();
      merchantController.clear();
      mccController.clear();
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
    const bgColor = Color(0xffF7F8FA);
    const cardColor = Colors.white;
    const primary = Color(0xFF67AFAC);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: bgColor,
        foregroundColor: Colors.black87,
        title: const Text(
          "Virtual Card",
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top info card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                    color: Colors.black.withOpacity(0.05),
                  ),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Test card payment",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "This is a fake payment used only to classify the transaction and save it to the wallet.",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Form card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                    color: Colors.black.withOpacity(0.05),
                  ),
                ],
              ),
              child: Column(
                children: [
                  TextField(
                    controller: merchantController,
                    decoration: const InputDecoration(
                      labelText: "Merchant name",
                      hintText: "e.g. STARBUCKS RIYADH",
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: mccController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "MCC",
                      hintText: "e.g. 5814",
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: "Amount (SAR)",
                      hintText: "e.g. 30.50",
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _simulatePayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        isLoading ? "Processing..." : "Simulate payment",
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            if (lastCategory != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                      color: Colors.black.withOpacity(0.05),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Last simulated transaction",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (lastMerchant != null)
                      Text(
                        "Merchant: $lastMerchant",
                        style: const TextStyle(fontSize: 13),
                      ),
                    if (lastAmount != null)
                      Text(
                        "Amount: ${lastAmount!.toStringAsFixed(2)} SAR",
                        style: const TextStyle(fontSize: 13),
                      ),
                    Text(
                      "Category: $lastCategory",
                      style: const TextStyle(
                        fontSize: 13,
                        color: primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
