// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:my_app/utils/check_auth.dart';
// import '../../child/models/chore_model.dart';
// import '../../child/services/chore_service.dart';

// class ParentChoresScreen extends StatefulWidget {
//   final int parentId;
//   final String token;

//   const ParentChoresScreen({
//     super.key,
//     required this.parentId,
//     required this.token,
//   });

//   @override
//   State<ParentChoresScreen> createState() => _ParentChoresScreenState();
// }

// class _ParentChoresScreenState extends State<ParentChoresScreen>
//     with SingleTickerProviderStateMixin {
//   bool _loading = true;
//   late TabController _tabController;
//   final ChoreService _choreService = ChoreService();

//   List<ChoreModel> _allChores = [];
//   List<Map<String, dynamic>> _childrenList = [];

//   // Colors
//   static const Color _tealMsg = Color(0xFF37C4BE);
//   static const Color _redMsg = Color(0xFFE74C3C);
//   static const Color _greenMsg = Color(0xFF27AE60);
//   static const Color hassalaGreen1 = Color(0xFF37C4BE); // ✅ تعريف اللون

//   final List<String> _daysOfWeek = [
//     'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 2, vsync: this);
//     _loadAllData();
//   }

//   void _showMessageBar(String message, {Color backgroundColor = _tealMsg}) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).clearSnackBars();
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message, style: const TextStyle(color: Colors.white)),
//         backgroundColor: backgroundColor,
//         behavior: SnackBarBehavior.floating,
//         margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       ),
//     );
//   }

//   Future<void> _loadAllData() async {
//     await checkAuthStatus(context);
//     try {
//       final chores = await _choreService.getAllParentChores(widget.parentId.toString());
//       final children = await _choreService.getChildren(widget.parentId.toString());

//       if (mounted) {
//         setState(() {
//           _allChores = chores;
//           _childrenList = children;
//           _loading = false;
//         });
//       }
//     } catch (e) {
//       if (mounted) setState(() => _loading = false);
//       debugPrint("Error loading data: $e");
//     }
//   }

//   Future<void> _approveChore(String choreId) async {
//     try {
//       await _choreService.updateChoreStatus(choreId, 'Completed');
//       _loadAllData();
//       _showMessageBar("Chore Approved!", backgroundColor: _greenMsg);
//     } catch (e) {
//       _showMessageBar("Failed to approve", backgroundColor: _redMsg);
//     }
//   }

//   String _getChildName(String id) {
//     if (id.isEmpty || id == "null") return "";
//     for (var child in _childrenList) {
//       if (child['childId'].toString() == id) {
//         return "For: ${child['firstName'] ?? 'Unknown'}";
//       }
//     }
//     return "";
//   }

//   void _showChoreDialog({ChoreModel? choreToEdit}) {
//     final isEditing = choreToEdit != null;
//     final titleController = TextEditingController(text: choreToEdit?.title ?? '');
//     final descController = TextEditingController(text: choreToEdit?.description ?? '');
//     final keysController = TextEditingController(text: choreToEdit?.keys.toString() ?? '');

//     String selectedType = isEditing ? choreToEdit!.type : 'One-time';
//     String? selectedDay;
//     TimeOfDay? selectedTime;

//     String? initialChildId = isEditing ? choreToEdit!.childId : null;
//     if (initialChildId != null && _childrenList.isNotEmpty) {
//       bool exists = _childrenList.any((c) => c['childId'].toString() == initialChildId);
//       if (!exists) initialChildId = null;
//     }
//     String? selectedChildId = initialChildId;

