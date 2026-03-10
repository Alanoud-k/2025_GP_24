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
import 'child_transactions_screen.dart';

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
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;
  double monthTotalSpent = 0.0;

  final List<String> monthNames = [
    "Jan",
    "Feb",
    "Mar",
    "Apr",
    "May",
    "Jun",
    "Jul",
    "Aug",
    "Sep",
    "Oct",
    "Nov",
    "Dec",
  ];

  double currentBalance = 0.0;
  int currentPoints = 0;
  String childName = '';
  bool _loading = true;
  String? avatarUrl;
  int unreadCount = 0;
  double spendBalance = 0.0;
  double savingBalance = 0.0;

  Map<String, double> categoryPercentages = {
    'Food & Restaurants': 0.0,
    'Grocery & Markets': 0.0,
    'Retail & Shopping': 0.0,
    'Transport': 0.0,
    'Medical': 0.0,
    'Digital & Subscriptions': 0.0,
  };

  static const String _sarIconPath = 'assets/icons/riyal.png';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await checkAuthStatus(context);
    });

    _fetchChildInfo();
    _fetchChildChartData();
    _fetchUnreadCount();
    _fetchInsights();
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

        double _toDouble(dynamic v) =>
            (v is num) ? v.toDouble() : (double.tryParse(v.toString()) ?? 0.0);

        setState(() {
          childName = data['firstName'] ?? '';
          spendBalance = _toDouble(data['spend']);
          savingBalance = _toDouble(data['saving']);
          currentPoints = data['rewardKeys'] ?? 0.toInt();

          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _fetchChildChartData() async {
    final url = Uri.parse(
      '${widget.baseUrl}/api/insights/child-chart/${widget.childId}?month=$selectedMonth&year=$selectedYear',
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
        final Map<String, dynamic> data = jsonDecode(response.body);

        double totalSpending = 0.0;
        Map<String, double> amounts = {};

        data.forEach((key, value) {
          double val = (value is num)
              ? value.toDouble()
              : (double.tryParse(value.toString()) ?? 0.0);
          amounts[key] = val;
          totalSpending += val;
        });

        if (mounted) {
          setState(() {
            monthTotalSpent = totalSpending;
            categoryPercentages.updateAll((key, value) => 0.0);

            if (totalSpending > 0) {
              amounts.forEach((key, value) {
                if (categoryPercentages.containsKey(key)) {
                  categoryPercentages[key] = (value / totalSpending) * 100;
                }
              });
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching chart data: $e");
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

  List<String> insights = [];

  Future<void> _fetchInsights() async {
    final url = Uri.parse("${widget.baseUrl}/api/insights/${widget.childId}");

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
          insights = List<String>.from(data.map((item) => item["message"]));
        });
      }
    } catch (e) {
      debugPrint("INSIGHTS ERROR: $e");
    }
  }

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
              : RefreshIndicator(
                  onRefresh: () async {
                    await _fetchChildInfo();
                    await _fetchChildChartData();
                    await _fetchUnreadCount();
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
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
                        const SizedBox(height: 12),
                        _keysBadge(),
                        const SizedBox(height: 24),
                        _actionsGrid(),
                        const SizedBox(height: 24),
                        _insightCard(),
                        const SizedBox(height: 20),
                        _breakdownCard(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
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
            await _fetchUnreadCount();
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(
                Icons.notifications_none_rounded,
                size: 30,
                color: Colors.black87,
              ),
              if (unreadCount > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53935),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Text(
                      unreadCount > 99 ? "99+" : unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

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
            Icon(Icons.vpn_key_rounded, size: 18, color: Colors.amber.shade800),
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

  Widget _actionsGrid() {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
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
              _actionButton('Transactions', Icons.receipt_long_outlined, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChildTransactionsScreen(
                      childId: widget.childId,
                      token: widget.token,
                      baseUrl: widget.baseUrl,
                    ),
                  ),
                );
              }),
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

  Widget _insightCard() {
    if (insights.isEmpty) return const SizedBox();

    final colors = [
      const Color(0xFF37C4BE),
      const Color(0xFF7E57C2),
      const Color(0xFFFFA726),
      const Color(0xFF42A5F5),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.lightbulb_rounded, color: Color(0xFF2EA49E)),
            SizedBox(width: 6),
            Text(
              "Smart Insights",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2C3E50),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        SizedBox(
          height: 120,
          child: PageView.builder(
            controller: PageController(viewportFraction: 0.85),
            itemCount: insights.length,
            itemBuilder: (context, index) {
              final color = colors[index % colors.length];
              final msg = insights[index];

              return Transform.scale(
                scale: index == 0 ? 1 : 0.94,
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.75)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),

                  child: Row(
                    children: [
                      Container(
                        height: 42,
                        width: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(width: 14),

                      Expanded(
                        child: Text(
                          msg,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.pie_chart_rounded, color: Color(0xFF2EA49E)),
                  SizedBox(width: 6),
                  Text(
                    'Breakdown',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ],
              ),

              // Month and Year Selector
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7FAFC),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    // زر السهم لليسار (الشهر السابق)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          if (selectedMonth == 1) {
                            selectedMonth = 12;
                            selectedYear--;
                          } else {
                            selectedMonth--;
                          }
                        });
                        _fetchChildChartData();
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          Icons.chevron_left_rounded,
                          size: 24,
                          color: Colors.black54,
                        ),
                      ),
                    ),

                    // النص القابل للنقر لفتح القائمة
                    GestureDetector(
                      onTap: _showMonthYearPicker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Text(
                              "${monthNames[selectedMonth - 1]} $selectedYear",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2EA49E),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 16,
                              color: Color(0xFF2EA49E),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // زر السهم لليمين (الشهر التالي)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          if (selectedMonth == 12) {
                            selectedMonth = 1;
                            selectedYear++;
                          } else {
                            selectedMonth++;
                          }
                        });
                        _fetchChildChartData();
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          size: 24,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ],
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
                sections: categoryPercentages.values.every((v) => v == 0)
                    ? [
                        PieChartSectionData(
                          value: 100,
                          color: Colors.grey.shade300,
                          title: '0%',
                          radius: 55,
                          titleStyle: const TextStyle(
                            color: Colors.black54,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ]
                    : _buildPieSections(),
              ),
            ),
          ),
          const SizedBox(height: 18),
          _legend(),
        ],
      ),
    );
  }

  void _showMonthYearPicker() {
    int tempMonth = selectedMonth;
    int tempYear = selectedYear;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: const Text(
                "Select Date",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2C3E50),
                  fontSize: 18,
                ),
              ),
              content: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // قائمة الأشهر
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7FAFC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButton<int>(
                      value: tempMonth,
                      underline: const SizedBox(),
                      dropdownColor: Colors.white,
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFF2EA49E),
                      ),
                      items: List.generate(12, (index) {
                        return DropdownMenuItem(
                          value: index + 1,
                          child: Text(
                            monthNames[index],
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                        );
                      }),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => tempMonth = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  // قائمة السنوات
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7FAFC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButton<int>(
                      value: tempYear,
                      underline: const SizedBox(),
                      dropdownColor: Colors.white,
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFF2EA49E),
                      ),
                      items: List.generate(10, (index) {
                        // نعرض 10 سنوات (من السنة الحالية وقبلها بـ 5 سنوات وبعدها)
                        int year = DateTime.now().year - 5 + index;
                        return DropdownMenuItem(
                          value: year,
                          child: Text(
                            year.toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                        );
                      }),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => tempYear = val);
                      },
                    ),
                  ),
                ],
              ),
              actionsAlignment: MainAxisAlignment.spaceEvenly,
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF37C4BE),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 10,
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      selectedMonth = tempMonth;
                      selectedYear = tempYear;
                    });
                    _fetchChildChartData(); // نجلب بيانات التاريخ الجديد
                    Navigator.pop(context); // نغلق النافذة
                  },
                  child: const Text(
                    "Apply",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _legend() {
    final List<String> ordered = [
      'Food & Restaurants',
      'Grocery & Markets',
      'Retail & Shopping',
      'Transport',
      'Medical',
      'Digital & Subscriptions',
    ];

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 24,
      runSpacing: 12,
      children: ordered.where((cat) => (categoryPercentages[cat] ?? 0) > 0).map(
        (cat) {
          final color = _getColorForCategory(cat);
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                cat,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          );
        },
      ).toList(),
    );
  }

  Color _getColorForCategory(String category) {
    switch (category) {
      case 'Food & Restaurants':
        return Colors.orangeAccent;
      case 'Grocery & Markets':
        return Colors.greenAccent;
      case 'Retail & Shopping':
        return Colors.pinkAccent;
      case 'Transport':
        return Colors.lightBlueAccent;
      case 'Medical':
        return Colors.redAccent;
      case 'Digital & Subscriptions':
        return Colors.purpleAccent;
      default:
        return Colors.blueGrey;
    }
  }

  List<PieChartSectionData> _buildPieSections() {
    return categoryPercentages.entries.where((entry) => entry.value > 0).map((
      entry,
    ) {
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
}
