// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:my_app/l10n/app_localizations.dart';

// import '../services/goals_api.dart';
// import '../models/goal_model.dart';
// import 'child_add_goal_screen.dart';
// import 'child_goal_details_screen.dart';
// import 'package:my_app/utils/check_auth.dart';

// /// ====== COLORS ======
// const kBg = Color(0xFFF7F8FA);
// const kMint = Color(0xFF9FE5E2);
// const kMintSoft = Color(0xFFE6FBF9);
// const kProgress = Color(0xFF67AFAC);
// const kTextSecondary = Color(0xFF6E6E6E);
// const kHassalaGreen = Color(0xFF37C4BE);

// class ChildGoalsScreen extends StatefulWidget {
//   final int childId;
//   final String baseUrl;
//   final String token;

//   const ChildGoalsScreen({
//     super.key,
//     required this.childId,
//     required this.baseUrl,
//     required this.token,
//   });

//   @override
//   State<ChildGoalsScreen> createState() => _ChildGoalsScreenState();
// }

// class _ChildGoalsScreenState extends State<ChildGoalsScreen> {
//   late GoalsApi _api;

//   bool _loading = true;
//   List<Goal> _goals = [];
//   List<Map<String, dynamic>> _goalInsights = [];
//   double _savingBalance = 0.0;
//   double _spendingBalance = 0.0;

//   Map<String, String> get _headers => {
//     "Authorization": "Bearer ${widget.token}",
//     "Content-Type": "application/json",
//   };

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       checkAuthStatus(context);
//     });

//     _api = GoalsApi(widget.baseUrl, widget.token);
//     _bootstrap();
//   }

//   Future<void> _bootstrap() async {
//     if (!mounted) return;
//     setState(() => _loading = true);

//     try {
//       final goals = await _api.listGoals(widget.childId);
//       final balances = await _fetchBalances();
//       await _fetchGoalInsights();

//       if (!mounted) return;
//       setState(() {
//         _goals = goals;
//         _savingBalance = balances['saving'] ?? 0.0;
//         _spendingBalance = balances['spending'] ?? 0.0;
//       });
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(AppLocalizations.of(context)!.failedToLoadGoals(e.toString())))
//       );
//     } finally {
//       if (mounted) setState(() => _loading = false);
//     }
//   }

//   Future<Map<String, double>> _fetchBalances() async {
//     final url = Uri.parse("${widget.baseUrl}/api/children/${widget.childId}/wallet/balances");
//     final res = await http.get(url, headers: _headers);

//     if (res.statusCode == 401) {
//       await checkAuthStatus(context);
//       return {"saving": 0.0, "spending": 0.0};
//     }

//     if (res.statusCode != 200) return {"saving": 0.0, "spending": 0.0};

//     final data = jsonDecode(res.body);

//     double parse(dynamic v) {
//       if (v == null) return 0.0;
//       if (v is num) return v.toDouble();
//       return double.tryParse(v.toString()) ?? 0.0;
//     }

//     final saving = data["saving"] ?? data["savingBalance"] ?? data["saving_balance"] ?? data["savingsBalance"] ?? data["savingAmount"] ?? data["saving_account"] ?? 0.0;
//     final spending = data["spending"] ?? data["spendingBalance"] ?? data["spending_balance"] ?? data["spendBalance"] ?? data["spendingAmount"] ?? data["spending_account"] ?? 0.0;

//     return {"saving": parse(saving), "spending": parse(spending)};
//   }

//   void _showErrorBar(String msg) {
//     if (!mounted) return;
//     final messenger = ScaffoldMessenger.of(context);
//     messenger.clearSnackBars();
//     messenger.showSnackBar(
//       SnackBar(
//         behavior: SnackBarBehavior.floating,
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         duration: const Duration(seconds: 4),
//         content: Container(
//           padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
//           decoration: BoxDecoration(
//             color: const Color(0xFFE74C3C),
//             borderRadius: BorderRadius.circular(16),
//             boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 10, offset: const Offset(0, 6))],
//           ),
//           child: Row(
//             children: [
//               const Icon(Icons.error_outline_rounded, color: Colors.white),
//               const SizedBox(width: 10),
//               Expanded(child: Text(msg, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   void _showSuccessBar(String msg) {
//     if (!mounted) return;
//     final messenger = ScaffoldMessenger.of(context);
//     messenger.clearSnackBars();
//     messenger.showSnackBar(
//       SnackBar(
//         behavior: SnackBarBehavior.floating,
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         duration: const Duration(seconds: 3),
//         content: Container(
//           padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
//           decoration: BoxDecoration(
//             color: const Color(0xFF2EA49E),
//             borderRadius: BorderRadius.circular(16),
//             boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 10, offset: const Offset(0, 6))],
//           ),
//           child: Row(
//             children: [
//               const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
//               const SizedBox(width: 10),
//               Expanded(child: Text(msg, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Future<void> _fetchGoalInsights() async {
//     final url = Uri.parse("${widget.baseUrl}/api/insights/goals/${widget.childId}");
//     try {
//       final res = await http.get(url, headers: _headers);
//       if (res.statusCode == 200) {
//         final data = jsonDecode(res.body);
//         if (!mounted) return;
//         setState(() { _goalInsights = List<Map<String, dynamic>>.from(data); });
//       }
//     } catch (e) {
//       debugPrint("Goal insight error: $e");
//     }
//   }

