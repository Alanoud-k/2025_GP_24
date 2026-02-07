import 'package:flutter/material.dart';
import '../../child/models/chore_model.dart'; 
import '../../child/services/chore_service.dart';

class ParentChildChoresScreen extends StatefulWidget {
  final String childName;
  final String childId;
  final int parentId; // ✅ أضفنا هذا لكي نتمكن من إنشاء المهمة

  const ParentChildChoresScreen({
    super.key,
    required this.childName,
    required this.childId,
    required this.parentId, // ✅ مطلوب
  });

  @override
  State<ParentChildChoresScreen> createState() => _ParentChildChoresScreenState();
}

class _ParentChildChoresScreenState extends State<ParentChildChoresScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ChoreService _choreService = ChoreService();
  late Future<List<ChoreModel>> _choresFuture;

  // --- Colors ---
  static const Color hassalaGreen1 = Color(0xFF37C4BE);
  static const Color hassalaGreen2 = Color(0xFF2EA49E);
  static const Color textColor = Color(0xFF2C3E50);
  static const Color bgColor = Color(0xFFF7FAFC);

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

  // ✅ دالة إظهار نافذة إضافة المهمة
  void _showChoreDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final keysController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Add New Chore", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: "Title")),
            TextField(controller: descController, decoration: const InputDecoration(labelText: "Description")),
            TextField(
              controller: keysController, 
              decoration: const InputDecoration(labelText: "Reward (Keys)"), 
              keyboardType: TextInputType.number
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: hassalaGreen1),
            onPressed: () async {
              if (titleController.text.isEmpty || keysController.text.isEmpty) return;
              
              try {
                // ✅ استدعاء السيرفر
                await _choreService.createChore(
                  title: titleController.text,
                  description: descController.text,
                  keys: int.parse(keysController.text),
                  childId: widget.childId,
                  parentId: widget.parentId.toString(),
                );
                Navigator.pop(context);
                // ✅ تحديث الصفحة
                setState(() {
                  _choresFuture = _choreService.getChores(widget.childId);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Chore added successfully!")),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error: $e")),
                );
              }
            },
            child: const Text("Create", style: TextStyle(color: Colors.white)),
          ),
        ],
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "${widget.childName}'s Chores",
          style: const TextStyle(color: textColor, fontWeight: FontWeight.w800, fontSize: 20),
        ),
      ),
      
      // ✅ الزر العائم مع الإصلاح (مرفوع للأعلى)
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90.0), 
        child: FloatingActionButton(
          onPressed: () => _showChoreDialog(), 
          backgroundColor: hassalaGreen1,
          child: const Icon(Icons.add, color: Colors.white, size: 30),
        ),
      ),

      body: FutureBuilder<List<ChoreModel>>(
        future: _choresFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: hassalaGreen1));
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  "Error: ${snapshot.error}",
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          } 
          
          final allChores = snapshot.data ?? [];
          final activeChores = allChores.where((c) => c.status != 'Completed').toList();
          final historyChores = allChores.where((c) => c.status == 'Completed').toList();

          return Column(
            children: [
              const SizedBox(height: 10),
              // --- Tab Bar ---
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [BoxShadow(color: Colors.black12.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    gradient: const LinearGradient(colors: [hassalaGreen1, hassalaGreen2]),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  tabs: const [Tab(text: "Active"), Tab(text: "History")],
                ),
              ),
              const SizedBox(height: 20),
              // --- Content ---
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    activeChores.isEmpty 
                      ? const Center(child: Text("No active chores"))
                      : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: activeChores.length,
                          itemBuilder: (context, index) => _buildChoreCard(activeChores[index], isActive: true),
                        ),
                    historyChores.isEmpty
                      ? const Center(child: Text("No history yet"))
                      : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: historyChores.length,
                          itemBuilder: (context, index) => _buildChoreCard(historyChores[index], isActive: false),
                        ),
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
    final bool isWaiting = chore.status == 'Waiting Approval';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4))],
        border: isWaiting ? Border.all(color: Colors.orange.withOpacity(0.5), width: 1.5) : null,
      ),
      child: Row(
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              color: isActive ? (isWaiting ? Colors.orange.withOpacity(0.1) : const Color(0xFFE0F2F1)) : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              isActive ? Icons.cleaning_services_outlined : Icons.check_circle_outline,
              color: isActive ? (isWaiting ? Colors.orange : hassalaGreen1) : Colors.grey,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(chore.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 4),
                Text(
                  isActive ? chore.status : "Completed",
                  style: TextStyle(fontSize: 12, color: isWaiting ? Colors.orange : Colors.grey, fontWeight: isWaiting ? FontWeight.bold : FontWeight.normal),
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
    );
  }
}