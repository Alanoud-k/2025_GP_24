// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:my_app/utils/check_auth.dart';

// class ChildChoresScreen extends StatefulWidget {
//   final int childId;
//   final String token;

//   const ChildChoresScreen({
//     super.key,
//     required this.childId,
//     required this.token,
//   });

//   @override
//   State<ChildChoresScreen> createState() => _ChildChoresScreenState();
// }

// class _ChildChoresScreenState extends State<ChildChoresScreen> with SingleTickerProviderStateMixin {
//   late TabController _tabController;
//   bool _loading = true;
  
//   // --- Mock Data (Replace with API) ---
//   final List<Map<String, dynamic>> _todoChores = [
//     {
//       'id': 1,
//       'title': 'Clean Room',
//       'description': 'Make your bed and organize desk',
//       'keys': 5,
//       'type': 'One-time',
//     },
//     {
//       'id': 2,
//       'title': 'Wash Dishes',
//       'description': 'After lunch',
//       'keys': 3,
//       'type': 'Weekly',
//     },
//   ];

//   final List<Map<String, dynamic>> _completedChores = [
//     {
//       'id': 3,
//       'title': 'Math Homework',
//       'keys': 10,
//       'status': 'Waiting Approval', // or 'Approved'
//     },
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 2, vsync: this);
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       checkAuthStatus(context);
//       setState(() => _loading = false);
//     });
//   }

//   // --- Logic: Mark as Done ---
//   void _completeChore(int index) {
//     // Show dialog to upload proof (Simulated)
//     showDialog(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         title: const Text("Did you finish it?"),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Text("Upload a photo to show your parent!"),
//             const SizedBox(height: 20),
//             Container(
//               height: 120,
//               width: double.infinity,
//               decoration: BoxDecoration(
//                 color: Colors.grey[100],
//                 borderRadius: BorderRadius.circular(16),
//                 border: Border.all(color: Colors.grey[300]!),
//               ),
//               child: const Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(Icons.camera_alt_outlined, size: 40, color: Colors.teal),
//                   SizedBox(height: 8),
//                   Text("Tap to take photo", style: TextStyle(color: Colors.teal)),
//                 ],
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(ctx),
//             child: const Text("Cancel"),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               // Move from Todo to Completed
//               final chore = _todoChores[index];
//               setState(() {
//                 _todoChores.removeAt(index);
//                 _completedChores.add({
//                   ...chore,
//                   'status': 'Waiting Approval',
//                 });
//               });
//               Navigator.pop(ctx);
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(content: Text("Great job! Sent for approval.")),
//               );
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: const Color(0xFF37C4BE),
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//             ),
//             child: const Text("Send Proof", style: TextStyle(color: Colors.white)),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     const hassalaGreen1 = Color(0xFF37C4BE);
//     const hassalaGreen2 = Color(0xFF2EA49E);

//     return Scaffold(
//       backgroundColor: const Color(0xFFF7FAFC),
//       appBar: AppBar(
//         title: const Text(
//           "My Chores",
//           style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF2C3E50)),
//         ),
//         centerTitle: true,
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Color(0xFF2C3E50)),
//           onPressed: () => Navigator.pop(context),
//         ),
//         bottom: TabBar(
//           controller: _tabController,
//           labelColor: hassalaGreen2,
//           unselectedLabelColor: Colors.grey,
//           indicatorColor: hassalaGreen2,
//           indicatorWeight: 3,
//           tabs: const [
//             Tab(text: "To Do"),
//             Tab(text: "Completed"),
//           ],
//         ),
//       ),
//       body: TabBarView(
//         controller: _tabController,
//         children: [
//           // --- Tab 1: To Do ---
//           _todoChores.isEmpty
//               ? _buildEmptyState("No chores assigned yet!", Icons.task_alt)
//               : ListView.builder(
//                   padding: const EdgeInsets.all(16),
//                   itemCount: _todoChores.length,
//                   itemBuilder: (context, index) {
//                     final item = _todoChores[index];
//                     return _buildChoreCard(
//                       title: item['title'],
//                       subtitle: item['description'],
//                       keys: item['keys'],
//                       isDone: false,
//                       onTap: () => _completeChore(index),
//                     );
//                   },
//                 ),

//           // --- Tab 2: Completed ---
//           _completedChores.isEmpty
//               ? _buildEmptyState("No completed chores yet.", Icons.history)
//               : ListView.builder(
//                   padding: const EdgeInsets.all(16),
//                   itemCount: _completedChores.length,
//                   itemBuilder: (context, index) {
//                     final item = _completedChores[index];
//                     return _buildChoreCard(
//                       title: item['title'],
//                       subtitle: item['status'], // 'Waiting Approval'
//                       keys: item['keys'],
//                       isDone: true,
//                       onTap: () {}, // No action for completed
//                     );
//                   },
//                 ),
//         ],
//       ),
//     );
//   }

