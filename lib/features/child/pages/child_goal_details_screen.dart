import 'package:flutter/material.dart';
import '../models/goal_model.dart';
import '../services/goals_api.dart';
import 'package:my_app/utils/check_auth.dart';

const kBg = Color(0xFFF7F8FA);
const kMint = Color(0xFF9FE5E2);
const kProgress = Color(0xFF67AFAC);
const kTextSecondary = Color(0xFF6E6E6E);

class ChildGoalDetailsScreen extends StatefulWidget {
  final int childId;
  final String baseUrl;
  final String token;
  final Goal goal;

  const ChildGoalDetailsScreen({
    super.key,
    required this.childId,
    required this.baseUrl,
    required this.token,
    required this.goal,
  });

  @override
  State<ChildGoalDetailsScreen> createState() => _ChildGoalDetailsScreenState();
}

class _ChildGoalDetailsScreenState extends State<ChildGoalDetailsScreen> {
  late GoalsApi _api;
  late Goal _goal;
  bool _busy = false;

  final RegExp _lettersRegex = RegExp(r'^[a-zA-Z\u0621-\u064A\s]+$');

  @override
  void initState() {
    super.initState();
    _api = GoalsApi(widget.baseUrl, widget.token);
    _goal = widget.goal;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkAuthStatus(context);
    });
  }

  Future<void> _refresh() async {
    final fresh = await _api.getGoalById(_goal.goalId);
    if (mounted) setState(() => _goal = fresh);
  }

  // -------------------------------
  // DELETE GOAL
  // -------------------------------
  Future<void> _deleteGoal() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Goal"),
        content: const Text(
          "Are you sure you want to delete this goal?\n"
          "If it contains money, deletion will be blocked.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _busy = true);

    try {
      await _api.deleteGoal(_goal.goalId);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Goal deleted")));

      Navigator.pop(context, true);
    } catch (e) {
      if (e.toString().contains("goal_has_money")) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Goal contains money. Move the balance out first."),
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("$e")));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // -------------------------------
  // EDIT GOAL
  // -------------------------------
  Future<void> _editGoal() async {
    final nameCtrl = TextEditingController(text: _goal.goalName);
    final descCtrl = TextEditingController(text: _goal.description);
    final targetCtrl = TextEditingController(
      text: _goal.targetAmount.toStringAsFixed(2),
    );

    final formKey = GlobalKey<FormState>();

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
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
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Edit Goal",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 14),

              // Name
              _fieldLabel("Goal name"),
              TextFormField(
                controller: nameCtrl,
                decoration: _fieldDeco(),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return "Enter name";
                  if (!_lettersRegex.hasMatch(v.trim())) return "Letters only";
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Description
              _fieldLabel("Description"),
              TextFormField(
                controller: descCtrl,
                maxLines: 3,
                decoration: _fieldDeco(),
              ),
              const SizedBox(height: 12),

              // Target
              _fieldLabel("Target amount"),
              TextFormField(
                controller: targetCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: _fieldDeco(),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return "Enter target";
                  final d = double.tryParse(v.trim());
                  if (d == null || d <= 0) return "Invalid amount";
                  if (d < _goal.goalBalance)
                    return "Target must be ≥ saved amount";
                  return null;
                },
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text("Cancel"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          Navigator.pop(ctx, true);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kProgress,
                      ),
                      child: const Text("Save"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (saved != true) return;

    setState(() => _busy = true);

    try {
      await _api.updateGoal(
        goalId: _goal.goalId,
        goalName: nameCtrl.text.trim(),
        targetAmount: double.parse(targetCtrl.text.trim()),
        description: descCtrl.text.trim(),
      );

      await _refresh();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // -------------------------------
  // MOVE IN / MOVE OUT
  // -------------------------------
  Future<void> _moveSheet({required bool isAdd}) async {
    final ctrl = TextEditingController();

    final amount = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
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
              isAdd ? "Move In (Saving → Goal)" : "Move Out (Goal → Saving)",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: _fieldDeco(hint: "Amount"),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: () {
                final v = double.tryParse(ctrl.text.trim());
                if (v != null && v > 0) Navigator.pop(ctx, v);
              },
              style: ElevatedButton.styleFrom(backgroundColor: kProgress),
              child: const Text("Confirm"),
            ),
          ],
        ),
      ),
    );

    if (amount == null) return;
    setState(() => _busy = true);

    try {
      if (isAdd) {
        await _api.addMoneyToGoal(
          childId: widget.childId,
          goalId: _goal.goalId,
          amount: amount,
        );
      } else {
        await _api.moveMoneyFromGoal(
          childId: widget.childId,
          goalId: _goal.goalId,
          amount: amount,
        );
      }

      await _refresh();

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(isAdd ? "Moved in" : "Moved out")));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // -------------------------------
  // UI
  // -------------------------------

  @override
  Widget build(BuildContext context) {
    final pct = (_goal.progress * 100).clamp(0, 100).toStringAsFixed(0);
    final remaining = (_goal.targetAmount - _goal.goalBalance).clamp(
      0,
      double.infinity,
    );

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: BackButton(color: Colors.black87),
        title: const Text(
          "Savings Goal",
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black87),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.black87),
            onPressed: _busy ? null : _editGoal,
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _busy ? null : _deleteGoal,
          ),
        ],
      ),
      body: _busy
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _ProgressRing(percent: _goal.progress, label: "$pct%"),
                  const SizedBox(height: 12),

                  if (_goal.description.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        _goal.description,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: kTextSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                  const SizedBox(height: 10),

                  Text(
                    _goal.goalName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 6),
                  Text(
                    "﷼ ${_goal.goalBalance.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    "Target: ﷼ ${_goal.targetAmount.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 13,
                      color: kTextSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    "Remaining: ﷼ ${remaining.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 13,
                      color: kTextSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          text: "Move Out\n(Goal → Saving)",
                          bg: kMint,
                          textColor: Colors.black,
                          onTap: () => _moveSheet(isAdd: false),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionButton(
                          text: "Move In\n(Saving → Goal)",
                          bg: kProgress,
                          textColor: Colors.white,
                          onTap: () => _moveSheet(isAdd: true),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  _DetailsCard(goal: _goal),
                ],
              ),
            ),
    );
  }
}

