// lib/screens/child_goals_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/goals_api.dart';
import '../models/goal_model.dart';
import 'child_add_goal_screen.dart';
import 'child_goal_details_screen.dart';
import 'package:my_app/utils/check_auth.dart';

/// ====== COLORS ======
const kBg = Color(0xFFF7F8FA);
const kMint = Color(0xFF9FE5E2);
const kMintSoft = Color(0xFFE6FBF9);
const kProgress = Color(0xFF67AFAC);
const kTextSecondary = Color(0xFF6E6E6E);
const kHassalaGreen = Color(0xFF37C4BE);

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

    // Auto-logout check
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkAuthStatus(context);
    });

    _api = GoalsApi(widget.baseUrl, widget.token);
    _bootstrap();
  }

  /// ---------------- LOAD INITIAL DATA ----------------
  Future<void> _bootstrap() async {
    if (!mounted) return;

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to load goals: $e")));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// ---------------- FETCH BALANCES ----------------
  Future<Map<String, double>> _fetchBalances() async {
    final url = Uri.parse(
      "${widget.baseUrl}/api/children/${widget.childId}/wallet/balances",
    );

    final res = await http.get(url, headers: _headers);

    if (res.statusCode == 401) {
      await checkAuthStatus(context);
      return {"saving": 0.0, "spending": 0.0};
    }

    if (res.statusCode != 200) {
      return {"saving": 0.0, "spending": 0.0};
    }

    final data = jsonDecode(res.body);

    double parse(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    // Accept any possible key your backend might use
    final saving =
        data["saving"] ??
        data["savingBalance"] ??
        data["saving_balance"] ??
        data["savingsBalance"] ??
        data["savingAmount"] ??
        data["saving_account"] ??
        0.0;

    final spending =
        data["spending"] ??
        data["spendingBalance"] ??
        data["spending_balance"] ??
        data["spendBalance"] ??
        data["spendingAmount"] ??
        data["spending_account"] ??
        0.0;

    return {"saving": parse(saving), "spending": parse(spending)};
  }

  /// ---------------- MOVE SAVING <-> SPENDING ----------------
  Future<void> _moveAmount(String type) async {
    final ctrl = TextEditingController();

    final amount = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 18,
          right: 18,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 18,
          top: 18,
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
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                hintText: "Amount",
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: () {
                final val = double.tryParse(ctrl.text.trim());
                if (val != null && val > 0) Navigator.pop(ctx, val);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kProgress,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
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
        throw Exception("Failed (${res.statusCode})");
      }

      await _bootstrap();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Move failed: $e")));
    }
  }

  /// ---------------- ADD GOAL ----------------
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

  /// ---------------- GOAL DETAILS ----------------
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

  /// ---------------- REDEEM COMPLETED ----------------
  Future<void> _redeemCompleted(Goal goal) async {
    try {
      await _api.redeemGoal(childId: widget.childId, goalId: goal.goalId);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Goal moved to Spending")));

      _bootstrap();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  /// ---------------- BUILD ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Colors.black87),
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

                    // -------- Saving | Spending pill ----------
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _SavingSpendingPill(
                        saving: _savingBalance,
                        spending: _spendingBalance,
                        onMoveIn: () => _moveAmount("move-in"),
                        onMoveOut: () => _moveAmount("move-out"),
                      ),
                    ),

                    const SizedBox(height: 22),

                    // -------- Add Goal Button ----------
                    InkWell(
                      borderRadius: BorderRadius.circular(40),
                      onTap: _openAddGoal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: kHassalaGreen,
                            child: Icon(
                              Icons.add,
                              size: 24,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(
                            "Add new goal",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // -------- Goals List ----------
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _GoalsList(
                        goals: _goals,
                        openActiveDetails: _openGoalDetails,
                        redeemCompleted: _redeemCompleted,
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }
}

//////////////////////////////////////////////////////////////////
///     SAVING | SPENDING PILL UI
//////////////////////////////////////////////////////////////////

class _SavingSpendingPill extends StatelessWidget {
  final double saving;
  final double spending;
  final VoidCallback onMoveIn;
  final VoidCallback onMoveOut;

  const _SavingSpendingPill({
    required this.saving,
    required this.spending,
    required this.onMoveIn,
    required this.onMoveOut,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Column(
        children: [
          // Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: kMintSoft,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              children: [
                _pillSegment("Saving", saving, kHassalaGreen),
                Container(
                  width: 1,
                  height: 24,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  color: Colors.teal.withOpacity(0.2),
                ),
                _pillSegment("Spending", spending, Colors.orange.shade700),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onMoveIn,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: kHassalaGreen.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    "Move In (Sp→Sv)",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: onMoveOut,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kHassalaGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    "Move Out (Sv→Sp)",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pillSegment(String label, double amount, Color color) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Icon(
              label == "Saving"
                  ? Icons.savings_outlined
                  : Icons.wallet_outlined,
              size: 16,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              Text(
                "﷼ ${amount.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

//////////////////////////////////////////////////////////////////
///     GOALS LIST
//////////////////////////////////////////////////////////////////

class _GoalsList extends StatelessWidget {
  final List<Goal> goals;
  final void Function(Goal) openActiveDetails;
  final Future<void> Function(Goal) redeemCompleted;

  const _GoalsList({
    required this.goals,
    required this.openActiveDetails,
    required this.redeemCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final active = goals.where((g) => !g.isCompleted).toList();
    final completed = goals.where((g) => g.isCompleted).toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //---------------- Active goals ----------------
          const Text(
            "Active goals",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),

          if (active.isEmpty)
            const Text(
              "You don’t have any active goals.",
              style: TextStyle(
                color: kTextSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            )
          else
            ...active.map(
              (g) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ActiveGoalCard(
                  goal: g,
                  onTap: () => openActiveDetails(g),
                ),
              ),
            ),

          //---------------- Completed ----------------
          if (completed.isNotEmpty) ...[
            const SizedBox(height: 22),
            const Text(
              "Completed goals",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            ...completed.map(
              (g) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _CompletedGoalCard(goal: g, onRedeem: redeemCompleted),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

//////////////////////////////////////////////////////////////////
///     ACTIVE GOAL CARD
//////////////////////////////////////////////////////////////////

class _ActiveGoalCard extends StatelessWidget {
  final Goal goal;
  final VoidCallback onTap;

  const _ActiveGoalCard({required this.goal, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final remaining = (goal.targetAmount - goal.goalBalance).clamp(0, 999999);
    final pct = (goal.progress * 100).clamp(0, 100).toStringAsFixed(0);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
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
                    goal.goalName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Text(
                  "Target: ﷼ ${goal.targetAmount.toStringAsFixed(0)}",
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
                      value: goal.progress,
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
      ),
    );
  }
}

//////////////////////////////////////////////////////////////////
///     COMPLETED GOAL CARD  (NOT CLICKABLE)
//////////////////////////////////////////////////////////////////

class _CompletedGoalCard extends StatelessWidget {
  final Goal goal;
  final Future<void> Function(Goal goal) onRedeem;

  const _CompletedGoalCard({required this.goal, required this.onRedeem});

  @override
  Widget build(BuildContext context) {
    final canRedeem = goal.goalBalance > 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F1F4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //---------------- Top row ----------------
          Row(
            children: [
              Expanded(
                child: Text(
                  goal.goalName,
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
            "Target: ﷼ ${goal.targetAmount.toStringAsFixed(0)}",
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: kTextSecondary,
            ),
          ),

          //---------------- Redeem button ----------------
          if (canRedeem) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton(
                onPressed: () => onRedeem(goal),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  "Move to Spending",
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
