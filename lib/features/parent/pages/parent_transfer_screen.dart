// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:my_app/utils/check_auth.dart';
// import 'package:my_app/core/api_config.dart';

// class ParentTransferScreen extends StatefulWidget {
//   final int parentId;
//   final int childId;
//   final String childName;
//   final String childBalance;
//   final String token;

//   // New Optional Parameters for Request Handling
//   final double? initialAmount;
//   final int? requestId;

//   const ParentTransferScreen({
//     super.key,
//     required this.parentId,
//     required this.childId,
//     required this.childName,
//     required this.childBalance,
//     required this.token,
//     this.initialAmount,
//     this.requestId,
//   });

//   @override
//   State<ParentTransferScreen> createState() => _ParentTransferScreenState();
// }

// class _ParentTransferScreenState extends State<ParentTransferScreen> {
//   final TextEditingController _amount = TextEditingController();
//   double savingPercentage = 50; // default 50/50 split for normal transfer
//   String? token;
//   late final String baseUrl = ApiConfig.baseUrl;

//   @override
//   void initState() {
//     super.initState();
//     _initialize();

//     // Check if coming from a Request
//     if (widget.initialAmount != null) {
//       _amount.text = widget.initialAmount.toString();
//       savingPercentage = 0; // Set to 0% Save (100% Spend) for requests
//     }
//   }

//   Future<void> _initialize() async {
//     await checkAuthStatus(context);
//     await _loadToken();
//   }

//   Future<void> _loadToken() async {
//     final prefs = await SharedPreferences.getInstance();
//     token = prefs.getString("token") ?? widget.token;
//   }

//   Future<bool> _handleExpired(int statusCode) async {
//     if (statusCode == 401) {
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.clear();

//       if (!mounted) return true;
//       Navigator.pushNamedAndRemoveUntil(context, '/mobile', (_) => false);
//       return true;
//     }
//     return false;
//   }

//   Future<void> _transfer() async {
//     if (_amount.text.trim().isEmpty || double.tryParse(_amount.text) == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Please enter a valid amount")),
//       );
//       return;
//     }

//     final url = Uri.parse('$baseUrl/api/auth/transfer');
//     final amount = double.parse(_amount.text);

//     print(
//       "Sending transfer request: parent=${widget.parentId}, child=${widget.childId}, amount=$amount",
//     );

//     try {
//       final response = await http.post(
//         url,
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer ${widget.token}', // ✅ JWT header
//         },
//         body: jsonEncode({
//           'parentId': widget.parentId,
//           'childId': widget.childId,
//           'amount': amount,
//           'savePercentage': savingPercentage,
//         }),
//       );

//       print("Response (${response.statusCode}): ${response.body}");

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);

//         final double save = (data['saveAmount'] as num).toDouble();
//         final double spend = (data['spendAmount'] as num).toDouble();

//         // ✅ If this was a request, mark it as Approved
//         if (widget.requestId != null) {
//           await _markRequestAsApproved(widget.requestId!);
//         }

//         _showSuccess(save, spend);
//       } else {
//         final error = jsonDecode(response.body);
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text(error['error'] ?? 'Transfer failed')),
//         );
//       }
//       if (response.statusCode == 401) {
//         final prefs = await SharedPreferences.getInstance();
//         await prefs.clear();
//         if (context.mounted) {
//           Navigator.pushNamedAndRemoveUntil(context, '/mobile', (_) => false);
//         }
//         return;
//       }
//     } catch (e) {
//       print("Transfer error: $e");
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text("Network error: $e")));
//     }
//   }

//   // ✅ New helper to update request status
//   Future<void> _markRequestAsApproved(int reqId) async {
//     try {
//       final url = Uri.parse('$baseUrl/api/money-requests/update');
//       await http.post(
//         url,
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer ${widget.token}',
//         },
//         body: jsonEncode({
//           "requestId": reqId,
//           "status": "Approved"
//         }),
//       );
//     } catch (e) {
//       print("Error auto-approving request: $e");
//     }
//   }

//   void _showSuccess(double save, double spend) {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (_) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Icon(Icons.check_circle, color: Colors.green, size: 60),
//             const SizedBox(height: 10),
//             const Text(
//               "Transfer Successful!",
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               "Saving: ${save.toStringAsFixed(2)} SAR\nSpending: ${spend.toStringAsFixed(2)} SAR",
//               textAlign: TextAlign.center,
//               style: const TextStyle(color: Colors.black54, fontSize: 14),
//             ),
//           ],
//         ),
//       ),
//     );

//     Future.delayed(const Duration(seconds: 2), () {
//       if (mounted) {
//         Navigator.pop(context); // Close Dialog
//         Navigator.pop(context, true); // Return 'true' to refresh prev screen
//       }
//     });
//   }

