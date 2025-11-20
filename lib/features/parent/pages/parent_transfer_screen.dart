import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ParentTransferScreen extends StatefulWidget {
  final int parentId;
  final int childId;
  final String childName;
  final String childBalance;

  const ParentTransferScreen({
    super.key,
    required this.parentId,
    required this.childId,
    required this.childName,
    required this.childBalance,
  });

  @override
  State<ParentTransferScreen> createState() => _ParentTransferScreenState();
}

class _ParentTransferScreenState extends State<ParentTransferScreen> {
  final TextEditingController _amount = TextEditingController();
  double savingPercentage = 50; // default 50/50 split

  Future<void> _transfer() async {
    if (_amount.text.trim().isEmpty || double.tryParse(_amount.text) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid amount")),
      );
      return;
    }

    final url = Uri.parse('http://10.0.2.2:3000/api/auth/transfer');
    final amount = double.parse(_amount.text);

    print(
      "Sending transfer request: parent=${widget.parentId}, child=${widget.childId}, amount=$amount",
    );

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'parentId': widget.parentId,
          'childId': widget.childId,
          'amount': amount,
          'savePercentage': savingPercentage,
        }),
      );

      print("Response (${response.statusCode}): ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final double save = (data['saveAmount'] as num).toDouble();
        final double spend = (data['spendAmount'] as num).toDouble();
        _showSuccess(save, spend);
      } else {
        final error = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error['error'] ?? 'Transfer failed')),
        );
      }
    } catch (e) {
      print("Transfer error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Network error: $e")));
    }
  }

  void _showSuccess(double save, double spend) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 60),
            const SizedBox(height: 10),
            const Text(
              "Transfer Successful!",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Saving: ${save.toStringAsFixed(2)} SAR\nSpending: ${spend.toStringAsFixed(2)} SAR",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54, fontSize: 14),
            ),
          ],
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context);
      Navigator.pop(context);
    });
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF1ABC9C);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text(
          "Transfer",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _infoCard(
              icon: Icons.groups_2_rounded,
              title: "From Parent",
              subtitle: "Balance: 200.00 SAR", // TODO: fetch from API
              color: Colors.teal,
            ),
            _infoCard(
              icon: Icons.person_rounded,
              title: "To ${widget.childName}",
              subtitle: "Balance: ${widget.childBalance} SAR",
              color: Colors.amber,
            ),
            const SizedBox(height: 30),

            // Amount Input
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
                decoration: const InputDecoration(
                  hintText: "00.00 SAR",
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 25),

            // Save/Spend Split Slider
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 6),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    "Split Between Saving and Spending",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Save: ${savingPercentage.toStringAsFixed(0)}%",
                        style: const TextStyle(
                          color: Colors.teal,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        "Spend: ${(100 - savingPercentage).toStringAsFixed(0)}%",
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: savingPercentage,
                    min: 0,
                    max: 100,
                    divisions: 20,
                    activeColor: Colors.teal,
                    inactiveColor: Colors.amber.shade200,
                    onChanged: (value) {
                      setState(() {
                        savingPercentage = value;
                      });
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Continue Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _transfer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary.withOpacity(0.7),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 3,
                ),
                child: const Text(
                  "Continue",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
