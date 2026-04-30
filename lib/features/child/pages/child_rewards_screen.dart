import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_app/utils/check_auth.dart';
import 'package:my_app/l10n/app_localizations.dart';

class ChildRewardsScreen extends StatefulWidget {
  final int childId;
  final String baseUrl;
  final String token;

  const ChildRewardsScreen({
    super.key,
    required this.childId,
    required this.baseUrl,
    required this.token,
  });

  @override
  State<ChildRewardsScreen> createState() => _ChildRewardsScreenState();
}

class _ChildRewardsScreenState extends State<ChildRewardsScreen> {
  int _myKeys = 0;
  List<dynamic> _rewards = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _validateSession();
    });
    _fetchRewardsData();
  }

  Future<void> _validateSession() async {
    try {
      await checkAuthStatus(context);
    } catch (e) {
      debugPrint("Auth error: $e");
    }
  }

  Future<void> _fetchRewardsData() async {
    setState(() => _isLoading = true);
    final url = Uri.parse("${widget.baseUrl}/api/rewards/child/${widget.childId}");
    try {
      final res = await http.get(url, headers: {"Authorization": "Bearer ${widget.token}"});
      if (res.statusCode >= 200 && res.statusCode <= 299) {
        final data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            // ✅ الحل الجذري: تحويل آمن للرقم لتجنب أخطاء الـ Type Mismatch من قاعدة البيانات
            _myKeys = int.tryParse(data['myKeys']?.toString() ?? '0') ?? 0;
            _rewards = data['rewards'] ?? [];
          });
        }
      } else {
        debugPrint("Error fetching rewards: ${res.statusCode}");
      }
    } catch (e) {
      debugPrint("Fetch Rewards Error: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _redeemReward(int rewardId, String title) async {
    final l10n = AppLocalizations.of(context)!;
    final url = Uri.parse("${widget.baseUrl}/api/rewards/redeem");
    try {
      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json", "Authorization": "Bearer ${widget.token}"},
        body: jsonEncode({
          "childId": widget.childId,
          "rewardId": rewardId,
        }),
      );
      
      if (res.statusCode >= 200 && res.statusCode <= 299) {
        _fetchRewardsData(); 
        _showSuccessDialog(title);
      } else {
         final errorData = jsonDecode(res.body);
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(
           content: Text(errorData['error'] ?? l10n.failedToRedeem),
           backgroundColor: Colors.red,
         ));
      }
    } catch (e) {
      debugPrint("Redeem Error: $e");
    }
  }

  void _showSuccessDialog(String title) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.celebration, size: 60, color: Color(0xFF37C4BE)),
            const SizedBox(height: 16),
            Text(l10n.yay, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
            const SizedBox(height: 8),
            Text(
              "${l10n.redeemedSuccessMsg1} '$title'.\n${l10n.redeemedSuccessMsg2}",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF37C4BE), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: Text(l10n.awesome, style: const TextStyle(color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFFF7FAFC), Color(0xFFE6F4F3)], begin: AlignmentDirectional.topCenter, end: AlignmentDirectional.bottomCenter),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(22, 18, 22, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.myPrizes, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF2C3E50))),
                        const SizedBox(height: 4),
                        Text(l10n.spendKeys, style: const TextStyle(fontSize: 14, color: Colors.black54)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                        border: Border.all(color: const Color(0xFFF6C44B).withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Text("$_myKeys", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
                          const SizedBox(width: 6),
                          const Icon(Icons.vpn_key_rounded, color: Color(0xFFF6C44B), size: 24),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Expanded(
                  child: _isLoading 
                    ? const Center(child: CircularProgressIndicator())
                    : _rewards.isEmpty
                      ? _buildEmptyState(l10n)
                      : ListView.builder(
                          padding: const EdgeInsetsDirectional.only(bottom: 20),
                          itemCount: _rewards.length,
                          itemBuilder: (context, index) {
                            final reward = _rewards[index];
                            return Padding(
                              padding: const EdgeInsetsDirectional.only(bottom: 16),
                              child: _buildChildRewardCard(
                                reward: reward,
                                userKeys: _myKeys,
                                onRedeem: () {
                                  // ✅ تحويل آمن للـ ID تجنباً لأي خطأ
                                  final rId = int.tryParse(reward['rewardid']?.toString() ?? '0') ?? 0;
                                  final rName = reward['rewardname']?.toString() ?? '';
                                  _redeemReward(rId, rName);
                                },
                                l10n: l10n,
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChildRewardCard({required Map<String, dynamic> reward, required int userKeys, required VoidCallback onRedeem, required AppLocalizations l10n}) {
    final bool isRedeemed = reward['rewardstatus'] == 'Redeemed';
    // ✅ تحويل آمن لنقاط (مفاتيح) الجائزة
    final int points = int.tryParse(reward['requiredkeys']?.toString() ?? '0') ?? 0;
    final bool canAfford = userKeys >= points;
    final Color cardColor = isRedeemed ? const Color(0xFFF9FAFB) : Colors.white;
    final Color textColor = isRedeemed ? Colors.grey : const Color(0xFF2C3E50);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: Colors.black12.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 6))],
        border: isRedeemed ? Border.all(color: const Color(0xFF37C4BE).withOpacity(0.5), width: 1.5) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  reward['rewardname']?.toString() ?? '',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor, decoration: isRedeemed ? TextDecoration.lineThrough : null),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: isRedeemed ? Colors.grey.shade200 : const Color(0xFFF6C44B).withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Text("$points", style: TextStyle(fontWeight: FontWeight.bold, color: isRedeemed ? Colors.grey : const Color(0xFF2C3E50))),
                    const SizedBox(width: 4),
                    Icon(Icons.vpn_key_rounded, size: 16, color: isRedeemed ? Colors.grey : const Color(0xFFF6C44B)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(reward['rewarddescription']?.toString() ?? '', style: TextStyle(fontSize: 14, color: isRedeemed ? Colors.grey.shade400 : Colors.black45)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 45,
            child: isRedeemed
                ? Container(
                    decoration: BoxDecoration(color: const Color(0xFF37C4BE).withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle, color: Color(0xFF37C4BE), size: 20),
                        const SizedBox(width: 8),
                        Text(l10n.youGotThis, style: const TextStyle(color: Color(0xFF37C4BE), fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: canAfford ? onRedeem : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF37C4BE),
                      disabledBackgroundColor: Colors.grey.shade300,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: Icon(canAfford ? Icons.redeem : Icons.lock_outline, color: canAfford ? Colors.white : Colors.grey.shade500, size: 20),
                    label: Text(canAfford ? l10n.redeemPrize : l10n.notEnoughKeys, style: TextStyle(fontWeight: FontWeight.bold, color: canAfford ? Colors.white : Colors.grey.shade600)),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.emoji_events_outlined, size: 80, color: Colors.black12),
          const SizedBox(height: 16),
          Text(l10n.noPrizesYet, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black38)),
        ],
      ),
    );
  }
}