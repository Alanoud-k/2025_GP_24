import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_app/utils/check_auth.dart'; // ✅ ADD THIS

import 'parent_select_child_screen.dart';
import 'parent_add_money_screen.dart';
import 'parent_add_card_screen.dart';

class ParentHomeScreen extends StatefulWidget {
  final int parentId;
  final String token;

  const ParentHomeScreen({
    super.key,
    required this.parentId,
    required this.token,
  });

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen> {
  static const String baseUrl = "https://2025gp24-production.up.railway.app";

  String firstname = '';
  String walletBalance = '0.0';
  bool _isLoading = true;
  bool parentHasCard = false;

  String get token => widget.token;
  int get parentId => widget.parentId;

  @override
  void initState() {
    super.initState();
    _validateSession();
  }

  Future<void> _validateSession() async {
    await checkAuthStatus(context);
    fetchParentInfo(); // runs only if user is still authenticated
  }

  // Fetch parent info and wallet balance
  Future<void> fetchParentInfo() async {
    if (token.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    final parentUrl = Uri.parse("$baseUrl/api/parent/$parentId");
    final cardUrl = Uri.parse("$baseUrl/api/parent/$parentId/card");

    try {
      // Get parent info
      final parentRes = await http.get(
        parentUrl,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (parentRes.statusCode == 200) {
        final data = jsonDecode(parentRes.body);
        firstname = data['firstname'] ?? data['firstName'] ?? '';
        walletBalance = data['balance']?.toString() ?? '0.0';
      }

      // Check card existence
      final cardRes = await http.get(
        cardUrl,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (cardRes.statusCode == 200) {
        final cardData = jsonDecode(cardRes.body);
        parentHasCard = cardData['hasCard'] == true;
      }

      setState(() => _isLoading = false);
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  // Refresh wallet data
  void _refreshFromDb() {
    setState(() => _isLoading = true);
    fetchParentInfo();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.teal));
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header icons
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

            // Welcome text
            Text(
              firstname.isNotEmpty ? "Welcome, $firstname" : "Welcome!",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4F4F4F),
              ),
            ),

            const SizedBox(height: 20),

            // Wallet card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    "Parent's Wallet",
                    style: TextStyle(
                      fontSize: 17,
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Balance + SAR icon (aligned perfectly)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // SAR icon on LEFT
                      Image.asset(
                        'assets/icons/Sar.png',
                        height: 26,
                        fit: BoxFit.contain,
                      ),

                      const SizedBox(width: 6),

                      // Balance text
                      Text(
                        double.tryParse(walletBalance)?.toStringAsFixed(2) ??
                            "0.00",
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Action buttons
            Column(
              children: [
                Row(
                  children: [
                    // Add money
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          if (!parentHasCard) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Please add a card first"),
                              ),
                            );
                            return;
                          }

                          final added = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ParentAddMoneyScreen(
                                parentId: parentId,
                                token: token,
                              ),
                            ),
                          );

                          if (added == true) {
                            _refreshFromDb();
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
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text("Add Money"),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Transactions
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Transactions page will be added later",
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
                    // Add card
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ParentAddCardScreen(
                                parentId: parentId,
                                token: token,
                              ),
                            ),
                          );

                          if (result == true) {
                            setState(() => parentHasCard = true);
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

                    // Insights
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

            // My Kids button
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ParentSelectChildScreen(
                      parentId: parentId,
                      token: token,
                    ),
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
