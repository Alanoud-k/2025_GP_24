// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
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
  
//   // --- Mock Data ---
//   final List<Map<String, dynamic>> _rewards = [
//     {
//       'id': 1,
//       'title': 'Zoo Trip',
//       'subtitle': 'Discover animals together',
//       'points': 6,
//       'isRedeemed': false,
//     },
//     {
//       'id': 2,
//       'title': 'Beach Day',
//       'subtitle': 'A relaxing weekend trip',
//       'points': 5,
//       'isRedeemed': true,
//     },
//     {
//       'id': 3,
//       'title': 'New Video Game',
//       'subtitle': 'Choose any game under 200 SAR',
//       'points': 15,
//       'isRedeemed': false,
//     },
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _initializeAuth();
//   }

//   Future<void> _initializeAuth() async {
//     await checkAuthStatus(context);
//     final prefs = await SharedPreferences.getInstance();
//     token = prefs.getString("token") ?? widget.token;

//     if (token == null || token!.isEmpty) {
//       _forceLogout();
//     }
//   }

//   void _forceLogout() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.clear();
//     if (mounted) {
//       Navigator.pushNamedAndRemoveUntil(context, '/mobile', (_) => false);
//     }
//   }

//   // --- CRUD Operations ---
//   void _addReward(String title, String subtitle, int points) {
//     setState(() {
//       _rewards.add({
//         'id': DateTime.now().millisecondsSinceEpoch,
//         'title': title,
//         'subtitle': subtitle,
//         'points': points,
//         'isRedeemed': false,
//       });
//     });
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Reward added successfully!'), backgroundColor: Color(0xFF37C4BE)),
//     );
//   }

//   void _editReward(int index, String title, String subtitle, int points) {
//     setState(() {
//       _rewards[index]['title'] = title;
//       _rewards[index]['subtitle'] = subtitle;
//       _rewards[index]['points'] = points;
//     });
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Reward updated!'), backgroundColor: Color(0xFF37C4BE)),
//     );
//   }

//   void _deleteReward(int index) {
//     final deletedItem = _rewards[index];
//     setState(() {
//       _rewards.removeAt(index);
//     });
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text('${deletedItem['title']} deleted'),
//         action: SnackBarAction(
//           label: 'Undo',
//           onPressed: () {
//             setState(() {
//               _rewards.insert(index, deletedItem);
//             });
//           },
//         ),
//       ),
//     );
//   }

//   // --- Dialogs ---
//   void _showRewardDialog({Map<String, dynamic>? reward, int? index}) {
//     final isEditing = reward != null;
//     final titleController = TextEditingController(text: reward?['title'] ?? '');
//     final subtitleController = TextEditingController(text: reward?['subtitle'] ?? '');
//     final pointsController = TextEditingController(text: reward?['points']?.toString() ?? '');

//     const hassalaColor = Color(0xFF37C4BE);

//     showDialog(
//       context: context,
//       builder: (context) => Dialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
//         backgroundColor: Colors.white,
//         child: Padding(
//           padding: const EdgeInsets.all(24.0),
//           child: SingleChildScrollView(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Center(
//                   child: Text(
//                     isEditing ? "Edit Reward" : "New Reward",
//                     style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF2C3E50)),
//                   ),
//                 ),
//                 const SizedBox(height: 25),
//                 _buildDialogLabel("Reward Title"),
//                 _buildModernTextField(controller: titleController, hint: "e.g. Zoo Trip", icon: Icons.card_giftcard),
//                 const SizedBox(height: 16),
//                 _buildDialogLabel("Description"),
//                 _buildModernTextField(controller: subtitleController, hint: "Short description...", icon: Icons.description_outlined),
//                 const SizedBox(height: 16),
//                 _buildDialogLabel("Cost (Keys)"),
//                 _buildModernTextField(controller: pointsController, hint: "e.g. 10", icon: Icons.vpn_key_outlined, keyboardType: TextInputType.number),
//                 const SizedBox(height: 30),
//                 Row(
//                   children: [
//                     Expanded(
//                       child: TextButton(
//                         onPressed: () => Navigator.pop(context),
//                         child: const Text("Cancel", style: TextStyle(color: Colors.grey, fontSize: 16)),
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: ElevatedButton(
//                         onPressed: () {
//                           if (titleController.text.isEmpty || pointsController.text.isEmpty) return;
//                           Navigator.pop(context);
//                           final points = int.tryParse(pointsController.text) ?? 0;
//                           if (isEditing && index != null) {
//                             _editReward(index, titleController.text, subtitleController.text, points);
//                           } else {
//                             _addReward(titleController.text, subtitleController.text, points);
//                           }
//                         },
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: hassalaColor,
//                           padding: const EdgeInsets.symmetric(vertical: 14),
//                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//                         ),
//                         child: Text(
//                           isEditing ? "Save" : "Add",
//                           style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   // --- UI Helpers ---
//   Widget _buildDialogLabel(String text) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8, left: 4),
//       child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF607D8B))),
//     );
//   }

//   Widget _buildModernTextField({
//     required TextEditingController controller,
//     required String hint,
//     required IconData icon,
//     TextInputType? keyboardType,
//   }) {
//     return Container(
//       decoration: BoxDecoration(
//         color: const Color(0xFFF8FAFC),
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: Colors.grey.shade300),
//       ),
//       child: TextField(
//         controller: controller,
//         keyboardType: keyboardType,
//         decoration: InputDecoration(
//           prefixIcon: Icon(icon, color: Colors.grey.shade500, size: 22),
//           hintText: hint,
//           hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
//           border: InputBorder.none,
//           contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     const Color hassalaGreen1 = Color(0xFF37C4BE);

