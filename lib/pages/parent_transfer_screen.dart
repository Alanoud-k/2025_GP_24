import 'package:flutter/material.dart';

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

  void _transfer() {
    if (_amount.text.trim().isEmpty || double.tryParse(_amount.text) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid amount")),
      );
      return;
    }

    // هنا مستقبلاً بننادي API
    _showSuccess();
  }

  void _showSuccess() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.check_circle, color: Colors.green, size: 60),
            SizedBox(height: 10),
            Text(
              "Transfer Successful!",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 1), () {
      Navigator.pop(context); // close success popup
      Navigator.pop(context); // back to child list
    });
  }

  Widget _infoCard({required IconData icon, required String title, required String subtitle, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 40),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(subtitle, style: const TextStyle(color: Colors.grey)),
            ],
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Transfer")),
      backgroundColor: const Color(0xFFF7F9FC),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _infoCard(
              icon: Icons.person,
              title: "From Parent",
              subtitle: "Balance: 200.00 SAR", // TODO: نجيبها من API لاحقاً
              color: Colors.teal,
            ),
            const SizedBox(height: 12),
            _infoCard(
              icon: Icons.child_care,
              title: "To ${widget.childName}",
              subtitle: "Balance: ${widget.childBalance} SAR",
              color: Colors.amber,
            ),
            const SizedBox(height: 25),

            TextField(
              controller: _amount,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                hintText: "00.00 SAR",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _transfer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text("Continue", style: TextStyle(fontSize: 18)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