//   Future<void> _moveAmount(String type, AppLocalizations l10n) async {
//     final ctrl = TextEditingController();

//     final amount = await showModalBottomSheet<double>(
//       context: context,
//       isScrollControlled: true,
//       builder: (ctx) => Padding(
//         padding: EdgeInsetsDirectional.only(
//           start: 18,
//           end: 18,
//           bottom: MediaQuery.of(ctx).viewInsets.bottom + 18,
//           top: 18,
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(
//               type == "move-in" ? l10n.moveInSpendingToSaving : l10n.moveOutSavingToSpending,
//               style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 14),
//             TextField(
//               controller: ctrl,
//               keyboardType: const TextInputType.numberWithOptions(decimal: true),
//               decoration: InputDecoration(
//                 hintText: l10n.amountStr,
//                 filled: true,
//                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
//               ),
//             ),
//             const SizedBox(height: 14),
//             ElevatedButton(
//               onPressed: () {
//                 final val = double.tryParse(ctrl.text.trim());
//                 if (val != null && val > 0) Navigator.pop(ctx, val);
//               },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: kProgress,
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
//               ),
//               child: Text(l10n.confirmBtn, style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
//             ),
//           ],
//         ),
//       ),
//     );

//     if (amount == null) return;
//     final available = (type == "move-in") ? _spendingBalance : _savingBalance;

//     if (amount > available) {
//       _showErrorBar(l10n.notEnoughBalanceToMove);
//       return;
//     }

//     final url = Uri.parse("${widget.baseUrl}/api/saving/$type");
//     try {
//       final res = await http.post(
//         url,
//         headers: _headers,
//         body: jsonEncode({"childId": widget.childId, "amount": amount}),
//       );

//       if (res.statusCode == 401) {
//         await checkAuthStatus(context);
//         return;
//       }

//       if (res.statusCode < 200 || res.statusCode > 299) {
//         _showErrorBar(l10n.moveFailed);
//         return;
//       }

//       _showSuccessBar(l10n.movedSuccessfully);
//       await _bootstrap();
//     } catch (_) {
//       _showErrorBar(l10n.networkError);
//     }
//   }

//   Future<void> _openAddGoal() async {
//     final created = await Navigator.push(context, MaterialPageRoute(builder: (_) => ChildAddGoalScreen(childId: widget.childId, baseUrl: widget.baseUrl, token: widget.token)));
//     if (created == true) _bootstrap();
//   }

//   Future<void> _openGoalDetails(Goal g) async {
//     final changed = await Navigator.push(context, MaterialPageRoute(builder: (_) => ChildGoalDetailsScreen(childId: widget.childId, baseUrl: widget.baseUrl, token: widget.token, goal: g)));
//     if (changed == true) _bootstrap();
//   }

//   Future<void> _redeemCompleted(Goal goal, AppLocalizations l10n) async {
//     try {
//       await _api.redeemGoal(childId: widget.childId, goalId: goal.goalId);
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.goalMoneyMovedToSpending)));
//       _bootstrap();
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${l10n.errorPrefix}: $e")));
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final l10n = AppLocalizations.of(context)!;
//     return Scaffold(
//       backgroundColor: kBg,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         centerTitle: true,
//         leading: const BackButton(color: Colors.black87),
//         title: Text(l10n.goals, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black87)),
//         bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1, color: Color(0xFFEDEDED))),
//       ),
//       body: _loading
//           ? const Center(child: CircularProgressIndicator())
//           : RefreshIndicator(
//               onRefresh: _bootstrap,
//               child: SingleChildScrollView(
//                 physics: const AlwaysScrollableScrollPhysics(),
//                 child: Column(
//                   children: [
//                     const SizedBox(height: 18),
//                     Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 16),
//                       child: _SavingSpendingPill(
//                         saving: _savingBalance,
//                         spending: _spendingBalance,
//                         onMoveIn: () => _moveAmount("move-in", l10n),
//                         onMoveOut: () => _moveAmount("move-out", l10n),
//                       ),
//                     ),
//                     const SizedBox(height: 22),
//                     _GoalInsights(insights: _goalInsights),
//                     const SizedBox(height: 20),
//                     InkWell(
//                       borderRadius: BorderRadius.circular(40),
//                       onTap: _openAddGoal,
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           const CircleAvatar(radius: 22, backgroundColor: kHassalaGreen, child: Icon(Icons.add, size: 24, color: Colors.white)),
//                           const SizedBox(width: 10),
//                           Text(l10n.addNewGoal, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87)),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 20),
//                     Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 16),
//                       child: _GoalsList(
//                         goals: _goals,
//                         openActiveDetails: _openGoalDetails,
//                         redeemCompleted: (g) => _redeemCompleted(g, l10n),
//                       ),
//                     ),
//                     const SizedBox(height: 40),
//                   ],
//                 ),
//               ),
//             ),
//     );
//   }
// }

