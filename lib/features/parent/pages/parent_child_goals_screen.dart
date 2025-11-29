// lib/screens/parent_child_goals_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_app/utils/check_auth.dart';

const kMintSoft = Color(0xFFE6FBF9);
const kProgress = Color(0xFF67AFAC);
const kTextSecondary = Color(0xFF6E6E6E);

class ParentChildGoalsScreen extends StatefulWidget {
  final int childId;
  final String childName;
  final String token;
  final String baseUrl;

  const ParentChildGoalsScreen({
    super.key,
    required this.childId,
    required this.childName,
    required this.token,
    required this.baseUrl,
  });

  @override
  State<ParentChildGoalsScreen> createState() => _ParentChildGoalsScreenState();
}

class _ParentChildGoalsScreenState extends State<ParentChildGoalsScreen> {
  bool _loading = true;
  List<dynamic> _goals = [];

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    await checkAuthStatus(context);

    try {
      final url = Uri.parse(
        "${widget.baseUrl}/api/children/${widget.childId}/goals",
      );

      final res = await http.get(
        url,
        headers: {
          "Authorization": "Bearer ${widget.token}",
          "Content-Type": "application/json",
        },
      );

      if (res.statusCode == 401) {
        await checkAuthStatus(context);
        return;
      }

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() => _goals = data);
      }
    } catch (_) {}

    if (mounted) setState(() => _loading = false);
  }

  double _parse(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final active = _goals
        .where(
          (g) => g["goalstatus"] != "Achieved" && g["goalStatus"] != "Achieved",
        )
        .toList();

    final completed = _goals
        .where(
          (g) => g["goalstatus"] == "Achieved" || g["goalStatus"] == "Achieved",
        )
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black87),
        centerTitle: true,
        title: Text(
          "${widget.childName}'s Goals",
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFEDEDED)),
        ),
      ),

      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadGoals,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ------------------ ACTIVE ------------------
                    const Text(
                      "Active Goals",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),

                    if (active.isEmpty)
                      const Text(
                        "No active goals",
                        style: TextStyle(
                          color: kTextSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    else
                      ...active.map((g) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _activeGoalCard(g),
                        );
                      }),

                    const SizedBox(height: 24),

                    // ---------------- COMPLETED ----------------
                    if (completed.isNotEmpty) ...[
                      const Text(
                        "Completed Goals",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 10),

                      ...completed.map((g) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _completedGoalCard(g),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  // -------------------------------------------------------
  // ACTIVE GOAL CARD (same as child)
  // -------------------------------------------------------
  Widget _activeGoalCard(dynamic g) {
    final name = g["goalname"] ?? g["goalName"] ?? "Goal";
    final target = _parse(g["targetamount"] ?? g["targetAmount"]);
    final saved = _parse(g["balance"] ?? g["goalBalance"]);
    final remaining = (target - saved).clamp(0.0, double.infinity);

    final progress = (target == 0) ? 0.0 : (saved / target).clamp(0.0, 1.0);

    final pct = (progress * 100).toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: kMintSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // top row
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
              ),
              Text(
                "Target: ﷼ ${target.toStringAsFixed(0)}",
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: kTextSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          Text(
            "Remaining: ﷼ ${remaining.toStringAsFixed(0)}",
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: kTextSecondary,
            ),
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: Colors.white,
                    valueColor: const AlwaysStoppedAnimation(kProgress),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "$pct%",
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------
  // COMPLETED GOAL CARD (same as child, read-only)
  // -------------------------------------------------------
  Widget _completedGoalCard(dynamic g) {
    final name = g["goalname"] ?? g["goalName"] ?? "Goal";
    final target = _parse(g["targetamount"] ?? g["targetAmount"]);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F1F4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // top row
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  "Completed",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            "Target: ﷼ ${target.toStringAsFixed(0)}",
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: kTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
