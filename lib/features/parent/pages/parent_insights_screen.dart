import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_app/core/api_config.dart';
import 'package:my_app/utils/check_auth.dart';

class ParentInsightsScreen extends StatefulWidget {
  final int parentId;
  final String token;

  const ParentInsightsScreen({
    super.key,
    required this.parentId,
    required this.token,
  });

  @override
  State<ParentInsightsScreen> createState() => _ParentInsightsScreenState();
}

class _ParentInsightsScreenState extends State<ParentInsightsScreen> {
  bool _loading = true;
  String? token;

  // Data: Key = Child Name, Value = Amount Spent
  Map<String, double> _childSpending = {};
  double _totalSpent = 0.0; // Used for percentage calculation only

  // Colors for each child
  final List<Color> _chartColors = [
    const Color(0xFF37C4BE), // Teal (Ahmed)
    const Color(0xFF7E57C2), // Purple (Sara)
    const Color(0xFFFFB74D), // Orange (Khalid)
    const Color(0xFFEF5350), // Red
    const Color(0xFF42A5F5), // Blue
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();
    });
  }

  Future<void> _initialize() async {
    await checkAuthStatus(context);
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString("token") ?? widget.token;

    if (token == null || token!.isEmpty) {
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/mobile', (_) => false);
      }
      return;
    }

    await _fetchInsights();
  }

  Future<void> _fetchInsights() async {
    try {
      // --- MOCK DATA (Replace with API logic later) ---
      // This simulates fetching spending sum for each child
      await Future.delayed(const Duration(seconds: 1)); 
      
      final Map<String, double> mockData = {
        "Ahmed": 450.0,
        "Sara": 320.0,
        "Khalid": 120.0,
      };
      
      double total = 0;
      mockData.forEach((key, value) => total += value);

      if (mounted) {
        setState(() {
          _childSpending = mockData;
          _totalSpent = total; // Kept for calculation
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading insights: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const hassalaGreen1 = Color(0xFF37C4BE);
    const bgColor = Color(0xFFF7FAFC);
    const textColor = Color(0xFF2C3E50);

    if (_loading) {
      return const Scaffold(
        backgroundColor: bgColor,
        body: Center(child: CircularProgressIndicator(color: hassalaGreen1)),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          "Spending Insights",
          style: TextStyle(fontWeight: FontWeight.w800, color: textColor),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              // 1. Title
              const Text(
                "Spending by Child",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "See which child is spending the most this month.",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),

              const SizedBox(height: 30),

              // 2. Pie Chart Section
              if (_childSpending.isNotEmpty) ...[
                SizedBox(
                  height: 250,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sectionsSpace: 4, // Space between sections
                          centerSpaceRadius: 60,
                          sections: _buildChartSections(),
                        ),
                      ),
                      // Inner Text (Total or Label)
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.people_outline, size: 30, color: Colors.grey),
                          const SizedBox(height: 4),
                          Text(
                            "${_childSpending.length} Kids",
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // 3. Child List (Legend & Details)
                const Text(
                  "Breakdown",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 16),
                
                ..._childSpending.entries.map((entry) {
                  final index = _childSpending.keys.toList().indexOf(entry.key);
                  final color = _chartColors[index % _chartColors.length];
                  // Calculate percentage
                  final percent = _totalSpent > 0 
                      ? (entry.value / _totalSpent * 100).toStringAsFixed(1) 
                      : "0.0";

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Color Indicator (Avatar-like)
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.person, color: color, size: 20),
                        ),
                        const SizedBox(width: 16),
                        
                        // Child Name & Percent
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.key, // Child Name
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              Text(
                                "$percent% of total",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Amount Spent
                        Text(
                          "${entry.value.toStringAsFixed(0)} SAR",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: color, // Matching the chart color
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ] else
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 50),
                    child: Text(
                      "No spending data available yet.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper to build Pie Chart sections based on Children
  List<PieChartSectionData> _buildChartSections() {
    int i = 0;
    return _childSpending.entries.map((entry) {
      final isLarge = i == 0; // Highlight the first one slightly
      final color = _chartColors[i % _chartColors.length];
      
      final percentVal = _totalSpent > 0 ? (entry.value / _totalSpent * 100) : 0.0;
      
      i++;
      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: '${percentVal.toStringAsFixed(0)}%', // Show % on chart
        radius: isLarge ? 55 : 50,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }
}