//     showDialog(
//       context: context,
//       builder: (context) => StatefulBuilder(
//         builder: (context, setStateDialog) {
//           // ✅ 1. تغليف الـ Dialog بـ Theme لتغيير اللون البنفسجي إلى التركوازي
//           return Theme(
//             data: Theme.of(context).copyWith(
//               colorScheme: const ColorScheme.light(
//                 primary: hassalaGreen1,
//                 onPrimary: Colors.white,
//                 surface: Colors.white,
//               ),
//               inputDecorationTheme: InputDecorationTheme(
//                 focusedBorder: OutlineInputBorder(
//                   borderSide: const BorderSide(color: hassalaGreen1, width: 2),
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
//               ),
//             ),
//             child: AlertDialog(
//               backgroundColor: Colors.white,
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//               title: Text(isEditing ? "Edit Chore" : "Add New Chore", style: const TextStyle(fontWeight: FontWeight.bold)),
//               content: SingleChildScrollView(
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     TextField(controller: titleController, decoration: const InputDecoration(labelText: "Title", prefixIcon: Icon(Icons.title))),
//                     const SizedBox(height: 10),
//                     TextField(controller: descController, decoration: const InputDecoration(labelText: "Description", prefixIcon: Icon(Icons.description))),
//                     const SizedBox(height: 10),
//                     TextField(
//                       controller: keysController,
//                       decoration: const InputDecoration(labelText: "Reward (Keys)", prefixIcon: Icon(Icons.vpn_key)),
//                       keyboardType: TextInputType.number,
//                       inputFormatters: [FilteringTextInputFormatter.digitsOnly],
//                     ),
//                     const SizedBox(height: 15),

//                     DropdownButtonFormField<String>(
//                       dropdownColor: Colors.white, // ✅ 2. خلفية بيضاء
//                       decoration: const InputDecoration(
//                         labelText: "Chore Type",
//                         prefixIcon: Icon(Icons.repeat),
//                       ),
//                       value: selectedType,
//                       items: const [
//                         DropdownMenuItem(value: 'One-time', child: Text("One-time")),
//                         DropdownMenuItem(value: 'Weekly', child: Text("Weekly")),
//                       ],
//                       onChanged: (val) {
//                         if (val != null) {
//                           setStateDialog(() {
//                             selectedType = val;
//                             if (val == 'One-time') {
//                               selectedDay = null;
//                               selectedTime = null;
//                             }
//                           });
//                         }
//                       },
//                     ),

//                     if (selectedType == 'Weekly' && !isEditing) ...[
//                       const SizedBox(height: 15),
//                       Row(
//                         children: [
//                           Expanded(
//                             child: DropdownButtonFormField<String>(
//                               dropdownColor: Colors.white, // ✅ خلفية بيضاء
//                               decoration: const InputDecoration(
//                                 labelText: "Day",
//                                 contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
//                               ),
//                               value: selectedDay,
//                               items: _daysOfWeek.map((day) => DropdownMenuItem(value: day, child: Text(day, style: const TextStyle(fontSize: 14)))).toList(),
//                               onChanged: (val) => setStateDialog(() => selectedDay = val),
//                             ),
//                           ),
//                           const SizedBox(width: 10),
//                           Expanded(
//                             child: InkWell(
//                               onTap: () async {
//                                 final time = await showTimePicker(
//                                   context: context,
//                                   initialTime: TimeOfDay.now(),
//                                   builder: (context, child) {
//                                     // ✅ تعديل ألوان الـ TimePicker
//                                     return Theme(
//                                       data: Theme.of(context).copyWith(
//                                         colorScheme: const ColorScheme.light(
//                                           primary: hassalaGreen1,
//                                           onPrimary: Colors.white,
//                                           surface: Colors.white,
//                                           onSurface: Colors.black,
//                                         ),
//                                       ),
//                                       child: child!,
//                                     );
//                                   },
//                                 );
//                                 if (time != null) {
//                                   setStateDialog(() => selectedTime = time);
//                                 }
//                               },
//                               child: InputDecorator(
//                                 decoration: const InputDecoration(
//                                   labelText: "Time",
//                                   suffixIcon: Icon(Icons.access_time, size: 20),
//                                   contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
//                                 ),
//                                 child: Text(
//                                   selectedTime != null ? selectedTime!.format(context) : "Select Time",
//                                   style: const TextStyle(fontSize: 14),
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],

