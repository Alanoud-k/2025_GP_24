import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'parent_transfer_screen.dart';
import 'parent_money_requests_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_app/utils/check_auth.dart';

class ParentChildOverviewScreen extends StatefulWidget {
  final int parentId;
  final int childId;
  final String childName;
  final String token;

  const ParentChildOverviewScreen({
    super.key,
    required this.parentId,
    required this.childId,
    required this.childName,
    required this.token,
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

  String? token;
  static const String baseUrl = "http://10.0.2.2:3000";
  static const String _sarIcon = "assets/icons/Sar.png";

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // 1) Check if expired → auto redirect
    await checkAuthStatus(context);

    // 2) Load token locally
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString("token") ?? widget.token;

    // 3) If missing → force logout
    if (token == null || token!.isEmpty) {
      _forceLogout();
      return;
    }

    // 4) Fetch child info
    await _fetchChildInfo();

    if (mounted) setState(() => _loading = false);
  }

  void _forceLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/mobile', (route) => false);
    }
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString("token");
  }

  Future<void> _fetchChildInfo() async {
    if (token == null) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Missing token — please log in again.")),
      );
      return;
    }

    try {
      final url = Uri.parse("$baseUrl/api/auth/child/info/${widget.childId}");
      final res = await http.get(
        url,
        headers: {"Authorization": "Bearer $token"},
      );

      if (!mounted) return;

      if (res.statusCode == 401) {
        _forceLogout();
        return;
      }
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        double _toDouble(dynamic v) =>
            (v is num) ? v.toDouble() : (double.tryParse(v.toString()) ?? 0.0);

        if (!mounted) return;

        setState(() {
          _firstName = (data['firstName'] ?? widget.childName).toString();
          _phoneNo = (data['phoneNo'] ?? '').toString();
          _balance = _toDouble(data['balance']);
          _spend = _toDouble(data['spend']);
          _saving = _toDouble(data['saving']);
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    const Color primary1 = Color(0xFF37C4BE);
    const Color primary2 = Color(0xFF2EA49E);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,

        /// FULL BACKGROUND
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF7FAFC), Color(0xFFE6F4F3)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),

        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// ---------------- HEADER ----------------
                      Row(
                        children: [
                          Container(
                            height: 42,
                            width: 42,
                            child: IconButton(
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.black,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _firstName,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.notifications_none,
                            size: 28,
                            color: Colors.black54,
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      /// ---------------- CHILD CARD ----------------
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12.withOpacity(0.10),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundColor: primary1.withOpacity(0.25),
                              child: const Icon(
                                Icons.person,
                                color: Color(0xFF2EA49E),
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _firstName,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF2C3E50),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _phoneNo,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 22),

                      /// ---------------- BALANCE CARD ----------------
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [primary1, primary2],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12.withOpacity(0.18),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Total Balance",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Image.asset(_sarIcon, height: 22),
                                const SizedBox(width: 6),
                                Text(
                                  _balance.toStringAsFixed(2),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 14),
                            Row(
                              children: [
                                _balanceTile(
                                  "Spend",
                                  _spend,
                                  Icons.shopping_bag_outlined,
                                ),
                                const SizedBox(width: 12),
                                _balanceTile(
                                  "Save",
                                  _saving,
                                  Icons.account_balance_wallet_rounded,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      /// ---------------- ACTION BUTTONS ----------------
                      Row(
                        children: [
                          Expanded(
                            child: _actionButton(
                              "Transfer Money",
                              Icons.send_rounded,
                              () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ParentTransferScreen(
                                      parentId: widget.parentId,
                                      childId: widget.childId,
                                      childName: widget.childName,
                                      childBalance: _balance.toStringAsFixed(2),
                                      token: widget.token,
                                    ),
                                  ),
                                );

                                if (result == true) {
                                  await _fetchChildInfo(); // 🔧 Refresh balances
                                  setState(() {}); // 🔄 Update UI
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _actionButton(
                              "Chores",
                              Icons.check_circle_outline,
                              () {},
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: _actionButton(
                              "Transactions",
                              Icons.receipt_long_rounded,
                              () {},
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _actionButton(
                              "Money Requests",
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
                        children: [
                          Expanded(
                            child: _actionButton(
                              "Goals",
                              Icons.flag_rounded,
                              () {},
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _balanceTile(String label, double amount, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Row(
                  children: [
                    Image.asset(_sarIcon, height: 16, width: 16),
                    const SizedBox(width: 4),
                    Text(
                      amount.toStringAsFixed(2),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(String text, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 90,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 26, color: const Color(0xFF2EA49E)),
            const SizedBox(height: 8),
            Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