//     return Scaffold(
//       backgroundColor: Colors.transparent, // مهم للشفافية
//       // ✅ التعديل هنا: رفع الزر للأعلى بـ Padding لتجاوز الـ Navigation Bar
//       floatingActionButton: Padding(
//         padding: const EdgeInsets.only(bottom: 90.0), // رفع الزر 90 بيكسل
//         child: FloatingActionButton(
//           onPressed: () => _showRewardDialog(),
//           backgroundColor: hassalaGreen1,
//           child: const Icon(Icons.add, color: Colors.white, size: 30),
//         ),
//       ),
      
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             colors: [Color(0xFFF7FAFC), Color(0xFFE6F4F3)],
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//           ),
//         ),
//         child: SafeArea(
//           child: Padding(
//             // إضافة مساحة سفلية (bottom: 80) للقائمة لكي لا يختفي آخر عنصر خلف البار
//             padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 /// HEADER
//                 Row(
//                   children: const [
//                     SizedBox(width: 4),
//                     Text(
//                       "Manage Rewards",
//                       style: TextStyle(
//                         fontSize: 26,
//                         fontWeight: FontWeight.w800,
//                         color: Color(0xFF2C3E50),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 8),
//                 const Text(
//                   "Create fun rewards for your children to earn!",
//                   style: TextStyle(fontSize: 15, color: Colors.black54),
//                 ),
//                 const SizedBox(height: 28),