// class _SavingSpendingPill extends StatelessWidget {
//   final double saving;
//   final double spending;
//   final VoidCallback onMoveIn;
//   final VoidCallback onMoveOut;

//   const _SavingSpendingPill({required this.saving, required this.spending, required this.onMoveIn, required this.onMoveOut});

//   @override
//   Widget build(BuildContext context) {
//     final l10n = AppLocalizations.of(context)!;
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
//       decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)]),
//       child: Column(
//         children: [
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
//             decoration: BoxDecoration(color: kMintSoft, borderRadius: BorderRadius.circular(999)),
//             child: Row(
//               children: [
//                 _pillSegment(l10n.savingTab, saving, kHassalaGreen, Icons.account_balance_wallet_rounded),
//                 Container(width: 1, height: 24, margin: const EdgeInsets.symmetric(horizontal: 8), color: Colors.teal.withOpacity(0.2)),
//                 _pillSegment(l10n.spendingTab, spending, Colors.orange.shade700, Icons.shopping_bag_outlined),
//               ],
//             ),
//           ),
//           const SizedBox(height: 12),
//           Row(
//             children: [
//               Expanded(
//                 child: OutlinedButton(
//                   onPressed: onMoveIn,
//                   style: OutlinedButton.styleFrom(side: BorderSide(color: kHassalaGreen.withOpacity(0.5)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
//                   child: Text(l10n.moveInSpSv, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
//                 ),
//               ),
//               const SizedBox(width: 10),
//               Expanded(
//                 child: ElevatedButton(
//                   onPressed: onMoveOut,
//                   style: ElevatedButton.styleFrom(backgroundColor: kHassalaGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
//                   child: Text(l10n.moveOutSvSp, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white), textAlign: TextAlign.center),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _pillSegment(String label, double amount, Color color, IconData icon) {
//     return Expanded(
//       child: Row(
//         children: [
//           Container(width: 22, height: 22, decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(999)), child: Icon(icon, size: 19, color: color)),
//           const SizedBox(width: 6),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
//               SarAmount(amount: amount, decimals: 2, iconSize: 13, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.black87)),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _GoalsList extends StatelessWidget {
//   final List<Goal> goals;
//   final void Function(Goal) openActiveDetails;
//   final Future<void> Function(Goal) redeemCompleted;

//   const _GoalsList({required this.goals, required this.openActiveDetails, required this.redeemCompleted});

//   @override
//   Widget build(BuildContext context) {
//     final l10n = AppLocalizations.of(context)!;
//     final active = goals.where((g) => !g.isCompleted).toList();
//     final completed = goals.where((g) => g.isCompleted).toList();

//     return Container(
//       padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
//       decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)]),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(l10n.activeGoals, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.black87)),
//           const SizedBox(height: 10),
//           if (active.isEmpty)
//             Text(l10n.noActiveGoals, style: const TextStyle(color: kTextSecondary, fontSize: 13, fontWeight: FontWeight.w500))
//           else
//             ...active.map((g) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _ActiveGoalCard(goal: g, onTap: () => openActiveDetails(g)))),

//           if (completed.isNotEmpty) ...[
//             const SizedBox(height: 22),
//             Text(l10n.completedGoals, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.black87)),
//             const SizedBox(height: 10),
//             ...completed.map((g) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _CompletedGoalCard(goal: g, onRedeem: redeemCompleted))),
//           ],
//         ],
//       ),
//     );
//   }
// }

// class _ActiveGoalCard extends StatelessWidget {
//   final Goal goal;
//   final VoidCallback onTap;

//   const _ActiveGoalCard({required this.goal, required this.onTap});

