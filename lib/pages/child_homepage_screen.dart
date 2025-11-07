import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';

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

      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ===== Header =====
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 22,
                              backgroundImage:
                                  AssetImage('assets/images/child_avatar.png'),
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
                        const Icon(Icons.notifications_none,
                            color: Colors.black),
                      ],
                    ),
                    const SizedBox(height: 25),

                    // ===== Balance Cards =====
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _balanceCard('spend balance', '﷼ 38.9'),
                        _balanceCard('saving balance', '﷼ 76.5'),
                      ],
                    ),
                    const SizedBox(height: 25),

                    // ===== Action Buttons =====
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.8,
                      children: [
                        _actionButton('Chores', () {}),
                        _actionButton('Goals', () {}),
                        _actionButton('Transaction', () {}),
                        _actionButton('Request Money', () {}),
                      ],
                    ),
                    const SizedBox(height: 35),

                    // ===== Pie Chart (Expense Breakdown) =====
                    Center(
                      child: Column(
                        children: [
                          const Text(
                            'Spending Breakdown',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
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

                          // ===== Legend (الألوان والعناوين) =====
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 16,
                            runSpacing: 8,
                            children: [
                              _legendItem(Colors.teal, 'Food'),
                              _legendItem(Colors.orange, 'Shopping'),
                              _legendItem(Colors.purple, 'Gifts'),
                              _legendItem(Colors.blueGrey, 'Others'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

      // ===== Bottom Navigation =====
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 2,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.card_giftcard_outlined), label: ''),
          BottomNavigationBarItem(
              icon: Icon(Icons.videogame_asset_outlined), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(
              icon: Icon(Icons.list_alt_outlined), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: ''),
        ],
      ),
    );
  }

  // ===== Widgets =====

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
            Text(title,
                style: const TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onPressed: onTap,
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections() {
    return [
      PieChartSectionData(
        value: 25,
        color: Colors.teal,
        title: '25%',
        radius: 55,
        titleStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: 14,
        ),
      ),
      PieChartSectionData(
        value: 55,
        color: Colors.orange,
        title: '55%',
        radius: 55,
        titleStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: 14,
        ),
      ),
      PieChartSectionData(
        value: 10,
        color: Colors.purple,
        title: '10%',
        radius: 55,
        titleStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: 14,
        ),
      ),
      PieChartSectionData(
        value: 10,
        color: Colors.blueGrey,
        title: '10%',
        radius: 55,
        titleStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: 14,
        ),
      ),
    ];
  }

  Widget _legendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}