//                 /// REWARDS LIST
//                 Expanded(
//                   child: _rewards.isEmpty 
//                   ? _buildEmptyState()
//                   : ListView.builder(
//                     padding: const EdgeInsets.only(bottom: 100), // مساحة إضافية في الأسفل
//                     itemCount: _rewards.length,
//                     itemBuilder: (context, index) {
//                       final reward = _rewards[index];
//                       return Padding(
//                         padding: const EdgeInsets.only(bottom: 16),
//                         child: _rewardCard(
//                           title: reward['title'],
//                           subtitle: reward['subtitle'],
//                           points: reward['points'],
//                           isRedeemed: reward['isRedeemed'],
//                           onEdit: () => _showRewardDialog(reward: reward, index: index),
//                           onDelete: () => _deleteReward(index),
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildEmptyState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: const [
//           Icon(Icons.card_giftcard, size: 80, color: Colors.black12),
//           SizedBox(height: 16),
//           Text(
//             "No rewards yet",
//             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black38),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _rewardCard({
//     required String title,
//     required String subtitle,
//     required int points,
//     required bool isRedeemed,
//     required VoidCallback onEdit,
//     required VoidCallback onDelete,
//   }) {
//     const Color gold = Color(0xFFF6C44B);
//     final Color cardColor = isRedeemed ? const Color(0xFFF5F5F5) : Colors.white;
//     final Color textColor = isRedeemed ? Colors.grey.shade600 : const Color(0xFF2C3E50);

//     return GestureDetector(
//       onTap: onEdit,
//       child: Container(
//         width: double.infinity,
//         padding: const EdgeInsets.all(20),
//         decoration: BoxDecoration(
//           color: cardColor,
//           borderRadius: BorderRadius.circular(22),
//           boxShadow: [
//             BoxShadow(color: Colors.black12.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 5)),
//           ],
//           border: isRedeemed ? Border.all(color: const Color(0xFF2EA49E), width: 1.5) : null,
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Expanded(
//                   child: Text(
//                     title,
//                     style: TextStyle(
//                       fontSize: 18, fontWeight: FontWeight.w700, color: textColor,
//                       decoration: isRedeemed ? TextDecoration.lineThrough : null,
//                     ),
//                   ),
//                 ),
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                   decoration: BoxDecoration(
//                     color: isRedeemed ? Colors.grey.shade200 : gold.withOpacity(0.15),
//                     borderRadius: BorderRadius.circular(30),
//                   ),
//                   child: Row(
//                     children: [
//                       Text(points.toString(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isRedeemed ? Colors.grey : const Color(0xFF2C3E50))),
//                       const SizedBox(width: 6),
//                       Icon(Icons.vpn_key_rounded, color: isRedeemed ? Colors.grey : gold, size: 20),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 8),
//             Text(subtitle, style: TextStyle(fontSize: 14, color: isRedeemed ? Colors.grey.shade500 : Colors.black45)),
//             const SizedBox(height: 18),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 if (isRedeemed)
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
//                     decoration: BoxDecoration(color: const Color(0xFF2EA49E).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
//                     child: Row(
//                       children: const [
//                         Icon(Icons.check_circle, size: 16, color: Color(0xFF2EA49E)),
//                         SizedBox(width: 6),
//                         Text("Redeemed", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2EA49E))),
//                       ],
//                     ),
//                   )
//                 else
//                   const Text("Tap to edit", style: TextStyle(fontSize: 12, color: Colors.black26)),
//                 InkWell(
//                   onTap: onDelete,
//                   borderRadius: BorderRadius.circular(20),
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
//                     decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
//                     child: const Row(
//                       children: [
//                         Icon(Icons.delete_outline, size: 18, color: Colors.red),
//                         SizedBox(width: 4),
//                         Text("Delete", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.red)),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_app/utils/check_auth.dart';
import 'package:my_app/core/api_config.dart';

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
  List<dynamic> _rewards = [];
  bool _isLoading = true;

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
    } else {
      _fetchRewards();
    }
  }

  void _forceLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/mobile', (_) => false);
    }
  }

  // --- API Methods ---
  Future<void> _fetchRewards() async {
    setState(() => _isLoading = true);
    final url = Uri.parse("${ApiConfig.baseUrl}/api/rewards/parent/${widget.parentId}");
    try {
      final res = await http.get(url, headers: {"Authorization": "Bearer $token"});
      if (res.statusCode == 200) {
        setState(() {
          _rewards = jsonDecode(res.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addReward(String title, String subtitle, int points) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/api/rewards/create");
    try {
      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
        body: jsonEncode({
          "parentId": widget.parentId,
          "rewardName": title,
          "rewardDescription": subtitle,
          "requiredKeys": points
        }),
      );
      if (res.statusCode == 201) {
        _fetchRewards();
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reward added successfully!'), backgroundColor: Color(0xFF37C4BE)));
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  Future<void> _editReward(int rewardId, String title, String subtitle, int points) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/api/rewards/$rewardId");
    try {
      final res = await http.put(
        url,
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
        body: jsonEncode({
          "rewardName": title,
          "rewardDescription": subtitle,
          "requiredKeys": points
        }),
      );
      if (res.statusCode == 200) {
        _fetchRewards();
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reward updated!'), backgroundColor: Color(0xFF37C4BE)));
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  Future<void> _deleteReward(int rewardId) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/api/rewards/$rewardId");
    try {
      final res = await http.delete(url, headers: {"Authorization": "Bearer $token"});
      if (res.statusCode == 200) {
        _fetchRewards();
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reward deleted!'), backgroundColor: Colors.red));
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  // --- Dialogs ---
  void _showDeleteConfirmation(int rewardId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Reward"),
        content: const Text("Are you sure you want to delete this reward?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              _deleteReward(rewardId);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  void _showRewardDialog({Map<String, dynamic>? reward}) {
    final isEditing = reward != null;
    final titleController = TextEditingController(text: reward?['rewardname'] ?? '');
    final subtitleController = TextEditingController(text: reward?['rewarddescription'] ?? '');
    final pointsController = TextEditingController(text: reward?['requiredkeys']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    isEditing ? "Edit Reward" : "New Reward",
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF2C3E50)),
                  ),
                ),
                const SizedBox(height: 25),
                _buildDialogLabel("Reward Title"),
                _buildModernTextField(controller: titleController, hint: "e.g. Zoo Trip", icon: Icons.card_giftcard),
                const SizedBox(height: 16),
                _buildDialogLabel("Description"),
                _buildModernTextField(controller: subtitleController, hint: "Short description...", icon: Icons.description_outlined),
                const SizedBox(height: 16),
                _buildDialogLabel("Cost (Keys)"),
                _buildModernTextField(controller: pointsController, hint: "e.g. 10", icon: Icons.vpn_key_outlined, keyboardType: TextInputType.number),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel", style: TextStyle(color: Colors.grey, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (titleController.text.isEmpty || pointsController.text.isEmpty) return;
                          final points = int.tryParse(pointsController.text) ?? 0;
                          if (points <= 0) {
                             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Keys must be greater than 0")));
                             return;
                          }
                          Navigator.pop(context);
                          if (isEditing) {
                            _editReward(reward['rewardid'], titleController.text, subtitleController.text, points);
                          } else {
                            _addReward(titleController.text, subtitleController.text, points);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF37C4BE),
                          padding: const EdgeInsets.symmetric(vertical: 14),
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

  Widget _buildDialogLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF607D8B))),
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90.0),
        child: FloatingActionButton(
          onPressed: () => _showRewardDialog(),
          backgroundColor: const Color(0xFF37C4BE),
          child: const Icon(Icons.add, color: Colors.white, size: 30),
        ),
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
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Manage Rewards", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF2C3E50))),
                const SizedBox(height: 8),
                const Text("Create fun rewards for your children to earn!", style: TextStyle(fontSize: 15, color: Colors.black54)),
                const SizedBox(height: 28),
                Expanded(
                  child: _isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : _rewards.isEmpty 
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 100),
                        itemCount: _rewards.length,
                        itemBuilder: (context, index) {
                          final reward = _rewards[index];
                          final isRedeemed = reward['rewardstatus'] == 'Redeemed';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _rewardCard(
                              title: reward['rewardname'],
                              subtitle: reward['rewarddescription'],
                              points: reward['requiredkeys'],
                              isRedeemed: isRedeemed,
                              redeemedByName: reward['redeemed_by_name'],
                              onEdit: isRedeemed ? null : () => _showRewardDialog(reward: reward),
                              onDelete: () => _showDeleteConfirmation(reward['rewardid']),
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
          Text("No rewards yet", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black38)),
        ],
      ),
    );
  }

  Widget _rewardCard({
    required String title,
    required String subtitle,
    required int points,
    required bool isRedeemed,
    String? redeemedByName,
    VoidCallback? onEdit,
    required VoidCallback onDelete,
  }) {
    const Color gold = Color(0xFFF6C44B);
    final Color cardColor = isRedeemed ? const Color(0xFFF5F5F5) : Colors.white;
    final Color textColor = isRedeemed ? Colors.grey.shade600 : const Color(0xFF2C3E50);

    return GestureDetector(
      onTap: onEdit,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: Colors.black12.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 5))],
          border: isRedeemed ? Border.all(color: const Color(0xFF2EA49E), width: 1.5) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textColor, decoration: isRedeemed ? TextDecoration.lineThrough : null),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: isRedeemed ? Colors.grey.shade200 : gold.withOpacity(0.15), borderRadius: BorderRadius.circular(30)),
                  child: Row(
                    children: [
                      Text(points.toString(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isRedeemed ? Colors.grey : const Color(0xFF2C3E50))),
                      const SizedBox(width: 6),
                      Icon(Icons.vpn_key_rounded, color: isRedeemed ? Colors.grey : gold, size: 20),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(subtitle, style: TextStyle(fontSize: 14, color: isRedeemed ? Colors.grey.shade500 : Colors.black45)),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (isRedeemed)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFF2EA49E).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, size: 16, color: Color(0xFF2EA49E)),
                        const SizedBox(width: 6),
                        Text("Redeemed by $redeemedByName", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2EA49E))),
                      ],
                    ),
                  )
                else
                  const Text("Tap to edit", style: TextStyle(fontSize: 12, color: Colors.black26)),
                InkWell(
                  onTap: onDelete,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                    child: const Row(
                      children: [
                        Icon(Icons.delete_outline, size: 18, color: Colors.red),
                        SizedBox(width: 4),
                        Text("Delete", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.red)),
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