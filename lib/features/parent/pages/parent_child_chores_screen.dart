import 'package:flutter/material.dart';

class ParentChildChoresScreen extends StatefulWidget {
  final String childName;

  const ParentChildChoresScreen({
    super.key,
    required this.childName,
  });

  @override
  State<ParentChildChoresScreen> createState() => _ParentChildChoresScreenState();
}

class _ParentChildChoresScreenState extends State<ParentChildChoresScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // --- Mock Data (بيانات شكلية فقط) ---
  final List<Map<String, dynamic>> _activeChores = [
    {
      'title': 'Clean Room',
      'description': 'Make bed and organize desk',
      'keys': 5,
      'type': 'One-time',
      'status': 'In Progress',
    },
    {
      'title': 'Wash Dishes',
      'description': 'After lunch',
      'keys': 3,
      'type': 'Weekly',
      'status': 'Waiting Approval', // حالة تنتظر موافقة الأب
    },
  ];

  final List<Map<String, dynamic>> _historyChores = [
    {
      'title': 'Finish Homework',
      'description': 'Math Chapter 1',
      'keys': 10,
      'date': 'Yesterday',
      'status': 'Completed',
    },
    {
      'title': 'Walk the Dog',
      'description': '',
      'keys': 4,
      'date': '2 days ago',
      'status': 'Completed',
    },
  ];

  // --- Colors ---
  static const Color hassalaGreen1 = Color(0xFF37C4BE);
  static const Color hassalaGreen2 = Color(0xFF2EA49E);
  static const Color textColor = Color(0xFF2C3E50);
  static const Color bgColor = Color(0xFFF7FAFC);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
          style: const TextStyle(
            color: textColor,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          
          // --- Tab Bar ---
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
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
                borderRadius: BorderRadius.circular(25),
                gradient: const LinearGradient(
                  colors: [hassalaGreen1, hassalaGreen2],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: "Active"),
                Tab(text: "History"),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // --- Content ---
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Active List
                ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _activeChores.length,
                  itemBuilder: (context, index) {
                    return _buildChoreCard(_activeChores[index], isActive: true);
                  },
                ),

                // Tab 2: History List
                ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _historyChores.length,
                  itemBuilder: (context, index) {
                    return _buildChoreCard(_historyChores[index], isActive: false);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChoreCard(Map<String, dynamic> chore, {required bool isActive}) {
    final bool isWaiting = chore['status'] == 'Waiting Approval';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: isWaiting 
          ? Border.all(color: Colors.orange.withOpacity(0.5), width: 1.5) 
          : null,
      ),
      child: Row(
        children: [
          // Icon Container
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isActive 
                  ? (isWaiting ? Colors.orange.withOpacity(0.1) : const Color(0xFFE0F2F1))
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              isActive ? Icons.cleaning_services_outlined : Icons.check_circle_outline,
              color: isActive 
                  ? (isWaiting ? Colors.orange : hassalaGreen1)
                  : Colors.grey,
              size: 26,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Texts
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chore['title'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isActive 
                      ? (chore['status'] ?? chore['type']) 
                      : "Finished ${chore['date']}",
                  style: TextStyle(
                    fontSize: 12,
                    color: isWaiting ? Colors.orange : Colors.grey,
                    fontWeight: isWaiting ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),

          // Reward Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1), // Light Yellow
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFFECB3)),
            ),
            child: Row(
              children: [
                Text(
                  "${chore['keys']}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFA000),
                  ),
                ),
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