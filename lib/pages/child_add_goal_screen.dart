import 'package:flutter/material.dart';

class ChildAddGoalScreen extends StatelessWidget {
  const ChildAddGoalScreen({super.key});

  // 🎨 Colors
  static const kBg = Color(0xFFF7F8FA);
  static const kCard = Color(0xFF9FE5E2);
  static const kAddBtn = Color(0xFF75C6C3); // ✅ exact Add button color
  static const kTextSecondary = Color(0xFF6E6E6E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,

      // ✅ Fintech-style App Bar
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

      // ✅ Centered card slightly higher
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Align(
                alignment: Alignment.center,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: _GoalFormCard(),
                  ),
                ),
              ),
            ),
          );
        },
      ),

      // ✅ Bottom Navigation
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: kAddBtn,
        unselectedItemColor: const Color(0xFFAAAAAA),
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.sports_esports), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.card_giftcard), label: ''),
        ],
      ),
    );
  }
}

class _GoalFormCard extends StatelessWidget {
  const _GoalFormCard();

  static const kCard = Color(0xFF9FE5E2);
  static const kAddBtn = Color(0xFF75C6C3);
  static const kTextSecondary = Color(0xFF6E6E6E);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 36),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            const Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: Text(
                  'Create a new goal',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),

            // Goal name
            const Text(
              'Goal name',
              style: TextStyle(
                fontSize: 13,
                color: kTextSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _inputField(),

            const SizedBox(height: 22),

            // Amount field
            const Text(
              'Amount of money need to save',
              style: TextStyle(
                fontSize: 13,
                color: kTextSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _inputField(keyboardType: TextInputType.number),

            const SizedBox(height: 36),

            // ✅ Buttons (exact look like image)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _flatPillButton('Add', bg: kAddBtn, textColor: Colors.black),
                const SizedBox(width: 16),
                _flatPillButton('Cancel',
                    bg: Colors.white, textColor: Colors.black),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Input field
  static Widget _inputField({TextInputType? keyboardType}) {
    return TextField(
      keyboardType: keyboardType,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // ✅ Flat style button (like image)
  static Widget _flatPillButton(String text,
      {required Color bg, required Color textColor}) {
    return Container(
      width: 120,
      height: 44,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
