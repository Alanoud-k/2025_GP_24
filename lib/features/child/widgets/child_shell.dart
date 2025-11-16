import 'package:flutter/material.dart';

// Pages
import '../pages/child_homepage_screen.dart';
import '../pages/child_goals_screen.dart';
import '../pages/child_rewards_screen.dart';
import '../pages/child_game_screen.dart';
import '../pages/child_card_screen.dart';
import '../pages/child_more_screen.dart';

// Widgets
import '../widgets/child_bottom_nav_bar.dart';

class ChildShell extends StatefulWidget {
  final int childId;
  final String baseUrl;

  const ChildShell({
    super.key,
    required this.childId,
    required this.baseUrl,
  });

  @override
  State<ChildShell> createState() => _ChildShellState();
}

class _ChildShellState extends State<ChildShell> {
  int currentIndex = 2; // Home tab as default

  @override
  Widget build(BuildContext context) {
    // Shell pages in navigation order
    final List<Widget> pages = [
      ChildRewardsScreen(childId: widget.childId, baseUrl: widget.baseUrl), // 0
      ChildGameScreen(childId: widget.childId, baseUrl: widget.baseUrl), // 1
      ChildHomePageScreen(childId: widget.childId, baseUrl: widget.baseUrl), // 2
      ChildCardScreen(childId: widget.childId, baseUrl: widget.baseUrl), // 3
      ChildMoreScreen(childId: widget.childId, baseUrl: widget.baseUrl), // 4
    ];

    return Scaffold(
      backgroundColor: const Color(0xffF7F8FA),

      body: SafeArea(
        child: pages[currentIndex],
      ),

      // Custom bottom navigation bar with floating home button
      bottomNavigationBar: ChildBottomNavBar(
        currentIndex: currentIndex,
        onTap: (i) {
          setState(() => currentIndex = i);
        },
      ),
    );
  }
}
