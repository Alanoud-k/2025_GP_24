// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart'; // لإدخال الأرقام فقط
// import '../../child/models/chore_model.dart'; 
// import '../../child/services/chore_service.dart';

// class ParentChildChoresScreen extends StatefulWidget {
//   final String childName;
//   final String childId;
//   final int parentId; 

//   const ParentChildChoresScreen({
//     super.key,
//     required this.childName,
//     required this.childId,
//     required this.parentId,
//   });

//   @override
//   State<ParentChildChoresScreen> createState() => _ParentChildChoresScreenState();
// }

// class _ParentChildChoresScreenState extends State<ParentChildChoresScreen>
//     with SingleTickerProviderStateMixin {
//   late TabController _tabController;
//   final ChoreService _choreService = ChoreService();
//   late Future<List<ChoreModel>> _choresFuture;

//   // --- Colors & Styles ---
//   static const Color hassalaGreen1 = Color(0xFF37C4BE);
//   static const Color hassalaGreen2 = Color(0xFF2EA49E);
//   static const Color textColor = Color(0xFF2C3E50);
//   static const Color bgColor = Color(0xFFF7FAFC);

//   // ألوان الرسائل الموحدة
//   static const Color _tealMsg = Color(0xFF37C4BE);
//   static const Color _redMsg = Color(0xFFE74C3C);
//   static const Color _greenMsg = Color(0xFF27AE60);

//   final List<String> _daysOfWeek = [
//     'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 2, vsync: this);
//     _choresFuture = _choreService.getChores(widget.childId);
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }

//   void _showMessageBar(
//     String message, {
//     Color backgroundColor = _tealMsg,
//     Duration duration = const Duration(seconds: 3),
//   }) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).clearSnackBars();
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message, style: const TextStyle(color: Colors.white)),
//         backgroundColor: backgroundColor,
//         behavior: SnackBarBehavior.floating,
//         margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         duration: duration,
//       ),
//     );
//   }

//   // دالة إظهار نافذة إضافة المهمة
//   void _showChoreDialog() {
//     final titleController = TextEditingController();
//     final descController = TextEditingController();
//     final keysController = TextEditingController();
    
//     // متغيرات الحالة للنافذة
//     String selectedType = 'One-time';
//     String? selectedDay;
//     TimeOfDay? selectedTime;

