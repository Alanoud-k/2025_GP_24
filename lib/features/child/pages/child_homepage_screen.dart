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
  int selectedDay = DateTime.now().day;
  String selectedPeriod = "Monthly";
  double monthTotalSpent = 0.0;

  final List<String> monthNames = [
    "Jan", "Feb", "Mar", "Apr", "May", "Jun",
    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
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
    final url = Uri.parse('${widget.baseUrl}/api/auth/child/info/${widget.childId}');

    try {
      final response = await http.get(url, headers: {"Authorization": "Bearer ${widget.token}", "Content-Type": "application/json"});
      if (response.statusCode == 401) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/mobile', (_) => false);
        return;
      }
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        double _toDouble(dynamic v) => (v is num) ? v.toDouble() : (double.tryParse(v.toString()) ?? 0.0);
        setState(() {
          childName = data['firstName'] ?? '';
          spendBalance = _toDouble(data['spend']);
          savingBalance = _toDouble(data['saving']);
          currentPoints = data['rewardKeys'] ?? 0;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  bool _canGoForward() {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    if (selectedPeriod == 'Daily') {
      return DateTime(selectedYear, selectedMonth, selectedDay).add(const Duration(days: 1)).compareTo(today) <= 0;
    } else if (selectedPeriod == 'Weekly') {
      return DateTime(selectedYear, selectedMonth, selectedDay).add(const Duration(days: 7)).compareTo(today) <= 0;
    } else if (selectedPeriod == 'Monthly') {
      return (selectedYear < now.year) || (selectedYear == now.year && selectedMonth < now.month);
    } else if (selectedPeriod == 'Yearly') {
      return selectedYear < now.year;
    }
    return false;
  }

  void _changeDate(int offset) {
    if (offset > 0 && !_canGoForward()) return;

    setState(() {
      DateTime current = DateTime(selectedYear, selectedMonth, selectedDay);
      if (selectedPeriod == 'Daily') {
        current = current.add(Duration(days: offset));
      } else if (selectedPeriod == 'Weekly') {
        current = current.add(Duration(days: offset * 7));
      } else if (selectedPeriod == 'Monthly') {
        current = DateTime(selectedYear, selectedMonth + offset, selectedDay);
      } else if (selectedPeriod == 'Yearly') {
        current = DateTime(selectedYear + offset, selectedMonth, selectedDay);
      }
      
      DateTime now = DateTime.now();
      if (current.isAfter(now)) current = now;

      selectedDay = current.day;
      selectedMonth = current.month;
      selectedYear = current.year;
    });
    _fetchChildChartData();
  }

  Future<void> _fetchChildChartData() async {
    String p = 'month';
    if (selectedPeriod == 'Daily') p = 'day';
    else if (selectedPeriod == 'Weekly') p = 'week';
    else if (selectedPeriod == 'Yearly') p = 'year';

    final url = Uri.parse('${widget.baseUrl}/api/insights/child-chart/${widget.childId}?month=$selectedMonth&year=$selectedYear&day=$selectedDay&period=$p');
    try {
      final response = await http.get(url, headers: {"Authorization": "Bearer ${widget.token}", "Content-Type": "application/json"});
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        double totalSpending = 0.0;
        Map<String, double> amounts = {};

        data.forEach((key, value) {
          double val = (value is num) ? value.toDouble() : (double.tryParse(value.toString()) ?? 0.0);
          amounts[key] = val;
          totalSpending += val;
        });

        if (mounted) {
          setState(() {
            monthTotalSpent = totalSpending;
            categoryPercentages.updateAll((key, value) => 0.0);
            if (totalSpending > 0) {
              amounts.forEach((key, value) {
                if (categoryPercentages.containsKey(key)) categoryPercentages[key] = (value / totalSpending) * 100;
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
    final url = Uri.parse("${ApiConfig.baseUrl}/api/notifications/unread/child/${widget.childId}");
    try {
      final response = await http.get(url, headers: {"Authorization": "Bearer ${widget.token}", "Content-Type": "application/json"});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => unreadCount = data["unread"] ?? 0);
      }
    } catch (_) {}
  }

  List<Map<String, dynamic>> insights = [];
  int currentInsight = 0;

  Future<void> _fetchInsights() async {
    final url = Uri.parse("${widget.baseUrl}/api/insights/${widget.childId}");
    try {
      final response = await http.get(url, headers: {"Authorization": "Bearer ${widget.token}", "Content-Type": "application/json"});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          insights = List<Map<String, dynamic>>.from(data);
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
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [bg1, bg2], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
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
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
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
                        if (insights.isNotEmpty) _insightsSection(),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Row(
            children: [
              const CircleAvatar(radius: 24, backgroundColor: Colors.grey, child: Icon(Icons.person, size: 26, color: Colors.white)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Welcome back,", maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: Colors.black54)),
                    Text(childName.isNotEmpty ? childName : 'Child', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF2C3E50))),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => ChildNotificationsScreen(childId: widget.childId, token: widget.token)));
            await _fetchUnreadCount();
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_none_rounded, size: 30, color: Colors.black87),
              if (unreadCount > 0)
                Positioned(
                  right: -2, top: -2,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 18),
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFFE53935), borderRadius: BorderRadius.circular(999), border: Border.all(color: Colors.white, width: 2)),
                    child: Text(unreadCount > 99 ? "99+" : unreadCount.toString(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
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
        Expanded(child: _balanceCard(title: 'Spend balance', amount: spendBalance, gradientColors: const [Color(0xFF37C4BE), Color(0xFF2EA49E)], leadingIcon: Icons.shopping_bag_outlined)),
        const SizedBox(width: 12),
        Expanded(child: _balanceCard(title: 'Save balance', amount: savingBalance, gradientColors: const [Color(0xFF7E57C2), Color(0xFF5C6BC0)], leadingIcon: Icons.account_balance_wallet_rounded)),
      ],
    );
  }

  Widget _balanceCard({required String title, required double amount, required List<Color> gradientColors, required IconData leadingIcon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(gradient: LinearGradient(colors: gradientColors, begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black12.withOpacity(0.18), blurRadius: 10, offset: const Offset(0, 6))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(leadingIcon, size: 18, color: Colors.white), const SizedBox(width: 6), Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, color: Colors.white70)))]),
          const SizedBox(height: 10),
          Row(children: [Image.asset(_sarIconPath, height: 18, color: Colors.white), const SizedBox(width: 4), Expanded(child: Text(amount.toStringAsFixed(2), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)))]),
        ],
      ),
    );
  }

  Widget _keysBadge() {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFEDEDED)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 4))]),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.vpn_key_rounded, size: 18, color: Colors.amber.shade800),
            const SizedBox(width: 6),
            Flexible(child: Text("$currentPoints Keys", maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF2C3E50)))),
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
              _actionButton('Chores', Icons.checklist_rounded, () { Navigator.push(context, MaterialPageRoute(builder: (_) => ChildChoresScreen(childId: widget.childId, token: widget.token))); }),
              const SizedBox(height: 12),
              _actionButton('Transactions', Icons.receipt_long_outlined, () { Navigator.push(context, MaterialPageRoute(builder: (_) => ChildTransactionsScreen(childId: widget.childId, token: widget.token, baseUrl: widget.baseUrl))); }),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            children: [
              _actionButton('Goals', Icons.flag_rounded, () { Navigator.push(context, MaterialPageRoute(builder: (_) => ChildGoalsScreen(childId: widget.childId, baseUrl: widget.baseUrl, token: widget.token))); }),
              const SizedBox(height: 12),
              _actionButton('Request Money', Icons.payments_rounded, () { Navigator.push(context, MaterialPageRoute(builder: (_) => ChildRequestMoneyScreen(childId: widget.childId, baseUrl: widget.baseUrl, token: widget.token))); }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInsightText(String message) {
    final parts = message.split("SAR");
    const textStyle = TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800, height: 1.35);

    if (parts.length == 1) return Text(message, maxLines: 4, overflow: TextOverflow.ellipsis, style: textStyle);

    List<InlineSpan> spans = [];
    for (int i = 0; i < parts.length; i++) {
      spans.add(TextSpan(text: parts[i], style: textStyle));
      if (i != parts.length - 1) {
        spans.add(WidgetSpan(alignment: PlaceholderAlignment.middle, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Image.asset("assets/icons/Sar.png", height: 16, color: Colors.white))));
      }
    }
    return RichText(maxLines: 4, overflow: TextOverflow.ellipsis, text: TextSpan(children: spans));
  }

  int _currentPage = 0;
  final Map<String, Map<String, dynamic>> insightStyles = {
    "weekly": {"colors": [Color(0xFF37C4BE), Color(0xFF6EE7DF)], "icon": Icons.calendar_today},
    "category": {"colors": [Color(0xFFAB47BC), Color(0xFFCE93D8)], "icon": Icons.pie_chart},
    "self-control": {"colors": [Color(0xFF66BB6A), Color(0xFFA5D6A7)], "icon": Icons.self_improvement},
    "goal-start": {"colors": [Color(0xFF42A5F5), Color(0xFF90CAF9)], "icon": Icons.flag},
    "goal-progress": {"colors": [Color(0xFF5C6BC0), Color(0xFF9FA8DA)], "icon": Icons.trending_up},
    "goal-close": {"colors": [Color(0xFFFFA726), Color(0xFFFFCC80)], "icon": Icons.emoji_events},
    "increase": {"colors": [Color(0xFFFF7043), Color(0xFFFFAB91)], "icon": Icons.trending_up},
    "empty": {"colors": [Color(0xFFB0BEC5), Color(0xFFECEFF1)], "icon": Icons.info_outline},
  };

  Widget _insightsSection() {
    final controller = PageController(viewportFraction: 0.88);

    return Column(
      children: [
        SizedBox(
          height: 150,
          child: PageView.builder(
            controller: controller,
            itemCount: insights.length,
            onPageChanged: (index) { setState(() => _currentPage = index); },
            itemBuilder: (context, i) {
              final insight = insights[i];
              final type = insight["type"] ?? "empty";
              final title = insight["title"] ?? "";
              final message = insight["message"] ?? "";
              final style = insightStyles[type] ?? insightStyles["empty"]!;
              final gradient = style["colors"] as List<Color>;
              final icon = style["icon"] as IconData;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: gradient[0].withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 12))]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [Icon(icon, color: Colors.white), const SizedBox(width: 8), Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)))]),
                    const SizedBox(height: 10),
                    _buildInsightText(message),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(insights.length, (index) {
            final isActive = index == _currentPage;
            return AnimatedContainer(duration: const Duration(milliseconds: 250), margin: const EdgeInsets.symmetric(horizontal: 4), width: isActive ? 14 : 6, height: 6, decoration: BoxDecoration(color: isActive ? const Color(0xFF37C4BE) : Colors.grey.shade400, borderRadius: BorderRadius.circular(999)));
          }),
        ),
      ],
    );
  }

  Widget _actionButton(String text, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFEDEDED), width: 1), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 4))]),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Container(height: 40, width: 40, decoration: BoxDecoration(color: const Color(0xFF37C4BE).withOpacity(0.12), borderRadius: BorderRadius.circular(14)), child: Icon(icon, size: 22, color: const Color(0xFF2EA49E))),
            const SizedBox(width: 8),
            Expanded(child: Text(text, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF2C3E50)))),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: const Color(0xFFF7FAFC), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: ['Daily', 'Weekly', 'Monthly', 'Yearly'].map((p) {
          final isSelected = selectedPeriod == p;
          return Expanded(
            child: GestureDetector(
              onTap: () { setState(() { selectedPeriod = p; }); _fetchChildChartData(); },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(color: isSelected ? const Color(0xFF37C4BE) : Colors.transparent, borderRadius: BorderRadius.circular(12)),
                child: Center(child: Text(p, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: isSelected ? Colors.white : Colors.black54, fontWeight: FontWeight.bold, fontSize: 12))),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDateSelector() {
    String dateText = "";
    if (selectedPeriod == 'Daily') {
      dateText = "$selectedDay ${monthNames[selectedMonth - 1]} $selectedYear";
    } else if (selectedPeriod == 'Weekly') {
      DateTime current = DateTime(selectedYear, selectedMonth, selectedDay);
      DateTime weekAgo = current.subtract(const Duration(days: 6));
      dateText = "${weekAgo.day} ${monthNames[weekAgo.month - 1]} - $selectedDay ${monthNames[selectedMonth - 1]}";
    } else if (selectedPeriod == 'Monthly') {
      dateText = "${monthNames[selectedMonth - 1]} $selectedYear";
    } else if (selectedPeriod == 'Yearly') {
      dateText = "$selectedYear";
    }

    bool canGoForward = _canGoForward();
    bool canSelectPicker = (selectedPeriod == 'Monthly' || selectedPeriod == 'Yearly');

    return Flexible(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerRight,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(color: const Color(0xFFF7FAFC), borderRadius: BorderRadius.circular(20)),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => _changeDate(-1),
                child: const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Icon(Icons.chevron_left_rounded, size: 24, color: Colors.black54)),
              ),
              GestureDetector(
                onTap: canSelectPicker ? _showMonthYearPicker : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                  child: Row(
                    children: [
                      Text(dateText, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2EA49E), fontSize: 13)),
                      if (canSelectPicker) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF2EA49E)),
                      ]
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: canGoForward ? () => _changeDate(1) : null,
                child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Icon(Icons.chevron_right_rounded, size: 24, color: canGoForward ? Colors.black54 : Colors.grey.shade300)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _breakdownCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xFFEDEDED)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 6))]),
      child: Column(
        children: [
          _buildPeriodToggle(),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.pie_chart_rounded, color: Color(0xFF2EA49E)),
                    SizedBox(width: 6),
                    Flexible(child: Text('Breakdown', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF2C3E50)))),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildDateSelector(),
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
                    ? [PieChartSectionData(value: 100, color: Colors.grey.shade300, title: '0%', radius: 55, titleStyle: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold))]
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Text("Select Date", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF2C3E50), fontSize: 18)),
              content: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (selectedPeriod == 'Monthly') ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: const Color(0xFFF7FAFC), borderRadius: BorderRadius.circular(12)),
                      child: DropdownButton<int>(
                        value: tempMonth,
                        underline: const SizedBox(),
                        dropdownColor: Colors.white,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF2EA49E)),
                        items: List.generate(12, (index) {
                          int m = index + 1;
                          bool isDisabled = (tempYear == DateTime.now().year && m > DateTime.now().month);
                          return DropdownMenuItem<int>(
                            value: m,
                            enabled: !isDisabled,
                            child: Text(monthNames[index], style: TextStyle(fontWeight: FontWeight.w600, color: isDisabled ? Colors.grey : const Color(0xFF2C3E50)))
                          );
                        }),
                        onChanged: (val) { 
                          if (val != null) {
                            if (tempYear == DateTime.now().year && val > DateTime.now().month) return;
                            setDialogState(() => tempMonth = val); 
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(color: const Color(0xFFF7FAFC), borderRadius: BorderRadius.circular(12)),
                    child: DropdownButton<int>(
                      value: tempYear,
                      underline: const SizedBox(),
                      dropdownColor: Colors.white,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF2EA49E)),
                      items: List.generate(6, (index) {
                        int year = DateTime.now().year - 5 + index; 
                        return DropdownMenuItem(value: year, child: Text(year.toString(), style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2C3E50))));
                      }),
                      onChanged: (val) { 
                        if (val != null) {
                          setDialogState(() {
                            tempYear = val;
                            if (tempYear == DateTime.now().year && tempMonth > DateTime.now().month) {
                              tempMonth = DateTime.now().month;
                            }
                          }); 
                        }
                      },
                    ),
                  ),
                ],
              ),
              actionsAlignment: MainAxisAlignment.spaceEvenly,
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF37C4BE), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10)),
                  onPressed: () {
                    setState(() { 
                      selectedMonth = tempMonth; 
                      selectedYear = tempYear; 
                      if (selectedYear == DateTime.now().year && selectedMonth == DateTime.now().month) {
                        if (selectedDay > DateTime.now().day) {
                          selectedDay = DateTime.now().day;
                        }
                      }
                    });
                    _fetchChildChartData();
                    Navigator.pop(context);
                  },
                  child: const Text("Apply", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _legend() {
    final List<String> ordered = ['Food & Restaurants', 'Grocery & Markets', 'Retail & Shopping', 'Transport', 'Medical', 'Digital & Subscriptions'];
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 24,
      runSpacing: 12,
      children: ordered.where((cat) => (categoryPercentages[cat] ?? 0) > 0).map((cat) {
        final color = _getColorForCategory(cat);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 14, height: 14, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(cat, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF2C3E50))),
          ],
        );
      }).toList(),
    );
  }

  Color _getColorForCategory(String category) {
    switch (category) {
      case 'Food & Restaurants': return Colors.orangeAccent;
      case 'Grocery & Markets': return Colors.greenAccent;
      case 'Retail & Shopping': return Colors.pinkAccent;
      case 'Transport': return Colors.lightBlueAccent;
      case 'Medical': return Colors.redAccent;
      case 'Digital & Subscriptions': return Colors.purpleAccent;
      default: return Colors.blueGrey;
    }
  }

  List<PieChartSectionData> _buildPieSections() {
    return categoryPercentages.entries.where((entry) => entry.value > 0).map((entry) {
      return PieChartSectionData(value: entry.value, color: _getColorForCategory(entry.key), title: '${entry.value.toStringAsFixed(0)}%', radius: 55, titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14));
    }).toList();
  }
}