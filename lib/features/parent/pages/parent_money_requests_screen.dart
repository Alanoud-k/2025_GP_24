// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:my_app/utils/check_auth.dart';
// import 'package:my_app/core/api_config.dart';
// import 'parent_transfer_screen.dart';

// class ParentMoneyRequestsScreen extends StatefulWidget {
//   final int parentId;
//   final int childId;
//   final String? token;

//   const ParentMoneyRequestsScreen({
//     super.key,
//     required this.parentId,
//     required this.childId,
//     this.token,
//   });

//   @override
//   State<ParentMoneyRequestsScreen> createState() =>
//       _ParentMoneyRequestsScreenState();
// }

// class _ParentMoneyRequestsScreenState extends State<ParentMoneyRequestsScreen> {
//   bool _loading = true;
//   List<dynamic> _requests = [];
//   String? token;

//   final String baseUrl = ApiConfig.baseUrl;

//   @override
//   void initState() {
//     super.initState();
//     _initializeFlow();
//   }

//   Future<void> _initializeFlow() async {
//     await checkAuthStatus(context);

//     final prefs = await SharedPreferences.getInstance();
//     token = prefs.getString("token") ?? widget.token;

//     if (token == null || token!.isEmpty) {
//       _forceLogout();
//       return;
//     }

//     await _fetchRequests();
//   }

//   void _forceLogout() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.clear();

//     if (mounted) {
//       Navigator.pushNamedAndRemoveUntil(context, '/mobile', (_) => false);
//     }
//   }

//   Future<void> _fetchRequests() async {
//     try {
//       final url = Uri.parse('$baseUrl/api/money-requests/${widget.childId}');

//       final response = await http.get(
//         url,
//         headers: {
//           "Authorization": "Bearer $token",
//           "Content-Type": "application/json",
//         },
//       );

//       if (response.statusCode == 401) {
//         _forceLogout();
//         return;
//       }

//       if (response.statusCode == 200) {
//         setState(() {
//           _requests = jsonDecode(response.body);
//           _loading = false;
//         });
//       } else {
//         setState(() => _loading = false);
//       }
//     } catch (e) {
//       setState(() => _loading = false);
//     }
//   }

//   Future<void> _updateRequestStatus(int requestId, String newStatus) async {
//     final url = Uri.parse('$baseUrl/api/money-requests/update');

//     try {
//       final response = await http.post(
//         url,
//         headers: {
//           "Authorization": "Bearer $token",
//           "Content-Type": "application/json",
//         },
//         body: jsonEncode({"requestId": requestId, "status": newStatus}),
//       );

//       if (response.statusCode == 200) {
//         _fetchRequests();
//       }
//     } catch (_) {}
//   }

//   // ------------------------------------------------------------
//   // Confirmation dialog for decline
//   // ------------------------------------------------------------
//   void _confirmDecline(int requestId) {
//     showDialog(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         title: const Text(
//           "Decline Request?",
//           textAlign: TextAlign.center,
//           style: TextStyle(
//             fontSize: 19,
//             fontWeight: FontWeight.w700,
//             color: Color(0xFF2C3E50),
//           ),
//         ),
//         content: const Text(
//           "Are you sure you want to decline this request?",
//           textAlign: TextAlign.center,
//           style: TextStyle(fontSize: 15, color: Colors.black54),
//         ),
//         actionsAlignment: MainAxisAlignment.center,
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(ctx),
//             child: const Text(
//               "Cancel",
//               style: TextStyle(color: Colors.black54),
//             ),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               Navigator.pop(ctx);
//               _updateRequestStatus(requestId, "Declined");
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.redAccent,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(10),
//               ),
//             ),
//             child: const Text("Decline"),
//           ),
//         ],
//       ),
//     );
//   }

//   // ------------------------------------------------------------
//   // UI
//   // ------------------------------------------------------------
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           "Money Requests",
//           style: TextStyle(fontWeight: FontWeight.w700),
//         ),
//         backgroundColor: Colors.white,
//         foregroundColor: Colors.black87,
//         elevation: 0,
//       ),
//       backgroundColor: const Color(0xFFF7F8FA),

