import 'package:flutter/material.dart';
import '../models/goal_model.dart';
import '../services/goals_api.dart';
import 'package:my_app/utils/check_auth.dart'; // <<--- ADDED

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

  // Letters only (Arabic + English + spaces)
  final RegExp _lettersRegex = RegExp(r'^[a-zA-Z\u0621-\u064A\s]+$');

  @override
  void initState() {
    super.initState();
    _api = GoalsApi(widget.baseUrl, widget.token);
    _goal = widget.goal;
  }

  Future<void> _refreshGoal() async {
    try {
      final fresh = await _api.getGoalById(_goal.goalId);
      if (!mounted) return;
      setState(() => _goal = fresh);
    } catch (_) {}
  }

  // Edit goal bottom sheet
  Future<void> _openEditSheet() async {
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  "Edit goal",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 14),

              const Text(
                "Goal name",
                style: TextStyle(
                  fontSize: 13,
                  color: kTextSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: nameCtrl,
                decoration: _fieldDeco(),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return "Enter goal name";
                  if (!_lettersRegex.hasMatch(v.trim())) return "Letters only";
                  return null;
                },
              ),

              const SizedBox(height: 12),

              const Text(
                "Description",
                style: TextStyle(
                  fontSize: 13,
                  color: kTextSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: descCtrl,
                maxLines: 3,
                decoration: _fieldDeco(),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null; // optional
                  if (!_lettersRegex.hasMatch(v.trim())) return "Letters only";
                  if (v.trim().length > 200) return "Max 200 characters";
                  return null;
                },
              ),

              const SizedBox(height: 12),

              const Text(
                "Target amount",
                style: TextStyle(
                  fontSize: 13,
                  color: kTextSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: targetCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: _fieldDeco(),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return "Enter target";
                  final d = double.tryParse(v.trim());
                  if (d == null || d <= 0) return "Numbers only";
                  if (d < _goal.goalBalance) {
                    return "Target must be >= saved";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: ElevatedButton(
                        onPressed: () {
                          if (!formKey.currentState!.validate()) return;
                          Navigator.pop(ctx, true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kProgress,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Save",
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
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

      await _refreshGoal();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Goal updated")));
      Navigator.pop(context, true); // refresh parent list
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Update failed: $e")));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openAmountSheet({required bool isAdd}) async {
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
              isAdd ? "Add money" : "Move money",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
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
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
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

      await _refreshGoal();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(isAdd ? "Added" : "Moved")));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed: $e")));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pct = (_goal.progress * 100).clamp(0, 100).toStringAsFixed(0);
    final remaining = (_goal.targetAmount - _goal.goalBalance).clamp(0, 999999);

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
          onPressed: () => Navigator.pop(context, false),
        ),
        title: const Text(
          "Savings goal",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _busy ? null : _openEditSheet,
            icon: const Icon(Icons.edit, color: Colors.black87, size: 20),
          ),
          const SizedBox(width: 6),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFEDEDED)),
        ),
      ),
      body: SafeArea(
        child: _busy
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                child: Column(
                  children: [
                    _ProgressRing(percent: _goal.progress, label: "$pct%"),

                    const SizedBox(height: 10),

                    // Description under ring
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

                    const SizedBox(height: 12),

                    Text(
                      _goal.goalName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      "﷼ ${_goal.goalBalance.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Target: ﷼ ${_goal.targetAmount.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 13,
                        color: kTextSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Remaining: ﷼ ${remaining.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 13,
                        color: kTextSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 18),

                    Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            text: "Move money",
                            bg: kMint,
                            textColor: Colors.black87,
                            onTap: () => _openAmountSheet(isAdd: false),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionButton(
                            text: "Add money",
                            bg: kProgress,
                            textColor: Colors.white,
                            onTap: () => _openAmountSheet(isAdd: true),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    _DetailsCard(goal: _goal),
                  ],
                ),
              ),
      ),
    );
  }
}

// Field decoration
InputDecoration _fieldDeco() => InputDecoration(
  filled: true,
  fillColor: Colors.white,
  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide.none,
  ),
);

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
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            color: textColor,
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
    final remaining = (goal.targetAmount - goal.goalBalance).clamp(0, 999999);

    return Container(
      width: double.infinity,
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
          _detailRow("Status", goal.goalStatus),
          _detailRow("Saved", "﷼ ${goal.goalBalance.toStringAsFixed(2)}"),
          _detailRow("Target", "﷼ ${goal.targetAmount.toStringAsFixed(2)}"),
          _detailRow("Remaining", "﷼ ${remaining.toStringAsFixed(2)}"),
        ],
      ),
    );
  }

  Widget _detailRow(String k, String v) {
    return Padding(
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
}
