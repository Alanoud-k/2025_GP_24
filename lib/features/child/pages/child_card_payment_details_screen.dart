import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ChildCardPaymentDetailsScreen extends StatefulWidget {
  final int childId;
  final int receiverAccountId;
  final String token;
  final String baseUrl; // Backend URL

  const ChildCardPaymentDetailsScreen({
    super.key,
    required this.childId,
    required this.receiverAccountId,
    required this.token,
    required this.baseUrl,
  });

  @override
  State<ChildCardPaymentDetailsScreen> createState() =>
      _ChildCardPaymentDetailsScreenState();
}

class _ChildCardPaymentDetailsScreenState
    extends State<ChildCardPaymentDetailsScreen> {
  static const Color kPrimary = Color(0xFF37C4BE);
  static const Color kBg = Color(0xFFF7F8FA);
  static const Color kTextDark = Color(0xFF222222);

  // Merchants list without Star Cafe
  final List<String> merchants = const [
    "McDonald's",
    "Albaik",
    "Alnahdi Pharmacy",
    "Starbucks",
  ];

  String? selectedMerchant = "McDonald's";

  double total = 55.0;
  double fee = 0.56;
  bool _isLoading = false;

  Future<void> _confirmAndPay() async {
    if (selectedMerchant == null) return;

    setState(() {
      _isLoading = true;
    });

    final double amountToSend = total + fee;

    try {
      final url =
          Uri.parse("${widget.baseUrl}/api/payment/card/simulate");

      final body = {
        "childId": widget.childId,
        "receiverAccountId": widget.receiverAccountId,
        "amount": amountToSend,
        "merchantName": selectedMerchant,
      };

      final res = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.token}",
        },
        body: jsonEncode(body),
      );

      if (!mounted) return;

      if (res.statusCode == 201) {
        final decoded = jsonDecode(res.body);
        final tx = decoded["data"];
        final category = decoded["mlCategory"];

        // Success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Payment completed successfully.",
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            duration: Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Go back to card screen after 5 seconds
        Future.delayed(const Duration(seconds: 5), () {
          if (!mounted) return;
          Navigator.pop(context); // back from Payment Details
          Navigator.pop(context); // back from Scan to Card screen
        });

        // Example debug usage if needed:
        // debugPrint("Transaction id: ${tx["transactionid"]}, category: $category");
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Error: ${res.statusCode} - ${res.body}",
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Something went wrong: $e"),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double afterPayment = total + fee;

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: kTextDark),
        title: const Text(
          "Payment Details",
          style: TextStyle(
            color: kTextDark,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "Review Payment",
              style: TextStyle(
                color: kTextDark,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),

            // Payment summary card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Merchant",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedMerchant,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                      items: merchants.map((m) {
                        return DropdownMenuItem(
                          value: m,
                          child: Text(
                            m,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: kTextDark,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          selectedMerchant = val;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  _AmountRow(label: "Total:", value: total),
                  const SizedBox(height: 4),
                  _AmountRow(label: "Fee:", value: fee),
                  const Divider(height: 24),
                  _AmountRow(
                    label: "After Payment:",
                    value: afterPayment,
                    isBold: true,
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Confirm & Pay button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _isLoading ? null : _confirmAndPay,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        "Confirm & Pay",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isBold;

  const _AmountRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    const Color kTextDark = Color(0xFF222222);

    final styleBase = TextStyle(
      fontSize: 14,
      color: kTextDark,
      fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: styleBase),
        Text(
          "﷼ ${value.toStringAsFixed(2)}",
          style: styleBase,
        ),
      ],
    );
  }
}
