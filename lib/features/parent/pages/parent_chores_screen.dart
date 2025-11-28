// // lib/features/parent/pages/parent_chores_screen.dart

// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:my_app/utils/check_auth.dart'; // ✅ ADD THIS

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

// class _ParentChoresScreenState extends State<ParentChoresScreen> {
//   bool _loading = true;
//   String? token;

//   @override
//   void initState() {
//     super.initState();
//     _initializeAuthCheck();
//   }

//   Future<void> _initializeAuthCheck() async {
//     await checkAuthStatus(context);

//     final prefs = await SharedPreferences.getInstance();
//     token = prefs.getString("token") ?? widget.token;

//     if (token == null || token!.isEmpty) {
//       _forceLogout();
//       return;
//     }

//     if (mounted) setState(() => _loading = false);
//   }

//   void _forceLogout() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.clear();

//     if (mounted) {
//       Navigator.pushNamedAndRemoveUntil(context, '/mobile', (route) => false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_loading) {
//       return const Scaffold(
//         backgroundColor: Color(0xFFF7F8FA),
//         body: Center(child: CircularProgressIndicator(color: Colors.teal)),
//       );
//     }

//     return SafeArea(
//       child: Container(
//         color: const Color(0xFFF7F8FA),
//         padding: const EdgeInsets.all(20),
//         child: const Center(
//           child: Text(
//             "Chores screen will be implemented later",
//             style: TextStyle(fontSize: 16, color: Colors.black87),
//             textAlign: TextAlign.center,
//           ),
//         ),
//       ),
//     );
//   }
// }
// lib/features/parent/pages/parent_chores_screen.dart

// lib/features/parent/pages/parent_chores_screen.dart

// lib/features/parent/pages/parent_chores_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_app/utils/check_auth.dart';

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
  String? token;
  late TabController _tabController;

  // قائمة أسماء الأطفال الوهمية لاستخدامها في الـ Dropdown
  final List<String> _mockChildrenNames = ['Ahmed', 'Sara', 'Khalid'];

  // --- Mock Data ---
  final List<Map<String, dynamic>> _pendingReviews = [
    {
      'id': 101,
      'title': 'Clean Room',
      'description': 'Make sure to organize the desk',
      'child': 'Ahmed',
      'keys': 5,
      'status': 'Submitted',
      'proof': 'https://via.placeholder.com/150' // رابط وهمي للصورة
    },
    {
      'id': 102,
      'title': 'Water Plants',
      'description': 'Water all plants in the balcony',
      'child': 'Sara',
      'keys': 2,
      'status': 'Submitted',
      'proof': 'https://via.placeholder.com/150'
    },
  ];

  final List<Map<String, dynamic>> _activeChores = [
    {
      'id': 201,
      'title': 'Wash Dishes',
      'description': 'After lunch',
      'child': 'Sara',
      'type': 'Weekly',
      'keys': 3
    },
    {
      'id': 202,
      'title': 'Finish Homework',
      'description': 'Math and Science',
      'child': 'Ahmed',
      'type': 'One-time',
      'keys': 10
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeAuthCheck();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeAuthCheck() async {
    await checkAuthStatus(context);

    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString("token") ?? widget.token;

    if (token == null || token!.isEmpty) {
      _forceLogout();
      return;
    }

    if (mounted) setState(() => _loading = false);
  }

  void _forceLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/mobile', (route) => false);
    }
  }

  // --- Logic Methods ---

  void _approveChore(int index) {
    setState(() {
      _pendingReviews.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chore approved! Keys sent to child.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _rejectChore(int index) {
    setState(() {
      _pendingReviews.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chore rejected.'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _deleteActiveChore(int index) {
    final deletedItem = _activeChores[index];
    setState(() {
      _activeChores.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${deletedItem['title']} deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              _activeChores.insert(index, deletedItem);
            });
          },
        ),
      ),
    );
  }

  // Show Proof Dialog (Simulated Image)
  void _showProofDialog(String title, String proofUrl) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Proof for: $title"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.image, size: 80, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            const Text(
              "Here is the proof image uploaded by the child.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  // --- New Styled Dialog ---

  void _showChoreDialog({Map<String, dynamic>? chore, int? index}) {
    final isEditing = chore != null;
    final titleController = TextEditingController(text: chore?['title'] ?? '');
    final descController = TextEditingController(text: chore?['description'] ?? '');
    final keysController = TextEditingController(text: chore?['keys']?.toString() ?? '');

    String? selectedChild = chore?['child'];
    if (selectedChild != null && !_mockChildrenNames.contains(selectedChild)) {
      selectedChild = null;
    }

    const hassalaColor = Color(0xFF37C4BE);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return Dialog(
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
                    // --- Header ---
                    Center(
                      child: Text(
                        isEditing ? "Edit Chore" : "New Chore",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2C3E50),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),

                    // --- Title Field ---
                    _buildModernLabel("Chore Title"),
                    _buildModernTextField(
                      controller: titleController,
                      hint: "e.g. Clean Room",
                      icon: Icons.cleaning_services_outlined,
                    ),
                    const SizedBox(height: 16),

                    // --- Description Field ---
                    _buildModernLabel("Description (Optional)"),
                    _buildModernTextField(
                      controller: descController,
                      hint: "Add details...",
                      icon: Icons.description_outlined,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),

                    // --- Child Dropdown ---
                    _buildModernLabel("Assign to"),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedChild,
                          hint: Row(
                            children: const [
                              Icon(Icons.person_outline, color: Colors.grey, size: 22),
                              SizedBox(width: 10),
                              Text("Select Child", style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down, color: hassalaColor),
                          items: _mockChildrenNames.map((String name) {
                            return DropdownMenuItem<String>(
                              value: name,
                              child: Row(
                                children: [
                                  const Icon(Icons.face, color: hassalaColor, size: 22),
                                  const SizedBox(width: 10),
                                  Text(name, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2C3E50))),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) => setStateDialog(() => selectedChild = val),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- Reward Field ---
                    _buildModernLabel("Reward"),
                    _buildModernTextField(
                      controller: keysController,
                      hint: "Number of Keys",
                      icon: Icons.vpn_key_outlined,
                      keyboardType: TextInputType.number,
                      isLast: true,
                    ),
                    const SizedBox(height: 30),

                    // --- Buttons ---
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
                              if (titleController.text.isEmpty || selectedChild == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please fill required fields')),
                                );
                                return;
                              }
                              Navigator.pop(context);
                              // Save Logic
                              if (isEditing && index != null) {
                                setState(() {
                                  _activeChores[index] = {
                                    ...chore!,
                                    'title': titleController.text,
                                    'description': descController.text,
                                    'child': selectedChild,
                                    'keys': int.tryParse(keysController.text) ?? 0,
                                  };
                                });
                              } else {
                                // Add Logic (Mock)
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Chore assigned successfully!'), backgroundColor: hassalaColor),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: hassalaColor,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: Text(
                              isEditing ? "Save Changes" : "Assign Chore",
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
          );
        },
      ),
    );
  }

  // Helper: Label Text
  Widget _buildModernLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Color(0xFF607D8B),
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  // Helper: Modern Text Field
  Widget _buildModernTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    bool isLast = false,
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
        maxLines: maxLines,
        textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
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

  Widget _buildDialogTextField(
      TextEditingController controller, String hintText,
      {TextInputType? keyboardType, int maxLines = 1}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFFDFDFD),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF37C4BE)),
        ),
      ),
    );
  }

