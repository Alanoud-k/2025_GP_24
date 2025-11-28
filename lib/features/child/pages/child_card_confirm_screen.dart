import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ChildCardConfirmScreen extends StatefulWidget {
  final int childId;
  final int receiverAccountId;
  final String token;
  final String baseUrl;

  final String initialMerchant;
  final String initialMcc;
  final String initialAmount;

  const ChildCardConfirmScreen({
    super.key,
    required this.childId,
    required this.receiverAccountId,
    required this.token,
    required this.baseUrl,
    required this.initialMerchant,
    required this.initialMcc,
    required this.initialAmount,
  });

  @override
  State<ChildCardConfirmScreen> createState() =>
      _ChildCardConfirmScreenState();
}

class _ChildCardConfirmScreenState extends State<ChildCardConfirmScreen> {
  late TextEditingController merchantController;
  late TextEditingController mccController;
  late TextEditingController amountController;

  bool isSubmitting = false;
  String? lastCategory;

  @override
  void initState() {
    super.initState();
    merchantController = TextEditingController(text: widget.initialMerchant);
    mccController = TextEditingController(text: widget.initialMcc);
    amountController = TextEditingController(text: widget.initialAmount);
  }

  @override
  void dispose() {
    merchantController.dispose();
    mccController.dispose();
    amountController.dispose();
    super.dispose();
  }

  Future<void> _confirmAndPay() async {
    final merchant = merchantController.text.trim();
    final mccText = mccController.text.trim();
    final amountText = amountController.text.trim();

    if (merchant.isEmpty || mccText.isEmpty || amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    final int? mcc = int.tryParse(mccText);
    final double? amount = double.tryParse(amountText);

    if (mcc == null || amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid MCC or amount")),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      final uri =
          Uri.parse("${widget.baseUrl}/api/transaction/simulate-card");

      final res = await http.post(
        uri,
        headers: {
          "Content-Type": "application/json",
          // Add token later when backend requires it
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

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final category =
          data["data"]?["transactioncategory"] ?? "Uncategorized";

      setState(() {
        lastCategory = category;
      });

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_rounded,
                size: 70,
                color: Color(0xFF67AFAC),
              ),
              const SizedBox(height: 16),
              const Text(
                "Payment confirmed",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "The transaction has been saved and classified as $category.",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "$merchant • ${amount.toStringAsFixed(2)} SAR",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Done"),
                ),
              ),
            ],
          ),
        ),
      );

      if (mounted) {
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color kPrimary = Color(0xFF67AFAC);
    const Color kBg = Color(0xFFF7F8FA);

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.black87,
        title: const Text(
          "Confirm payment",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 18,
                    offset: const Offset(0, 12),
                    color: Colors.black.withOpacity(0.05),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Payment details",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: merchantController,
                    decoration: const InputDecoration(
                      labelText: "Merchant name",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: mccController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "MCC",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: "Amount (SAR)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kBg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 20,
                          color: Colors.black54,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            lastCategory == null
                                ? "The AI model will classify this transaction and add it to the wallet."
                                : "Last detected category: $lastCategory",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                      ),
                      onPressed: isSubmitting ? null : _confirmAndPay,
                      child: Text(
                        isSubmitting
                            ? "Processing..."
                            : "Confirm and pay",
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
          ],
        ),
      ),
    );
  }
}
