import 'package:flutter/material.dart';
import 'package:my_app/utils/check_auth.dart';

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
  // --- Mock Data ---
  int _myKeys = 20; // رصيد الطفل الحالي من المفاتيح (وهمي)

  final List<Map<String, dynamic>> _rewards = [
    {
      'id': 1,
      'title': 'Zoo Trip',
      'subtitle': 'Discover animals together',
      'points': 6,
      'isRedeemed': false,
    },
    {
      'id': 2,
      'title': 'Beach Day',
      'subtitle': 'A relaxing weekend trip',
      'points': 5,
      'isRedeemed': true, // جائزة تم طلبها مسبقاً
    },
    {
      'id': 3,
      'title': 'New Video Game',
      'subtitle': 'Choose any game under 200 SAR',
      'points': 15,
      'isRedeemed': false,
    },
    {
      'id': 4,
      'title': 'Theme Park',
      'subtitle': 'Ticket to Wonderland',
      'points': 50, // جائزة غالية (أكثر من الرصيد)
      'isRedeemed': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkAuthStatus(context); // 🔐 validate token
    });
    // TODO: Fetch real rewards and key balance from API here using widget.token
  }

  // --- Logic: Redeem Reward ---
  void _redeemReward(int index) {
    final reward = _rewards[index];
    final cost = reward['points'] as int;

    if (_myKeys >= cost) {
      setState(() {
        _myKeys -= cost; // خصم المفاتيح
        _rewards[index]['isRedeemed'] = true; // تغيير الحالة
      });

      // TODO: Call API to register redemption
      
      _showSuccessDialog(reward['title']);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You don't have enough keys yet! Keep going!"),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _showSuccessDialog(String title) {
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
            const Text(
              "Yay!",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
            ),
            const SizedBox(height: 8),
            Text(
              "You've redeemed '$title'.\nAsk your parent to approve it!",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF37C4BE),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Awesome!", style: TextStyle(color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color hassalaGreen1 = Color(0xFF37C4BE);
    const Color hassalaGreen2 = Color(0xFF2EA49E);
    const Color gold = Color(0xFFF6C44B);

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF7FAFC), Color(0xFFE6F4F3)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                // --- Header & Balance ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "My Prizes",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Spend your hard-earned keys!",
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                      ],
                    ),
                    // Key Balance Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                        border: Border.all(color: gold.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Text(
                            "$_myKeys",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.vpn_key_rounded, color: gold, size: 24),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // --- Rewards List ---
                Expanded(
                  child: _rewards.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 20),
                          itemCount: _rewards.length,
                          itemBuilder: (context, index) {
                            final reward = _rewards[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _buildChildRewardCard(
                                reward: reward,
                                userKeys: _myKeys,
                                onRedeem: () => _redeemReward(index),
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

  Widget _buildChildRewardCard({
    required Map<String, dynamic> reward,
    required int userKeys,
    required VoidCallback onRedeem,
  }) {
    const Color gold = Color(0xFFF6C44B);
    const Color hassalaGreen = Color(0xFF37C4BE);

    final bool isRedeemed = reward['isRedeemed'];
    final int points = reward['points'];
    final bool canAfford = userKeys >= points;
    
    // Visual States
    final Color cardColor = isRedeemed ? const Color(0xFFF9FAFB) : Colors.white;
    final Color textColor = isRedeemed ? Colors.grey : const Color(0xFF2C3E50);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: isRedeemed 
          ? Border.all(color: hassalaGreen.withOpacity(0.5), width: 1.5) 
          : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  reward['title'],
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    decoration: isRedeemed ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              // Price Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isRedeemed ? Colors.grey.shade200 : gold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Text(
                      "$points",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isRedeemed ? Colors.grey : const Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.vpn_key_rounded, size: 16, color: isRedeemed ? Colors.grey : gold),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            reward['subtitle'],
            style: TextStyle(fontSize: 14, color: isRedeemed ? Colors.grey.shade400 : Colors.black45),
          ),
          const SizedBox(height: 20),
          
          // Action Button
          SizedBox(
            width: double.infinity,
            height: 45,
            child: isRedeemed
                ? _buildStatusButton(
                    text: "Requested",
                    icon: Icons.check_circle,
                    color: hassalaGreen,
                    bgColor: hassalaGreen.withOpacity(0.1),
                  )
                : ElevatedButton.icon(
                    onPressed: canAfford ? onRedeem : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hassalaGreen,
                      disabledBackgroundColor: Colors.grey.shade300,
                      elevation: canAfford ? 2 : 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: Icon(
                      canAfford ? Icons.redeem : Icons.lock_outline,
                      color: canAfford ? Colors.white : Colors.grey.shade500,
                      size: 20,
                    ),
                    label: Text(
                      canAfford ? "Redeem Prize" : "Not enough keys",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: canAfford ? Colors.white : Colors.grey.shade600,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusButton({required String text, required IconData icon, required Color color, required Color bgColor}) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.emoji_events_outlined, size: 80, color: Colors.black12),
          SizedBox(height: 16),
          Text(
            "No prizes available yet",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black38),
          ),
        ],
      ),
    );
  }
}