//   @override
//   Widget build(BuildContext context) {
//     final l10n = AppLocalizations.of(context)!;
//     final remaining = (goal.targetAmount - goal.goalBalance).clamp(0, 999999);
//     final pct = (goal.progress * 100).clamp(0, 100).toStringAsFixed(0);

//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(18),
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
//         decoration: BoxDecoration(color: kMintSoft, borderRadius: BorderRadius.circular(18)),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Expanded(child: Text(goal.goalName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.black87))),
//                 Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Text(l10n.targetLabel, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kTextSecondary)),
//                     const SizedBox(width: 6),
//                     SarAmount(amount: goal.targetAmount, decimals: 0, iconSize: 12, iconColor: kTextSecondary, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kTextSecondary)),
//                   ],
//                 ),
//               ],
//             ),
//             const SizedBox(height: 6),
//             Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Text(l10n.remainingLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: kTextSecondary)),
//                 const SizedBox(width: 6),
//                 SarAmount(amount: remaining.toDouble(), decimals: 0, iconSize: 12, iconColor: kTextSecondary, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: kTextSecondary)),
//               ],
//             ),
//             const SizedBox(height: 10),
//             Row(
//               children: [
//                 Expanded(
//                   child: ClipRRect(
//                     borderRadius: BorderRadius.circular(999),
//                     child: LinearProgressIndicator(value: goal.progress, minHeight: 6, backgroundColor: Colors.white, valueColor: const AlwaysStoppedAnimation(kProgress)),
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 Text("$pct%", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black87)),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _CompletedGoalCard extends StatelessWidget {
//   final Goal goal;
//   final Future<void> Function(Goal goal) onRedeem;

//   const _CompletedGoalCard({required this.goal, required this.onRedeem});

//   @override
//   Widget build(BuildContext context) {
//     final l10n = AppLocalizations.of(context)!;
//     final canRedeem = goal.goalBalance > 0;

//     return Container(
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(color: const Color(0xFFF0F1F4), borderRadius: BorderRadius.circular(16)),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Expanded(child: Text(goal.goalName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.black87))),
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                 decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(12)),
//                 child: Text(l10n.completed, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.green)),
//               ),
//             ],
//           ),
//           const SizedBox(height: 8),
//           Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text(l10n.targetLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: kTextSecondary)),
//               const SizedBox(width: 6),
//               SarAmount(amount: goal.targetAmount, decimals: 0, iconSize: 12, iconColor: kTextSecondary, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: kTextSecondary)),
//             ],
//           ),
//           if (canRedeem) ...[
//             const SizedBox(height: 12),
//             SizedBox(
//               width: double.infinity,
//               height: 40,
//               child: ElevatedButton(
//                 onPressed: () => onRedeem(goal),
//                 style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
//                 child: Text(l10n.moveToSpending, style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }
// }

// class SarAmount extends StatelessWidget {
//   final double amount;
//   final TextStyle style;
//   final double iconSize;
//   final Color? iconColor;
//   final int decimals;

//   const SarAmount({
//     super.key,
//     required this.amount,
//     required this.style,
//     this.iconSize = 14,
//     this.iconColor,
//     this.decimals = 2,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Image.asset(
//           'assets/icons/Sar.png',
//           width: iconSize,
//           height: iconSize,
//           color: iconColor ?? style.color,
//         ),
//         const SizedBox(width: 4),
//         Text(amount.toStringAsFixed(decimals), style: style),
//       ],
//     );
//   }
// }

// class _GoalInsights extends StatefulWidget {
//   final List<Map<String, dynamic>> insights;
//   const _GoalInsights({required this.insights});

//   @override
//   State<_GoalInsights> createState() => _GoalInsightsState();
// }

// class _GoalInsightsState extends State<_GoalInsights> {
//   int _currentPage = 0;

//   final Map<String, Map<String, dynamic>> insightStyles = {
//     "goal-start": {"colors": [Color(0xFF42A5F5), Color(0xFF90CAF9)], "icon": Icons.flag},
//     "goal-progress": {"colors": [Color(0xFF5C6BC0), Color(0xFF9FA8DA)], "icon": Icons.trending_up},
//     "goal-close": {"colors": [Color(0xFFFFA726), Color(0xFFFFCC80)], "icon": Icons.emoji_events},
//     "empty": {"colors": [Color(0xFFB0BEC5), Color(0xFFECEFF1)], "icon": Icons.info_outline},
//   };

//   // ✅ دوال الترجمة الخاصة بالرسائل الذكية
//   String _getTranslatedTitle(String titleKey, AppLocalizations l10n) {
//     switch (titleKey) {
//       case "insight_title_start_saving": return l10n.insight_title_start_saving;
//       case "insight_title_almost_there": return l10n.insight_title_almost_there;
//       case "insight_title_goal_progress": return l10n.insight_title_goal_progress;
//       case "No Goals Yet": return l10n.insight_title_no_goals_yet; // 👈 مفتاح جديد
//       default: return titleKey; 
//     }
//   }

