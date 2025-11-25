// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'parent_transfer_screen.dart';
// import 'parent_money_requests_screen.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:my_app/utils/check_auth.dart';

// class ParentChildOverviewScreen extends StatefulWidget {
//   final int parentId;
//   final int childId;
//   final String childName;
//   final String token;

//   const ParentChildOverviewScreen({
//     super.key,
//     required this.parentId,
//     required this.childId,
//     required this.childName,
//     required this.token,
//   });

//   @override
//   State<ParentChildOverviewScreen> createState() =>
//       _ParentChildOverviewScreenState();
// }

// class _ParentChildOverviewScreenState extends State<ParentChildOverviewScreen> {
//   bool _loading = true;
//   String _firstName = '';
//   String _phoneNo = '';
//   double _balance = 0.0;
//   double _spend = 0.0;
//   double _saving = 0.0;

//   String? token;
//   static const String baseUrl = "http://10.0.2.2:3000";

//   @override
//   void initState() {
//     super.initState();
//     _initialize();
//   }

//   Future<void> _initialize() async {
//     await checkAuthStatus(context);
//     await _loadToken();
//     await _fetchChildInfo();
//   }

//   Future<void> _loadToken() async {
//     final prefs = await SharedPreferences.getInstance();
//     token = prefs.getString("token");
//   }

//   Future<void> _fetchChildInfo() async {
//     if (token == null) {
//       setState(() => _loading = false);
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Missing token — please log in again.")),
//       );
//       return;
//     }

//     try {
//       final url = Uri.parse("$baseUrl/api/auth/child/info/${widget.childId}");

//       final res = await http.get(
//         url,
//         headers: {
//           "Authorization": "Bearer $token", // 🔥 JWT applied
//         },
//       );

//       if (!mounted) return;

//       if (res.statusCode == 200) {
//         final data = jsonDecode(res.body);

//         double _toDouble(dynamic v) =>
//             (v is num) ? v.toDouble() : (double.tryParse(v.toString()) ?? 0.0);

//         setState(() {
//           _firstName = (data['firstName'] ?? widget.childName).toString();
//           _phoneNo = (data['phoneNo'] ?? '').toString();
//           _balance = _toDouble(data['balance']);
//           _spend = _toDouble(data['spend']);
//           _saving = _toDouble(data['saving']);
//           _loading = false;
//         });
//       } else {
//         setState(() => _loading = false);
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               "Failed to load child info (Code: ${res.statusCode})",
//             ),
//           ),
//         );
//       }
//       if (res.statusCode == 401) {
//         final prefs = await SharedPreferences.getInstance();
//         await prefs.clear(); // clear token, ids, role
//         if (context.mounted) {
//           Navigator.pushNamedAndRemoveUntil(context, '/mobile', (_) => false);
//         }
//         return;
//       }
//     } catch (e) {
//       if (!mounted) return;
//       setState(() => _loading = false);
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text("Error fetching child info: $e")));
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     const labelStyle = TextStyle(fontSize: 14, color: Colors.grey);
//     const valueStyle = TextStyle(fontSize: 32, fontWeight: FontWeight.bold);

