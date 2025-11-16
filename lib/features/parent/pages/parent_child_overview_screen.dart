import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'parent_transfer_screen.dart';
import 'parent_money_requests_screen.dart';


class ParentChildOverviewScreen extends StatefulWidget {
  final int parentId;
  final int childId;
  final String childName;

  const ParentChildOverviewScreen({
    super.key,
    required this.parentId,
    required this.childId,
    required this.childName,
  });

  @override
  State<ParentChildOverviewScreen> createState() =>
      _ParentChildOverviewScreenState();
}

class _ParentChildOverviewScreenState extends State<ParentChildOverviewScreen> {
  bool _loading = true;
  String _firstName = '';
  String _phoneNo = '';
  double _balance = 0.0;
  double _spend = 0.0;
  double _saving = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchChildInfo();
  }

  Future<void> _fetchChildInfo() async {
    try {
      final url = Uri.parse(
        'http://10.0.2.2:3000/api/auth/child/info/${widget.childId}',
      );
      final res = await http.get(url);
      if (!mounted) return;

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        // Safely parse numeric fields that might arrive as strings
        double _toDouble(dynamic v) => (v is num)
            ? v.toDouble()
            : (double.tryParse(v?.toString() ?? '') ?? 0.0);

        setState(() {
          _firstName = (data['firstName'] ?? widget.childName).toString();
          _phoneNo = (data['phoneNo'] ?? '').toString(); // << use phoneNo
          _balance = _toDouble(data['balance']);
          _spend = _toDouble(data['spend']); // optional (falls back to 0.0)
          _saving = _toDouble(data['saving']); // optional (falls back to 0.0)
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load child info')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    const labelStyle = TextStyle(fontSize: 14, color: Colors.grey);
    const valueStyle = TextStyle(fontSize: 32, fontWeight: FontWeight.bold);

    return Scaffold(
      appBar: AppBar(
        title: Text(_firstName.isEmpty ? widget.childName : _firstName),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.teal,
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                          SizedBox(width: 12),
                        ],
                      ),
                      const Icon(Icons.notifications_none, size: 28),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _firstName.isNotEmpty ? _firstName : widget.childName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _phoneNo.isNotEmpty ? _phoneNo : '—',
                    style: const TextStyle(color: Colors.black54),
                  ),

                  const SizedBox(height: 16),

                  // Balance card
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Balance: ${_balance.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'spend balance',
                                      style: labelStyle,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '﷼ ${_spend.toStringAsFixed(2)}',
                                      style: valueStyle,
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: const Color(0x11000000),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'saving balance',
                                      style: labelStyle,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '﷼ ${_saving.toStringAsFixed(2)}',
                                      style: valueStyle,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Actions grid (placeholders)
                  Row(
                    children: [
                      Expanded(
                        child: _tileButton(
                          'Transfer Money',
                          Icons.send_rounded,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ParentTransferScreen(
                                  parentId: widget.parentId,
                                  childId: widget.childId,
                                  childName: widget.childName,
                                  childBalance: _balance.toStringAsFixed(2),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(width: 12),
                      Expanded(
                        child: _tileButton(
                          'Chores',
                          Icons.check_circle_outline, // ✅ fits for tasks/chores
                          () {},
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _tileButton(
                          'Transactions',
                          Icons
                              .receipt_long_rounded, // 🧾 clear for transaction history
                          () {},
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _tileButton(
  'Money Requests',
  Icons.request_page_outlined,
  () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ParentMoneyRequestsScreen(
          parentId: widget.parentId,
          childId: widget.childId,
        ),
      ),
    );
  },
),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: _tileButton(
                          'Goals',
                          Icons.flag_rounded, // 🎯 perfect visual match
                          () {},
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _tileButton(String text, IconData icon, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        elevation: 2,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Column(
        children: [Icon(icon), const SizedBox(height: 8), Text(text)],
      ),
    );
  }
}
