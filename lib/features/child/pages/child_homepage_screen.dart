import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:my_app/core/api_config.dart';
import 'child_goals_screen.dart';
import 'child_request_money_screen.dart';
import 'package:my_app/utils/check_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'child_notifications_screen.dart';
import 'child_chores_screen.dart';

class ChildHomePageScreen extends StatefulWidget {
  final int childId;
  final String baseUrl;
  final String token;

  const ChildHomePageScreen({
    super.key,
    required this.childId,
    required this.baseUrl,
    required this.token,
  });

  @override
  State<ChildHomePageScreen> createState() => _ChildHomePageScreenState();
}

class _ChildHomePageScreenState extends State<ChildHomePageScreen> {
  double currentBalance = 0.0;
  int currentPoints = 0;
  String childName = '';
  bool _loading = true;
  String? avatarUrl; // CHANGED: store avatar URL from backend
  int unreadCount = 0;
  double spendBalance = 0.0;
  double savingBalance = 0.0;

  Map<String, double> categoryPercentages = {
    'Food': 25,
    'Education': 10,
    'Entertainment': 25,
    'Shopping': 30,
    'Gifts': 5,
    'Others': 5,
  };

  static const String _sarIconPath = 'assets/icons/riyal.png';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await checkAuthStatus(context); // ✅ auto logout if token expired
    });

    _fetchChildInfo();
    _fetchUnreadCount();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (mounted) _fetchChildInfo();
  }

  Future<void> _fetchChildInfo() async {
    setState(() => _loading = true);

    final url = Uri.parse(
      '${widget.baseUrl}/api/auth/child/info/${widget.childId}',
    );

    try {
      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer ${widget.token}",
          "Content-Type": "application/json",
        },
      );
      if (response.statusCode == 401) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/mobile', (_) => false);
        }
        return;
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print(data);

        double _toDouble(dynamic v) =>
            (v is num) ? v.toDouble() : (double.tryParse(v.toString()) ?? 0.0);

        setState(() {
          childName = data['firstName'] ?? '';
          spendBalance = _toDouble(data['spend']);
          savingBalance = _toDouble(data['saving']);
          currentPoints = data['rewardKeys'] ?? 0.toInt();
          // avatarUrl = data['avatarUrl']; // CHANGED: store avatar

          categoryPercentages = Map<String, double>.from(
            data['categories'] ?? categoryPercentages,
          );

          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _fetchUnreadCount() async {
    final url = Uri.parse(
      "${ApiConfig.baseUrl}/api/notifications/unread/child/${widget.childId}",
    );

    try {
      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer ${widget.token}",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          unreadCount = data["unread"] ?? 0;
        });
      }
    } catch (e) {}
  }

  // ---------------------------------------------------------
  // UI
  // ---------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    const bg1 = Color(0xFFF7FAFC);
    const bg2 = Color(0xFFE6F4F3);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [bg1, bg2],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _header(),
                      const SizedBox(height: 20),
                      _balancesRow(),
                      const SizedBox(height: 10),
                      _keysBadge(),
                      const SizedBox(height: 24),
                      _actionsGrid(),
                      const SizedBox(height: 28),
                      _breakdownCard(),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // Header
  // ---------------------------------------------------------
  Widget _header() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // LEFT SIDE — avatar + name
        Row(
          children: [
            const CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, size: 26, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Welcome back,",
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
                Text(
                  childName.isNotEmpty ? childName : 'Child',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ],
            ),
          ],
        ),

        GestureDetector(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChildNotificationsScreen(
                  childId: widget.childId,
                  token: widget.token,
                ),
              ),
            );
          },
          child: const Icon(
            Icons.notifications_none_rounded,
            size: 30,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------
  // Balance Cards
  // ---------------------------------------------------------
  Widget _balancesRow() {
    return Row(
      children: [
        Expanded(
          child: _balanceCard(
            title: 'Spend balance',
            amount: spendBalance,
            gradientColors: const [Color(0xFF37C4BE), Color(0xFF2EA49E)],
            leadingIcon: Icons.shopping_bag_outlined,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _balanceCard(
            title: 'Save balance',
            amount: savingBalance,
            gradientColors: const [Color(0xFF7E57C2), Color(0xFF5C6BC0)],
            leadingIcon: Icons.account_balance_wallet_rounded,
          ),
        ),
      ],
    );
  }

  Widget _balanceCard({
    required String title,
    required double amount,
    required List<Color> gradientColors,
    required IconData leadingIcon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
              Icon(leadingIcon, size: 20, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 13, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Image.asset(_sarIconPath, height: 20),
              const SizedBox(width: 4),
              Text(
                amount.toStringAsFixed(2),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // Keys Badge
  // ---------------------------------------------------------
  Widget _keysBadge() {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.vpn_key_rounded,
              size: 18,
              color: Colors.amber.shade800, // ← الذهبي
            ),
            const SizedBox(width: 6),
            Text(
              "$currentPoints Keys",
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2C3E50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // Actions Grid
  // ---------------------------------------------------------
  Widget _actionsGrid() {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              // داخل ChildHomePageScreen
              _actionButton('Chores', Icons.checklist_rounded, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChildChoresScreen(
                      childId: widget.childId,
                      token: widget.token,
                    ),
                  ),
                );
              }),
              const SizedBox(height: 12),
              _actionButton('Transaction', Icons.receipt_long_outlined, () {}),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            children: [
              _actionButton('Goals', Icons.flag_rounded, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChildGoalsScreen(
                      childId: widget.childId,
                      baseUrl: widget.baseUrl,
                      token: widget.token,
                    ),
                  ),
                );
              }),
              const SizedBox(height: 12),
              _actionButton('Request Money', Icons.payments_rounded, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChildRequestMoneyScreen(
                      childId: widget.childId,
                      baseUrl: widget.baseUrl,
                      token: widget.token,
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _actionButton(String text, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF2EA49E).withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 22, color: const Color(0xFF2EA49E)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // Breakdown Card
  // ---------------------------------------------------------
  Widget _breakdownCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.10),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: const [
              Icon(Icons.pie_chart_rounded, color: Color(0xFF2EA49E)),
              SizedBox(width: 6),
              Text(
                'Spending Breakdown',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 210,
            child: PieChart(
              PieChartData(
                centerSpaceRadius: 40,
                sectionsSpace: 3,
                sections: [
                  PieChartSectionData(
                    value: 30,
                    color: Colors.pinkAccent,
                    radius: 55,
                    title: '30%',
                    titleStyle: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  PieChartSectionData(
                    value: 25,
                    color: Colors.orangeAccent,
                    radius: 55,
                    title: '25%',
                    titleStyle: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  PieChartSectionData(
                    value: 20,
                    color: Colors.lightBlueAccent,
                    radius: 55,
                    title: '20%',
                    titleStyle: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  PieChartSectionData(
                    value: 25,
                    color: Colors.greenAccent,
                    radius: 55,
                    title: '25%',
                    titleStyle: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          _legend(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // Legend (ترتيب ثابت + لون داخلي)
  // ---------------------------------------------------------
  Widget _legend() {
    final List<String> ordered = [
      'Food',
      'Education',
      'Entertainment',
      'Shopping',
      'Gifts',
      'Others',
    ];

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 24,
      runSpacing: 12,
      children: ordered.map((cat) {
        final color = _getColorForCategory(cat);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 18,
              height: 18,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(shape: BoxShape.circle),
              child: Container(
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              cat,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  // ---------------------------------------------------------
  // Pie Chart sections
  // ---------------------------------------------------------
  List<PieChartSectionData> _buildPieSections() {
    return categoryPercentages.entries.map((entry) {
      return PieChartSectionData(
        value: entry.value,
        color: _getColorForCategory(entry.key),
        title: '${entry.value.toStringAsFixed(0)}%',
        radius: 55,
        titleStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: 14,
        ),
      );
    }).toList();
  }

  Color _getColorForCategory(String category) {
    switch (category) {
      case 'Food':
        return Colors.orangeAccent;
      case 'Education':
        return Colors.greenAccent;
      case 'Entertainment':
        return Colors.lightBlueAccent;
      case 'Shopping':
        return Colors.pinkAccent;
      case 'Gifts':
        return Colors.purpleAccent;
      default:
        return Colors.blueGrey;
    }
  }
}