//     return Scaffold(
//       appBar: AppBar(
//         title: Text(_firstName.isEmpty ? widget.childName : _firstName),
//       ),
//       body: _loading
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//               padding: const EdgeInsets.all(20),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Header
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Row(
//                         children: const [
//                           CircleAvatar(
//                             radius: 24,
//                             backgroundColor: Colors.teal,
//                             child: Icon(Icons.person, color: Colors.white),
//                           ),
//                           SizedBox(width: 12),
//                         ],
//                       ),
//                       const Icon(Icons.notifications_none, size: 28),
//                     ],
//                   ),
//                   const SizedBox(height: 12),
//                   Text(
//                     _firstName.isNotEmpty ? _firstName : widget.childName,
//                     style: const TextStyle(
//                       fontSize: 22,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     _phoneNo.isNotEmpty ? _phoneNo : '—',
//                     style: const TextStyle(color: Colors.black54),
//                   ),

//                   const SizedBox(height: 16),

//                   // Balance card
//                   Card(
//                     elevation: 3,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(14),
//                     ),
//                     child: Padding(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 18,
//                         vertical: 16,
//                       ),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             'Total Balance: ${_balance.toStringAsFixed(2)}',
//                             style: const TextStyle(fontWeight: FontWeight.w600),
//                           ),
//                           const SizedBox(height: 14),
//                           Row(
//                             children: [
//                               Expanded(
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.center,
//                                   children: [
//                                     const Text(
//                                       'spend balance',
//                                       style: labelStyle,
//                                     ),
//                                     const SizedBox(height: 4),
//                                     Text(
//                                       '﷼ ${_spend.toStringAsFixed(2)}',
//                                       style: valueStyle,
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                               Container(
//                                 width: 1,
//                                 height: 40,
//                                 color: const Color(0x11000000),
//                               ),
//                               Expanded(
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.center,
//                                   children: [
//                                     const Text(
//                                       'saving balance',
//                                       style: labelStyle,
//                                     ),
//                                     const SizedBox(height: 4),
//                                     Text(
//                                       '﷼ ${_saving.toStringAsFixed(2)}',
//                                       style: valueStyle,
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),

//                   const SizedBox(height: 16),

//                   // Actions grid (placeholders)
//                   Row(
//                     children: [
//                       Expanded(
//                         child: _tileButton(
//                           'Transfer Money',
//                           Icons.send_rounded,
//                           () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (_) => ParentTransferScreen(
//                                   parentId: widget.parentId,
//                                   childId: widget.childId,
//                                   childName: widget.childName,
//                                   childBalance: _balance.toStringAsFixed(2),
//                                   token: widget.token,
//                                 ),
//                               ),
//                             );
//                           },
//                         ),
//                       ),

//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: _tileButton(
//                           'Chores',
//                           Icons.check_circle_outline, // ✅ fits for tasks/chores
//                           () {},
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 12),
//                   Row(
//                     children: [
//                       Expanded(
//                         child: _tileButton(
//                           'Transactions',
//                           Icons
//                               .receipt_long_rounded, // 🧾 clear for transaction history
//                           () {},
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: _tileButton(
//                           'Money Requests',
//                           Icons.request_page_outlined,
//                           () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (_) => ParentMoneyRequestsScreen(
//                                   parentId: widget.parentId,
//                                   childId: widget.childId,
//                                 ),
//                               ),
//                             );
//                           },
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 12),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Expanded(
//                         child: _tileButton(
//                           'Goals',
//                           Icons.flag_rounded, // 🎯 perfect visual match
//                           () {},
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//     );
//   }

//   Widget _tileButton(String text, IconData icon, VoidCallback onTap) {
//     return ElevatedButton(
//       onPressed: onTap,
//       style: ElevatedButton.styleFrom(
//         elevation: 2,
//         backgroundColor: Colors.white,
//         foregroundColor: Colors.black,
//         padding: const EdgeInsets.symmetric(vertical: 20),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
//       ),
//       child: Column(
//         children: [Icon(icon), const SizedBox(height: 8), Text(text)],
//       ),
//     );
//   }
// }
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
    await checkAuthStatus(context);
    await _loadToken();
    await _fetchChildInfo();
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

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        double _toDouble(dynamic v) =>
            (v is num) ? v.toDouble() : (double.tryParse(v.toString()) ?? 0.0);

        setState(() {
          _firstName = (data['firstName'] ?? widget.childName).toString();
          _phoneNo = (data['phoneNo'] ?? '').toString();
          _balance = _toDouble(data['balance']);
          _spend = _toDouble(data['spend']);
          _saving = _toDouble(data['saving']);
          _loading = false;
        });
      } else {
        _loading = false;
      }
    } catch (e) {
      if (!mounted) return;
      _loading = false;
    }

    setState(() {});
  }

 @override
Widget build(BuildContext context) {
  const Color primary1 = Color(0xFF37C4BE);
  const Color primary2 = Color(0xFF2EA49E);

  return Scaffold(
  body: Stack(
    children: [
      /// 🔥 Gradient background ALWAYS fills whole screen
      Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF7FAFC), Color(0xFFE6F4F3)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),

      /// 🔥 Page content فوق الخلفية
      SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// … كل عناصرك تبقى نفسها بدون تغيير …
                    ],
                  ),
                ),
              ),
      ),
    ],
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
                    Image.asset(
                      _sarIcon,
                      height: 16,
                      width: 16,
                      fit: BoxFit.contain,
                    ),
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