//                     if (!isEditing) ...[
//                       const SizedBox(height: 15),
//                       _childrenList.isEmpty
//                         ? const Text("No children found.", style: TextStyle(color: Colors.red))
//                         : DropdownButtonFormField<String>(
//                             dropdownColor: Colors.white, // ✅ خلفية بيضاء
//                             decoration: const InputDecoration(
//                               labelText: "Assign to Child",
//                               prefixIcon: Icon(Icons.face),
//                             ),
//                             value: selectedChildId,
//                             items: _childrenList.map((child) {
//                               return DropdownMenuItem<String>(
//                                 value: child['childId'].toString(),
//                                 child: Text(child['firstName'] ?? "Unknown"),
//                               );
//                             }).toList(),
//                             onChanged: (val) {
//                               setStateDialog(() => selectedChildId = val);
//                             },
//                             hint: const Text("Select a child"),
//                           ),
//                     ]
//                   ],
//                 ),
//               ),
//               actions: [
//                 TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
//                 ElevatedButton(
//                   style: ElevatedButton.styleFrom(backgroundColor: hassalaGreen1),
//                   onPressed: () async {
//                     int keysValue = int.tryParse(keysController.text) ?? 0;
//                     if (keysValue <= 0) {
//                        _showMessageBar("Reward must be greater than 0", backgroundColor: _redMsg);
//                        return;
//                     }

//                     try {
//                       if (isEditing) {
//                         await _choreService.editChore(
//                           choreId: choreToEdit!.id,
//                           title: titleController.text,
//                           description: descController.text,
//                           keys: keysValue,
//                         );
//                         _showMessageBar("Chore updated!", backgroundColor: _greenMsg);
//                       } else {
//                         if (titleController.text.isEmpty || selectedChildId == null) {
//                            _showMessageBar("Please fill all fields & select a child", backgroundColor: _redMsg);
//                            return;
//                         }

//                         if (selectedType == 'Weekly' && (selectedDay == null || selectedTime == null)) {
//                           _showMessageBar("Please select day and time", backgroundColor: _redMsg);
//                           return;
//                         }

//                         String? formattedTime;
//                         if (selectedTime != null) {
//                           final hour = selectedTime!.hour.toString().padLeft(2, '0');
//                           final minute = selectedTime!.minute.toString().padLeft(2, '0');
//                           formattedTime = "$hour:$minute";
//                         }

//                         await _choreService.createChore(
//                           title: titleController.text,
//                           description: descController.text,
//                           keys: keysValue,
//                           childId: selectedChildId!,
//                           parentId: widget.parentId.toString(),
//                           type: selectedType,
//                           assignedDay: selectedDay,
//                           assignedTime: formattedTime,
//                         );
//                         _showMessageBar("Chore created!", backgroundColor: _greenMsg);
//                       }
//                       if (context.mounted) Navigator.pop(context);
//                       _loadAllData();
//                     } catch (e) {
//                       _showMessageBar("Error: $e", backgroundColor: _redMsg);
//                     }
//                   },
//                   child: Text(isEditing ? "Save" : "Create", style: const TextStyle(color: Colors.white)),
//                 ),
//               ],
//             ),
//           );
//         }
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     const hassalaGreen2 = Color(0xFF2EA49E);

//     if (_loading) {
//       return const Scaffold(
//         backgroundColor: Color(0xFFF7F8FA),
//         body: Center(child: CircularProgressIndicator(color: hassalaGreen1)),
//       );
//     }

//     final activeChores = _allChores.where((c) => c.status == 'In Progress' || c.status == 'Pending').toList();
//     final pendingChores = _allChores.where((c) => c.status == 'Waiting Approval').toList();