//   Widget _infoCard({
//     required IconData icon,
//     required String title,
//     required String subtitle,
//     required Color color,
//   }) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 10),
//       padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(14),
//         boxShadow: const [
//           BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
//         ],
//       ),
//       child: Row(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(10),
//             decoration: BoxDecoration(
//               color: color.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: Icon(icon, color: color, size: 32),
//           ),
//           const SizedBox(width: 14),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   title,
//                   style: const TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w700,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(subtitle, style: const TextStyle(color: Colors.grey)),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     // const Color primary = Color(0xFF1ABC9C); // Unused but kept if needed

//     return Scaffold(
//       backgroundColor: const Color(0xFFF8F9FB),
//       appBar: AppBar(
//         title: const Text(
//           "Transfer",
//           style: TextStyle(fontWeight: FontWeight.w600),
//         ),
//         backgroundColor: Colors.white,
//         centerTitle: true,
//         elevation: 0.5,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.black87),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           children: [
//             // ✅ Restored Info Cards
//             _infoCard(
//               icon: Icons.groups_2_rounded,
//               title: "From Parent",
//               subtitle: "Balance: 200.00 SAR", // TODO: fetch from API
//               color: Colors.teal,
//             ),
//             _infoCard(
//               icon: Icons.person_rounded,
//               title: "To ${widget.childName}",
//               subtitle: "Balance: ${widget.childBalance} SAR",
//               color: Colors.amber,
//             ),
//             const SizedBox(height: 30),

//             // Amount Input
//             Container(
//               padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(14),
//                 boxShadow: const [
//                   BoxShadow(
//                     color: Colors.black12,
//                     blurRadius: 6,
//                     offset: Offset(0, 3),
//                   ),
//                 ],
//               ),
//               child: TextField(
//                 controller: _amount,
//                 keyboardType: const TextInputType.numberWithOptions(
//                   decimal: true,
//                 ),
//                 textAlign: TextAlign.center,
//                 style: const TextStyle(
//                   fontSize: 32,
//                   fontWeight: FontWeight.bold,
//                   letterSpacing: 1,
//                 ),
//                 decoration: const InputDecoration(
//                   hintText: "00.00 SAR",
//                   border: InputBorder.none,
//                 ),
//               ),
//             ),
//             const SizedBox(height: 25),

//             // Save/Spend Split Slider
//             Container(
//               padding: const EdgeInsets.all(18),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(14),
//                 boxShadow: const [
//                   BoxShadow(color: Colors.black12, blurRadius: 6),
//                 ],
//               ),
//               child: Column(
//                 children: [
//                   const Text(
//                     "Split Between Saving and Spending",
//                     style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//                   ),
//                   const SizedBox(height: 15),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         "Save: ${savingPercentage.toStringAsFixed(0)}%",
//                         style: const TextStyle(
//                           color: Colors.teal,
//                           fontSize: 15,
//                         ),
//                       ),
//                       Text(
//                         "Spend: ${(100 - savingPercentage).toStringAsFixed(0)}%",
//                         style: const TextStyle(
//                           color: Colors.amber,
//                           fontSize: 15,
//                         ),
//                       ),
//                     ],
//                   ),
//                   Slider(
//                     value: savingPercentage,
//                     min: 0,
//                     max: 100,
//                     divisions: 20,
//                     activeColor: const Color(0xFF2EA49E),
//                     inactiveColor: Colors.amber.shade200,
//                     onChanged: (value) {
//                       setState(() {
//                         savingPercentage = value;
//                       });
//                     },
//                   ),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 30),

//             // Continue Button
//             SizedBox(
//               width: double.infinity,
//               height: 55,
//               child: ElevatedButton(
//                 onPressed: _transfer,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFF2EA49E),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(14),
//                   ),
//                   elevation: 3,
//                 ),
//                 child: const Text(
//                   "Continue",
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.w700,
//                     color: Colors.white,
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_app/utils/check_auth.dart';
import 'package:my_app/core/api_config.dart';

class ParentTransferScreen extends StatefulWidget {
  final int parentId;
  final int childId;
  final String childName;
  final String childBalance;
  final String token;

  // New Optional Parameters for Request Handling
  final double? initialAmount;
  final int? requestId;

  const ParentTransferScreen({
    super.key,
    required this.parentId,
    required this.childId,
    required this.childName,
    required this.childBalance,
    required this.token,
    this.initialAmount,
    this.requestId,
  });

  @override
  State<ParentTransferScreen> createState() => _ParentTransferScreenState();
}

