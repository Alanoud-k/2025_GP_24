import 'package:flutter/material.dart';
import '../services/goals_api.dart';
import '../models/goal_model.dart';
import '../widgets/child_bottom_nav_bar.dart';
import 'child_add_goal_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _api = GoalsApi(widget.baseUrl, widget.token);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() => _loading = true);
    try {
      //await _api.setupWallet(widget.childId);
      final goals = await _api.listGoals(widget.childId);
      setState(() => _goals = goals);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load goals: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,

      // الجسم
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : LayoutBuilder(
                builder: (context, constraints) {
                  return RefreshIndicator(
                    onRefresh: _bootstrap,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Column(
                          children: [
                            const SizedBox(height: 20),

                            // العنوان
                            const Text(
                              'My Goals',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),

                            const SizedBox(height: 20),

                            // الكرت الأساسي
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: _MainGoalsCard(
                                goals: _goals,
                                onTapAdd: _openAddGoal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),

      bottomNavigationBar: ChildBottomNavBar(
        currentIndex: 2,
        onTap: (i) {
          if (i == 2) {
            Navigator.of(context).pop(true);
          }
        },
      ),
    );
  }
}

class _MainGoalsCard extends StatelessWidget {
  final List<Goal> goals;
  final VoidCallback onTapAdd;

  const _MainGoalsCard({required this.goals, required this.onTapAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 385,
      constraints: const BoxConstraints(minHeight: 598),
      padding: const EdgeInsets.fromLTRB(18, 28, 18, 22),
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
        children: [
          if (goals.isNotEmpty)
            ...goals.map(
              (g) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _GoalTile(goal: g),
              ),
            ),

          const SizedBox(height: 40),

          // زر إضافة هدف جديد
          InkWell(
            onTap: onTapAdd,
            borderRadius: BorderRadius.circular(40),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                CircleAvatar(
                  radius: 27,
                  backgroundColor: kMint,
                  child: Icon(Icons.add, color: Colors.white, size: 30),
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
        ],
      ),
    );
  }
}

class _GoalTile extends StatelessWidget {
  final Goal goal;

  const _GoalTile({required this.goal});

  @override
  Widget build(BuildContext context) {
    final remaining = (goal.targetAmount - goal.goalBalance).clamp(0, 999999);
    final pct = (goal.progress * 100).clamp(0, 100).toStringAsFixed(0);

    return Container(
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
          // العنوان + المبلغ
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
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