//   String _getTranslatedMessage(String msgKey, String? val1, String? val2, AppLocalizations l10n) {
//     String translatedVal1 = val1 ?? "";
//     String translatedVal2 = val2 ?? "";
    
//     switch (msgKey) {
//       case "insight_msg_start_saving": return l10n.insight_msg_start_saving(translatedVal1);
//       case "insight_msg_almost_there": return l10n.insight_msg_almost_there(translatedVal1, translatedVal2);
//       case "insight_msg_goal_progress": return l10n.insight_msg_goal_progress(translatedVal1, translatedVal2);
//       case "Start your first goal and track your progress here.": return l10n.insight_msg_no_goals_yet; // 👈 مفتاح جديد
//       default: return msgKey;
//     }
//   }

//   Widget _buildInsightText(String message) {
//     final parts = message.split("SAR");
//     const textStyle = TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800, height: 1.35);

//     if (parts.length == 1) return Text(message, maxLines: 4, overflow: TextOverflow.ellipsis, style: textStyle);

//     List<InlineSpan> spans = [];
//     for (int i = 0; i < parts.length; i++) {
//       spans.add(TextSpan(text: parts[i], style: textStyle));
//       if (i != parts.length - 1) {
//         spans.add(WidgetSpan(alignment: PlaceholderAlignment.middle, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Image.asset("assets/icons/Sar.png", height: 16, color: Colors.white))));
//       }
//     }
//     return RichText(maxLines: 4, overflow: TextOverflow.ellipsis, text: TextSpan(children: spans));
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (widget.insights.isEmpty) return const SizedBox();
    
//     final l10n = AppLocalizations.of(context)!;
//     final controller = PageController(viewportFraction: 0.88);

//     return Column(
//       children: [
//         SizedBox(
//           height: 150,
//           child: PageView.builder(
//             controller: controller,
//             itemCount: widget.insights.length,
//             onPageChanged: (index) { setState(() => _currentPage = index); },
//             itemBuilder: (context, i) {
//               final insight = widget.insights[i];
//               final type = insight["type"] ?? "empty";
              
//               final titleKey = insight["title"] ?? "";
//               final msgKey = insight["message"] ?? "";
//               final val1 = insight["value"]?.toString();
//               final val2 = insight["extraValue"]?.toString();

//               final translatedTitle = _getTranslatedTitle(titleKey, l10n);
//               final translatedMessage = _getTranslatedMessage(msgKey, val1, val2, l10n);

//               final style = insightStyles[type] ?? insightStyles["empty"]!;
//               final gradient = style["colors"] as List<Color>;
//               final icon = style["icon"] as IconData;

