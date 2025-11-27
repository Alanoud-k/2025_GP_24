// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:http/http.dart' as http;
// import 'package:my_app/utils/check_auth.dart';

// class ParentGiftsScreen extends StatefulWidget {
//   final int parentId;
//   final String token;

//   const ParentGiftsScreen({
//     super.key,
//     required this.parentId,
//     required this.token,
//   });

//   @override
//   State<ParentGiftsScreen> createState() => _ParentGiftsScreenState();
// }

// class _ParentGiftsScreenState extends State<ParentGiftsScreen> {
//   String? token;

//   @override
//   void initState() {
//     super.initState();
//     _initializeAuth();
//   }

//   Future<void> _initializeAuth() async {
//     // Step 1 — check if expired
//     await checkAuthStatus(context);

//     // Step 2 — load token
//     final prefs = await SharedPreferences.getInstance();
//     token = prefs.getString("token") ?? widget.token;

//     // Step 3 — if missing → logout
//     if (token == null || token!.isEmpty) {
//       _forceLogout();
//       return;
//     }

//     // Step 4 — load gifts (later)
//     // await _fetchGifts();
//   }

//   void _forceLogout() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.clear();

//     if (mounted) {
//       Navigator.pushNamedAndRemoveUntil(context, '/mobile', (_) => false);
//     }
//   }

//   Future<void> _loadToken() async {
//     final prefs = await SharedPreferences.getInstance();
//     token = prefs.getString("token");
//   }

//   Future<bool> _checkExpired(http.Response res) async {
//     if (res.statusCode == 401) {
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.clear();
//       if (mounted) {
//         Navigator.pushNamedAndRemoveUntil(context, '/mobile', (_) => false);
//       }
//       return true;
//     }
//     return false;
//   }

//   Future<void> _fetchGifts() async {
//     if (token == null) return;

//     final res = await http.get(
//       Uri.parse("http://10.0.2.2:3000/api/gifts/${widget.parentId}"),
//       headers: {"Authorization": "Bearer $token"},
//     );

//     if (await _checkExpired(res)) return;

