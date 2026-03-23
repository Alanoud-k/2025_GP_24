// import 'package:flutter/material.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:my_app/core/api_config.dart';
// import 'package:my_app/utils/check_auth.dart';

// class ParentInsightsScreen extends StatefulWidget {
//   final int parentId;
//   final String token;

//   const ParentInsightsScreen({
//     super.key,
//     required this.parentId,
//     required this.token,
//   });

//   @override
//   State<ParentInsightsScreen> createState() => _ParentInsightsScreenState();
// }

// class _ParentInsightsScreenState extends State<ParentInsightsScreen> {
//   bool _loading = true;
//   String? token;

//   int selectedMonth = DateTime.now().month;
//   int selectedYear = DateTime.now().year;
//   String selectedChild = "All";
//   List<String> childrenNames = ["All"];

//   final List<String> monthNames = [
//     "Jan", "Feb", "Mar", "Apr", "May", "Jun", 
//     "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
//   ];

//   Map<String, double> _chartData = {};
//   double _totalSpent = 0.0; 

//   final List<Color> _chartColors = [
//     const Color(0xFF37C4BE),
//     const Color(0xFF7E57C2),
//     const Color(0xFFFFB74D),
//     const Color(0xFFEF5350),
//     const Color(0xFF42A5F5),
//   ];

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _initialize();
//     });
//   }

//   Future<void> _initialize() async {
//     await checkAuthStatus(context);
//     final prefs = await SharedPreferences.getInstance();
//     token = prefs.getString("token") ?? widget.token;

//     if (token == null || token!.isEmpty) {
//       if (mounted) {
//         Navigator.pushNamedAndRemoveUntil(context, '/mobile', (_) => false);
//       }
//       return;
//     }

//     await _fetchChildrenList();
//     await _fetchInsights();
//   }

//   Future<void> _fetchChildrenList() async {
//     final url = Uri.parse('${ApiConfig.baseUrl}/api/auth/parent/${widget.parentId}/children');
//     try {
//       final response = await http.get(
//         url,
//         headers: {
//           "Authorization": "Bearer $token",
//           "Content-Type": "application/json",
//         },
//       );

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         List<dynamic> list = [];
//         if (data is Map && data.containsKey('data')) {
//           list = data['data'];
//         } else if (data is List) {
//           list = data;
//         }
        
//         final names = list.map((c) => c['firstName'].toString()).toList();
//         if (mounted) {
//           setState(() {
//             childrenNames = ["All", ...names];
//           });
//         }
//       }
//     } catch (e) {
//       debugPrint("Error fetching children list: $e");
//     }
//   }

//   Future<void> _fetchInsights() async {
//     setState(() => _loading = true);
//     final url = Uri.parse('${ApiConfig.baseUrl}/api/insights/parent-chart/${widget.parentId}?month=$selectedMonth&year=$selectedYear&childName=$selectedChild');

//     try {
//       final response = await http.get(
//         url,
//         headers: {
//           "Authorization": "Bearer $token",
//           "Content-Type": "application/json",
//         },
//       );

//       if (response.statusCode == 200) {
//         final Map<String, dynamic> data = jsonDecode(response.body);
//         Map<String, double> realData = {};
//         double total = 0;

//         data.forEach((key, value) {
//           double val = (value is num) ? value.toDouble() : (double.tryParse(value.toString()) ?? 0.0);
//           realData[key] = val;
//           total += val;
//         });

//         if (mounted) {
//           setState(() {
//             _chartData = realData;
//             _totalSpent = total;
//             _loading = false;
//           });
//         }
//       } else {
//         if (mounted) setState(() => _loading = false);
//       }
//     } catch (e) {
//       if (mounted) setState(() => _loading = false);
//     }
//   }

//   void _showMonthYearPicker() {
//     int tempMonth = selectedMonth;
//     int tempYear = selectedYear;

