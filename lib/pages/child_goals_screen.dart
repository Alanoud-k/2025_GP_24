import 'package:flutter/material.dart';
import '../services/goals_api.dart';
import '../models/goal_model.dart';

// Global colors
const kBg = Color(0xFFF7F8FA);
const kMint = Color(0xFF9FE5E2);
const kMint26 = Color(0x429FE5E2); // 26% opacity
const kNavInactive = Color(0xFFAAAAAA);
const kNavActive = Color(0xFF67AFAC);
const kTextSecondary = Color(0xFF6E6E6E);
const kProgress = Color(0xFF67AFAC);

class ChildGoalsScreen extends StatefulWidget {
  const ChildGoalsScreen({super.key});

  @override
  State<ChildGoalsScreen> createState() => _ChildGoalsScreenState();
}

class _ChildGoalsScreenState extends State<ChildGoalsScreen> {
  int _navIndex = 2;
  late GoalsApi _api;
  late int _childId;
  late String _baseUrl;
  bool _loading = true;
  List<Goal> _goals = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = (ModalRoute.of(context)?.settings.arguments as Map?) ?? {};
    _childId = (args['childId'] ?? 0) as int;
    _baseUrl = (args['baseUrl'] ?? 'http://10.0.2.2:3000') as String;
    _api = GoalsApi(_baseUrl);
    if (_loading) _bootstrap();
  }

  // Load goals
  Future<void> _bootstrap() async {
    setState(() => _loading = true);
    try {
      await _api.setupWallet(_childId);
      final goals = await _api.listGoals(_childId);
      setState(() => _goals = goals);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to load goals: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Open add-goal screen
  Future<void> _openAddGoal() async {
    final created = await Navigator.pushNamed(
      context,
      '/childAddGoal',
      arguments: {'childId': _childId, 'baseUrl': _baseUrl},
    );
    if (created == true) _bootstrap();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,

      // App bar
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(85),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 3)),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new,
                        size: 20, color: Colors.black87),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const Spacer(),
                  const Text(
                    'My Goals',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),
        ),
      ),

      // Body
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                return RefreshIndicator(
                  onRefresh: _bootstrap,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                          child: _MainGoalsCard(
                            goals: _goals,
                            onTapAdd: _openAddGoal,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

      // Bottom nav
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: _navIndex,
        selectedItemColor: kNavActive,
        unselectedItemColor: kNavInactive,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.card_giftcard), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.sports_esports), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: ''),
        ],
        onTap: (i) => setState(() => _navIndex = i),
      ),
    );
  }
}

/// White main card (center, Figma-like size)
class _MainGoalsCard extends StatelessWidget {
  const _MainGoalsCard({required this.goals, required this.onTapAdd});

  final List<Goal> goals;
  final VoidCallback onTapAdd;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 385, // Figma width
      child: Container(
        constraints: const BoxConstraints(
          minHeight: 598, // Figma height as minimum
        ),
        padding: const EdgeInsets.fromLTRB(18, 28, 18, 22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 4), // soft shadow
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (goals.isNotEmpty)
              ...goals.map(
                (g) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _GoalTile(goal: g),
                ),
              ),
            const SizedBox(height: 40), // space above add button
            InkWell(
              onTap: onTapAdd,
              borderRadius: BorderRadius.circular(40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 27,
                    backgroundColor: kMint,
                    child: Icon(Icons.add, color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 12),
                  const Text(
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
      ),
    );
  }
}

/// Single goal tile (mint card)
class _GoalTile extends StatelessWidget {
  const _GoalTile({required this.goal});
  final Goal goal;

  @override
  Widget build(BuildContext context) {
    final remaining = (goal.targetAmount - goal.goalBalance).clamp(0, 999999);
    final pct = (goal.progress * 100).clamp(0, 100).toStringAsFixed(0);

    return Container(
      width: 358, // Figma width
      constraints: const BoxConstraints(minHeight: 117), // Figma min height
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      decoration: BoxDecoration(
        color: kMint26,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + amount
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
            style: const TextStyle(
              fontSize: 14,
              color: kTextSecondary,
            ),
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
    );
  }
}
