import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:my_app/utils/check_auth.dart';

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
  String walletBalance = '0.00';
  bool _isLoading = true;
  bool parentHasCard = false;

  String get token => widget.token;
  int get parentId => widget.parentId;

  // Unified fintech label style (actions + My Kids)
  static const TextStyle fintechLabelStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: Colors.black87,
    letterSpacing: 0.2,
  );

  @override
  void initState() {
    super.initState();
    _validateSession();
  }

  Future<void> _validateSession() async {
    await checkAuthStatus(context);
    if (!mounted) return;
    await fetchParentInfo();
  }

  // Fetch parent info (includes balance) and card status
  Future<void> fetchParentInfo() async {
    if (token.isEmpty) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      return;
    }

    final parentUrl = Uri.parse("$baseUrl/api/parent/$parentId");
    final cardUrl = Uri.parse("$baseUrl/api/parent/$parentId/card");

    try {
      String newFirstname = firstname;
      double newBalance = double.tryParse(walletBalance) ?? 0.0;
      bool newHasCard = parentHasCard;

      final parentRes = await http.get(
        parentUrl,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (parentRes.statusCode == 200) {
        final data = jsonDecode(parentRes.body);
        newFirstname = data['firstname'] ?? data['firstName'] ?? '';

        final b = data['balance'];
        if (b != null) {
          newBalance =
              (b is num) ? b.toDouble() : double.tryParse(b.toString()) ?? 0.0;
        }
      }

      final cardRes = await http.get(
        cardUrl,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (cardRes.statusCode == 200) {
        final cardData = jsonDecode(cardRes.body);
        newHasCard = cardData['hasCard'] == true;
      }

      if (!mounted) return;
      setState(() {
        firstname = newFirstname;
        walletBalance = newBalance.toStringAsFixed(2);
        parentHasCard = newHasCard;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  // Refresh wallet after add money
  Future<void> _refreshFromDb() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    await fetchParentInfo();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.teal),
      );
    }

    final balanceText =
        double.tryParse(walletBalance)?.toStringAsFixed(2) ?? "0.00";

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top bar (old parent icon style)
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.teal,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  Icon(Icons.notifications_none_rounded, size: 28),
                ],
              ),

              const SizedBox(height: 18),

              // Welcome
              Text(
                firstname.isNotEmpty ? "Welcome, $firstname" : "Welcome!",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF3F3F3F),
                ),
              ),

              const SizedBox(height: 18),

              // Wallet card
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFF0F0F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 14,
                      spreadRadius: 1,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      "Parent's Wallet",
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          "assets/icons/Sar.png",
                          height: 24,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          balanceText,
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // Actions grid
              Row(
                children: [
                  Expanded(
                    child: _ActionCard(
                      title: "Add Money",
                      asset: "assets/icons/addMoney.png",
                      labelStyle: fintechLabelStyle,
                      onTap: () async {
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
                          await _refreshFromDb();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionCard(
                      title: "Transactions",
                      asset: "assets/icons/transactions.png",
                      labelStyle: fintechLabelStyle,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text("Transactions page will be added later"),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _ActionCard(
                      title: parentHasCard ? "My Card" : "Add Card",
                      asset: "assets/icons/addCard.png",
                      labelStyle: fintechLabelStyle,
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ParentAddCardScreen(
                              parentId: parentId,
                              token: token,
                            ),
                          ),
                        );

                        if (result == true && mounted) {
                          setState(() => parentHasCard = true);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionCard(
                      title: "Insights",
                      asset: "assets/icons/insights.png",
                      labelStyle: fintechLabelStyle,
                      onTap: () {},
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // My Kids (white fintech style, no icon circle)
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
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
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE6E6E6)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        "assets/icons/myKids.png",
                        height: 28,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "My Kids",
                        style: fintechLabelStyle,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String asset;
  final VoidCallback onTap;
  final TextStyle labelStyle;

  const _ActionCard({
    required this.title,
    required this.asset,
    required this.onTap,
    required this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          // Big card is pure white + subtle border/shadow
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFEDEDED), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon without circle
              Image.asset(
                asset,
                height: 28,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 10),
              Text(title, style: labelStyle),
            ],
          ),
        ),
      ),
    );
  }
}