@override
  Widget build(BuildContext context) {
    const hassalaGreen1 = Color(0xFF37C4BE);
    const hassalaGreen2 = Color(0xFF2EA49E);

    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7F8FA),
        body: Center(child: CircularProgressIndicator(color: hassalaGreen1)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA), // تأكيد لون الخلفية
      
      // ✅ التعديل هنا: رفع الزر للأعلى
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90.0), // رفع الزر 90 بيكسل
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
              // ... (باقي كود الهيدر والتاب بار كما هو)
              // ====== HEADER ======
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: const [
                    Text( // تم إزالة Expanded و TextAlign
                      "Manage Chores",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // ====== TAB BAR ======
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
                  indicatorSize: TabBarIndicatorSize.tab, // يغطي كامل المساحة
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: const LinearGradient(
                      colors: [hassalaGreen1, hassalaGreen2],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey,
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                  tabs: const [
                    Tab(text: "Pending Approval"),
                    Tab(text: "Active Chores"),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ====== TAB VIEW ======
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Pending Reviews
                    _pendingReviews.isEmpty
                        ? _buildEmptyState("No chores waiting for review.")
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _pendingReviews.length,
                            itemBuilder: (context, index) {
                              final item = _pendingReviews[index];
                              return _buildReviewCard(item, index);
                            },
                          ),

                    // Tab 2: Active Chores
                    _activeChores.isEmpty
                        ? _buildEmptyState("No active chores assigned.")
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _activeChores.length,
                            itemBuilder: (context, index) {
                              final item = _activeChores[index];
                              return _buildActiveChoreItem(item, index);
                            },
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Widgets ---

  // 1. Pending Review Card
  Widget _buildReviewCard(Map<String, dynamic> item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: const Icon(Icons.check_circle_outline,
                color: Colors.orange, size: 32),
            title: Text(
              item['title'],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF2C3E50),
              ),
            ),
            subtitle: Text(
              "${item['child']} • Reward: ${item['keys']} Keys",
              style: const TextStyle(fontSize: 13, color: Color(0xFF607D8B)),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: () => _approveChore(index),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () => _rejectChore(index),
                ),
              ],
            ),
          ),
          // "View Proof" Button
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () =>
                    _showProofDialog(item['title'], item['proof'] ?? ''),
                icon: const Icon(Icons.visibility, size: 18),
                label: const Text("View Proof"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF37C4BE),
                  side: const BorderSide(color: Color(0xFF37C4BE)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 2. Active Chore Item
  Widget _buildActiveChoreItem(Map<String, dynamic> item, int index) {
    const hassalaGreen2 = Color(0xFF2EA49E);

    return Dismissible(
      key: Key(item['id'].toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white, size: 30),
      ),
      onDismissed: (direction) {
        _deleteActiveChore(index);
      },
      child: GestureDetector(
        onTap: () => _showChoreDialog(chore: item, index: index),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black12.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            // تم تعديل الحاوية هنا لتشمل أيقونة المفتاح أسفل الرقم
            leading: Container(
              padding: const EdgeInsets.all(8),
              width: 50, // تحديد عرض مناسب
              decoration: BoxDecoration(
                color: hassalaGreen2.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12), // شكل مربع بحواف ناعمة
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "${item['keys']}",
                    style: const TextStyle(
                      color: hassalaGreen2,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Icon(Icons.vpn_key, size: 14, color: hassalaGreen2),
                ],
              ),
            ),
            title: Text(
              item['title'],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF2C3E50),
              ),
            ),
            subtitle: Text(
              "${item['child']} • ${item['type']}",
              style: const TextStyle(fontSize: 13, color: Color(0xFF607D8B)),
            ),
            trailing: const Icon(Icons.edit, color: Colors.grey, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.assignment_outlined,
              size: 80, color: Color(0xFFB0BEC5)),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF607D8B),
            ),
          ),
        ],
      ),
    );
  }
}