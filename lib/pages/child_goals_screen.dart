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

      // App bar
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(85),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 5,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new,
                        size: 20, color: Colors.black87),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const Spacer(),
                  const Text(
                    'Goals',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),
        ),
      ),

      // Body
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: const [
          _SavingBalanceCard(balance: 70.0),
          SizedBox(height: 16),
          _EmptyGoalsCard(),
        ],
      ),

      // Bottom nav
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
        },
      ),
    );
  }
}

// Saving balance card
class _SavingBalanceCard extends StatelessWidget {
  const _SavingBalanceCard({required this.balance});
  final double balance;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 2.2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'saving balance',
              style: TextStyle(fontSize: 13, color: Color(0xFF6E6E6E)),
            ),
            const SizedBox(height: 6),
            Text(
              '﷼ ${balance.toStringAsFixed(1)}',
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

// Empty goals card
class _EmptyGoalsCard extends StatelessWidget {
  const _EmptyGoalsCard();

  static const kAddBtn = Color(0xFF9FE5E2);
  static const kTextSecondary = Color(0xFF6E6E6E);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 2.2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),

      // ✅ Added navigation to Add Goal page
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.pushNamed(context, '/childAddGoal');
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Start your savings journey",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: kTextSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "set your first goal now!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: kTextSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),

              // + icon + text
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: const BoxDecoration(
                      color: kAddBtn,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, size: 30, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'Add new goal',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