//   Widget _buildChoreCard({
//     required String title,
//     required String subtitle,
//     required int keys,
//     required bool isDone,
//     required VoidCallback onTap,
//   }) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(18),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 8,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: ListTile(
//         contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//         leading: Container(
//           padding: const EdgeInsets.all(10),
//           decoration: BoxDecoration(
//             color: isDone ? Colors.orange.withOpacity(0.1) : const Color(0xFF37C4BE).withOpacity(0.1),
//             shape: BoxShape.circle,
//           ),
//           child: Icon(
//             isDone ? Icons.access_time : Icons.cleaning_services,
//             color: isDone ? Colors.orange : const Color(0xFF37C4BE),
//           ),
//         ),
//         title: Text(
//           title,
//           style: const TextStyle(
//             fontWeight: FontWeight.bold,
//             fontSize: 16,
//             color: Color(0xFF2C3E50),
//           ),
//         ),
//         subtitle: Text(
//           subtitle,
//           style: TextStyle(
//             fontSize: 13,
//             color: isDone ? Colors.orange : Colors.grey[600],
//             fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
//           ),
//         ),
//         trailing: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Icon(Icons.vpn_key, color: Color(0xFFF6C44B), size: 18),
//             Text(
//               "$keys",
//               style: const TextStyle(
//                 fontWeight: FontWeight.bold,
//                 color: Color(0xFFF6C44B),
//               ),
//             ),
//           ],
//         ),
//         onTap: isDone ? null : onTap, // Clickable only if To Do
//       ),
//     );
//   }

//   Widget _buildEmptyState(String message, IconData icon) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(icon, size: 80, color: Colors.black12),
//           const SizedBox(height: 16),
//           Text(
//             message,
//             style: const TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.w600,
//               color: Colors.black38,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// import 'package:flutter/material.dart';
// import 'package:my_app/utils/check_auth.dart';
// import '../../child/models/chore_model.dart'; // تأكدي من المسار
// import '../../child/services/chore_service.dart'; // تأكدي من المسار
// import 'package:image_picker/image_picker.dart';
// class ChildChoresScreen extends StatefulWidget {
//   final int childId;
//   final String token;

//   const ChildChoresScreen({
//     super.key,
//     required this.childId,
//     required this.token,
//   });

//   @override
//   State<ChildChoresScreen> createState() => _ChildChoresScreenState();
// }

// class _ChildChoresScreenState extends State<ChildChoresScreen> with SingleTickerProviderStateMixin {
//   late TabController _tabController;
//   final ChoreService _choreService = ChoreService();
//   late Future<List<ChoreModel>> _choresFuture;
  
//   // Colors
//   static const Color hassalaGreen1 = Color(0xFF37C4BE);
//   static const Color hassalaGreen2 = Color(0xFF2EA49E);

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 2, vsync: this);
//     _loadChores();
//   }

//   void _loadChores() {
//     setState(() {
//       _choresFuture = _choreService.getChores(widget.childId.toString());
//     });
//   }

//   // دالة إنهاء المهمة
//   Future<void> _completeChore(String choreId) async {
//     try {
//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (_) => const Center(child: CircularProgressIndicator(color: hassalaGreen1)),
//       );

//       await _choreService.completeChore(choreId);
      
//       if (mounted) Navigator.pop(context); // إغلاق التحميل
      
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Great job! Sent for approval."), backgroundColor: Colors.green),
//       );
      
//       _loadChores(); // تحديث القائمة
//     } catch (e) {
//       if (mounted) Navigator.pop(context);
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
//       );
//     }
//   }

//   // نافذة التأكيد
//   void _showCompletionDialog(ChoreModel chore) {
//     showDialog(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         title: const Text("Did you finish it?"),
//         content: const Text("By clicking send, you notify your parent that this chore is done."),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(ctx),
//             child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               Navigator.pop(ctx);
//               _completeChore(chore.id);
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: hassalaGreen1,
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//             ),
//             child: const Text("Yes, I'm Done!", style: TextStyle(color: Colors.white)),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF7FAFC),
//       appBar: AppBar(
//         title: const Text(
//           "My Chores",
//           style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF2C3E50)),
//         ),
//         centerTitle: true,
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Color(0xFF2C3E50)),
//           onPressed: () => Navigator.pop(context),
//         ),
//         bottom: TabBar(
//           controller: _tabController,
//           labelColor: hassalaGreen2,
//           unselectedLabelColor: Colors.grey,
//           indicatorColor: hassalaGreen2,
//           indicatorWeight: 3,
//           tabs: const [
//             Tab(text: "To Do"),
//             Tab(text: "History"),
//           ],
//         ),
//       ),
//       body: FutureBuilder<List<ChoreModel>>(
//         future: _choresFuture,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator(color: hassalaGreen1));
//           } else if (snapshot.hasError) {
//             return Center(child: Text("Error: ${snapshot.error}"));
//           } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
//             return const Center(child: Text("No chores found"));
//           }