Widget _fieldLabel(String text) => Padding(
  padding: const EdgeInsets.only(bottom: 6),
  child: Text(
    text,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: kTextSecondary,
    ),
  ),
);

InputDecoration _fieldDeco({String? hint}) => InputDecoration(
  hintText: hint,
  filled: true,
  fillColor: Colors.white,
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide.none,
  ),
  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
);

// --------------------------------------------------------
// UI Widgets
// --------------------------------------------------------

class _ProgressRing extends StatelessWidget {
  final double percent;
  final String label;

  const _ProgressRing({required this.percent, required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      height: 170,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 170,
            height: 170,
            child: CircularProgressIndicator(
              value: percent.clamp(0, 1),
              strokeWidth: 12,
              backgroundColor: const Color(0xFFE8EEF0),
              valueColor: const AlwaysStoppedAnimation(kProgress),
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String text;
  final Color bg;
  final Color textColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.text,
    required this.bg,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  final Goal goal;
  const _DetailsCard({required this.goal});

  @override
  Widget build(BuildContext context) {
    final remaining = (goal.targetAmount - goal.goalBalance).clamp(
      0,
      double.infinity,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Goal details",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          _row("Status", goal.goalStatus),
          _row("Saved", "﷼ ${goal.goalBalance.toStringAsFixed(2)}"),
          _row("Target", "﷼ ${goal.targetAmount.toStringAsFixed(2)}"),
          _row("Remaining", "﷼ ${remaining.toStringAsFixed(2)}"),
        ],
      ),
    );
  }

  Widget _row(String k, String v) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        Expanded(
          child: Text(
            k,
            style: const TextStyle(
              fontSize: 13,
              color: kTextSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          v,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
      ],
    ),
  );
}
