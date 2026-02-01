// lib/screens/parent_child_goals_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_app/utils/check_auth.dart';

const kBg = Color(0xFFF7F8FA);
const kMintSoft = Color(0xFFE6FBF9);
const kProgress = Color(0xFF67AFAC);
const kTextSecondary = Color(0xFF6E6E6E);
const kHassalaGreen = Color(0xFF37C4BE);

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

  Widget _sarIcon({double size = 14, Color? color}) {
    return Image.asset(
      'assets/icons/Sar.png',
      width: size,
      height: size,
      color: color,
    );
  }

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    await checkAuthStatus(context);

    if (mounted) setState(() => _loading = true);

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
        if (mounted) setState(() => _goals = data);
      }
    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  double _parse(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  bool _isAchieved(dynamic g) {
    final s1 = (g["goalstatus"] ?? "").toString();
    final s2 = (g["goalStatus"] ?? "").toString();
    return s1 == "Achieved" || s2 == "Achieved";
  }

  @override
  Widget build(BuildContext context) {
    final active = _goals.where((g) => !_isAchieved(g)).toList();
    final completed = _goals.where((g) => _isAchieved(g)).toList();

    return Scaffold(
      backgroundColor: kBg,
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
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeader(title: "Active Goals", count: active.length),
                    const SizedBox(height: 10),

                    if (active.isEmpty)
                      const _EmptyState(text: "No active goals")
                    else
                      ...active.map(
                        (g) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _activeGoalCard(g),
                        ),
                      ),

                    const SizedBox(height: 20),

                    if (completed.isNotEmpty) ...[
                      _SectionHeader(
                        title: "Completed Goals",
                        count: completed.length,
                      ),
                      const SizedBox(height: 10),
                      ...completed.map(
                        (g) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _completedGoalCard(g),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  // -------------------------------------------------------
  // ACTIVE GOAL CARD
  // -------------------------------------------------------
  Widget _activeGoalCard(dynamic g) {
    final name = (g["goalname"] ?? g["goalName"] ?? "Goal").toString();
    final target = _parse(g["targetamount"] ?? g["targetAmount"]);
    final saved = _parse(g["balance"] ?? g["goalBalance"]);
    final remaining = (target - saved).clamp(0.0, double.infinity);
    final progress = (target == 0) ? 0.0 : (saved / target).clamp(0.0, 1.0);
    final pct = (progress * 100).toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: kMintSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      target.toStringAsFixed(0),
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(width: 6),
                    _sarIcon(size: 14, color: const Color(0xFF2C3E50)),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Saved / Remaining row
          Row(
            children: [
              _miniMetric(
                label: "Saved",
                value: saved.toStringAsFixed(0),
                color: kHassalaGreen,
              ),
              const SizedBox(width: 10),
              _miniMetric(
                label: "Remaining",
                value: remaining.toStringAsFixed(0),
                color: Colors.orange.shade700,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: kProgress.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  "$pct%",
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFEFF3F5),
              valueColor: const AlwaysStoppedAnimation(kProgress),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniMetric({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "$label: ",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(width: 6),
          _sarIcon(size: 13, color: const Color(0xFF2C3E50)),
        ],
      ),
    );
  }

  // -------------------------------------------------------
  // COMPLETED GOAL CARD
  // -------------------------------------------------------
  Widget _completedGoalCard(dynamic g) {
    final name = (g["goalname"] ?? g["goalName"] ?? "Goal").toString();
    final target = _parse(g["targetamount"] ?? g["targetAmount"]);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: Colors.green,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Target: ",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: kTextSecondary,
                      ),
                    ),
                    Text(
                      target.toStringAsFixed(0),
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(width: 6),
                    _sarIcon(size: 13, color: const Color(0xFF2C3E50)),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              "Completed",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;

  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: Colors.black87,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: kMintSoft,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            "$count",
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Color(0xFF2C3E50),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String text;
  const _EmptyState({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: kMintSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.flag_outlined, color: Color(0xFF2C3E50)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: kTextSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