//           final allChores = snapshot.data!;
//           // To Do: Pending (Active)
//           final todoList = allChores.where((c) => c.status == 'Pending').toList();
//           // History: Waiting Approval OR Completed
//           final historyList = allChores.where((c) => c.status == 'Waiting Approval' || c.status == 'Completed').toList();

//           return TabBarView(
//             controller: _tabController,
//             children: [
//               _buildList(todoList, isTodo: true),
//               _buildList(historyList, isTodo: false),
//             ],
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildList(List<ChoreModel> chores, {required bool isTodo}) {
//     if (chores.isEmpty) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(isTodo ? Icons.task_alt : Icons.history, size: 80, color: Colors.black12),
//             const SizedBox(height: 16),
//             Text(
//               isTodo ? "No chores assigned yet!" : "No completed chores yet.",
//               style: const TextStyle(fontSize: 16, color: Colors.black38),
//             ),
//           ],
//         ),
//       );
//     }

//     return ListView.builder(
//       padding: const EdgeInsets.all(16),
//       itemCount: chores.length,
//       itemBuilder: (context, index) {
//         final item = chores[index];
//         return _buildChoreCard(item, isTodo: isTodo);
//       },
//     );
//   }

//   Widget _buildChoreCard(ChoreModel chore, {required bool isTodo}) {
//     final bool isWaiting = chore.status == 'Waiting Approval';
//     final bool isWeekly = chore.type == 'Weekly';

//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(18),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 8,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: ListTile(
//         contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//         leading: Container(
//           padding: const EdgeInsets.all(10),
//           decoration: BoxDecoration(
//             color: isTodo ? const Color(0xFF37C4BE).withOpacity(0.1) : (isWaiting ? Colors.orange.withOpacity(0.1) : Colors.grey.withOpacity(0.1)),
//             shape: BoxShape.circle,
//           ),
//           child: Icon(
//             isTodo ? Icons.cleaning_services : (isWaiting ? Icons.hourglass_empty : Icons.check),
//             color: isTodo ? const Color(0xFF37C4BE) : (isWaiting ? Colors.orange : Colors.grey),
//           ),
//         ),
//         title: Row(
//           children: [
//             Text(
//               chore.title,
//               style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2C3E50)),
//             ),
//              if (isWeekly) ...[
//                 const SizedBox(width: 8),
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//                   decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
//                   child: const Text("Weekly", style: TextStyle(fontSize: 10, color: Colors.blue)),
//                 ),
//             ]
//           ],
//         ),
//         subtitle: Text(
//           isTodo ? (chore.description ?? "No description") : chore.status,
//           style: TextStyle(
//             fontSize: 13,
//             color: isWaiting ? Colors.orange : Colors.grey[600],
//             fontWeight: isWaiting ? FontWeight.bold : FontWeight.normal,
//           ),
//         ),
//         trailing: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Icon(Icons.vpn_key, color: Color(0xFFF6C44B), size: 18),
//             Text(
//               "${chore.keys}",
//               style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF6C44B)),
//             ),
//           ],
//         ),
//         onTap: isTodo ? () => _showCompletionDialog(chore) : null,
//       ),
//     );
//   }
// }

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // تأكدي من وجود المكتبة
import '../../child/models/chore_model.dart';
import '../../child/services/chore_service.dart';

class ChildChoresScreen extends StatefulWidget {
  final int childId;
  final String token;

  const ChildChoresScreen({
    super.key,
    required this.childId,
    required this.token,
  });

  @override
  State<ChildChoresScreen> createState() => _ChildChoresScreenState();
}

class _ChildChoresScreenState extends State<ChildChoresScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ChoreService _choreService = ChoreService();
  late Future<List<ChoreModel>> _choresFuture;
  
  // Colors
  static const Color hassalaGreen1 = Color(0xFF37C4BE);
  static const Color hassalaGreen2 = Color(0xFF2EA49E);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadChores();
  }

  void _loadChores() {
    setState(() {
      _choresFuture = _choreService.getChores(widget.childId.toString());
    });
  }

  // دالة إنهاء المهمة مع ملف
  Future<void> _completeChore(String choreId, File proofImage) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator(color: hassalaGreen1)),
      );

      // استدعاء السيرفس الجديدة مع الصورة
      await _choreService.completeChore(choreId, proofImage);
      
      if (mounted) Navigator.pop(context); // إغلاق التحميل
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Great job! Sent for approval."), backgroundColor: Colors.green),
      );
      
      _loadChores(); 
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  // نافذة التأكيد مع اختيار الصورة
  void _showCompletionDialog(ChoreModel chore) {
    File? selectedImage;
    final picker = ImagePicker();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text("Submit Proof"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Select a photo from your gallery to prove you finished the task."),
                const SizedBox(height: 15),
                GestureDetector(
                  onTap: () async {
                    // ✅ اختيار من الاستوديو (Gallery)
                    final picked = await picker.pickImage(source: ImageSource.gallery);
                    
                    if (picked != null) {
                      setStateDialog(() {
                        selectedImage = File(picked.path);
                      });
                    }
                  },
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                      image: selectedImage != null 
                        ? DecorationImage(image: FileImage(selectedImage!), fit: BoxFit.cover)
                        : null
                    ),
                    child: selectedImage == null 
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.photo_library, size: 40, color: Colors.teal), // أيقونة المعرض
                            SizedBox(height: 8),
                            Text("Tap to open Gallery", style: TextStyle(color: Colors.teal)),
                          ],
                        )
                      : null,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () {
                  if (selectedImage == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Proof picture is required!"), backgroundColor: Colors.red),
                    );
                    return;
                  }
                  Navigator.pop(ctx);
                  _completeChore(chore.id, selectedImage!); // إرسال الصورة
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: hassalaGreen1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Submit", style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        title: const Text(
          "My Chores",
          style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF2C3E50)),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2C3E50)),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: hassalaGreen2,
          unselectedLabelColor: Colors.grey,
          indicatorColor: hassalaGreen2,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: "To Do"),
            Tab(text: "History"),
          ],
        ),
      ),
      body: FutureBuilder<List<ChoreModel>>(
        future: _choresFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: hassalaGreen1));
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No chores found"));
          }

          final allChores = snapshot.data!;
          // To Do: Pending
          final todoList = allChores.where((c) => c.status == 'Pending').toList();
          // History: Submitted (Waiting Approval) OR Completed
          final historyList = allChores.where((c) => c.status == 'Submitted' || c.status == 'Waiting Approval' || c.status == 'Completed').toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildList(todoList, isTodo: true),
              _buildList(historyList, isTodo: false),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(List<ChoreModel> chores, {required bool isTodo}) {
    if (chores.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isTodo ? Icons.task_alt : Icons.history, size: 80, color: Colors.black12),
            const SizedBox(height: 16),
            Text(
              isTodo ? "No chores assigned yet!" : "No history yet.",
              style: const TextStyle(fontSize: 16, color: Colors.black38),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: chores.length,
      itemBuilder: (context, index) {
        final item = chores[index];
        return _buildChoreCard(item, isTodo: isTodo);
      },
    );
  }

  Widget _buildChoreCard(ChoreModel chore, {required bool isTodo}) {
    // التحقق من الحالات المختلفة
    final bool isWaiting = chore.status == 'Submitted' || chore.status == 'Waiting Approval';
    final bool isWeekly = chore.type == 'Weekly';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isTodo ? const Color(0xFF37C4BE).withOpacity(0.1) : (isWaiting ? Colors.orange.withOpacity(0.1) : Colors.grey.withOpacity(0.1)),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isTodo ? Icons.cleaning_services : (isWaiting ? Icons.hourglass_empty : Icons.check),
            color: isTodo ? const Color(0xFF37C4BE) : (isWaiting ? Colors.orange : Colors.grey),
          ),
        ),
        title: Row(
          children: [
            Text(
              chore.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2C3E50)),
            ),
             if (isWeekly) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
                  child: const Text("Weekly", style: TextStyle(fontSize: 10, color: Colors.blue)),
                ),
            ]
          ],
        ),
        subtitle: Text(
          isTodo ? (chore.description ?? "No description") : (isWaiting ? "Waiting Approval" : "Completed"),
          style: TextStyle(
            fontSize: 13,
            color: isWaiting ? Colors.orange : Colors.grey[600],
            fontWeight: isWaiting ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.vpn_key, color: Color(0xFFF6C44B), size: 18),
            Text(
              "${chore.keys}",
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF6C44B)),
            ),
          ],
        ),
        onTap: isTodo ? () => _showCompletionDialog(chore) : null,
      ),
    );
  }
}