//     showDialog(
//       context: context,
//       builder: (context) {
//         return StatefulBuilder(
//           builder: (context, setDialogState) {
//             return AlertDialog(
//               backgroundColor: Colors.white,
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
//               title: const Text(
//                 "Select Date",
//                 textAlign: TextAlign.center,
//                 style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF2C3E50), fontSize: 18),
//               ),
//               content: Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 12),
//                     decoration: BoxDecoration(color: const Color(0xFFF7FAFC), borderRadius: BorderRadius.circular(12)),
//                     child: DropdownButton<int>(
//                       value: tempMonth,
//                       underline: const SizedBox(),
//                       dropdownColor: Colors.white,
//                       icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF37C4BE)),
//                       items: List.generate(12, (index) {
//                         return DropdownMenuItem(
//                           value: index + 1,
//                           child: Text(monthNames[index], style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2C3E50))),
//                         );
//                       }),
//                       onChanged: (val) {
//                         if (val != null) setDialogState(() => tempMonth = val);
//                       },
//                     ),
//                   ),
//                   const SizedBox(width: 16),
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 12),
//                     decoration: BoxDecoration(color: const Color(0xFFF7FAFC), borderRadius: BorderRadius.circular(12)),
//                     child: DropdownButton<int>(
//                       value: tempYear,
//                       underline: const SizedBox(),
//                       dropdownColor: Colors.white,
//                       icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF37C4BE)),
//                       items: List.generate(10, (index) {
//                         int year = DateTime.now().year - 5 + index;
//                         return DropdownMenuItem(
//                           value: year,
//                           child: Text(year.toString(), style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2C3E50))),
//                         );
//                       }),
//                       onChanged: (val) {
//                         if (val != null) setDialogState(() => tempYear = val);
//                       },
//                     ),
//                   ),
//                 ],
//               ),
//               actionsAlignment: MainAxisAlignment.spaceEvenly,
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.pop(context),
//                   child: const Text("Cancel", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
//                 ),
//                 ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color(0xFF37C4BE),
//                     elevation: 0,
//                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                     padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
//                   ),
//                   onPressed: () {
//                     setState(() {
//                       selectedMonth = tempMonth;
//                       selectedYear = tempYear;
//                     });
//                     _fetchInsights();
//                     Navigator.pop(context); 
//                   },
//                   child: const Text("Apply", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//     );
//   }

//   Color _getColorForCategory(String category) {
//     switch (category) {
//       case 'Food & Restaurants': return Colors.orangeAccent;
//       case 'Grocery & Markets': return Colors.greenAccent;
//       case 'Retail & Shopping': return Colors.pinkAccent;
//       case 'Transport': return Colors.lightBlueAccent;
//       case 'Medical': return Colors.redAccent;
//       case 'Digital & Subscriptions': return Colors.purpleAccent;
//       default: return Colors.blueGrey;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     const textColor = Color(0xFF2C3E50);