//     showDialog(
//       context: context,
//       builder: (context) => StatefulBuilder( 
//         builder: (context, setStateDialog) {
//           // ✅ 1. تغليف الـ Dialog بـ Theme لتغيير اللون البنفسجي إلى التركوازي
//           return Theme(
//             data: Theme.of(context).copyWith(
//               colorScheme: const ColorScheme.light(
//                 primary: hassalaGreen1, // لون الإطار والفوكس
//                 onPrimary: Colors.white, 
//                 surface: Colors.white,
//                 onSurface: textColor,
//               ),
//               textSelectionTheme: const TextSelectionThemeData(
//                 cursorColor: hassalaGreen1,
//                 selectionHandleColor: hassalaGreen1,
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
//               title: const Text("Add New Chore", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
//               content: SingleChildScrollView(
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     TextField(
//                       controller: titleController, 
//                       decoration: const InputDecoration(labelText: "Title", prefixIcon: Icon(Icons.title))
//                     ),
//                     const SizedBox(height: 10),
//                     TextField(
//                       controller: descController, 
//                       decoration: const InputDecoration(labelText: "Description", prefixIcon: Icon(Icons.description))
//                     ),
//                     const SizedBox(height: 10),
//                     TextField(
//                       controller: keysController, 
//                       decoration: const InputDecoration(labelText: "Reward (Keys)", prefixIcon: Icon(Icons.vpn_key)), 
//                       keyboardType: TextInputType.number,
//                       inputFormatters: [FilteringTextInputFormatter.digitsOnly],
//                     ),
//                     const SizedBox(height: 15),

//                     // قائمة اختيار نوع المهمة
//                     DropdownButtonFormField<String>(
//                       dropdownColor: Colors.white, // ✅ 2. خلفية القائمة بيضاء
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

//                     if (selectedType == 'Weekly') ...[
//                       const SizedBox(height: 15),
//                       Row(
//                         children: [
//                           // اختيار اليوم
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
//                           // اختيار الوقت
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
//                                           primary: hassalaGreen1, // الهيدر
//                                           onPrimary: Colors.white,
//                                           surface: Colors.white, // الخلفية
//                                           onSurface: textColor, // النص
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
//                   ],
//                 ),
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.pop(context), 
//                   child: const Text("Cancel", style: TextStyle(color: Colors.grey))
//                 ),
//                 ElevatedButton(
//                   style: ElevatedButton.styleFrom(backgroundColor: hassalaGreen1),
//                   onPressed: () async {
//                     if (titleController.text.isEmpty || keysController.text.isEmpty) {
//                       _showMessageBar("Please fill all required fields", backgroundColor: _redMsg);
//                       return;
//                     }

//                     int keysValue = int.tryParse(keysController.text) ?? 0;
//                     if (keysValue <= 0) {
//                       _showMessageBar("Reward must be greater than 0", backgroundColor: _redMsg);
//                       return;
//                     }

//                     if (selectedType == 'Weekly' && (selectedDay == null || selectedTime == null)) {
//                       _showMessageBar("Please select day and time for weekly chore", backgroundColor: _redMsg);
//                       return;
//                     }
                    
//                     try {
//                       String? formattedTime;
//                       if (selectedTime != null) {
//                         final hour = selectedTime!.hour.toString().padLeft(2, '0');
//                         final minute = selectedTime!.minute.toString().padLeft(2, '0');
//                         formattedTime = "$hour:$minute";
//                       }

//                       await _choreService.createChore(
//                         title: titleController.text,
//                         description: descController.text,
//                         keys: keysValue,
//                         childId: widget.childId,
//                         parentId: widget.parentId.toString(),
//                         type: selectedType,
//                         assignedDay: selectedDay,
//                         assignedTime: formattedTime,
//                       );
                      
//                       if (mounted) Navigator.pop(context);
                      
//                       setState(() {
//                         _choresFuture = _choreService.getChores(widget.childId);
//                       });
                      
//                       _showMessageBar("Chore added successfully!", backgroundColor: _greenMsg);
//                     } catch (e) {
//                       if (mounted) Navigator.pop(context);
//                       _showMessageBar("Error: $e", backgroundColor: _redMsg);
//                     }
//                   },
//                   child: const Text("Create", style: TextStyle(color: Colors.white)),
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
//     return Scaffold(
//       backgroundColor: bgColor,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         centerTitle: true,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: textColor),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: Text(
//           "${widget.childName}'s Chores",
//           style: const TextStyle(color: textColor, fontWeight: FontWeight.w800, fontSize: 20),
//         ),
//       ),
      
//       floatingActionButton: Padding(
//         padding: const EdgeInsets.only(bottom: 90.0), 
//         child: FloatingActionButton(
//           onPressed: () => _showChoreDialog(), 
//           backgroundColor: hassalaGreen1,
//           child: const Icon(Icons.add, color: Colors.white, size: 30),
//         ),
//       ),

//       body: FutureBuilder<List<ChoreModel>>(
//         future: _choresFuture,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator(color: hassalaGreen1));
//           } else if (snapshot.hasError) {
//             return Center(
//               child: Padding(
//                 padding: const EdgeInsets.all(20.0),
//                 child: Text(
//                   "Error: ${snapshot.error}",
//                   style: const TextStyle(color: _redMsg),
//                   textAlign: TextAlign.center,
//                 ),
//               ),
//             );
//           } 
          
//           final allChores = snapshot.data ?? [];
//           final activeChores = allChores.where((c) => c.status != 'Completed').toList();
//           final historyChores = allChores.where((c) => c.status == 'Completed').toList();

//           return Column(
//             children: [
//               const SizedBox(height: 10),
//               Container(
//                 margin: const EdgeInsets.symmetric(horizontal: 20),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(25),
//                   boxShadow: [BoxShadow(color: Colors.black12.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
//                 ),
//                 child: TabBar(
//                   controller: _tabController,
//                   indicatorSize: TabBarIndicatorSize.tab,
//                   indicator: BoxDecoration(
//                     borderRadius: BorderRadius.circular(25),
//                     gradient: const LinearGradient(colors: [hassalaGreen1, hassalaGreen2]),
//                   ),
//                   labelColor: Colors.white,
//                   unselectedLabelColor: Colors.grey,
//                   labelStyle: const TextStyle(fontWeight: FontWeight.bold),
//                   tabs: const [Tab(text: "Active"), Tab(text: "History")],
//                 ),
//               ),
//               const SizedBox(height: 20),
//               Expanded(
//                 child: TabBarView(
//                   controller: _tabController,
//                   children: [
//                     activeChores.isEmpty 
//                       ? const Center(child: Text("No active chores"))
//                       : ListView.builder(
//                           padding: const EdgeInsets.all(20),
//                           itemCount: activeChores.length,
//                           itemBuilder: (context, index) => _buildChoreCard(activeChores[index], isActive: true),
//                         ),
//                     historyChores.isEmpty
//                       ? const Center(child: Text("No history yet"))
//                       : ListView.builder(
//                           padding: const EdgeInsets.all(20),
//                           itemCount: historyChores.length,
//                           itemBuilder: (context, index) => _buildChoreCard(historyChores[index], isActive: false),
//                         ),
//                   ],
//                 ),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildChoreCard(ChoreModel chore, {required bool isActive}) {
//     final bool isWaiting = chore.status == 'Waiting Approval';
//     final bool isWeekly = chore.type == 'Weekly';

//     return Container(
//       margin: const EdgeInsets.only(bottom: 16),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4))],
//         border: isWaiting ? Border.all(color: Colors.orange.withOpacity(0.5), width: 1.5) : null,
//       ),
//       child: Row(
//         children: [
//           Container(
//             width: 50, height: 50,
//             decoration: BoxDecoration(
//               color: isActive ? (isWaiting ? Colors.orange.withOpacity(0.1) : const Color(0xFFE0F2F1)) : Colors.grey.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(15),
//             ),
//             child: Icon(
//               isActive ? Icons.cleaning_services_outlined : Icons.check_circle_outline,
//               color: isActive ? (isWaiting ? Colors.orange : hassalaGreen1) : Colors.grey,
//               size: 26,
//             ),
//           ),
//           const SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Text(chore.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
//                     const SizedBox(width: 8),
//                     if (isWeekly)
//                        Container(
//                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//                          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
//                          child: const Text("Weekly", style: TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold)),
//                        ),
//                   ],
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   isActive ? chore.status : "Completed",
//                   style: TextStyle(fontSize: 12, color: isWaiting ? Colors.orange : Colors.grey, fontWeight: isWaiting ? FontWeight.bold : FontWeight.normal),
//                 ),
//               ],
//             ),
//           ),
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//             decoration: BoxDecoration(
//               color: const Color(0xFFFFF8E1),
//               borderRadius: BorderRadius.circular(20),
//               border: Border.all(color: const Color(0xFFFFECB3)),
//             ),
//             child: Row(
//               children: [
//                 Text("${chore.keys}", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFFA000))),
//                 const SizedBox(width: 4),
//                 const Icon(Icons.vpn_key, size: 14, color: Color(0xFFFFA000)),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import '../../child/models/chore_model.dart'; 
import '../../child/services/chore_service.dart';

class ParentChildChoresScreen extends StatefulWidget {
  final String childName;
  final String childId;
  final int parentId; 

  const ParentChildChoresScreen({
    super.key,
    required this.childName,
    required this.childId,
    required this.parentId,
  });

  @override
  State<ParentChildChoresScreen> createState() => _ParentChildChoresScreenState();
}

class _ParentChildChoresScreenState extends State<ParentChildChoresScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ChoreService _choreService = ChoreService();
  late Future<List<ChoreModel>> _choresFuture;

  // --- Colors & Styles ---
  static const Color hassalaGreen1 = Color(0xFF37C4BE);
  static const Color hassalaGreen2 = Color(0xFF2EA49E);
  static const Color textColor = Color(0xFF2C3E50);
  static const Color bgColor = Color(0xFFF7FAFC);

  static const Color _tealMsg = Color(0xFF37C4BE);
  static const Color _redMsg = Color(0xFFE74C3C);
  static const Color _greenMsg = Color(0xFF27AE60);

  final List<String> _daysOfWeek = [
    'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _choresFuture = _choreService.getChores(widget.childId);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showMessageBar(String message, {Color backgroundColor = _tealMsg}) {
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

  // تحديث البيانات
  void _refreshData() {
    setState(() {
      _choresFuture = _choreService.getChores(widget.childId);
    });
  }

  Future<void> _approveChore(String choreId) async {
    try {
      await _choreService.updateChoreStatus(choreId, 'Completed');
      _refreshData();
      _showMessageBar("Chore Approved!", backgroundColor: _greenMsg);
    } catch (e) {
      _showMessageBar("Failed to approve", backgroundColor: _redMsg);
    }
  }

void _showReviewDialog(ChoreModel chore) {
    String imageUrl = chore.proofUrl ?? "";

    // إصلاح الرابط إذا كان http
    if (imageUrl.isNotEmpty && imageUrl.startsWith('http:')) {
      imageUrl = imageUrl.replaceFirst('http:', 'https:');
    }
    
    debugPrint("🖼️ Displaying Image: $imageUrl");

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Review Proof", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
        
        // 🔥🔥 التعديل هنا: تحديد عرض المحتوى لكسر اللانهائية
        content: SizedBox(
          width: double.maxFinite, // ✅ هذا السطر يحل المشكلة
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Child completed: ${chore.title}", style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 15),
              
              if (imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    height: 250, // طول ثابت
                    width: double.infinity, // الآن هذا سيعمل لأن الأب (SizedBox) له عرض محدد
                    fit: BoxFit.cover,
                    
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 250,
                        width: double.infinity,
                        color: Colors.grey[100],
                        child: const Center(child: CircularProgressIndicator(color: hassalaGreen1)),
                      );
                    },
                    
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint("❌ Image Error: $error");
                      return Container(
                        height: 150, 
                        width: double.infinity,
                        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image, color: Colors.grey, size: 40),
                            SizedBox(height: 8),
                            Text("Image not found", style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      );
                    },
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(20),
                  width: double.infinity,
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                  child: const Column(
                    children: [
                      Icon(Icons.image_not_supported, color: Colors.grey, size: 40),
                      SizedBox(height: 8),
                      Text("No proof image provided.", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: const Text("Close", style: TextStyle(color: Colors.grey))
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _approveChore(chore.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF27AE60),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Approve", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showChoreDialog() {
    // ... (نفس كود النافذة السابق - سأضعه مختصراً هنا للنسخ الكامل)
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final keysController = TextEditingController();
    String selectedType = 'One-time';
    String? selectedDay;
    TimeOfDay? selectedTime;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder( 
        builder: (context, setStateDialog) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(primary: hassalaGreen1, onPrimary: Colors.white, surface: Colors.white),
              inputDecorationTheme: InputDecorationTheme(focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: hassalaGreen1, width: 2), borderRadius: BorderRadius.circular(10)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
            ),
            child: AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text("Add New Chore", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: titleController, decoration: const InputDecoration(labelText: "Title", prefixIcon: Icon(Icons.title))),
                    const SizedBox(height: 10),
                    TextField(controller: descController, decoration: const InputDecoration(labelText: "Description", prefixIcon: Icon(Icons.description))),
                    const SizedBox(height: 10),
                    TextField(controller: keysController, decoration: const InputDecoration(labelText: "Reward (Keys)", prefixIcon: Icon(Icons.vpn_key)), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
                    const SizedBox(height: 15),
                    DropdownButtonFormField<String>(
                      dropdownColor: Colors.white,
                      decoration: const InputDecoration(labelText: "Chore Type", prefixIcon: Icon(Icons.repeat)),
                      value: selectedType,
                      items: const [DropdownMenuItem(value: 'One-time', child: Text("One-time")), DropdownMenuItem(value: 'Weekly', child: Text("Weekly"))],
                      onChanged: (val) { if (val != null) setStateDialog(() { selectedType = val; if (val == 'One-time') { selectedDay = null; selectedTime = null; } }); },
                    ),
                    if (selectedType == 'Weekly') ...[
                      const SizedBox(height: 15),
                      Row(children: [
                        Expanded(child: DropdownButtonFormField<String>(dropdownColor: Colors.white, decoration: const InputDecoration(labelText: "Day", contentPadding: EdgeInsets.symmetric(horizontal: 10)), value: selectedDay, items: _daysOfWeek.map((day) => DropdownMenuItem(value: day, child: Text(day, style: const TextStyle(fontSize: 14)))).toList(), onChanged: (val) => setStateDialog(() => selectedDay = val))),
                        const SizedBox(width: 10),
                        Expanded(child: InkWell(onTap: () async { final time = await showTimePicker(context: context, initialTime: TimeOfDay.now(), builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: hassalaGreen1, onPrimary: Colors.white, surface: Colors.white)), child: child!)); if (time != null) setStateDialog(() => selectedTime = time); }, child: InputDecorator(decoration: const InputDecoration(labelText: "Time", suffixIcon: Icon(Icons.access_time, size: 20), contentPadding: EdgeInsets.symmetric(horizontal: 10)), child: Text(selectedTime != null ? selectedTime!.format(context) : "Select Time", style: const TextStyle(fontSize: 14))))),
                      ]),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: hassalaGreen1),
                  onPressed: () async {
                    int keysValue = int.tryParse(keysController.text) ?? 0;
                    if (titleController.text.isEmpty || keysValue <= 0) { _showMessageBar("Invalid input", backgroundColor: _redMsg); return; }
                    String? formattedTime;
                    if (selectedTime != null) formattedTime = "${selectedTime!.hour.toString().padLeft(2,'0')}:${selectedTime!.minute.toString().padLeft(2,'0')}";
                    try {
                      await _choreService.createChore(title: titleController.text, description: descController.text, keys: keysValue, childId: widget.childId, parentId: widget.parentId.toString(), type: selectedType, assignedDay: selectedDay, assignedTime: formattedTime);
                      if (mounted) Navigator.pop(context);
                      _refreshData();
                      _showMessageBar("Chore added!", backgroundColor: _greenMsg);
                    } catch (e) { _showMessageBar("Error: $e", backgroundColor: _redMsg); }
                  },
                  child: const Text("Create", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: textColor), onPressed: () => Navigator.pop(context)),
        title: Text("${widget.childName}'s Chores", style: const TextStyle(color: textColor, fontWeight: FontWeight.w800, fontSize: 20)),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90.0), 
        child: FloatingActionButton(onPressed: () => _showChoreDialog(), backgroundColor: hassalaGreen1, child: const Icon(Icons.add, color: Colors.white, size: 30)),
      ),
      body: FutureBuilder<List<ChoreModel>>(
        future: _choresFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: hassalaGreen1));
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: _redMsg)));
          
          final allChores = snapshot.data ?? [];
          // هنا نعتبر Submitted أيضاً من المهام النشطة لكن بانتظار الموافقة
          final activeChores = allChores.where((c) => c.status != 'Completed').toList();
          final historyChores = allChores.where((c) => c.status == 'Completed').toList();

          return Column(
            children: [
              const SizedBox(height: 10),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black12.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(borderRadius: BorderRadius.circular(25), gradient: const LinearGradient(colors: [hassalaGreen1, hassalaGreen2])),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  tabs: const [Tab(text: "Active"), Tab(text: "History")],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    activeChores.isEmpty ? const Center(child: Text("No active chores")) : ListView.builder(padding: const EdgeInsets.all(20), itemCount: activeChores.length, itemBuilder: (context, index) => _buildChoreCard(activeChores[index], isActive: true)),
                    historyChores.isEmpty ? const Center(child: Text("No history yet")) : ListView.builder(padding: const EdgeInsets.all(20), itemCount: historyChores.length, itemBuilder: (context, index) => _buildChoreCard(historyChores[index], isActive: false)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildChoreCard(ChoreModel chore, {required bool isActive}) {
    final bool isSubmitted = chore.status == 'Submitted' || chore.status == 'Waiting Approval';
    final bool isWeekly = chore.type == 'Weekly';

    return GestureDetector(
      // ✅ إذا كانت بانتظار الموافقة، نسمح بالضغط لفتح نافذة المراجعة
      onTap: (isActive && isSubmitted) ? () => _showReviewDialog(chore) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4))],
          border: isSubmitted ? Border.all(color: Colors.orange.withOpacity(0.5), width: 1.5) : null,
        ),
        child: Row(
          children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                color: isActive ? (isSubmitted ? Colors.orange.withOpacity(0.1) : const Color(0xFFE0F2F1)) : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                isActive ? (isSubmitted ? Icons.visibility : Icons.cleaning_services_outlined) : Icons.check_circle_outline,
                color: isActive ? (isSubmitted ? Colors.orange : hassalaGreen1) : Colors.grey,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(chore.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                      const SizedBox(width: 8),
                      if (isWeekly)
                         Container(
                           padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                           decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
                           child: const Text("Weekly", style: TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold)),
                         ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isActive ? (isSubmitted ? "Waiting Review" : chore.status) : "Completed",
                    style: TextStyle(fontSize: 12, color: isSubmitted ? Colors.orange : Colors.grey, fontWeight: isSubmitted ? FontWeight.bold : FontWeight.normal),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFFECB3)),
              ),
              child: Row(
                children: [
                  Text("${chore.keys}", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFFA000))),
                  const SizedBox(width: 4),
                  const Icon(Icons.vpn_key, size: 14, color: Color(0xFFFFA000)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}