//               return Container(
//                 margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
//                 padding: const EdgeInsets.all(18),
//                 decoration: BoxDecoration(gradient: LinearGradient(colors: gradient, begin: AlignmentDirectional.topStart, end: AlignmentDirectional.bottomEnd), borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: gradient[0].withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 12))]),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(children: [Icon(icon, color: Colors.white), const SizedBox(width: 8), Expanded(child: Text(translatedTitle, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)))]),
//                     const SizedBox(height: 10),
//                     _buildInsightText(translatedMessage),
//                   ],
//                 ),
//               );
//             },
//           ),
//         ),
//         const SizedBox(height: 8),
//         Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: List.generate(widget.insights.length, (index) {
//             final isActive = index == _currentPage;
//             return AnimatedContainer(duration: const Duration(milliseconds: 250), margin: const EdgeInsets.symmetric(horizontal: 4), width: isActive ? 14 : 6, height: 6, decoration: BoxDecoration(color: isActive ? const Color(0xFF37C4BE) : Colors.grey.shade400, borderRadius: BorderRadius.circular(999)));
//           }),
//         ),
//       ],
//     );
//   }
// }

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_app/l10n/app_localizations.dart';

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
  List<Map<String, dynamic>> _goalInsights = [];
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
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final goals = await _api.listGoals(widget.childId);
      final balances = await _fetchBalances();
      await _fetchGoalInsights();

      if (!mounted) return;
      setState(() {
        _goals = goals;
        _savingBalance = balances['saving'] ?? 0.0;
        _spendingBalance = balances['spending'] ?? 0.0;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.failedToLoadGoals(e.toString())))
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<Map<String, double>> _fetchBalances() async {
    final url = Uri.parse("${widget.baseUrl}/api/children/${widget.childId}/wallet/balances");
    final res = await http.get(url, headers: _headers);

    if (res.statusCode == 401) {
      await checkAuthStatus(context);
      return {"saving": 0.0, "spending": 0.0};
    }

    if (res.statusCode != 200) return {"saving": 0.0, "spending": 0.0};

    final data = jsonDecode(res.body);

    double parse(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    final saving = data["saving"] ?? data["savingBalance"] ?? data["saving_balance"] ?? data["savingsBalance"] ?? data["savingAmount"] ?? data["saving_account"] ?? 0.0;
    final spending = data["spending"] ?? data["spendingBalance"] ?? data["spending_balance"] ?? data["spendBalance"] ?? data["spendingAmount"] ?? data["spending_account"] ?? 0.0;

    return {"saving": parse(saving), "spending": parse(spending)};
  }

  void _showErrorBar(String msg) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: const Duration(seconds: 4),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFE74C3C),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 10, offset: const Offset(0, 6))],
          ),
          child: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text(msg, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessBar(String msg) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: const Duration(seconds: 3),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF2EA49E),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 10, offset: const Offset(0, 6))],
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text(msg, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _fetchGoalInsights() async {
    final url = Uri.parse("${widget.baseUrl}/api/insights/goals/${widget.childId}");
    try {
      final res = await http.get(url, headers: _headers);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (!mounted) return;
        setState(() { _goalInsights = List<Map<String, dynamic>>.from(data); });
      }
    } catch (e) {
      debugPrint("Goal insight error: $e");
    }
  }

  Future<void> _moveAmount(String type, AppLocalizations l10n) async {
    final ctrl = TextEditingController();

    final amount = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsetsDirectional.only(
          start: 18,
          end: 18,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 18,
          top: 18,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              type == "move-in" ? l10n.moveInSpendingToSaving : l10n.moveOutSavingToSpending,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: l10n.amountStr,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(l10n.confirmBtn, style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (amount == null) return;
    final available = (type == "move-in") ? _spendingBalance : _savingBalance;

    if (amount > available) {
      _showErrorBar(l10n.notEnoughBalanceToMove);
      return;
    }

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
        _showErrorBar(l10n.moveFailed);
        return;
      }

      _showSuccessBar(l10n.movedSuccessfully);
      await _bootstrap();
    } catch (_) {
      _showErrorBar(l10n.networkError);
    }
  }

  Future<void> _openAddGoal() async {
    final created = await Navigator.push(context, MaterialPageRoute(builder: (_) => ChildAddGoalScreen(childId: widget.childId, baseUrl: widget.baseUrl, token: widget.token)));
    if (created == true) _bootstrap();
  }

  Future<void> _openGoalDetails(Goal g) async {
    final changed = await Navigator.push(context, MaterialPageRoute(builder: (_) => ChildGoalDetailsScreen(childId: widget.childId, baseUrl: widget.baseUrl, token: widget.token, goal: g)));
    if (changed == true) _bootstrap();
  }

  Future<void> _redeemCompleted(Goal goal, AppLocalizations l10n) async {
    try {
      await _api.redeemGoal(childId: widget.childId, goalId: goal.goalId);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.goalMoneyMovedToSpending)));
      _bootstrap();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${l10n.errorPrefix}: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Colors.black87),
        title: Text(l10n.goals, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black87)),
        bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1, color: Color(0xFFEDEDED))),
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
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _SavingSpendingPill(
                        saving: _savingBalance,
                        spending: _spendingBalance,
                        onMoveIn: () => _moveAmount("move-in", l10n),
                        onMoveOut: () => _moveAmount("move-out", l10n),
                      ),
                    ),
                    const SizedBox(height: 22),
                    _GoalInsights(insights: _goalInsights),
                    const SizedBox(height: 20),
                    InkWell(
                      borderRadius: BorderRadius.circular(40),
                      onTap: _openAddGoal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircleAvatar(radius: 22, backgroundColor: kHassalaGreen, child: Icon(Icons.add, size: 24, color: Colors.white)),
                          const SizedBox(width: 10),
                          Text(l10n.addNewGoal, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _GoalsList(
                        goals: _goals,
                        openActiveDetails: _openGoalDetails,
                        redeemCompleted: (g) => _redeemCompleted(g, l10n),
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

class _SavingSpendingPill extends StatelessWidget {
  final double saving;
  final double spending;
  final VoidCallback onMoveIn;
  final VoidCallback onMoveOut;

  const _SavingSpendingPill({required this.saving, required this.spending, required this.onMoveIn, required this.onMoveOut});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)]),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(color: kMintSoft, borderRadius: BorderRadius.circular(999)),
            child: Row(
              children: [
                _pillSegment(l10n.savingTab, saving, kHassalaGreen, Icons.account_balance_wallet_rounded),
                Container(width: 1, height: 24, margin: const EdgeInsets.symmetric(horizontal: 8), color: Colors.teal.withOpacity(0.2)),
                _pillSegment(l10n.spendingTab, spending, Colors.orange.shade700, Icons.shopping_bag_outlined),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onMoveIn,
                  style: OutlinedButton.styleFrom(side: BorderSide(color: kHassalaGreen.withOpacity(0.5)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: Text(l10n.moveInSpSv, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: onMoveOut,
                  style: ElevatedButton.styleFrom(backgroundColor: kHassalaGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: Text(l10n.moveOutSvSp, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white), textAlign: TextAlign.center),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pillSegment(String label, double amount, Color color, IconData icon) {
    return Expanded(
      child: Row(
        children: [
          Container(width: 22, height: 22, decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(999)), child: Icon(icon, size: 19, color: color)),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
              SarAmount(amount: amount, decimals: 2, iconSize: 13, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.black87)),
            ],
          ),
        ],
      ),
    );
  }
}

class _GoalsList extends StatelessWidget {
  final List<Goal> goals;
  final void Function(Goal) openActiveDetails;
  final Future<void> Function(Goal) redeemCompleted;

  const _GoalsList({required this.goals, required this.openActiveDetails, required this.redeemCompleted});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final active = goals.where((g) => !g.isCompleted).toList();
    final completed = goals.where((g) => g.isCompleted).toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.activeGoals, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.black87)),
          const SizedBox(height: 10),
          if (active.isEmpty)
            Text(l10n.noActiveGoals, style: const TextStyle(color: kTextSecondary, fontSize: 13, fontWeight: FontWeight.w500))
          else
            ...active.map((g) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _ActiveGoalCard(goal: g, onTap: () => openActiveDetails(g)))),

          if (completed.isNotEmpty) ...[
            const SizedBox(height: 22),
            Text(l10n.completedGoals, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.black87)),
            const SizedBox(height: 10),
            ...completed.map((g) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _CompletedGoalCard(goal: g, onRedeem: redeemCompleted))),
          ],
        ],
      ),
    );
  }
}

