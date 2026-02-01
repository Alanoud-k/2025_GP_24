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

  Future<void> _forceLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/mobile', (_) => false);
    }
  }

  Widget _sarIcon({double size = 16, Color? color}) {
    return Image.asset(
      'assets/icons/Sar.png',
      width: size,
      height: size,
      color: color,
    );
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

      if (mounted) {
        setState(() {
          _requests = response.statusCode == 200
              ? jsonDecode(response.body)
              : <dynamic>[];
          _loading = false;
        });
      }
    } catch (_) {
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
        await _fetchRequests();
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // --- Confirmation Dialog ---
  void _confirmDecline(int requestId) {
    const kTextDark = Color(0xFF2C3E50);
    const kRed = Color(0xFFE74C3C);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Optional top icon (matches your “soft” style)
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kRed.withOpacity(0.12),
                  ),
                  child: const Icon(Icons.close_rounded, color: kRed, size: 30),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Decline request?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: kTextDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Are you sure you want to decline this request?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.35,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: kTextDark,
                            side: BorderSide(
                              color: Colors.black12.withOpacity(0.14),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            if (!mounted) return;
                            setState(() => _loading = true);
                            await _updateRequestStatus(requestId, "Declined");
                            if (mounted) setState(() => _loading = false);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kRed,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            "Decline",
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case "Approved":
        return Colors.green;
      case "Declined":
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case "Approved":
        return Icons.check_circle_rounded;
      case "Declined":
        return Icons.cancel_rounded;
      default:
        return Icons.hourglass_top_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xffF7F8FA);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text(
          "Money Requests",
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFEDEDED)),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
          ? const Center(
              child: Text(
                "No requests found",
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchRequests,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _requests.length,
                itemBuilder: (context, i) {
                  final req = _requests[i];

                  final status = (req["requestStatus"] ?? "Pending").toString();
                  final amountStr = (req["amount"] ?? "0").toString();
                  final childName = (req["childName"] ?? "Child").toString();
                  final desc = (req["requestDescription"] ?? "No message")
                      .toString();

                  final statusColor = _statusColor(status);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 10,
                          offset: const Offset(0, 6),
                          color: Colors.black12.withOpacity(0.05),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row: child + status pill
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                _statusIcon(status),
                                color: statusColor,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    childName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF2C3E50),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    desc,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: Colors.black54,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                status == "Approved"
                                    ? "Paid"
                                    : status, // keep your wording
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Amount row (amount + SAR icon right next to it)
                        Row(
                          children: [
                            const Spacer(),
                            Text(
                              amountStr,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                            const SizedBox(width: 6),
                            _sarIcon(size: 16, color: const Color(0xFF2C3E50)),
                          ],
                        ),

                        if (status == "Pending") ...[
                          const SizedBox(height: 14),
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
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    "Decline",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
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
                                          childName: childName,
                                          childBalance: "0.00",
                                          token: token!,
                                          requestId: req["requestId"],
                                          initialAmount: double.tryParse(
                                            amountStr,
                                          ),
                                        ),
                                      ),
                                    );
                                    if (result == true) _fetchRequests();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2EA49E),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: const Text(
                                    "Approve",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}
