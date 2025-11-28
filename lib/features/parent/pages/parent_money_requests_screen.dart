// 
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_app/utils/check_auth.dart';
import 'package:my_app/core/api_config.dart'; // Ensure correct import for baseUrl if needed, or use hardcoded if preferred.
import 'parent_transfer_screen.dart'; // Import transfer screen

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
  // Use config or hardcode as per your original file
  final String baseUrl = 'http://10.0.2.2:3000'; 

  @override
  void initState() {
    super.initState();
    _initializeFlow();
  }

  Future<void> _initializeFlow() async {
    // 1) Check expired
    await checkAuthStatus(context);

    // 2) Load token
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString("token") ?? widget.token;

    // 3) Token missing → logout
    if (token == null || token!.isEmpty) {
      _forceLogout();
      return;
    }

    // 4) Fetch requests
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
      final url = Uri.parse(
        '$baseUrl/api/money-requests/${widget.childId}',
      );

      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${token}",
        },
      );
      if (response.statusCode == 401) {
        _forceLogout();
        return;
      }

      if (response.statusCode == 200) {
        setState(() {
          _requests = jsonDecode(response.body);
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _updateRequestStatus(int requestId, String newStatus) async {
    final url = Uri.parse('$baseUrl/api/money-requests/update');

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${token}",
        },
        body: jsonEncode({"requestId": requestId, "status": newStatus}),
      );

      if (response.statusCode == 401) {
        _forceLogout();
        return;
      }

      if (response.statusCode == 200) {
        _fetchRequests();
      }
    } catch (_) {}
  }

  // --- Confirmation Dialog for Decline ---
  void _confirmDecline(int requestId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20), // زوايا دائرية ناعمة
        ),
        backgroundColor: Colors.white,
        title: const Text(
          "Decline Request?",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800, // خط عريض للعناوين
            color: Color(0xFF2C3E50), // لون النص الغامق الموحد
          ),
        ),
        content: const Text(
          "Are you sure you want to decline this request?",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: Colors.black54, // لون رمادي للنص الفرعي
            height: 1.4,
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        actionsAlignment: MainAxisAlignment.center, // توسيط الأزرار
        actions: [
          // زر الإلغاء (بسيط)
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey,
            ),
            child: const Text(
              "Cancel",
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ),
          const SizedBox(width: 10),
          // زر الرفض (مميز بلون أحمر)
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx); // إغلاق النافذة
              _updateRequestStatus(requestId, "Declined"); // تنفيذ الرفض
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent, // خلفية حمراء للتحذير
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
          ),
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
        backgroundColor: Colors.white, // Keep your style
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
                          const CircleAvatar(
                            radius: 26,
                            backgroundImage: AssetImage(
                              'assets/images/child_avatar.png',
                            ),
                          ),
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

                      // Status Handling
                      if (req["requestStatus"] == "Pending")
                        Row(
                          children: [
                            // 1. Decline Button (with Confirmation)
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  _confirmDecline(req['requestId']);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text("Decline Request"),
                              ),
                            ),
                            const SizedBox(width: 12),
                            
                            // 2. Approve Button (Go to Transfer Screen)
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  // Navigate to Transfer Screen with pre-filled data
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ParentTransferScreen(
                                        parentId: widget.parentId,
                                        childId: widget.childId,
                                        childName: req["childName"] ?? "Child",
                                        childBalance: "0.00", // Fetch real balance if needed
                                        token: token!,
                                        // Pass request details
                                        initialAmount: double.tryParse(req["amount"].toString()),
                                        requestId: req["requestId"],
                                      ),
                                    ),
                                  );

                                  // Refresh list if transfer was successful
                                  if (result == true) {
                                    _fetchRequests();
                                  }
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
                                child: const Text("Approve Request"),
                              ),
                            ),
                          ],
                        ),

                      if (req["requestStatus"] == "Declined")
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Text(
                              "Declined",
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                      if (req["requestStatus"] == "Approved")
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Text(
                              "Paid",
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