class _ActiveGoalCard extends StatelessWidget {
  final Goal goal;
  final VoidCallback onTap;

  const _ActiveGoalCard({required this.goal, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final remaining = (goal.targetAmount - goal.goalBalance).clamp(0, 999999);
    final pct = (goal.progress * 100).clamp(0, 100).toStringAsFixed(0);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: kMintSoft, borderRadius: BorderRadius.circular(18)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(goal.goalName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.black87))),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.targetLabel, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kTextSecondary)),
                    const SizedBox(width: 6),
                    SarAmount(amount: goal.targetAmount, decimals: 0, iconSize: 12, iconColor: kTextSecondary, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kTextSecondary)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.remainingLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: kTextSecondary)),
                const SizedBox(width: 6),
                SarAmount(amount: remaining.toDouble(), decimals: 0, iconSize: 12, iconColor: kTextSecondary, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: kTextSecondary)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(value: goal.progress, minHeight: 6, backgroundColor: Colors.white, valueColor: const AlwaysStoppedAnimation(kProgress)),
                  ),
                ),
                const SizedBox(width: 8),
                Text("$pct%", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black87)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CompletedGoalCard extends StatelessWidget {
  final Goal goal;
  final Future<void> Function(Goal goal) onRedeem;

  const _CompletedGoalCard({required this.goal, required this.onRedeem});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canRedeem = goal.goalBalance > 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFFF0F1F4), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(goal.goalName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.black87))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(12)),
                child: Text(l10n.completed, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.green)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.targetLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: kTextSecondary)),
              const SizedBox(width: 6),
              SarAmount(amount: goal.targetAmount, decimals: 0, iconSize: 12, iconColor: kTextSecondary, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: kTextSecondary)),
            ],
          ),
          if (canRedeem) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton(
                onPressed: () => onRedeem(goal),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: Text(l10n.moveToSpending, style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
              ),
            ),
          ],
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

class _GoalInsights extends StatefulWidget {
  final List<Map<String, dynamic>> insights;
  const _GoalInsights({required this.insights});

  @override
  State<_GoalInsights> createState() => _GoalInsightsState();
}

class _GoalInsightsState extends State<_GoalInsights> {
  int _currentPage = 0;

