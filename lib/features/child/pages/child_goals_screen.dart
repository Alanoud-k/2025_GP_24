import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/goals_api.dart';
import '../models/goal_model.dart';
import 'child_add_goal_screen.dart';
import 'child_goal_details_screen.dart';
import 'package:my_app/utils/check_auth.dart';

const kBg = Color(0xFFF7F8FA);
const kMint = Color(0xFF9FE5E2);
const kMint26 = Color(0x429FE5E2);
const kTextSecondary = Color(0xFF6E6E6E);
const kProgress = Color(0xFF67AFAC);

class ChildGoalsScreen extends StatefulWidget {
  final int childId;
  final String baseUrl;
  final String token;

  const ChildGoalsScreen({
    super.key,
    required this.childId,
    required this.baseUrl,
    required this.token,
  });

  @override
  State<ChildGoalsScreen> createState() => _ChildGoalsScreenState();
}

class _ChildGoalsScreenState extends State<ChildGoalsScreen> {
  late GoalsApi _api;

  bool _loading = true;
  List<Goal> _goals = [];

  double _savingBalance = 0.0;
  double _spendingBalance = 0.0;

  Map<String, String> get _headers => {
    "Authorization": "Bearer ${widget.token}",
    "Content-Type": "application/json",
  };

  @override
  void initState() {
    super.initState();
    _fetchBalances();

    // Check token after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkAuthStatus(context);
    });

    _api = GoalsApi(widget.baseUrl, widget.token);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() => _loading = true);

    try {
      // 1) Load goals
      final goals = await _api.listGoals(widget.childId);

      // 2) Load saving + spending balances
      final balances = await _fetchBalances();

      if (!mounted) return;
      setState(() {
        _goals = goals;
        _savingBalance = balances['saving'] ?? 0.0;
        _spendingBalance = balances['spending'] ?? 0.0;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load goals: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Calls a backend endpoint like:
  ///   GET /api/children/:childId/wallet/balances
  /// Expected response (flexible):
  ///   { "saving": 50.0, "spending": 20.0 }
  ///   or { "savingBalance": 50.0, "spend": 20.0 } etc.
  Future<Map<String, double>> _fetchBalances() async {
    final res = await http.get(
      Uri.parse(
        "${widget.baseUrl}/api/children/${widget.childId}/wallet/balances",
      ),
      headers: {"Authorization": "Bearer ${widget.token}"},
    );
    if (res.statusCode == 401) {
      await checkAuthStatus(context);
      return {"saving": 0.0, "spending": 0.0};
    }
    if (res.statusCode != 200) {
      return {"saving": 0.0, "spending": 0.0};
    }

    final data = jsonDecode(res.body);

    double _toDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    final saving = _toDouble(
      data['saving'] ??
          data['savingBalance'] ??
          data['save'] ??
          data['saving_balance'],
    );

    final spending = _toDouble(
      data['spending'] ??
          data['spend'] ??
          data['spendingBalance'] ??
          data['spend_balance'],
    );

    return {"saving": saving, "spending": spending};
  }

  /// type = "move-in"  (Spending → Saving)
  /// type = "move-out" (Saving → Spending)
  Future<void> _moveInOrOut(String type) async {
    final ctrl = TextEditingController();

    final amount = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              type == "move-in"
                  ? "Move In (Spending → Saving)"
                  : "Move Out (Saving → Spending)",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                hintText: "Amount",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () {
                  final v = double.tryParse(ctrl.text.trim());
                  if (v != null && v > 0) Navigator.pop(ctx, v);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kProgress,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Confirm",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (amount == null) return;

    try {
      // Your backend routes for these should be:
      //   POST /api/saving/move-in
      //   POST /api/saving/move-out
      final url = Uri.parse("${widget.baseUrl}/api/saving/$type");
      final res = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({"childId": widget.childId, "amount": amount}),
      );

      if (res.statusCode == 401) {
        await checkAuthStatus(context);
        return;
      }

      if (res.statusCode >= 200 && res.statusCode < 300) {
        // Refresh balances + goals
        await _bootstrap();
      } else {
        throw Exception("Request failed (${res.statusCode})");
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${type.replaceAll('-', ' ')} failed: $e")),
      );
    }
  }

  Future<void> _openAddGoal() async {
    final created = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChildAddGoalScreen(
          childId: widget.childId,
          baseUrl: widget.baseUrl,
          token: widget.token,
        ),
      ),
    );

    if (created == true) _bootstrap();
  }

  Future<void> _openGoalDetails(Goal g) async {
    final changed = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChildGoalDetailsScreen(
          childId: widget.childId,
          baseUrl: widget.baseUrl,
          token: widget.token,
          goal: g,
        ),
      ),
    );

    if (changed == true) _bootstrap();
  }

  @override
  Widget build(BuildContext context) {
    const hassalaGreen1 = Color(0xFF37C4BE);

    return FutureBuilder(
      future: checkAuthStatus(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          backgroundColor: kBg,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                size: 20,
                color: Colors.black87,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              "My Goals",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 1, thickness: 1, color: Color(0xFFEDEDED)),
            ),
          ),
          body: SafeArea(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _bootstrap,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        children: [
                          const SizedBox(height: 18),

                          // Saving + Spending section
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            child: _SavingSection(
                              savingBalance: _savingBalance,
                              spendingBalance: _spendingBalance,
                              onMoveIn: () => _moveInOrOut("move-in"),
                              onMoveOut: () => _moveInOrOut("move-out"),
                            ),
                          ),

                          const SizedBox(height: 18),

                          // Add goal button
                          InkWell(
                            onTap: _openAddGoal,
                            borderRadius: BorderRadius.circular(40),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                CircleAvatar(
                                  radius: 27,
                                  backgroundColor: hassalaGreen1,
                                  child: Icon(
                                    Icons.add,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Add new goal',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 18),

                          // Goals card
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            child: _MainGoalsCard(
                              goals: _goals,
                              onTapGoal: _openGoalDetails,
                            ),
                          ),

                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }
}

/* ---------------- Saving + Spending UI ---------------- */

class _SavingSection extends StatelessWidget {
  final double savingBalance;
  final double spendingBalance;
  final VoidCallback onMoveIn;
  final VoidCallback onMoveOut;

  const _SavingSection({
    required this.savingBalance,
    required this.spendingBalance,
    required this.onMoveIn,
    required this.onMoveOut,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "Saving & Spending",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),

          // Balances row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _balanceTile("Saving", savingBalance, Colors.teal),
              _balanceTile("Spending", spendingBalance, Colors.orange),
            ],
          ),

          const SizedBox(height: 20),

          const SizedBox(height: 14),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _MintCircleAction(
                label: "Move In\n(Spending → Saving)",
                icon: Icons.arrow_downward,
                onTap: onMoveIn,
              ),
              const SizedBox(width: 32),
              _MintCircleAction(
                label: "Move Out\n(Saving → Spending)",
                icon: Icons.arrow_upward,
                onTap: onMoveOut,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _balanceTile(String name, double amount, Color color) {
    return Column(
      children: [
        Text(
          name,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        Text(
          "﷼ ${amount.toStringAsFixed(2)}",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _MintCircleAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _MintCircleAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(50),
          child: CircleAvatar(
            radius: 27,
            backgroundColor: kMint,
            child: Icon(icon, size: 28, color: Colors.white),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

/* ---------------- Goals list card ---------------- */

class _MainGoalsCard extends StatelessWidget {
  final List<Goal> goals;
  final void Function(Goal) onTapGoal;

  const _MainGoalsCard({required this.goals, required this.onTapGoal});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 385,
      constraints: const BoxConstraints(minHeight: 300),
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: goals.isEmpty
            ? const [
                SizedBox(height: 20),
                Text(
                  "No goals yet",
                  style: TextStyle(
                    color: kTextSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 20),
              ]
            : goals
                  .map(
                    (g) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _GoalTile(goal: g, onTap: () => onTapGoal(g)),
                    ),
                  )
                  .toList(),
      ),
    );
  }
}

class _GoalTile extends StatelessWidget {
  final Goal goal;
  final VoidCallback onTap;

  const _GoalTile({required this.goal, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final remaining = (goal.targetAmount - goal.goalBalance).clamp(0, 999999);
    final pct = (goal.progress * 100).clamp(0, 100).toStringAsFixed(0);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 358,
        constraints: const BoxConstraints(minHeight: 117),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
        decoration: BoxDecoration(
          color: kMint26,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    goal.goalName,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Text(
                  '﷼ ${goal.targetAmount.toStringAsFixed(1)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Remaining: ${remaining.toStringAsFixed(1)}',
              style: const TextStyle(fontSize: 14, color: kTextSecondary),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: goal.progress,
                minHeight: 6,
                backgroundColor: Colors.white,
                valueColor: const AlwaysStoppedAnimation<Color>(kProgress),
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '$pct%',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
