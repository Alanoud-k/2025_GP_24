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
const kProgress = Color(0xFF67AFAC);
const kTextSecondary = Color(0xFF6E6E6E);

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkAuthStatus(context);
    });

    _api = GoalsApi(widget.baseUrl, widget.token);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() => _loading = true);

    try {
      final goals = await _api.listGoals(widget.childId);
      final balances = await _fetchBalances();

      if (!mounted) return;
      setState(() {
        _goals = goals;
        _savingBalance = balances['saving'] ?? 0.0;
        _spendingBalance = balances['spending'] ?? 0.0;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load goals/balances: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<Map<String, double>> _fetchBalances() async {
    final url = Uri.parse(
      "${widget.baseUrl}/api/children/${widget.childId}/wallet/balances",
    );
    print("BALANCES URL => $url");

    final res = await http.get(
      url,
      headers: {"Authorization": "Bearer ${widget.token}"},
    );

    print("BALANCES STATUS => ${res.statusCode}");
    print("BALANCES BODY   => ${res.body}");

    if (res.statusCode == 401) {
      // token issue
      await checkAuthStatus(context);
      throw Exception("Unauthorized (401) while loading balances");
    }
    if (res.statusCode != 200) {
      throw Exception("Failed to load balances: ${res.statusCode} ${res.body}");
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

  Future<void> _moveAmount(String type) async {
    final ctrl = TextEditingController();

    final amount = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 18,
          right: 18,
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
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
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
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final v = double.tryParse(ctrl.text.trim());
                if (v != null && v > 0) Navigator.pop(ctx, v);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kProgress,
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text(
                "Confirm",
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );

    if (amount == null) return;

    final url = Uri.parse("${widget.baseUrl}/api/saving/$type");

    try {
      final res = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({"childId": widget.childId, "amount": amount}),
      );

      if (res.statusCode == 401) {
        await checkAuthStatus(context);
        return;
      }

      if (res.statusCode < 200 || res.statusCode > 299) {
        throw Exception("Request failed (${res.statusCode})");
      }

      await _bootstrap();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed: $e")));
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
    const hassalaGreen = Color(0xFF37C4BE);

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: BackButton(color: Colors.black87),
        title: const Text(
          "My Goals",
          style: TextStyle(
            fontSize: 20,
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
              onRefresh: _bootstrap,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 18),

                    /// --- Balance Panel ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _SavingPanel(
                        saving: _savingBalance,
                        spending: _spendingBalance,
                        onMoveIn: () => _moveAmount("move-in"),
                        onMoveOut: () => _moveAmount("move-out"),
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// --- Add Goal ---
                    InkWell(
                      borderRadius: BorderRadius.circular(50),
                      onTap: _openAddGoal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          CircleAvatar(
                            radius: 27,
                            backgroundColor: hassalaGreen,
                            child: Icon(
                              Icons.add,
                              size: 30,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            "Add new goal",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// --- Goals List ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _GoalsList(goals: _goals, onTap: _openGoalDetails),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }
}

/* ===================== BALANCES PANEL ===================== */

class _SavingPanel extends StatelessWidget {
  final double saving;
  final double spending;
  final VoidCallback onMoveIn;
  final VoidCallback onMoveOut;

  const _SavingPanel({
    required this.saving,
    required this.spending,
    required this.onMoveIn,
    required this.onMoveOut,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _balance("Saving", saving, Colors.teal),
              _balance("Spending", spending, Colors.orange),
            ],
          ),

          const SizedBox(height: 22),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _circleAction(
                "Move In\n(Sp → Sv)",
                Icons.arrow_downward,
                onMoveIn,
              ),
              const SizedBox(width: 40),
              _circleAction(
                "Move Out\n(Sv → Sp)",
                Icons.arrow_upward,
                onMoveOut,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _balance(String label, double amt, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        Text(
          "﷼ ${amt.toStringAsFixed(2)}",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _circleAction(String text, IconData icon, VoidCallback onTap) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: CircleAvatar(
            radius: 27,
            backgroundColor: kMint,
            child: Icon(icon, size: 26, color: Colors.white),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

/* ===================== GOALS LIST ===================== */

class _GoalsList extends StatelessWidget {
  final List<Goal> goals;
  final void Function(Goal) onTap;

  const _GoalsList({required this.goals, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
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
      child: goals.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                "No goals yet",
                style: TextStyle(
                  color: kTextSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : Column(
              children: goals
                  .map(
                    (g) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _GoalCard(goal: g, onTap: () => onTap(g)),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final Goal goal;
  final VoidCallback onTap;

  const _GoalCard({required this.goal, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final remaining = (goal.targetAmount - goal.goalBalance).clamp(0, 999999);
    final pct = (goal.progress * 100).clamp(0, 100).toStringAsFixed(0);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        decoration: BoxDecoration(
          color: kMint26,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Title + Target
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
                  "﷼ ${goal.targetAmount.toStringAsFixed(1)}",
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Text(
              "Remaining: ${remaining.toStringAsFixed(1)}",
              style: const TextStyle(color: kTextSecondary, fontSize: 14),
            ),

            const SizedBox(height: 10),

            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: goal.progress,
                minHeight: 6,
                backgroundColor: Colors.white,
                valueColor: const AlwaysStoppedAnimation(kProgress),
              ),
            ),

            const SizedBox(height: 4),

            Align(
              alignment: Alignment.centerRight,
              child: Text(
                "$pct%",
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