  final Map<String, Map<String, dynamic>> insightStyles = {
    "goal-start": {"colors": [Color(0xFF42A5F5), Color(0xFF90CAF9)], "icon": Icons.flag},
    "goal-progress": {"colors": [Color(0xFF5C6BC0), Color(0xFF9FA8DA)], "icon": Icons.trending_up},
    "goal-close": {"colors": [Color(0xFFFFA726), Color(0xFFFFCC80)], "icon": Icons.emoji_events},
    "empty": {"colors": [Color(0xFFB0BEC5), Color(0xFFECEFF1)], "icon": Icons.info_outline},
    "ai-category": {"colors": [Color(0xFF5C6BC0), Color(0xFF9FA8DA)], "icon": Icons.auto_awesome},
  };

  // ✅ دوال الترجمة الخاصة بالرسائل الذكية
  String _getTranslatedTitle(String titleKey, AppLocalizations l10n) {
    switch (titleKey) {
      case "insight_title_start_saving": return l10n.insight_title_start_saving;
      case "insight_title_almost_there": return l10n.insight_title_almost_there;
      case "insight_title_goal_progress": return l10n.insight_title_goal_progress;
      case "insight_title_no_goals_yet": return l10n.insight_title_no_goals_yet;
      case "insight_title_smart_insight": return l10n.insight_title_smart_insight;
      case "No Goals Yet": return l10n.insight_title_no_goals_yet; // Fallback
      default: return titleKey; 
    }
  }

  String _getTranslatedMessage(String msgKey, String? val1, String? val2, AppLocalizations l10n) {
    String translatedVal1 = val1 ?? "";
    String translatedVal2 = val2 ?? "";
    
    switch (msgKey) {
      case "insight_msg_start_saving": return l10n.insight_msg_start_saving(translatedVal1);
      case "insight_msg_almost_there": return l10n.insight_msg_almost_there(translatedVal1, translatedVal2);
      case "insight_msg_goal_progress": return l10n.insight_msg_goal_progress(translatedVal1, translatedVal2);
      case "insight_msg_no_goals_yet": return l10n.insight_msg_no_goals_yet;
      case "Start your first goal and track your progress here.": return l10n.insight_msg_no_goals_yet; // Fallback
      default: return msgKey;
    }
  }

  Widget _buildInsightText(String message) {
  final parts = message.split(RegExp(r'\s*(SAR|ريال|ر\.س)\s*', caseSensitive: false));    const textStyle = TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800, height: 1.35);

    if (parts.length == 1) return Text(message, maxLines: 4, overflow: TextOverflow.ellipsis, style: textStyle);

    List<InlineSpan> spans = [];
    for (int i = 0; i < parts.length; i++) {
      spans.add(TextSpan(text: parts[i], style: textStyle));
      if (i != parts.length - 1) {
        spans.add(WidgetSpan(alignment: PlaceholderAlignment.middle, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Image.asset("assets/icons/Sar.png", height: 16, color: Colors.white))));
      }
    }
    return RichText(maxLines: 4, overflow: TextOverflow.ellipsis, text: TextSpan(children: spans));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.insights.isEmpty) return const SizedBox();
    
    final l10n = AppLocalizations.of(context)!;
    final controller = PageController(viewportFraction: 0.88);

    return Column(
      children: [
        SizedBox(
          height: 150,
          child: PageView.builder(
            controller: controller,
            itemCount: widget.insights.length,
            onPageChanged: (index) { setState(() => _currentPage = index); },
            itemBuilder: (context, i) {
              final insight = widget.insights[i];
              final type = insight["type"] ?? "empty";
              
              final titleKey = insight["title"] ?? "";
              final msgKey = insight["message"] ?? "";
              final val1 = insight["value"]?.toString();
              final val2 = insight["extraValue"]?.toString();

              final translatedTitle = _getTranslatedTitle(titleKey, l10n);
              final translatedMessage = type == "ai-category" 
                  ? msgKey 
                  : _getTranslatedMessage(msgKey, val1, val2, l10n);

              final style = insightStyles[type] ?? insightStyles["empty"]!;
              final gradient = style["colors"] as List<Color>;
              final icon = style["icon"] as IconData;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(gradient: LinearGradient(colors: gradient, begin: AlignmentDirectional.topStart, end: AlignmentDirectional.bottomEnd), borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: gradient[0].withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 12))]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [Icon(icon, color: Colors.white), const SizedBox(width: 8), Expanded(child: Text(translatedTitle, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)))]),
                    const SizedBox(height: 10),
                    _buildInsightText(translatedMessage),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.insights.length, (index) {
            final isActive = index == _currentPage;
            return AnimatedContainer(duration: const Duration(milliseconds: 250), margin: const EdgeInsets.symmetric(horizontal: 4), width: isActive ? 14 : 6, height: 6, decoration: BoxDecoration(color: isActive ? const Color(0xFF37C4BE) : Colors.grey.shade400, borderRadius: BorderRadius.circular(999)));
          }),
        ),
      ],
    );
  }
}