//     return Scaffold(
//       backgroundColor: const Color(0xFFF7FAFC),
//       appBar: AppBar(
//         title: const Text(
//           "Spending Insights",
//           style: TextStyle(fontWeight: FontWeight.w800, color: textColor),
//         ),
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         centerTitle: true,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: textColor),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: SafeArea(
//         child: _loading 
//             ? const Center(child: CircularProgressIndicator(color: Color(0xFF37C4BE)))
//             : SingleChildScrollView(
//                 padding: const EdgeInsets.all(20),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
                    
//                     // TOP ROW: Child Selector & Date Selector
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         // Child Dropdown - التنسيق الجديد
//                         Container(
//                           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
//                           decoration: BoxDecoration(
//                             color: const Color(0xFFE6F4F3), // لون خلفية أخضر فاتح متناسق
//                             borderRadius: BorderRadius.circular(16),
//                           ),
//                           child: DropdownButton<String>(
//                             value: selectedChild,
//                             underline: const SizedBox(),
//                             icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF2EA49E)),
//                             dropdownColor: Colors.white,
//                             borderRadius: BorderRadius.circular(16),
//                             items: childrenNames.map((name) {
//                               return DropdownMenuItem(
//                                 value: name,
//                                 child: Text(
//                                   name == "All" ? "All Children" : name, 
//                                   style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF2EA49E), fontSize: 14),
//                                 ),
//                               );
//                             }).toList(),
//                             onChanged: (val) {
//                               if (val != null) {
//                                 setState(() => selectedChild = val);
//                                 _fetchInsights();
//                               }
//                             },
//                           ),
//                         ),

//                         // Date Selector
//                         GestureDetector(
//                           onTap: _showMonthYearPicker,
//                           child: Container(
//                             padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
//                             decoration: BoxDecoration(
//                               color: Colors.white,
//                               borderRadius: BorderRadius.circular(14),
//                               border: Border.all(color: Colors.grey.shade300),
//                             ),
//                             child: Row(
//                               children: [
//                                 const Icon(Icons.calendar_today_rounded, size: 16, color: Colors.grey),
//                                 const SizedBox(width: 6),
//                                 Text(
//                                   "${monthNames[selectedMonth - 1]} $selectedYear",
//                                   style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2EA49E), fontSize: 13),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),

//                     const SizedBox(height: 30),

//                     Text(
//                       selectedChild == "All" ? "Comparison by Child" : "$selectedChild's Category Breakdown",
//                       style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textColor),
//                     ),
//                     const SizedBox(height: 10),
//                     Text(
//                       selectedChild == "All" 
//                           ? "See which child is spending the most." 
//                           : "Track where $selectedChild's money goes.",
//                       style: const TextStyle(fontSize: 14, color: Colors.grey),
//                     ),

//                     const SizedBox(height: 30),

//                     if (_chartData.isNotEmpty) ...[
//                       SizedBox(
//                         height: 250,
//                         child: Stack(
//                           alignment: Alignment.center,
//                           children: [
//                             PieChart(
//                               PieChartData(
//                                 sectionsSpace: 4, 
//                                 centerSpaceRadius: 60,
//                                 sections: _buildChartSections(),
//                               ),
//                             ),
//                             Column(
//                               mainAxisSize: MainAxisSize.min,
//                               children: [
//                                 Icon(selectedChild == "All" ? Icons.people_outline : Icons.category_outlined, size: 30, color: Colors.grey),
//                                 const SizedBox(height: 4),
//                                 // إضافة أيقونة الريال في إجمالي الصرف
//                                 Row(
//                                   mainAxisSize: MainAxisSize.min,
//                                   children: [
//                                     Image.asset('assets/icons/riyal.png', height: 14),
//                                     const SizedBox(width: 4),
//                                     Text(
//                                       _totalSpent.toStringAsFixed(0),
//                                       style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
//                                     ),
//                                   ],
//                                 ),
//                               ],
//                             )
//                           ],
//                         ),
//                       ),

//                       const SizedBox(height: 40),

//                       const Text(
//                         "Details",
//                         style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textColor),
//                       ),
//                       const SizedBox(height: 16),
                      
//                       ..._chartData.entries.map((entry) {
//                         final index = _chartData.keys.toList().indexOf(entry.key);
//                         final color = selectedChild == "All" ? _chartColors[index % _chartColors.length] : _getColorForCategory(entry.key);
//                         final percent = _totalSpent > 0 ? (entry.value / _totalSpent * 100).toStringAsFixed(1) : "0.0";

//                         return Container(
//                           margin: const EdgeInsets.only(bottom: 12),
//                           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//                           decoration: BoxDecoration(
//                             color: Colors.white,
//                             borderRadius: BorderRadius.circular(16),
//                             boxShadow: [
//                               BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3)),
//                             ],
//                           ),
//                           child: Row(
//                             children: [
//                               Container(
//                                 width: 40,
//                                 height: 40,
//                                 decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
//                                 child: Icon(selectedChild == "All" ? Icons.person : Icons.label_important_rounded, color: color, size: 20),
//                               ),
//                               const SizedBox(width: 16),
//                               Expanded(
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Text(
//                                       entry.key, 
//                                       style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
//                                     ),
//                                     Text(
//                                       "$percent% of total",
//                                       style: TextStyle(fontSize: 12, color: Colors.grey[600]),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                               // إضافة أيقونة الريال في تفاصيل الفئات
//                               Row(
//                                 mainAxisSize: MainAxisSize.min,
//                                 children: [
//                                   Image.asset('assets/icons/riyal.png', height: 16),
//                                   const SizedBox(width: 4),
//                                   Text(
//                                     entry.value.toStringAsFixed(0),
//                                     style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
//                                   ),
//                                 ],
//                               ),
//                             ],
//                           ),
//                         );
//                       }).toList(),
//                     ] else
//                       Center(
//                         child: Padding(
//                           padding: const EdgeInsets.only(top: 50),
//                           child: Column(
//                             children: [
//                               Icon(Icons.inbox_rounded, size: 60, color: Colors.grey.shade300),
//                               const SizedBox(height: 12),
//                               const Text(
//                                 "No spending data available for this date.",
//                                 style: TextStyle(color: Colors.grey, fontSize: 15),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//       ),
//     );
//   }

//   List<PieChartSectionData> _buildChartSections() {
//     int i = 0;
//     return _chartData.entries.map((entry) {
//       final isLarge = i == 0; 
//       final color = selectedChild == "All" ? _chartColors[i % _chartColors.length] : _getColorForCategory(entry.key);
//       final percentVal = _totalSpent > 0 ? (entry.value / _totalSpent * 100) : 0.0;
      
//       i++;
//       return PieChartSectionData(
//         color: color,
//         value: entry.value,
//         title: '${percentVal.toStringAsFixed(0)}%', 
//         radius: isLarge ? 55 : 50,
//         titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
//       );
//     }).toList();
//   }
// }
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

  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;
  String selectedChild = "All";
  String selectedPeriod = "Monthly"; 
  List<String> childrenNames = ["All"];

  final List<String> monthNames = [
    "Jan", "Feb", "Mar", "Apr", "May", "Jun", 
    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
  ];

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
    String p = selectedPeriod == 'Weekly' ? 'week' : selectedPeriod == 'Yearly' ? 'year' : 'month';
    final url = Uri.parse('${ApiConfig.baseUrl}/api/insights/parent-chart/${widget.parentId}?month=$selectedMonth&year=$selectedYear&childName=$selectedChild&period=$p');

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
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF37C4BE)),
                        items: List.generate(12, (index) => DropdownMenuItem(value: index + 1, child: Text(monthNames[index], style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2C3E50))))),
                        onChanged: (val) { if (val != null) setDialogState(() => tempMonth = val); },
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
                      items: List.generate(10, (index) {
                        int year = DateTime.now().year - 5 + index;
                        return DropdownMenuItem(value: year, child: Text(year.toString(), style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2C3E50))));
                      }),
                      onChanged: (val) { if (val != null) setDialogState(() => tempYear = val); },
                    ),
                  ),
                ],
              ),
              actionsAlignment: MainAxisAlignment.spaceEvenly,
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF37C4BE), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10)),
                  onPressed: () {
                    setState(() { selectedMonth = tempMonth; selectedYear = tempYear; });
                    _fetchInsights();
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

  Widget _buildPeriodToggle() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: const Color(0xFFF7FAFC), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: Row(
        children: ['Weekly', 'Monthly', 'Yearly'].map((p) {
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
                child: Center(child: Text(p, style: TextStyle(color: isSelected ? Colors.white : Colors.black54, fontWeight: FontWeight.bold, fontSize: 13))),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDateSelector() {
    if (selectedPeriod == 'Weekly') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(color: const Color(0xFFF7FAFC), borderRadius: BorderRadius.circular(14)),
        child: const Text("This Week", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2EA49E), fontSize: 13)),
      );
    }
    return GestureDetector(
      onTap: _showMonthYearPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade300)),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded, size: 16, color: Colors.grey),
            const SizedBox(width: 6),
            Text(
              selectedPeriod == 'Yearly' ? "$selectedYear" : "${monthNames[selectedMonth - 1]} $selectedYear",
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2EA49E), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const textColor = Color(0xFF2C3E50);

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        title: const Text("Spending Insights", style: TextStyle(fontWeight: FontWeight.w800, color: textColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: textColor), onPressed: () => Navigator.pop(context)),
      ),
      body: SafeArea(
        child: _loading 
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF37C4BE)))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPeriodToggle(),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFFE6F4F3), borderRadius: BorderRadius.circular(16)),
                          child: DropdownButton<String>(
                            value: selectedChild,
                            underline: const SizedBox(),
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF2EA49E)),
                            dropdownColor: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            items: childrenNames.map((name) => DropdownMenuItem(value: name, child: Text(name == "All" ? "All Children" : name, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF2EA49E), fontSize: 14)))).toList(),
                            onChanged: (val) {
                              if (val != null) { setState(() => selectedChild = val); _fetchInsights(); }
                            },
                          ),
                        ),
                        _buildDateSelector(),
                      ],
                    ),

                    const SizedBox(height: 30),
                    Text(selectedChild == "All" ? "Comparison by Child" : "$selectedChild's Category Breakdown", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textColor)),
                    const SizedBox(height: 10),
                    Text(selectedChild == "All" ? "See which child is spending the most." : "Track where $selectedChild's money goes.", style: const TextStyle(fontSize: 14, color: Colors.grey)),

                    const SizedBox(height: 30),

                    if (_chartData.isNotEmpty) ...[
                      SizedBox(
                        height: 250,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            PieChart(PieChartData(sectionsSpace: 4, centerSpaceRadius: 60, sections: _buildChartSections())),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(selectedChild == "All" ? Icons.people_outline : Icons.category_outlined, size: 30, color: Colors.grey),
                                const SizedBox(height: 2),
                                const Text("Total", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                                const SizedBox(height: 2),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Image.asset('assets/icons/riyal.png', height: 14),
                                    const SizedBox(width: 4),
                                    Text(_totalSpent.toStringAsFixed(0), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
                                  ],
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      const Text("Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textColor)),
                      const SizedBox(height: 16),
                      
                      ..._chartData.entries.map((entry) {
                        final index = _chartData.keys.toList().indexOf(entry.key);
                        final color = selectedChild == "All" ? _chartColors[index % _chartColors.length] : _getColorForCategory(entry.key);
                        final percent = _totalSpent > 0 ? (entry.value / _totalSpent * 100).toStringAsFixed(1) : "0.0";

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
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
                                    Text(entry.key, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                                    Text("$percent% of total", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
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
                          padding: const EdgeInsets.only(top: 50),
                          child: Column(
                            children: [
                              Icon(Icons.inbox_rounded, size: 60, color: Colors.grey.shade300),
                              const SizedBox(height: 12),
                              const Text("No spending data available for this date.", style: TextStyle(color: Colors.grey, fontSize: 15)),
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
}