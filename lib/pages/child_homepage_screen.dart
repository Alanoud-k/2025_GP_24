import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ChildHomePageScreen extends StatefulWidget {
  const ChildHomePageScreen({super.key});

  @override
  State<ChildHomePageScreen> createState() => _ChildHomePageScreenState();
}

class _ChildHomePageScreenState extends State<ChildHomePageScreen> {
  double currentBalance = 0.0;
  int currentPoints = 0;
  String childName = '';
  late int childId;
  bool _loading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    childId = args?['childId'] ?? 0;
    _fetchChildInfo();
  }

  Future<void> _fetchChildInfo() async {
    setState(() => _loading = true);
    final url = Uri.parse('http://10.0.2.2:3000/api/auth/child/info/$childId');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          childName = data['firstName'] ?? '';
          currentBalance = (data['balance'] ?? 0).toDouble();
          currentPoints = (data['points'] ?? 0).toInt();
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
        print('Failed to load child info: ${response.body}');
      }
    } catch (e) {
      setState(() => _loading = false);
      print('Error fetching child info: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            const CircleAvatar(
              radius: 20,
              backgroundImage: AssetImage('assets/images/child_avatar.png'),
            ),
            const SizedBox(width: 10),
            Text(
              childName.isNotEmpty ? childName : 'Child',
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: const [
          Icon(Icons.notifications_none, color: Colors.black87),
          SizedBox(width: 12),
          Icon(Icons.more_horiz, color: Colors.black87),
          SizedBox(width: 12),
        ],
      ),

      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===== Wallet Card =====
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _infoColumn(
                          'current balance',
                          '﷼${currentBalance.toStringAsFixed(1)}',
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.grey[300],
                        ),
                        _infoColumn('current points', currentPoints.toString()),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ===== Buttons Row =====
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _actionButton(Icons.history, 'Transactions', () {
                        // TODO: navigate to transactions page
                      }),
                      _actionButton(
                        Icons.account_balance_wallet_outlined,
                        'Request Money',
                        () {
                          // TODO: navigate to request money page
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // ===== Optional placeholder =====
                  const Center(
                    child: Text(
                      'Recent transactions and activities will appear here.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),

      // ===== Bottom Navigation =====
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        currentIndex: 0,
        onTap: (index) {
          // TODO: handle navigation between tabs
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: ''),
          BottomNavigationBarItem(
            icon: Icon(Icons.videogame_asset_outlined),
            label: '',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.card_giftcard), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: ''),
        ],
      ),
    );
  }

  // Reusable widget for balance and points
  Widget _infoColumn(String title, String value) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  // Reusable widget for buttons
  Widget _actionButton(IconData icon, String text, VoidCallback onTap) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: onTap,
          icon: Icon(icon, size: 22),
          label: Text(text),
        ),
      ),
    );
  }
}
