import 'package:flutter/material.dart';
import '../services/goals_api.dart';       // <-- service layer (HTTP)
import '../models/goal_model.dart';        // <-- data model (Goal)

class ChildGoalsScreen extends StatefulWidget {
  const ChildGoalsScreen({super.key});

  @override
  State<ChildGoalsScreen> createState() => _ChildGoalsScreenState();
}

class _ChildGoalsScreenState extends State<ChildGoalsScreen> {
  // Colors
  static const kBg = Color(0xFFF7F8FA);
  static const kAddBtn = Color(0xFF9FE5E2);
  static const kNavInactive = Color(0xFFAAAAAA);
  static const kNavActive = Color(0xFF67AFAC);
  static const kTextSecondary = Color(0xFF6E6E6E);

  int _navIndex = 2; // active icon (Home)

  // ---- Runtime state ----
  late GoalsApi _api;                 // HTTP client
  late int _childId;                  // current child id
  late String _baseUrl;               // API base URL
  bool _loading = true;               // loading flag
  double _saveBalance = 0;            // saving account balance
  List<Goal> _goals = [];             // goals list

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Read arguments passed via Navigator (fallbacks are provided)
    final args = (ModalRoute.of(context)?.settings.arguments as Map?) ?? {};
    _childId = (args['childId'] ?? 0) as int;
    _baseUrl = (args['baseUrl'] ?? 'http://10.0.2.2:3000') as String;
    _api = GoalsApi(_baseUrl);

    // Bootstrap only the first time
    if (_loading) _bootstrap();
  }

  // Fetch wallet (idempotent), balance, and goals
  Future<void> _bootstrap() async {
    setState(() => _loading = true);
    try {
      // Ensure wallet & core accounts exist (safe to call multiple times)
      await _api.setupWallet(_childId);

      // Fetch saving balance and goals
      final bal = await _api.getSaveBalance(_childId);
      final goals = await _api.listGoals(_childId);

      setState(() {
        _saveBalance = bal;
        _goals = goals;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load goals: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Open Add Goal page then refresh on success
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
              BoxShadow(
                color: Colors.black12,
                blurRadius: 5,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new,
                        size: 20, color: Colors.black87),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const Spacer(),
                  const Text(
                    'Goals',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
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
          : RefreshIndicator(
              onRefresh: _bootstrap,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  _SavingBalanceCard(balance: _saveBalance),
                  const SizedBox(height: 16),
                  if (_goals.isEmpty)
                    _EmptyGoalsCard(onTapAdd: _openAddGoal)
                  else
                    Column(
                      children: _goals.map((g) => _GoalTile(goal: g)).toList(),
                    ),
                ],
              ),
            ),

      // Bottom nav
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        currentIndex: _navIndex,
        selectedItemColor: kNavActive,
        unselectedItemColor: kNavInactive,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.card_giftcard), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.sports_esports), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: ''),
        ],
        onTap: (i) {
          setState(() => _navIndex = i);
        },
      ),

      // Floating add button when list has items
      floatingActionButton: _goals.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _openAddGoal,
              backgroundColor: kAddBtn,
              label: const Text(
                'Add new goal',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
              icon: const Icon(Icons.add, color: Colors.white),
            ),
    );
  }
}

// Saving balance card (binds to live value)
class _SavingBalanceCard extends StatelessWidget {
  const _SavingBalanceCard({required this.balance});
  final double balance;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 2.2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'saving balance',
              style: TextStyle(fontSize: 13, color: Color(0xFF6E6E6E)),
            ),
            const SizedBox(height: 6),
            Text(
              '﷼ ${balance.toStringAsFixed(1)}',
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

// Empty goals card (navigates to Add Goal)
class _EmptyGoalsCard extends StatelessWidget {
  const _EmptyGoalsCard({required this.onTapAdd});
  final VoidCallback onTapAdd;

  static const kAddBtn = Color(0xFF9FE5E2);
  static const kTextSecondary = Color(0xFF6E6E6E);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 2.2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTapAdd,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Start your savings journey",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: kTextSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "set your first goal now!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: kTextSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),

              // + icon + text
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: const BoxDecoration(
                      color: kAddBtn,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, size: 30, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'Add new goal',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Single goal tile (progress + status)
class _GoalTile extends StatelessWidget {
  const _GoalTile({required this.goal});
  final Goal goal;

  @override
  Widget build(BuildContext context) {
    final pct = (goal.progress * 100).clamp(0, 100).toStringAsFixed(0);
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: name + status
            Row(
              children: [
                Expanded(
                  child: Text(
                    goal.goalName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(.06),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    goal.goalStatus,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),

            // Optional description
            if ((goal.goalDescription ?? '').isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                goal.goalDescription!,
                style: const TextStyle(fontSize: 13, color: Color(0xFF6E6E6E)),
              ),
            ],

            const SizedBox(height: 12),

            // Progress bar
            LinearProgressIndicator(
              value: goal.progress,
              minHeight: 10,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 8),

            // Amounts and percent
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '﷼ ${goal.goalBalance.toStringAsFixed(2)} / ${goal.targetAmount.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF6E6E6E)),
                ),
                Text('$pct%'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
