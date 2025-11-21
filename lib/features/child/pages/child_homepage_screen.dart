import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:my_app/core/api_config.dart';
import 'child_goals_screen.dart';
import 'child_request_money_screen.dart';

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

  double spendBalance = 0.0;
  double savingBalance = 0.0;
  Map<String, double> categoryPercentages = {};

  @override
  void initState() {
    super.initState();
    _fetchChildInfo();
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
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        double _toDouble(dynamic v) =>
            (v is num) ? v.toDouble() : (double.tryParse(v.toString()) ?? 0.0);

        setState(() {
          childName = data['firstName'] ?? '';
          currentBalance = _toDouble(data['balance']);
          spendBalance = _toDouble(data['spend']);
          savingBalance = _toDouble(data['saving']);
          currentPoints = (data['points'] ?? 0).toInt();

          categoryPercentages = Map<String, double>.from(
            data['categories'] ??
                {'Food': 25, 'Shopping': 55, 'Gifts': 10, 'Others': 10},
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 22,
                    backgroundImage: AssetImage(
                      'assets/images/child_avatar.png',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    childName.isNotEmpty ? childName : 'Child',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const Icon(Icons.notifications_none, color: Colors.black),
            ],
          ),

          const SizedBox(height: 25),

          // Balance Cards
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _balanceCard(
                'spend balance',
                '﷼ ${spendBalance.toStringAsFixed(2)}',
              ),
              _balanceCard(
                'saving balance',
                '﷼ ${savingBalance.toStringAsFixed(2)}',
              ),
            ],
          ),

          const SizedBox(height: 25),

          // Buttons
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.8,
            children: [
              _actionButton('Chores', () {}),
              _actionButton('Goals', () async {
                final needRefresh = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChildGoalsScreen(
                      childId: widget.childId,
                      baseUrl: widget.baseUrl,
                    ),
                  ),
                );

                if (needRefresh == true) {
                  _fetchChildInfo();
                }
              }),
              _actionButton('Transaction', () {}),
              _actionButton('Request Money', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ChildRequestMoneyScreen(childId: widget.childId),
                  ),
                );
              }),
            ],
          ),

          const SizedBox(height: 35),

          // Pie Chart
          Center(
            child: Column(
              children: [
                const Text(
                  'Spending Breakdown',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 220,
                  width: 220,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 40,
                      borderData: FlBorderData(show: false),
                      sections: _buildPieSections(),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Legend
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 16,
                  runSpacing: 8,
                  children: categoryPercentages.keys.map((key) {
                    return _legendItem(_getColorForCategory(key), key);
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // Widgets
  Widget _balanceCard(String title, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(String text, VoidCallback onTap) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onTap,
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w500)),
    );
  }

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
        return Colors.teal;
      case 'Shopping':
        return Colors.orange;
      case 'Gifts':
        return Colors.purple;
      default:
        return Colors.blueGrey;
    }
  }

  Widget _legendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}