class _ParentTransferScreenState extends State<ParentTransferScreen> {
  final TextEditingController _amount = TextEditingController();
  double savingPercentage = 50; // default 50/50 split for normal transfer
  String? token;
  late final String baseUrl = ApiConfig.baseUrl;

  // ✅ New variable to store real balance
  String parentCurrentBalance = "...";

  @override
  void initState() {
    super.initState();
    _initialize();

    // Check if coming from a Request
    if (widget.initialAmount != null) {
      _amount.text = widget.initialAmount.toString();
      savingPercentage = 0; // Set to 0% Save (100% Spend) for requests
    }
  }

  Future<void> _initialize() async {
    await checkAuthStatus(context);
    await _loadToken();
    await _fetchParentBalance(); // ✅ Fetch balance on start
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString("token") ?? widget.token;
  }

  // ✅ New function to get parent balance
  Future<void> _fetchParentBalance() async {
    try {
      final url = Uri.parse('$baseUrl/api/parent/${widget.parentId}');
      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer ${widget.token}",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Check different possible key names for balance
        final b = data['walletbalance'] ?? data['balance'] ?? 0;
        final double val = (b is num)
            ? b.toDouble()
            : double.tryParse(b.toString()) ?? 0.0;

        if (mounted) {
          setState(() {
            parentCurrentBalance = val.toStringAsFixed(2);
          });
        }
      }
    } catch (e) {
      print("Error fetching parent balance: $e");
    }
  }

  Future<void> _transfer() async {
    if (_amount.text.trim().isEmpty || double.tryParse(_amount.text) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid amount")),
      );
      return;
    }

    final url = Uri.parse('$baseUrl/api/auth/transfer');
    final amount = double.parse(_amount.text);

    print(
      "Sending transfer request: parent=${widget.parentId}, child=${widget.childId}, amount=$amount",
    );

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}', // ✅ JWT header
        },
        body: jsonEncode({
          'parentId': widget.parentId,
          'childId': widget.childId,
          'amount': amount,
          'savePercentage': savingPercentage,
        }),
      );

      print("Response (${response.statusCode}): ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final double save = (data['saveAmount'] as num).toDouble();
        final double spend = (data['spendAmount'] as num).toDouble();

        // ✅ If this was a request, mark it as Approved
        if (widget.requestId != null) {
          await _markRequestAsApproved(widget.requestId!);
        }

        _showSuccess(save, spend);
      } else {
        final error = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error['error'] ?? 'Transfer failed')),
        );
      }
      if (response.statusCode == 401) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        if (context.mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/mobile', (_) => false);
        }
        return;
      }
    } catch (e) {
      print("Transfer error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Network error: $e")));
    }
  }

  // ✅ New helper to update request status
  Future<void> _markRequestAsApproved(int reqId) async {
    try {
      final url = Uri.parse('$baseUrl/api/money-requests/update');
      await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({"requestId": reqId, "status": "Approved"}),
      );
    } catch (e) {
      print("Error auto-approving request: $e");
    }
  }

  void _showSuccess(double save, double spend) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 60),
            const SizedBox(height: 10),
            const Text(
              "Transfer Successful!",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Saving: ${save.toStringAsFixed(2)} SAR\nSpending: ${spend.toStringAsFixed(2)} SAR",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54, fontSize: 14),
            ),
          ],
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pop(context); // Close Dialog
        Navigator.pop(context, true); // Return 'true' to refresh prev screen
      }
    });
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text(
          "Transfer",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ✅ Info Cards with Real Data
            _infoCard(
              icon: Icons.groups_2_rounded,
              title: "From Parent",
              subtitle: "Balance: $parentCurrentBalance SAR", // ✅ Real Balance
              color: Colors.teal,
            ),
            _infoCard(
              icon: Icons.person_rounded,
              title: "To ${widget.childName}",
              subtitle: "Balance: ${widget.childBalance} SAR",
              color: Colors.amber,
            ),
            const SizedBox(height: 30),

            // Amount Input
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
                decoration: const InputDecoration(
                  hintText: "00.00 SAR",
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 25),

            // Save/Spend Split Slider
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 6),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    "Split Between Saving and Spending",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Save: ${savingPercentage.toStringAsFixed(0)}%",
                        style: const TextStyle(
                          color: Colors.teal,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        "Spend: ${(100 - savingPercentage).toStringAsFixed(0)}%",
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: savingPercentage,
                    min: 0,
                    max: 100,
                    divisions: 20,
                    activeColor: const Color(0xFF2EA49E),
                    inactiveColor: Colors.amber.shade200,
                    onChanged: (value) {
                      setState(() {
                        savingPercentage = value;
                      });
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Continue Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _transfer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2EA49E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 3,
                ),
                child: const Text(
                  "Continue",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