//     // When you implement gifts, handle response here
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       child: Container(
//         color: const Color(0xFFF7F8FA),
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const SizedBox(height: 10),

//             // Title
//             const Text(
//               "Gifts",
//               style: TextStyle(
//                 fontSize: 22,
//                 fontWeight: FontWeight.w600,
//                 color: Colors.black87,
//               ),
//             ),

//             const SizedBox(height: 25),

//             // Placeholder card
//             Container(
//               width: double.infinity,
//               padding: const EdgeInsets.all(20),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(14),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.08),
//                     blurRadius: 5,
//                     offset: const Offset(0, 3),
//                   ),
//                 ],
//               ),
//               child: const Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     "Send a Gift",
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.black87,
//                     ),
//                   ),
//                   SizedBox(height: 8),
//                   Text(
//                     "Gift feature will be implemented later.",
//                     style: TextStyle(fontSize: 14, color: Colors.grey),
//                   ),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 20),

//             // Another placeholder
//             Container(
//               width: double.infinity,
//               padding: const EdgeInsets.all(20),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(14),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.08),
//                     blurRadius: 5,
//                     offset: const Offset(0, 3),
//                   ),
//                 ],
//               ),
//               child: const Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     "Gift History",
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.black87,
//                     ),
//                   ),
//                   SizedBox(height: 8),
//                   Text(
//                     "No gift history found.",
//                     style: TextStyle(fontSize: 14, color: Colors.grey),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_app/utils/check_auth.dart';

class ParentGiftsScreen extends StatefulWidget {
  final int parentId;
  final String token;

  const ParentGiftsScreen({
    super.key,
    required this.parentId,
    required this.token,
  });

  @override
  State<ParentGiftsScreen> createState() => _ParentGiftsScreenState();
}

class _ParentGiftsScreenState extends State<ParentGiftsScreen> {
  String? token;
  
  // --- Mock Data for Rewards ---
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
      'isRedeemed': true,
    },
    {
      'id': 3,
      'title': 'New Video Game',
      'subtitle': 'Choose any game under 200 SAR',
      'points': 15,
      'isRedeemed': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    await checkAuthStatus(context);
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString("token") ?? widget.token;

    if (token == null || token!.isEmpty) {
      _forceLogout();
    }
  }

  void _forceLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/mobile', (_) => false);
    }
  }

  // --- CRUD Operations (Mock) ---

  void _addReward(String title, String subtitle, int points) {
    setState(() {
      _rewards.add({
        'id': DateTime.now().millisecondsSinceEpoch,
        'title': title,
        'subtitle': subtitle,
        'points': points,
        'isRedeemed': false,
      });
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reward added successfully!'), backgroundColor: Color(0xFF37C4BE)),
    );
  }

  void _editReward(int index, String title, String subtitle, int points) {
    setState(() {
      _rewards[index]['title'] = title;
      _rewards[index]['subtitle'] = subtitle;
      _rewards[index]['points'] = points;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reward updated!'), backgroundColor: Color(0xFF37C4BE)),
    );
  }

  void _deleteReward(int index) {
    final deletedItem = _rewards[index];
    setState(() {
      _rewards.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${deletedItem['title']} deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              _rewards.insert(index, deletedItem);
            });
          },
        ),
      ),
    );
  }

  // --- Modern Dialog (Matching Chores Style) ---

  void _showRewardDialog({Map<String, dynamic>? reward, int? index}) {
    final isEditing = reward != null;
    final titleController = TextEditingController(text: reward?['title'] ?? '');
    final subtitleController = TextEditingController(text: reward?['subtitle'] ?? '');
    final pointsController = TextEditingController(text: reward?['points']?.toString() ?? '');

    const hassalaColor = Color(0xFF37C4BE);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        elevation: 10,
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Center(
                  child: Text(
                    isEditing ? "Edit Reward" : "New Reward",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ),
                const SizedBox(height: 25),

                // Title Field
                _buildDialogLabel("Reward Title"),
                _buildModernTextField(
                  controller: titleController,
                  hint: "e.g. Zoo Trip",
                  icon: Icons.card_giftcard,
                ),
                const SizedBox(height: 16),

                // Description Field
                _buildDialogLabel("Description"),
                _buildModernTextField(
                  controller: subtitleController,
                  hint: "Short description...",
                  icon: Icons.description_outlined,
                ),
                const SizedBox(height: 16),

                // Cost Field
                _buildDialogLabel("Cost (Keys)"),
                _buildModernTextField(
                  controller: pointsController,
                  hint: "e.g. 10",
                  icon: Icons.vpn_key_outlined,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 30),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text("Cancel", style: TextStyle(color: Colors.grey, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (titleController.text.isEmpty || pointsController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please fill required fields')),
                            );
                            return; 
                          }
                          Navigator.pop(context);
                          final points = int.tryParse(pointsController.text) ?? 0;
                          
                          if (isEditing && index != null) {
                            _editReward(index, titleController.text, subtitleController.text, points);
                          } else {
                            _addReward(titleController.text, subtitleController.text, points);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: hassalaColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(
                          isEditing ? "Save" : "Add",
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- UI Helpers ---

  Widget _buildDialogLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Color(0xFF607D8B),
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.grey.shade500, size: 22),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color hassalaGreen1 = Color(0xFF37C4BE); // Same color as Chores screen

    return Scaffold(
      /// Floating Action Button (MATCHING CHORES SCREEN STYLE)
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showRewardDialog(),
        backgroundColor: hassalaGreen1,
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
      
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
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// HEADER
                Row(
                  children: const [
                    SizedBox(width: 4),
                    Text(
                      "Manage Rewards",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  "Create fun rewards for your children to earn!",
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 28),

                /// REWARDS LIST
                Expanded(
                  child: _rewards.isEmpty 
                  ? _buildEmptyState()
                  : ListView.builder(
                    itemCount: _rewards.length,
                    itemBuilder: (context, index) {
                      final reward = _rewards[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _rewardCard(
                          title: reward['title'],
                          subtitle: reward['subtitle'],
                          points: reward['points'],
                          isRedeemed: reward['isRedeemed'],
                          onEdit: () => _showRewardDialog(reward: reward, index: index),
                          onDelete: () => _deleteReward(index),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.card_giftcard, size: 80, color: Colors.black12),
          SizedBox(height: 16),
          Text(
            "No rewards yet",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black38),
          ),
          SizedBox(height: 8),
          Text(
            "Tap + to add the first reward",
            style: TextStyle(fontSize: 14, color: Colors.black26),
          ),
        ],
      ),
    );
  }

  Widget _rewardCard({
    required String title,
    required String subtitle,
    required int points,
    required bool isRedeemed,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    const Color gold = Color(0xFFF6C44B);
    
    final Color cardColor = isRedeemed ? const Color(0xFFF5F5F5) : Colors.white;
    final Color textColor = isRedeemed ? Colors.grey.shade600 : const Color(0xFF2C3E50);

    return GestureDetector(
      onTap: onEdit,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
          border: isRedeemed ? Border.all(color: const Color(0xFF2EA49E), width: 1.5) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Top Row: Title + Points Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                      decoration: isRedeemed ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isRedeemed ? Colors.grey.shade200 : gold.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      Text(
                        points.toString(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isRedeemed ? Colors.grey : const Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.vpn_key_rounded,
                        color: isRedeemed ? Colors.grey : gold,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            /// Subtitle
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: isRedeemed ? Colors.grey.shade500 : Colors.black45,
              ),
            ),

            const SizedBox(height: 18),

            /// Bottom Row: Status/Action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (isRedeemed)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2EA49E).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.check_circle, size: 16, color: Color(0xFF2EA49E)),
                        SizedBox(width: 6),
                        Text(
                          "Redeemed by Ahmed",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2EA49E),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  const Text(
                    "Tap to edit",
                    style: TextStyle(fontSize: 12, color: Colors.black26),
                  ),

                // Delete Button
                InkWell(
                  onTap: onDelete,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.delete_outline, size: 18, color: Colors.red),
                        SizedBox(width: 4),
                        Text(
                          "Delete",
                          style: TextStyle(
                            fontSize: 12, 
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}