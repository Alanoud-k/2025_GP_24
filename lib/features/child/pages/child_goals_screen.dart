import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/goals_api.dart';
import '../models/goal_model.dart';
import '../widgets/child_bottom_nav_bar.dart';
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

  Map<String, String> get _headers => {
    "Authorization": "Bearer ${widget.token}",
    "Content-Type": "application/json",
  };

  @override
  void initState() {
    super.initState();
    _api = GoalsApi(widget.baseUrl, widget.token);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() => _loading = true);

    try {
      final goals = await _api.listGoals(widget.childId);
      final saving = await _fetchSavingBalance();

      if (!mounted) return;
      setState(() {
        _goals = goals;
        _savingBalance = saving;
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

  Future<double> _fetchSavingBalance() async {
    final url = Uri.parse("${widget.baseUrl}/saving/balance/${widget.childId}");
    final res = await http.get(url, headers: _headers);
    if (res.statusCode != 200) return 0.0;

    final data = jsonDecode(res.body);
    return (data is num)
        ? data.toDouble()
        : (data["balance"] ?? data["savingBalance"] ?? 0).toDouble();
  }

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
              type == "move-in" ? "Move In" : "Move Out",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
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
                  style: TextStyle(fontWeight: FontWeight.w600,color: Color.fromARGB(255, 255, 255, 255),),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (amount == null) return;

    try {
      final url = Uri.parse("${widget.baseUrl}/saving/$type");
      final res = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({"childId": widget.childId, "amount": amount}),
      );

      if (res.statusCode >= 200 && res.statusCode < 300) {
        _bootstrap();
      } else {
        throw Exception("Request failed");
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${type.replaceAll('-', ' ')} failed")),
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
    return FutureBuilder(
      future: checkAuthStatus(context),
      builder: (context, snapshot) {
        // While checking token → show lightweight loader
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // After auth check → return actual screen
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

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _SavingSection(
                              savingBalance: _savingBalance,
                              onMoveIn: () => _moveInOrOut("move-in"),
                              onMoveOut: () => _moveInOrOut("move-out"),
                            ),
                          ),

                          const SizedBox(height: 18),

                          InkWell(
                            onTap: _openAddGoal,
                            borderRadius: BorderRadius.circular(40),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                CircleAvatar(
                                  radius: 27,
                                  backgroundColor: kMint,
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

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
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

          bottomNavigationBar: ChildBottomNavBar(
            currentIndex: 2,
            onTap: (i) {
              if (i == 2) Navigator.of(context).pop(true);
            },
          ),
        );
      },
    );
  }
}

// Saving section
class _SavingSection extends StatelessWidget {
  final double savingBalance;
  final VoidCallback onMoveIn;
  final VoidCallback onMoveOut;

  const _SavingSection({
    required this.savingBalance,
    required this.onMoveIn,
    required this.onMoveOut,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "Saving Balance",
            style: TextStyle(
              fontSize: 14,
              color: kTextSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "﷼ ${savingBalance.toStringAsFixed(2)}",
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 18),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _MintCircleAction(
                label: "Move In",
                icon: Icons.arrow_downward,
                onTap: onMoveIn,
              ),
              const SizedBox(width: 32),
              _MintCircleAction(
                label: "Move Out",
                icon: Icons.arrow_upward,
                onTap: onMoveOut,
              ),
            ],
          ),
        ],
      ),
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

// Goals list card
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