import 'package:flutter/material.dart';

class ChildGoalsScreen extends StatefulWidget {
  const ChildGoalsScreen({super.key});

  @override
  State<ChildGoalsScreen> createState() => _ChildGoalsScreenState();
}

class _ChildGoalsScreenState extends State<ChildGoalsScreen> {
  // Colors
  static const kBg = Color(0xFFF7F8FA);
  static const kAddBtn = Color(0xFF9FE5E2);
  static const kNavInactive = Color(0xFFAAAAAA);
  static const kNavActive = Color(0xFF67AFAC);
  static const kTextSecondary = Color(0xFF6E6E6E);

  int _navIndex = 2; // active icon (Home)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.6,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.black87),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        centerTitle: true,
        title: const Text(
          'Goals',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: const [
          _SavingBalanceCard(balance: 70.0),
          SizedBox(height: 16),
          _EmptyGoalsCard(),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        currentIndex: _navIndex,
        selectedItemColor: kNavActive,
        unselectedItemColor: kNavInactive,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.card_giftcard), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.sports_esports), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: ''),
        ],
        onTap: (i) {
          setState(() => _navIndex = i);
          // Add navigation logic here
        },
      ),
    );
  }
}

class _SavingBalanceCard extends StatelessWidget {
  const _SavingBalanceCard({required this.balance});

  final double balance;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2.2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'saving balance',
              style: TextStyle(fontSize: 12, color: Color(0xFF6E6E6E)),
            ),
            const SizedBox(height: 6),
            Text(
              '﷼ ${balance.toStringAsFixed(1)}',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyGoalsCard extends StatelessWidget {
  const _EmptyGoalsCard();

  static const kAddBtn = Color(0xFF9FE5E2);
  static const kTextSecondary = Color(0xFF6E6E6E);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2.2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Open add goal page
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "you don't have any goal yet\nclick '+' to add",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: kTextSecondary, height: 1.4),
              ),
              const SizedBox(height: 18),
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: kAddBtn,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, size: 30, color: Colors.white),
              ),
              const SizedBox(height: 8),
              const Text(
                'Add new goal',
                style: TextStyle(fontSize: 13, color: Colors.black87),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
