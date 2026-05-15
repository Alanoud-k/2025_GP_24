import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_app/core/api_config.dart';
import 'package:my_app/l10n/app_localizations.dart';
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
  int selectedDay = DateTime.now().day;
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;
  String selectedChild = "All";
  String selectedPeriod = "Monthly"; 
  List<String> childrenNames = ["All"];

  Map<String, double> _chartData = {};
  double _totalSpent = 0.0; 

  final List<Color> _chartColors = [
    const Color(0xFF37C4BE),
    const Color(0xFF7E57C2),
    const Color(0xFFFFB74D),
    const Color(0xFFEF5350),
    const Color(0xFF42A5F5),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();
    });
  }

  List<String> _getMonthNames(AppLocalizations l10n) {
    return [
      l10n.jan, l10n.feb, l10n.mar, l10n.apr, l10n.may, l10n.jun, 
      l10n.jul, l10n.aug, l10n.sep, l10n.oct, l10n.nov, l10n.dec
    ];
  }

  Future<void> _initialize() async {
    await checkAuthStatus(context);
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString("token") ?? widget.token;

    if (token == null || token!.isEmpty) {
      if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/mobile', (_) => false);
      return;
    }

    await _fetchChildrenList();
    await _fetchInsights();
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
    _fetchInsights();
  }

  Future<void> _fetchChildrenList() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/auth/parent/${widget.parentId}/children');
    try {
      final response = await http.get(
        url,
        headers: {"Authorization": "Bearer $token", "Content-Type": "application/json"},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> list = [];
        if (data is Map && data.containsKey('data')) list = data['data'];
        else if (data is List) list = data;
        
        final names = list.map((c) => c['firstName'].toString()).toList();
        if (mounted) setState(() => childrenNames = ["All", ...names]);
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  Future<void> _fetchInsights() async {
    setState(() => _loading = true);
    
    String p = 'month';
    if (selectedPeriod == 'Daily') p = 'day';
    else if (selectedPeriod == 'Weekly') p = 'week';
    else if (selectedPeriod == 'Yearly') p = 'year';

    final url = Uri.parse('${ApiConfig.baseUrl}/api/insights/parent-chart/${widget.parentId}?month=$selectedMonth&year=$selectedYear&day=$selectedDay&childName=$selectedChild&period=$p');
    try {
      final response = await http.get(
        url,
        headers: {"Authorization": "Bearer $token", "Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        Map<String, double> realData = {};
        double total = 0;

        data.forEach((key, value) {
          double val = (value is num) ? value.toDouble() : (double.tryParse(value.toString()) ?? 0.0);
          realData[key] = val;
          total += val;
        });

        if (mounted) {
          setState(() {
            _chartData = realData;
            _totalSpent = total;
            _loading = false;
          });
        }
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showMonthYearPicker() {
    final l10n = AppLocalizations.of(context)!;
    final monthNames = _getMonthNames(l10n);
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
              title: Text(l10n.selectDate, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF2C3E50), fontSize: 18)),
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
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF37C4BE)),
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
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF37C4BE)),
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
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.cancel, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
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
                    _fetchInsights();
                    Navigator.pop(context); 
                  },
                  child: Text(l10n.apply, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
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

  String _getLocalizedCategory(String category, AppLocalizations l10n) {
    switch (category) {
      case 'Food & Restaurants': return l10n.foodRestaurants;
      case 'Grocery & Markets': return l10n.groceryMarkets;
      case 'Retail & Shopping': return l10n.retailShopping;
      case 'Transport': return l10n.transport;
      case 'Medical': return l10n.medical;
      case 'Digital & Subscriptions': return l10n.digitalSubscriptions;
      default: return category;
    }
  }

  Widget _buildPeriodToggle(AppLocalizations l10n) {
    final periodLabels = {
      'Daily': l10n.daily,
      'Weekly': l10n.weekly,
      'Monthly': l10n.monthly,
      'Yearly': l10n.yearly,
    };

    return Container(
      margin: const EdgeInsetsDirectional.only(bottom: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: const Color(0xFFF7FAFC), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: Row(
        children: ['Daily', 'Weekly', 'Monthly', 'Yearly'].map((p) {
          final isSelected = selectedPeriod == p;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => selectedPeriod = p);
                _fetchInsights();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(color: isSelected ? const Color(0xFF37C4BE) : Colors.transparent, borderRadius: BorderRadius.circular(12)),
                child: Center(child: Text(periodLabels[p]!, style: TextStyle(color: isSelected ? Colors.white : Colors.black54, fontWeight: FontWeight.bold, fontSize: 12))),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDateSelector(AppLocalizations l10n) {
    final monthNames = _getMonthNames(l10n);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

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
        alignment: AlignmentDirectional.centerEnd,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(color: const Color(0xFFF7FAFC), borderRadius: BorderRadius.circular(20)),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => _changeDate(-1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4), 
                  child: Icon(isRtl ? Icons.chevron_right_rounded : Icons.chevron_left_rounded, size: 24, color: Colors.black54)
                ),
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
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4), 
                  child: Icon(isRtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded, size: 24, color: canGoForward ? Colors.black54 : Colors.grey.shade300)
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const textColor = Color(0xFF2C3E50);

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        title: Text(l10n.spendingBreakdown, style: const TextStyle(fontWeight: FontWeight.w800, color: textColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
         icon: Icon(Icons.arrow_back, color: textColor),          onPressed: () => Navigator.pop(context)
        ),
      ),
      body: SafeArea(
        child: _loading 
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF37C4BE)))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPeriodToggle(l10n),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(color: const Color(0xFFE6F4F3), borderRadius: BorderRadius.circular(16)),
                            child: DropdownButton<String>(
                              value: selectedChild,
                              isExpanded: true,
                              underline: const SizedBox(),
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF2EA49E)),
                              dropdownColor: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              items: childrenNames.map((name) => DropdownMenuItem(value: name, child: Text(name == "All" ? l10n.allChildren : name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF2EA49E), fontSize: 13)))).toList(),
                              onChanged: (val) {
                                if (val != null) { setState(() => selectedChild = val); _fetchInsights(); }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildDateSelector(l10n),
                      ],
                    ),

                    const SizedBox(height: 30),
                    Text(selectedChild == "All" ? l10n.comparisonByChild : l10n.categoryBreakdownFor(selectedChild), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textColor)),
                    const SizedBox(height: 10),
                    Text(selectedChild == "All" ? l10n.seeWhichChildSpendingMost : l10n.trackWhereMoneyGoes(selectedChild), style: const TextStyle(fontSize: 14, color: Colors.grey)),

                    const SizedBox(height: 30),