//       body: _loading
//           ? const Center(child: CircularProgressIndicator())
//           : _requests.isEmpty
//           ? const Center(
//               child: Text(
//                 "No requests yet",
//                 style: TextStyle(fontSize: 16, color: Colors.black54),
//               ),
//             )
//           : ListView.builder(
//               padding: const EdgeInsets.all(16),
//               itemCount: _requests.length,
//               itemBuilder: (_, i) {
//                 final req = _requests[i];

//                 return Container(
//                   margin: const EdgeInsets.only(bottom: 14),
//                   padding: const EdgeInsets.all(14),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(18),
//                     boxShadow: [
//                       BoxShadow(
//                         blurRadius: 6,
//                         color: Colors.black12.withOpacity(0.08),
//                       ),
//                     ],
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // Amount row
//                       Row(
//                         children: [
//                           const CircleAvatar(
//                             radius: 24,
//                             backgroundImage: AssetImage(
//                               'assets/images/child_avatar.png',
//                             ),
//                           ),
//                           const SizedBox(width: 12),
//                           Expanded(
//                             child: Text(
//                               "﷼ ${req["amount"]}",
//                               style: const TextStyle(
//                                 fontSize: 22,
//                                 fontWeight: FontWeight.w800,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),

//                       const SizedBox(height: 8),

//                       Text(
//                         req["requestDescription"] ?? "No message",
//                         style: const TextStyle(
//                           fontSize: 14,
//                           color: Colors.black54,
//                         ),
//                       ),

//                       const SizedBox(height: 14),

//                       if (req["requestStatus"] == "Pending")
//                         Row(
//                           children: [
//                             Expanded(
//                               child: OutlinedButton(
//                                 onPressed: () =>
//                                     _confirmDecline(req["requestId"]),
//                                 style: OutlinedButton.styleFrom(
//                                   foregroundColor: Colors.red,
//                                   side: const BorderSide(color: Colors.red),
//                                   padding: const EdgeInsets.symmetric(
//                                     vertical: 12,
//                                   ),
//                                   shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(10),
//                                   ),
//                                 ),
//                                 child: const Text("Decline"),
//                               ),
//                             ),
//                             const SizedBox(width: 12),
//                             Expanded(
//                               child: ElevatedButton(
//                                 onPressed: () async {
//                                   final result = await Navigator.push(
//                                     context,
//                                     MaterialPageRoute(
//                                       builder: (_) => ParentTransferScreen(
//                                         parentId: widget.parentId,
//                                         childId: widget.childId,
//                                         childName: req["childName"] ?? "Child",
//                                         childBalance: "0.00",
//                                         token: token!,
//                                         requestId: req["requestId"],
//                                         initialAmount: double.tryParse(
//                                           req["amount"].toString(),
//                                         ),
//                                       ),
//                                     ),
//                                   );
//                                   if (result == true) _fetchRequests();
//                                 },
//                                 style: ElevatedButton.styleFrom(
//                                   backgroundColor: Colors.green,
//                                   padding: const EdgeInsets.symmetric(
//                                     vertical: 12,
//                                   ),
//                                   shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(10),
//                                   ),
//                                 ),
//                                 child: const Text("Approve"),
//                               ),
//                             ),
//                           ],
//                         ),

//                       if (req["requestStatus"] == "Declined")
//                         _statusBadge("Declined", Colors.red),

//                       if (req["requestStatus"] == "Approved")
//                         _statusBadge("Paid", Colors.green),
//                     ],
//                   ),
//                 );
//               },
//             ),
//     );
//   }

