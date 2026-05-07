import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_app/utils/check_auth.dart';
import 'package:my_app/features/child/pages/child_transactions_screen.dart';
import 'package:my_app/l10n/app_localizations.dart';
import 'package:my_app/core/api_config.dart'; // ✅ استدعاء ملف الروابط الصحيح

import 'parent_transfer_screen.dart';
import 'parent_money_requests_screen.dart';
import 'parent_child_goals_screen.dart';
import 'parent_child_chores_screen.dart';

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
  static const String _sarIcon = "assets/icons/Sar.png";

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await checkAuthStatus(context);
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString("token") ?? widget.token;
    if (token == null || token!.isEmpty) {
      _forceLogout();
      return;
    }
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

  Future<void> _fetchChildInfo() async {
    if (token == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      // ✅ استخدام الرابط الديناميكي من ملف api_config.dart
      final url = Uri.parse("${ApiConfig.baseUrl}/api/auth/child/info/${widget.childId}");
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
    final l10n = AppLocalizations.of(context)!;
    const Color primary1 = Color(0xFF37C4BE);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF7FAFC), Color(0xFFE6F4F3)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: primary1))
              : RefreshIndicator(
                  onRefresh: () async {
                    await _fetchChildInfo();
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- HEADER ---
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.black),
                            onPressed: () => Navigator.pop(context),
                          ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                            _firstName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF2C3E50)),
                          ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // --- CHILD CARD ---
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: [BoxShadow(color: Colors.black12.withOpacity(0.10), blurRadius: 10, offset: const Offset(0, 5))],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(radius: 32, backgroundColor: primary1.withOpacity(0.25), child: const Icon(Icons.person, color: Color(0xFF2EA49E), size: 32)),
                            const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                    Text(_firstName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF2C3E50))),
                                const SizedBox(height: 4),
                                Text(_phoneNo, style: const TextStyle(fontSize: 14, color: Colors.black54)),
                              ],
                            ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),

                      // --- TOTAL BALANCE ---
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [BoxShadow(color: Colors.black12.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 5))],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                              Expanded(
                                child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                    Text(l10n.totalBalance, style: const TextStyle(color: Colors.black54, fontSize: 14, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Image.asset(_sarIcon, height: 22, color: const Color(0xFF2EA49E)), 
                                    const SizedBox(width: 6), 
                                        Expanded(
                                          child: Text(_balance.toStringAsFixed(2), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF2C3E50), fontSize: 26, fontWeight: FontWeight.w800)),
                                        )
                                  ],
                                ),
                              ],
                            ),
                              ),
                              const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2EA49E).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF2EA49E), size: 28),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // --- SPEND & SAVE CARDS ---
                      Row(
                        children: [
                          Expanded(
                            child: _balanceCard(
                              title: l10n.spendBalance,
                              amount: _spend,
                              gradientColors: const [Color(0xFF37C4BE), Color(0xFF2EA49E)],
                              leadingIcon: Icons.shopping_bag_outlined,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _balanceCard(
                              title: l10n.saveBalance,
                              amount: _saving,
                              gradientColors: const [Color(0xFF7E57C2), Color(0xFF5C6BC0)],
                              leadingIcon: Icons.account_balance_wallet_rounded,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // --- ACTION BUTTONS ---
                      Row(
                        children: [
                          Expanded(
                            child: _actionButton(
                              l10n.transferMoney_action,
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
                                  await _fetchChildInfo();
                                  if (mounted) setState(() {});
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _actionButton(
                              l10n.chores_action,
                              Icons.check_circle_outline,
                              () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ParentChildChoresScreen(
                                      childName: widget.childName,
                                      childId: widget.childId.toString(),
                                      parentId: widget.parentId, 
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
                            child: _actionButton(l10n.transactions_action, Icons.receipt_long_rounded, () {
                                  // ✅ التعديل هنا: تمرير ApiConfig.baseUrl بدلاً من baseUrl الثابتة
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => ChildTransactionsScreen(childId: widget.childId, token: widget.token, baseUrl: ApiConfig.baseUrl)));
                            }),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _actionButton(l10n.moneyRequests, Icons.request_page_outlined, () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => ParentMoneyRequestsScreen(parentId: widget.parentId, childId: widget.childId)));
                            }),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _actionButton(l10n.goals_action, Icons.flag_rounded, () {
                                  // ✅ التعديل هنا: تمرير ApiConfig.baseUrl بدلاً من baseUrl الثابتة
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => ParentChildGoalsScreen(childId: widget.childId, childName: widget.childName, token: widget.token, baseUrl: ApiConfig.baseUrl)));
                            }),
                          ),
                        ],
                      ),
                        const SizedBox(height: 30),
                    ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  // ✅ الأرصدة المتجاوبة مع الشاشات الصغيرة
  Widget _balanceCard({
    required String title,
    required double amount,
    required List<Color> gradientColors,
    required IconData leadingIcon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.18),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(leadingIcon, size: 18, color: Colors.white),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.5, color: Colors.white70),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Image.asset(_sarIcon, height: 18, color: Colors.white),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                amount.toStringAsFixed(2),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ✅ الأزرار المتجاوبة وتمنع الـ Overflow السفلي
  Widget _actionButton(String text, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 115, 
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(20), 
          boxShadow: [BoxShadow(color: Colors.black12.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 5))]
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, 
          children: [
            Icon(icon, size: 28, color: const Color(0xFF2EA49E)), 
            const SizedBox(height: 10), 
            Text(
              text, 
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFF2C3E50), height: 1.2)
            )
          ]
        ),
      ),
    );
  }
}