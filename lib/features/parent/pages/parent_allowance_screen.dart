import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ParentAllowanceScreen extends StatefulWidget {
  const ParentAllowanceScreen({
    super.key,
    required this.parentId,
    required this.childId,
  });
  final int parentId;
  final int childId;
  @override
  State<ParentAllowanceScreen> createState() => _ParentAllowanceScreenState();
}

class _ParentAllowanceScreenState extends State<ParentAllowanceScreen> {
  static const String baseUrl = "http://10.0.2.2:3000";

  bool allowanceOn = true;
  bool loading = true;

  String childName = "Loading...";
  double allowanceAmount = 0.0;
  String frequency = "—";
  String nextPayment = "—";
  String splitText = "—";

  String? token;

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetch();
  }

  Future<void> _loadTokenAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString("token");
    await _fetchAllowanceInfo();
  }

  Future<void> _fetchAllowanceInfo() async {
    try {
      final url = Uri.parse(
        "$baseUrl/api/parent/${widget.parentId}/allowance/${widget.childId}",
      );

      final response = await http.get(
        url,
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          childName = data["childName"] ?? "Unnamed";
          allowanceOn = data["enabled"] ?? true;
          allowanceAmount = (data["amount"] ?? 0).toDouble();
          frequency = data["frequency"] ?? "weekly";
          nextPayment = data["nextPayment"] ?? "—";
          splitText = data["splitText"] ?? "---";
          loading = false;
        });
      } else {
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to load allowance info")),
        );
      }
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _toggleAllowance(bool value) async {
    setState(() => allowanceOn = value);

    try {
      final url = Uri.parse(
        "$baseUrl/api/parent/${widget.parentId}/allowance/${widget.childId}/toggle",
      );

      final res = await http.put(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"enabled": value}),
      );

      if (res.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to update allowance")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color kPrimary = Color(0xFF67AFAC);
    const Color kBg = Color(0xFFF7F8FA);

    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.teal)),
      );
    }

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// TOP BAR
              Row(
                children: [
                  const Spacer(),
                  Text(
                    childName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kPrimary,
                      side: const BorderSide(color: kPrimary),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      "History",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              const Text(
                "Allowance",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 20),

              /// ALLOWANCE SUMMARY CARD
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          allowanceAmount.toStringAsFixed(2),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "SAR $frequency",
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      splitText,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Next payment: $nextPayment",
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// "ALL OR NOTHING" STATIC CARD (demo)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3CD),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.lock_outline,
                        color: Color(0xFFF4B000),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "All or nothing",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Complete 33 chores to earn the next payment.",
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              /// TOGGLE SECTION
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Allowance is on",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Turning this off will pause allowance payments.",
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: allowanceOn,
                    activeColor: Colors.white,
                    activeTrackColor: kPrimary,
                    onChanged: (value) => _toggleAllowance(value),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              /// KEEP THEM ON TRACK CARD
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: kPrimary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.checklist_rounded,
                        color: kPrimary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Keep them on track",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "See how your child is doing with their chores.",
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