//   Widget _statusBadge(String text, Color color) {
//     return Container(
//       padding: const EdgeInsets.symmetric(vertical: 10),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.15),
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: Center(
//         child: Text(
//           text,
//           style: TextStyle(color: color, fontWeight: FontWeight.w700),
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
import 'parent_transfer_screen.dart';

class ParentMoneyRequestsScreen extends StatefulWidget {
  final int parentId;
  final int childId;
  final String? token;

  const ParentMoneyRequestsScreen({
    super.key,
    required this.parentId,
    required this.childId,
    this.token,
  });

  @override
  State<ParentMoneyRequestsScreen> createState() =>
      _ParentMoneyRequestsScreenState();
}

class _ParentMoneyRequestsScreenState extends State<ParentMoneyRequestsScreen> {
  bool _loading = true;
  List<dynamic> _requests = [];
  String? token;
  final String baseUrl = ApiConfig.baseUrl;

  @override
  void initState() {
    super.initState();
    _initializeFlow();
  }

  Future<void> _initializeFlow() async {
    await checkAuthStatus(context);
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString("token") ?? widget.token;

    if (token == null || token!.isEmpty) {
      _forceLogout();
      return;
    }
    await _fetchRequests();
  }

  void _forceLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/mobile', (_) => false);
    }
  }

  Future<void> _fetchRequests() async {
    try {
      final url = Uri.parse('$baseUrl/api/money-requests/${widget.childId}');
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 401) {
        _forceLogout();
        return;
      }

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _requests = jsonDecode(response.body);
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

  Future<void> _updateRequestStatus(int requestId, String newStatus) async {
    final url = Uri.parse('$baseUrl/api/money-requests/update');

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"requestId": requestId, "status": newStatus}),
      );

      if (response.statusCode == 401) {
        _forceLogout();
        return;
      }
      if (response.statusCode == 200) {
        await _fetchRequests(); // ✅ ننتظر تحديث القائمة
      } else {
        // في حال الفشل من السيرفر نوقف اللودينج
        if (mounted) setState(() => _loading = false);
      }

    } catch (_) {
      // في حال خطأ الشبكة نوقف اللودينج
      if (mounted) setState(() => _loading = false);
    }
  }

  // --- Confirmation Dialog (Updated Logic) ---
  void _confirmDecline(int requestId) {
    showDialog(
      context: context,
      barrierDismissible: false, // يمنع الإغلاق بالضغط في الخارج أثناء التحميل
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: const Text(
          "Decline Request?",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF2C3E50),
          ),
        ),
        content: const Text(
          "Are you sure you want to decline this request?",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: Colors.black54, height: 1.4),
        ),
        actionsPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 15,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(foregroundColor: Colors.grey),
            child: const Text(
              "Cancel",
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ),
          const SizedBox(width: 10),

          // ✅ الزر المعدل (Async + Await)
       ElevatedButton(
  onPressed: () async {
    Navigator.pop(ctx); // ← أهم شيء

    if (mounted) {
      setState(() => _loading = true);
    }

    await _updateRequestStatus(requestId, "Declined");

    if (mounted) {
      setState(() => _loading = false);
    }
  },
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.redAccent,
    foregroundColor: Colors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
  ),
  child: const Text(
    "Decline",
    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
  ),
)

        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Money request"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      backgroundColor: const Color(0xffF7F8FA),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
          ? const Center(
              child: Text("No requests found", style: TextStyle(fontSize: 16)),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _requests.length,
              itemBuilder: (context, i) {
                final req = _requests[i];

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 4,
                        color: Colors.black12.withOpacity(0.05),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // const CircleAvatar(
                          //   radius: 26,
                          //   backgroundImage: AssetImage(
                          //     'assets/images/child_avatar.png',
                          //   ),
                          // ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "﷼ ${req['amount']}",
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        req["requestDescription"]?.toString() ?? "No message",
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (req["requestStatus"] == "Pending")
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () =>
                                    _confirmDecline(req["requestId"]),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text("Decline"),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ParentTransferScreen(
                                        parentId: widget.parentId,
                                        childId: widget.childId,
                                        childName: req["childName"] ?? "Child",
                                        childBalance: "0.00",
                                        token: token!,
                                        requestId: req["requestId"],
                                        initialAmount: double.tryParse(
                                          req["amount"].toString(),
                                        ),
                                      ),
                                    ),
                                  );
                                  if (result == true) _fetchRequests();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text("Approve"),
                              ),
                            ),
                          ],
                        ),

                      if (req["requestStatus"] == "Declined")
                        _statusBadge("Declined", Colors.red),

                      if (req["requestStatus"] == "Approved")
                        _statusBadge("Paid", Colors.green),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _statusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(color: color, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
