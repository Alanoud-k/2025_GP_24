import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_app/utils/check_auth.dart';
// استدعاء المودل والخدمة
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
  
  // قائمة المهام الحقيقية القادمة من السيرفر
  List<ChoreModel> _allChores = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAllData();
  }

  // دالة جلب كل المهام المرتبطة بالأب
  Future<void> _loadAllData() async {
    await checkAuthStatus(context);
    try {
      // نفترض أننا أضفنا دالة في ChoreService تجلب كل مهام الأب
      final chores = await _choreService.getAllParentChores(widget.parentId.toString());
      if (mounted) {
        setState(() {
          _allChores = chores;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      debugPrint("Error loading chores: $e");
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

    // تصفية المهام حسب الحالة
    final pendingChores = _allChores.where((c) => c.status == 'Waiting Approval').toList();
    final activeChores = _allChores.where((c) => c.status == 'In Progress').toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      // ... داخل الـ Scaffold
      floatingActionButton: Padding(
        // 👇 قمنا بزيادة القيمة من 20 إلى 90 لرفع الزر فوق الناف بار
        padding: const EdgeInsets.only(bottom: 90.0), 
        child: FloatingActionButton(
          onPressed: () => _showChoreDialog(), 
          backgroundColor: const Color(0xFF37C4BE), // hassalaGreen1
          child: const Icon(Icons.add, color: Colors.white, size: 30),
        ),
      ),
      // ... باقي الكود
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
              // --- Header ---
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Text(
                  "All Family Chores",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ),

              // --- Tab Bar ---
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(color: Colors.black12.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
                  ],
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: const LinearGradient(colors: [hassalaGreen1, hassalaGreen2]),
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

              // --- Content ---
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildChoreList(pendingChores, isReview: true),
                    _buildChoreList(activeChores, isReview: false),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ودجت بناء القوائم
  Widget _buildChoreList(List<ChoreModel> chores, {required bool isReview}) {
    if (chores.isEmpty) {
      return Center(
        child: Text(isReview ? "No chores to review" : "No active chores"),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: chores.length,
      itemBuilder: (context, index) {
        final chore = chores[index];
        return _buildChoreCard(chore, isReview);
      },
    );
  }

  // كارت المهمة الموحد
  Widget _buildChoreCard(ChoreModel chore, bool isReview) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isReview ? Colors.orange.withOpacity(0.1) : Colors.teal.withOpacity(0.1),
            child: Icon(isReview ? Icons.rate_review : Icons.pending_actions, color: isReview ? Colors.orange : Colors.teal),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(chore.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text("Reward: ${chore.keys} Keys", style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
          if (isReview)
            IconButton(
              icon: const Icon(Icons.check_circle, color: Colors.green),
              onPressed: () => _approveChore(chore.id),
            ),
        ],
      ),
    );
  }

  // منطق الموافقة (يرسل PATCH للسيرفر)
  Future<void> _approveChore(String choreId) async {
    try {
      // كود التحديث في السيرفر
      await _choreService.updateChoreStatus(choreId, 'Completed');
      _loadAllData(); // إعادة تحميل البيانات لتحديث الشاشة
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to approve")));
    }
  }

  void _showChoreDialog() {
    // هنا نضع Dialog إضافة مهمة جديدة الذي صممناه سابقاً
    // مع تعديل دالة الحفظ لترسل البيانات للسيرفر عبر ChoreService
  }
}