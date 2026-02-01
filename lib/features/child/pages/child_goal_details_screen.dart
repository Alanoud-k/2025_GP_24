// lib/screens/child_goal_details_screen.dart
import 'package:flutter/material.dart';

import '../models/goal_model.dart';
import '../services/goals_api.dart';
import 'package:my_app/utils/check_auth.dart';

const kBg = Color(0xFFF7F8FA);
const kMint = Color(0xFF9FE5E2);
const kMintSoft = Color(0xFFE6FBF9);
const kProgress = Color(0xFF67AFAC);
const kTextSecondary = Color(0xFF6E6E6E);
const kHassalaGreen = Color(0xFF37C4BE);

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
  bool _changed = false;

  // Letters only (Arabic + English + spaces)
  final RegExp _lettersRegex = RegExp(r'^[a-zA-Z\u0621-\u064A\s]+$');

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkAuthStatus(context);
    });

    _api = GoalsApi(widget.baseUrl, widget.token);
    _goal = widget.goal;
    _refreshGoal();
  }

  String _prettyError(String raw) {
    final msg = raw.replaceFirst('Exception: ', '');
    if (msg.contains('insufficient_saving')) {
      return 'Not enough Saving balance.';
    }
    if (msg.contains('insufficient_goal_balance')) {
      return 'Not enough money in this goal.';
    }
    if (msg.contains('over_target')) {
      return 'You cannot exceed the goal target amount.';
    }
    if (msg.contains('goal_completed_no_more_contributions')) {
      return 'This goal is completed and locked. You cannot add more money.';
    }
    if (msg.contains('goal_completed_no_move_out')) {
      return 'Completed goals cannot move money back to Saving.';
    }
    if (msg.contains('goal_has_money')) {
      return 'You must move all money back to Saving before deleting this goal.';
    }
    if (msg.contains('nothing_to_redeem')) {
      return 'There is nothing left to move to Spending.';
    }
    if (msg.contains('not_completed')) {
      return 'You can only redeem completed goals.';
    }
    if (msg.contains('goal_not_found')) {
      return 'This goal no longer exists.';
    }
    return msg;
  }

  Future<void> _refreshGoal() async {
    try {
      final fresh = await _api.getGoalById(_goal.goalId);
      if (!mounted) return;
      setState(() => _goal = fresh);
    } catch (_) {
      // ignore
    }
  }

  /* ---------------------- Edit goal sheet ------------------------ */

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
                  if (v == null || v.trim().isEmpty) return null;
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
                    return "Target must be ≥ saved amount";
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
      _changed = true;
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Goal updated")));
    } catch (e) {
      if (!mounted) return;
      final msg = _prettyError(e.toString());
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /* ---------------- Move money in/out of goal -------------------- */

  Future<void> _openAmountSheet({required bool isAdd}) async {
    if (_goal.isCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "This goal is completed and cannot be changed. You can redeem it instead.",
          ),
        ),
      );
      return;
    }

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
              textAlign: TextAlign.center,
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
      _changed = true;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAdd ? "Money added to goal" : "Money moved to Saving",
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = _prettyError(e.toString());
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

      if (e.toString().contains("401")) {
        await checkAuthStatus(context);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /* ----------------- Redeem completed goal → Spending ------------ */

  Future<void> _redeemGoal() async {
    setState(() => _busy = true);
    try {
      await _api.redeemGoal(childId: widget.childId, goalId: _goal.goalId);
      await _refreshGoal();
      _changed = true;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Goal money moved to Spending")),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = _prettyError(e.toString());
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /* -------------------------- Delete goal ------------------------ */

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete goal"),
        content: const Text(
          "Are you sure you want to delete this goal?\n\n"
          "If there is any money saved inside it, you must move it back to Saving first.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      await _api.deleteGoal(_goal.goalId);
      if (!mounted) return;

      _changed = true;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Goal deleted")));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      final msg = _prettyError(e.toString());
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /* -------------------------- Build ------------------------------ */

  @override
  Widget build(BuildContext context) {
    final pct = (_goal.progress * 100).clamp(0, 100).toStringAsFixed(0);
    final remaining = (_goal.targetAmount - _goal.goalBalance).clamp(0, 999999);
    final isAchieved = _goal.isCompleted;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _changed);
        return false;
      },
      child: Scaffold(
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
            onPressed: () => Navigator.pop(context, _changed),
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
                      // Header card with ring + title + status
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 18,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            _ProgressRing(
                              percent: _goal.progress,
                              label: "$pct%",
                              completed: isAchieved,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _goal.goalName,
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                      if (isAchieved)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green.shade100,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
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
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        "Saved:",
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      SarAmount(
                                        amount: _goal.goalBalance,
                                        decimals: 2,
                                        iconSize: 13,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        "Target:",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: kTextSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      SarAmount(
                                        amount: _goal.targetAmount,
                                        decimals: 2,
                                        iconSize: 12,
                                        iconColor: kTextSecondary,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: kTextSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        "Remaining:",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: kTextSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      SarAmount(
                                        amount: remaining.toDouble(),
                                        decimals: 2,
                                        iconSize: 12,
                                        iconColor: kTextSecondary,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: kTextSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      if (_goal.description.trim().isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: kMintSoft,
                            borderRadius: BorderRadius.circular(18),
                          ),
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

                      const SizedBox(height: 18),

                      // Action area
                      if (!isAchieved) ...[
                        Row(
                          children: [
                            Expanded(
                              child: _ActionButton(
                                text: "Move Out\n(Goal → Saving)",
                                bg: Colors.white,
                                borderColor: kHassalaGreen.withOpacity(0.55),
                                textColor: Colors.black87,
                                onTap: () => _openAmountSheet(isAdd: false),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _ActionButton(
                                text: "Move In\n(Saving → Goal)",
                                bg: kHassalaGreen,
                                textColor: Colors.white,
                                onTap: () => _openAmountSheet(isAdd: true),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Goal completed",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _goal.goalBalance > 0
                                    ? "You can move the collected amount to your Spending balance."
                                    : "This goal has already been redeemed to Spending.",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: kTextSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (_goal.goalBalance > 0) ...[
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  height: 46,
                                  child: ElevatedButton.icon(
                                    onPressed: _redeemGoal,
                                    icon: const Icon(Icons.card_giftcard),
                                    label: const Text(
                                      "Move to Spending",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 18),

                      _DetailsCard(goal: _goal),

                      const SizedBox(height: 18),

                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: OutlinedButton.icon(
                          onPressed: _busy ? null : _confirmDelete,
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          label: const Text(
                            "Delete goal",
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

/* ---------------- Shared UI helpers ---------------- */

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
  final bool completed;

  const _ProgressRing({
    required this.percent,
    required this.label,
    required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    final color = completed ? Colors.green : kProgress;

    return SizedBox(
      width: 90,
      height: 90,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 90,
            height: 90,
            child: CircularProgressIndicator(
              value: percent.clamp(0, 1),
              strokeWidth: 8,
              backgroundColor: const Color(0xFFE8EEF0),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
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
  final Color? borderColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.text,
    required this.bg,
    required this.textColor,
    this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasBorder = borderColor != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: hasBorder ? Border.all(color: borderColor!) : null,
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13,
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
          _detailRow(
            "Status",
            Text(
              goal.goalStatus,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
          ),
          _detailRow(
            "Saved",
            SarAmount(
              amount: goal.goalBalance,
              decimals: 2,
              iconSize: 12,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
          ),
          _detailRow(
            "Target",
            SarAmount(
              amount: goal.targetAmount,
              decimals: 2,
              iconSize: 12,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
          ),
          _detailRow(
            "Remaining",
            SarAmount(
              amount: remaining.toDouble(),
              decimals: 2,
              iconSize: 12,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String k, Widget value) {
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
          value,
        ],
      ),
    );
  }
}

class SarAmount extends StatelessWidget {
  final double amount;
  final TextStyle style;
  final double iconSize;
  final Color? iconColor;
  final int decimals;

  const SarAmount({
    super.key,
    required this.amount,
    required this.style,
    this.iconSize = 14,
    this.iconColor,
    this.decimals = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/icons/Sar.png',
          width: iconSize,
          height: iconSize,
          color: iconColor ?? style.color,
        ),
        const SizedBox(width: 4),
        Text(amount.toStringAsFixed(decimals), style: style),
      ],
    );
  }
}
