import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// same folder: lib/features/parent/pages/
import 'parent_select_child_screen.dart';
import 'parent_add_money_screen.dart';
import 'parent_add_card_screen.dart';

class ParentHomeScreen extends StatefulWidget {
  final int parentId;
  const ParentHomeScreen({super.key, required this.parentId});

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen> {
  String firstname = '';
  String walletBalance = '';
  bool _isLoading = true;
  bool parentHasCard = false;

  int get parentId => widget.parentId;

  @override
  void initState() {
    super.initState();
    fetchParentInfo();
  }

  Future<void> fetchParentInfo() async {
    final parentUrl = Uri.parse('http://10.0.2.2:3000/api/parent/$parentId');
    final cardUrl = Uri.parse('http://10.0.2.2:3000/api/parent/$parentId/card');

    try {
      final parentRes = await http.get(parentUrl);
      if (parentRes.statusCode == 200) {
        final data = jsonDecode(parentRes.body);
        firstname = data['firstname'] ?? data['firstName'] ?? '';
        walletBalance = data['walletbalance']?.toString() ?? '0.0';
      }

      final cardRes = await http.get(cardUrl);
      if (cardRes.statusCode == 200) {
        final cardData = jsonDecode(cardRes.body);
        parentHasCard = cardData['hasCard'] == true;
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _refreshFromDb() {
    setState(() {
      _isLoading = true;
    });
    fetchParentInfo();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.teal),
      );
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.teal,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                Icon(Icons.notifications_none, size: 28),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              firstname.isNotEmpty ? "Welcome, $firstname" : "Welcome!",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 5),
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text(
                        "current balance",
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "﷼${walletBalance.isNotEmpty ? walletBalance : '0.0'}",
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            Column(
              children: [
                Row(
                  children: [
                    // Add Money
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          if (!parentHasCard) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please add a card first'),
                              ),
                            );
                            return;
                          }

                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ParentAddMoneyScreen(parentId: parentId),
                            ),
                          );

                          _refreshFromDb();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          elevation: 2,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text("Add Money"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Transactions placeholder
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Transactions page will be added later',
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          elevation: 2,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.history),
                        label: const Text("Transactions"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                  // Add Card / My Card
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ParentAddCardScreen(parentId: parentId),
                            ),
                          );

                          if (result == true) {
                            setState(() {
                              parentHasCard = true;
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          elevation: 2,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.credit_card),
                        label: Text(parentHasCard ? "My Card" : "Add Card"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Insights placeholder
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          elevation: 2,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.insights),
                        label: const Text("Insights"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ParentSelectChildScreen(parentId: parentId),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.group),
              label: const Text("My Kids"),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