//     return Scaffold(
//       backgroundColor: const Color(0xFFF7F8FA),
//       floatingActionButton: Padding(
//         padding: const EdgeInsets.only(bottom: 90.0),
//         child: FloatingActionButton(
//           onPressed: () => _showChoreDialog(),
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
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Padding(
//                 padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
//                 child: Text("All Family Chores", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF2C3E50))),
//               ),
//               Container(
//                 margin: const EdgeInsets.symmetric(horizontal: 16),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(30),
//                   boxShadow: [BoxShadow(color: Colors.black12.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
//                 ),
//                 child: TabBar(
//                   controller: _tabController,
//                   indicatorSize: TabBarIndicatorSize.tab,
//                   indicator: BoxDecoration(
//                     borderRadius: BorderRadius.circular(30),
//                     gradient: const LinearGradient(colors: [hassalaGreen1, hassalaGreen2]),
//                   ),
//                   labelColor: Colors.white,
//                   unselectedLabelColor: Colors.grey,
//                   tabs: const [Tab(text: "To Review"), Tab(text: "In Progress")],
//                 ),
//               ),
//               const SizedBox(height: 20),
//               Expanded(
//                 child: TabBarView(
//                   controller: _tabController,
//                   children: [
//                     _buildChoreList(pendingChores, isReview: true),
//                     _buildChoreList(activeChores, isReview: false),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildChoreList(List<ChoreModel> chores, {required bool isReview}) {
//     if (chores.isEmpty) {
//       return Center(child: Text(isReview ? "No chores to review" : "No active chores"));
//     }
//     return ListView.builder(
//       padding: const EdgeInsets.symmetric(horizontal: 16),
//       itemCount: chores.length,
//       itemBuilder: (context, index) => _buildChoreCard(chores[index], isReview),
//     );
//   }

//   Widget _buildChoreCard(ChoreModel chore, bool isReview) {
//     final childNameText = _getChildName(chore.childId);
//     final isWeekly = chore.type == 'Weekly';

//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(18),
//         boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
//       ),
//       child: Row(
//         children: [
//           CircleAvatar(
//             backgroundColor: isReview ? Colors.orange.withOpacity(0.1) : Colors.teal.withOpacity(0.1),
//             child: Icon(isReview ? Icons.rate_review : Icons.pending_actions, color: isReview ? Colors.orange : Colors.teal),
//           ),
//           const SizedBox(width: 15),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Text(chore.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
//                     const SizedBox(width: 8),
//                     if (isWeekly)
//                        Container(
//                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//                          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
//                          child: const Text("Weekly", style: TextStyle(fontSize: 10, color: Colors.blue)),
//                        ),
//                     const SizedBox(width: 8),
//                     if (!isReview)
//                       GestureDetector(
//                         onTap: () => _showChoreDialog(choreToEdit: chore),
//                         child: const Icon(Icons.edit, size: 18, color: Colors.grey),
//                       ),
//                   ],
//                 ),
//                 if (childNameText.isNotEmpty)
//                   Text(childNameText, style: const TextStyle(color: Color(0xFF37C4BE), fontSize: 12, fontWeight: FontWeight.bold)),
//                 Text("Reward: ${chore.keys} Keys", style: const TextStyle(color: Colors.grey, fontSize: 13)),
//               ],
//             ),
//           ),
//           if (isReview)
//             IconButton(
//               icon: const Icon(Icons.check_circle, color: Colors.green),
//               onPressed: () => _approveChore(chore.id),
//             ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_app/utils/check_auth.dart';
import '../../child/models/chore_model.dart';
import '../../child/services/chore_service.dart';

class ParentChoresScreen extends StatefulWidget {
  final int parentId;
  final String token;

  const ParentChoresScreen({
    super.key,
    required this.parentId,
    required this.token,
  });

  @override
  State<ParentChoresScreen> createState() => _ParentChoresScreenState();
}

class _ParentChoresScreenState extends State<ParentChoresScreen>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  late TabController _tabController;
  final ChoreService _choreService = ChoreService();

  List<ChoreModel> _allChores = [];
  List<Map<String, dynamic>> _childrenList = [];

  static const Color hassalaGreen1 = Color(0xFF37C4BE);
  static const Color _redMsg = Color(0xFFE74C3C);
  static const Color _greenMsg = Color(0xFF27AE60);
  static const Color textColor = Color(0xFF2C3E50);

  final List<String> _daysOfWeek = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAllData();
  }

  void _showMessageBar(
    String message, {
    Color backgroundColor = hassalaGreen1,
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Future<void> _loadAllData() async {
    await checkAuthStatus(context);
    try {
      final chores = await _choreService.getAllParentChores(
        widget.parentId.toString(),
      );
      final children = await _choreService.getChildren(
        widget.parentId.toString(),
      );

      if (mounted) {
        setState(() {
          _allChores = chores;
          _childrenList = children;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      debugPrint("Error loading data: $e");
    }
  }

  Future<void> _approveChore(String choreId) async {
    try {
      await _choreService.updateChoreStatus(choreId, 'Completed');
      _loadAllData();
      _showMessageBar("Chore Approved!", backgroundColor: _greenMsg);
    } catch (e) {
      _showMessageBar("Failed to approve", backgroundColor: _redMsg);
    }
  }

  Future<void> _rejectChore(String choreId, String reason) async {
    try {
      await _choreService.rejectChore(choreId, reason);
      _loadAllData();
      _showMessageBar(
        "Chore Rejected & returned to child",
        backgroundColor: _redMsg,
      );
    } catch (e) {
      _showMessageBar("Failed to reject", backgroundColor: _redMsg);
    }
  }

  String _getChildNameOnly(String id) {
    for (var child in _childrenList) {
      if (child['childId'].toString() == id) {
        return child['firstName'] ?? 'Unknown';
      }
    }
    return "Unknown";
  }

  // ✅ الملاحظة 4: توحيد الألوان للنافذة البيضاء التركوازية
  void _showReviewDialog(ChoreModel chore) {
    String imageUrl = chore.proofUrl ?? "";
    if (imageUrl.isNotEmpty && imageUrl.startsWith('http:')) {
      imageUrl = imageUrl.replaceFirst('http:', 'https:');
    }

    final String cName = chore.childName ?? _getChildNameOnly(chore.childId);

    showDialog(
      context: context,
      builder: (ctx) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: hassalaGreen1,
            surface: Colors.white,
            onPrimary: Colors.white,
          ),
        ),
        child: AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            "Review $cName's Proof",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Task: ${chore.title}",
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 15),
                if (imageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imageUrl,
                      height: 250,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (ctx, child, progress) => progress == null
                          ? child
                          : Container(
                              height: 250,
                              color: Colors.grey[100],
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: hassalaGreen1,
                                ),
                              ),
                            ),
                      errorBuilder: (ctx, err, stack) => Container(
                        height: 150,
                        color: Colors.grey[100],
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.grey,
                          size: 40,
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(20),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Text(
                      "No proof image provided.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
              ],
            ),
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _showRejectReasonDialog(chore);
              },
              child: const Text(
                "Reject",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    "Close",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _approveChore(chore.id);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF27AE60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "Approve",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ✅ الملاحظة 4: توحيد لون نافذة الرفض
  void _showRejectReasonDialog(ChoreModel chore) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Colors.red,
            surface: Colors.white,
            onPrimary: Colors.white,
          ),
          inputDecorationTheme: InputDecorationTheme(
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.red, width: 2),
              borderRadius: BorderRadius.circular(10),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        child: AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Reason for Rejection",
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: reasonController,
            cursorColor: Colors.red,
            decoration: const InputDecoration(
              hintText: "E.g., The room is still messy!",
            ),
            maxLines: 2,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                if (reasonController.text.isNotEmpty) {
                  Navigator.pop(ctx);
                  _rejectChore(chore.id, reasonController.text);
                }
              },
              child: const Text(
                "Send to Child",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChoreDialog({ChoreModel? choreToEdit}) {
    final isEditing = choreToEdit != null;
    final titleController = TextEditingController(
      text: choreToEdit?.title ?? '',
    );
    final descController = TextEditingController(
      text: choreToEdit?.description ?? '',
    );
    final keysController = TextEditingController(
      text: choreToEdit?.keys.toString() ?? '',
    );

    String selectedType = isEditing ? choreToEdit!.type : 'One-time';
    String? selectedDay;
    TimeOfDay? selectedTime;

    String? initialChildId = isEditing ? choreToEdit!.childId : null;
    if (initialChildId != null && _childrenList.isNotEmpty) {
      bool exists = _childrenList.any(
        (c) => c['childId'].toString() == initialChildId,
      );
      if (!exists) initialChildId = null;
    }
    String? selectedChildId = initialChildId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          // ✅ الملاحظة 4: ثيم إضافة المهمة أبيض وتركوازي بالكامل
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: hassalaGreen1,
                onPrimary: Colors.white,
                surface: Colors.white,
              ),
              textSelectionTheme: const TextSelectionThemeData(
                cursorColor: hassalaGreen1,
                selectionHandleColor: hassalaGreen1,
              ),
              inputDecorationTheme: InputDecorationTheme(
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: hassalaGreen1, width: 2),
                  borderRadius: BorderRadius.circular(10),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            child: AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                isEditing ? "Edit Chore" : "Add New Chore",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: "Title",
                        prefixIcon: Icon(Icons.title),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(
                        labelText: "Description",
                        prefixIcon: Icon(Icons.description),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: keysController,
                      decoration: const InputDecoration(
                        labelText: "Reward (Keys)",
                        prefixIcon: Icon(Icons.vpn_key),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const SizedBox(height: 15),

                    DropdownButtonFormField<String>(
                      dropdownColor: Colors.white,
                      decoration: const InputDecoration(
                        labelText: "Chore Type",
                        prefixIcon: Icon(Icons.repeat),
                      ),
                      value: selectedType,
                      items: const [
                        DropdownMenuItem(
                          value: 'One-time',
                          child: Text("One-time"),
                        ),
                        DropdownMenuItem(
                          value: 'Weekly',
                          child: Text("Weekly"),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null)
                          setStateDialog(() {
                            selectedType = val;
                            if (val == 'One-time') {
                              selectedDay = null;
                              selectedTime = null;
                            }
                          });
                      },
                    ),

                    if (selectedType == 'Weekly' && !isEditing) ...[
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              dropdownColor: Colors.white,
                              decoration: const InputDecoration(
                                labelText: "Day",
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                              ),
                              value: selectedDay,
                              items: _daysOfWeek
                                  .map(
                                    (day) => DropdownMenuItem(
                                      value: day,
                                      child: Text(
                                        day,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) =>
                                  setStateDialog(() => selectedDay = val),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                  builder: (context, child) => Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: const ColorScheme.light(
                                        primary: hassalaGreen1,
                                        onPrimary: Colors.white,
                                        surface: Colors.white,
                                      ),
                                    ),
                                    child: child!,
                                  ),
                                );
                                if (time != null)
                                  setStateDialog(() => selectedTime = time);
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: "Time",
                                  suffixIcon: Icon(Icons.access_time, size: 20),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                ),
                                child: Text(
                                  selectedTime != null
                                      ? selectedTime!.format(context)
                                      : "Select Time",
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    if (!isEditing) ...[
                      const SizedBox(height: 15),
                      _childrenList.isEmpty
                          ? const Text(
                              "No children found.",
                              style: TextStyle(color: Colors.red),
                            )
                          : DropdownButtonFormField<String>(
                              dropdownColor: Colors.white,
                              decoration: const InputDecoration(
                                labelText: "Assign to Child",
                                prefixIcon: Icon(Icons.face),
                              ),
                              value: selectedChildId,
                              items: _childrenList
                                  .map(
                                    (child) => DropdownMenuItem<String>(
                                      value: child['childId'].toString(),
                                      child: Text(
                                        child['firstName'] ?? "Unknown",
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) =>
                                  setStateDialog(() => selectedChildId = val),
                              hint: const Text("Select a child"),
                            ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hassalaGreen1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    int keysValue = int.tryParse(keysController.text) ?? 0;
                    if (keysValue <= 0) {
                      _showMessageBar(
                        "Reward must be > 0",
                        backgroundColor: _redMsg,
                      );
                      return;
                    }

                    try {
                      if (isEditing) {
                        await _choreService.editChore(
                          choreId: choreToEdit!.id,
                          title: titleController.text,
                          description: descController.text,
                          keys: keysValue,
                        );
                        _showMessageBar(
                          "Chore updated!",
                          backgroundColor: _greenMsg,
                        );
                      } else {
                        if (titleController.text.isEmpty ||
                            selectedChildId == null) {
                          _showMessageBar(
                            "Please fill all fields",
                            backgroundColor: _redMsg,
                          );
                          return;
                        }
                        String? formattedTime;
                        if (selectedTime != null)
                          formattedTime =
                              "${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}";
                        await _choreService.createChore(
                          title: titleController.text,
                          description: descController.text,
                          keys: keysValue,
                          childId: selectedChildId!,
                          parentId: widget.parentId.toString(),
                          type: selectedType,
                          assignedDay: selectedDay,
                          assignedTime: formattedTime,
                        );
                        _showMessageBar(
                          "Chore created!",
                          backgroundColor: _greenMsg,
                        );
                      }
                      if (context.mounted) Navigator.pop(context);
                      _loadAllData();
                    } catch (e) {
                      _showMessageBar("Error: $e", backgroundColor: _redMsg);
                    }
                  },
                  child: Text(
                    isEditing ? "Save" : "Create",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ✅ نافذة تأكيد الحذف
  Future<void> _confirmDeleteChore(String choreId) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red),
            SizedBox(width: 8),
            Text(
              "Delete Chore?",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          "Are you sure you want to delete this chore? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _choreService.deleteChore(choreId);
        _loadAllData(); // تحديث القائمة بعد الحذف
        _showMessageBar(
          "Chore deleted successfully",
          backgroundColor: Colors.red,
        );
      } catch (e) {
        _showMessageBar("Failed to delete chore", backgroundColor: Colors.red);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7F8FA),
        body: Center(child: CircularProgressIndicator(color: hassalaGreen1)),
      );
    }

    List<ChoreModel> activeChores = _allChores
        .where((c) => c.status == 'In Progress' || c.status == 'Pending')
        .toList();
    List<ChoreModel> pendingChores = _allChores
        .where((c) => c.status == 'Submitted' || c.status == 'Waiting Approval')
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90.0),
        child: FloatingActionButton(
          onPressed: () => _showChoreDialog(),
          backgroundColor: hassalaGreen1,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Text(
                  "All Family Chores",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: const LinearGradient(
                      colors: [
                        hassalaGreen1,
                        Color.fromARGB(255, 53, 144, 169),
                      ],
                    ),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey,
                  tabs: const [
                    Tab(text: "To Review"),
                    Tab(text: "In Progress"),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildGroupedChoreList(pendingChores, isReview: true),
                    _buildGroupedChoreList(activeChores, isReview: false),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ الملاحظات 2 و 3: تجميع وعرض المهام حسب كل طفل
  Widget _buildGroupedChoreList(
    List<ChoreModel> chores, {
    required bool isReview,
  }) {
    if (chores.isEmpty) {
      return Center(
        child: Text(
          isReview ? "No chores to review" : "No active chores",
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    // تجميع المهام في قاموس (Map) حيث المفتاح هو الـ childId
    Map<String, List<ChoreModel>> groupedChores = {};
    for (var chore in chores) {
      if (!groupedChores.containsKey(chore.childId)) {
        groupedChores[chore.childId] = [];
      }
      groupedChores[chore.childId]!.add(chore);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: groupedChores.keys.length,
      itemBuilder: (context, index) {
        String childId = groupedChores.keys.elementAt(index);
        List<ChoreModel> childChores = groupedChores[childId]!;

        // جلب اسم الطفل النظيف
        String childName =
            childChores.first.childName ?? _getChildNameOnly(childId);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ عنوان القسم (اسم الطفل)
            Padding(
              padding: const EdgeInsets.only(top: 15, bottom: 10, left: 5),
              child: Row(
                children: [
                  const Icon(Icons.face, color: hassalaGreen1, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    "$childName's Chores",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
            // عرض المهام الخاصة بهذا الطفل فقط تحت اسمه
            ...childChores.map((c) => _buildChoreCard(c, isReview)).toList(),
            const SizedBox(height: 10),
          ],
        );
      },
    );
  }

  Widget _buildChoreCard(ChoreModel chore, bool isReview) {
    final isWeekly = chore.type == 'Weekly';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isReview
                ? Colors.orange.withOpacity(0.1)
                : Colors.teal.withOpacity(0.1),
            child: Icon(
              isReview ? Icons.rate_review : Icons.pending_actions,
              color: isReview ? Colors.orange : Colors.teal,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      chore.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isWeekly)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          "Weekly",
                          style: TextStyle(fontSize: 10, color: Colors.blue),
                        ),
                      ),
                    const SizedBox(width: 8),
                    if (!isReview)
                      // أيقونة التعديل
                      GestureDetector(
                        onTap: () => _showChoreDialog(choreToEdit: chore),
                        child: const Icon(
                          Icons.edit,
                          size: 18,
                          color: Colors.grey,
                        ),
                      ),
                    const SizedBox(width: 12), // مسافة بين الأيقونتين
                    // ✅ أيقونة الحذف الجديدة
                    GestureDetector(
                      onTap: () => _confirmDeleteChore(chore.id),
                      child: const Icon(
                        Icons.delete_outline,
                        size: 19,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
                // (تم إزالة اسم الطفل من داخل البطاقة لأنه أصبح موجوداً في عنوان القسم)
                Text(
                  "Reward: ${chore.keys} Keys",
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
          if (isReview)
            IconButton(
              icon: const Icon(Icons.visibility, color: Colors.orange),
              onPressed: () => _showReviewDialog(chore),
            ),
        ],
      ),
    );
  }
}