if (_chartData.isNotEmpty) ...[
  // التبديل بناءً على اختيار الأب
  selectedChild == "All" 
      ? _buildBarChart(textColor) 
      : _buildPieChart(l10n, textColor),
  
  const SizedBox(height: 16),
                      const SizedBox(height: 40),
                      Text(l10n.details, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textColor)),
                      const SizedBox(height: 16),
                      
                      ..._chartData.entries.map((entry) {
                        final index = _chartData.keys.toList().indexOf(entry.key);
                        final color = selectedChild == "All" ? _chartColors[index % _chartColors.length] : _getColorForCategory(entry.key);
                        final percent = _totalSpent > 0 ? (entry.value / _totalSpent * 100).toStringAsFixed(1) : "0.0";

                        return Container(
                          margin: const EdgeInsetsDirectional.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))]),
                          child: Row(
                            children: [
                              Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle), child: Icon(selectedChild == "All" ? Icons.person : Icons.label_important_rounded, color: color, size: 20)),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_getLocalizedCategory(entry.key, l10n), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                                    Text("$percent ${l10n.percentOfTotal}", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset('assets/icons/riyal.png', height: 16),
                                  const SizedBox(width: 4),
                                  Text(entry.value.toStringAsFixed(0), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ] else
                      Center(
                        child: Padding(
                          padding: const EdgeInsetsDirectional.only(top: 50),
                          child: Column(
                            children: [
                              Icon(Icons.inbox_rounded, size: 60, color: Colors.grey.shade300),
                              const SizedBox(height: 12),
                              Text(l10n.noSpendingData, style: const TextStyle(color: Colors.grey, fontSize: 15)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  List<PieChartSectionData> _buildChartSections() {
    int i = 0;
    return _chartData.entries.map((entry) {
      final isLarge = i == 0; 
      final color = selectedChild == "All" ? _chartColors[i % _chartColors.length] : _getColorForCategory(entry.key);
      final percentVal = _totalSpent > 0 ? (entry.value / _totalSpent * 100) : 0.0;
      i++;
      return PieChartSectionData(color: color, value: entry.value, title: '${percentVal.toStringAsFixed(0)}%', radius: isLarge ? 55 : 50, titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white));
    }).toList();
  }

// --- دالة رسم الأعمدة (عند اختيار جميع الأبناء) ---
  Widget _buildBarChart(Color textColor) {
    if (_chartData.isEmpty) return const SizedBox();

    double maxY = 0;
    for (var val in _chartData.values) {
      if (val > maxY) maxY = val;
    }
    // إضافة مساحة 20% فوق أعلى عمود لشكل جمالي أفضل
    maxY = maxY + (maxY * 0.2); 
    if (maxY == 0) maxY = 10;

    int index = 0;
    List<BarChartGroupData> barGroups = [];
    List<String> names = _chartData.keys.toList();

    for (var entry in _chartData.entries) {
      final color = _chartColors[index % _chartColors.length];
      barGroups.add(
        BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: entry.value,
              color: color,
              width: 22,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: maxY,
                color: Colors.grey.shade200, // لون خلفية العمود
              ),
            ),
          ],
        ),
      );
      index++;
    }

    return SizedBox(
      height: 250,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: const Color(0xFF2C3E50),              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${names[group.x.toInt()]}\n',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  children: [
                    TextSpan(
                      text: '${rod.toY.toStringAsFixed(0)} SAR',
                      style: const TextStyle(color: Color(0xFF37C4BE), fontWeight: FontWeight.w900, fontSize: 14),
                    ),
                  ],
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  if (value.toInt() >= 0 && value.toInt() < names.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        names[value.toInt()],
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (double value, TitleMeta meta) {
                  if (value == maxY) return const SizedBox.shrink();
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false), // إخفاء إطار الرسمة
          barGroups: barGroups,
        ),
      ),
    );
  }

  // --- دالة رسم الدائرة البيانية (عند اختيار طفل محدد) ---
  Widget _buildPieChart(AppLocalizations l10n, Color textColor) {
    return SizedBox(
      height: 250,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(PieChartData(
            sectionsSpace: 4, 
            centerSpaceRadius: 60, 
            sections: _buildChartSections()
          )),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.category_outlined, size: 30, color: Colors.grey),
              const SizedBox(height: 2),
              Text(l10n.totalWord, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.grey)),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/icons/riyal.png', height: 14),
                  const SizedBox(width: 4),
                  Text(_totalSpent.toStringAsFixed(0), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: textColor)),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }

}