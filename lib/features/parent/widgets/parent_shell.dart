import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:my_app/utils/check_auth.dart';

import '../pages/parent_homepage_screen.dart';
import '../pages/parent_chores_screen.dart';
import '../pages/parent_allowance_screen.dart';
import '../pages/parent_gifts_screen.dart';
import '../pages/parent_more_screen.dart';

class ParentShell extends StatefulWidget {
  final int parentId;
  final String token;

  const ParentShell({super.key, required this.parentId, required this.token});

  @override
  State<ParentShell> createState() => _ParentShellState();
}

class _ParentShellState extends State<ParentShell> {
  late int parentId;
  late String token;

  bool _initialized = false;

  // 0: Home, 1: Chores, 2: Allowance, 3: Gifts, 4: More
  int _index = 0;

  @override
  void initState() {
    super.initState();
    parentId = widget.parentId;
    token = widget.token;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)?.settings.arguments as Map?;
      if (args != null) {
        parentId = args['parentId'] ?? parentId;
        token = args['token'] ?? token;
      }
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.teal)),
      );
    }

    // Pages order must match nav indexes
    final pages = [
      ParentHomeScreen(parentId: parentId, token: token), // 0
      ParentChoresScreen(parentId: parentId, token: token), // 1
      ParentAllowanceScreen(
        parentId: parentId,
        token: token,
      ), // 2 (placeholder)
      ParentGiftsScreen(parentId: parentId, token: token), // 3
      MorePage(parentId: parentId, token: token), // 4
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: pages[_index],
      bottomNavigationBar: ParentBottomNavBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}

class ParentBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const ParentBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const double barHeight = 80;
    const double iconSize = 26;
    const double homeOuter = 80;
    const double homeInner = 62;

    const Color kPrimary = Color(0xFF67AFAC);
    const Color kUnselected = Color(0xFF555555);

    return SizedBox(
      height: barHeight + 50,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // Bar background
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: barHeight,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(26),
                  topRight: Radius.circular(26),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left group
                    Row(
                      children: [
                        _NavItem(
                          asset: "assets/icons/Reward.svg",
                          label: "Chores",
                          isSelected: currentIndex == 1,
                          iconSize: iconSize,
                          onTap: () => onTap(1),
                        ),
                        const SizedBox(width: 20),
                        _NavItem(
                          asset: "assets/icons/Card.svg",
                          label: "Allowance",
                          isSelected: currentIndex == 2,
                          iconSize: iconSize,
                          onTap: () => onTap(2),
                        ),
                      ],
                    ),

                    // Right group
                    Row(
                      children: [
                        _NavItem(
                          asset: "assets/icons/Gift.svg",
                          label: "Gifts",
                          isSelected: currentIndex == 3,
                          iconSize: iconSize,
                          onTap: () => onTap(3),
                        ),
                        const SizedBox(width: 20),
                        _NavItem(
                          asset: "assets/icons/More.svg",
                          label: "More",
                          isSelected: currentIndex == 4,
                          iconSize: iconSize,
                          onTap: () => onTap(4),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Floating Home button
          Positioned(
            top: 10,
            child: GestureDetector(
              onTap: () => onTap(0),
              child: Container(
                width: homeOuter,
                height: homeOuter,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: homeInner,
                    height: homeInner,
                    decoration: BoxDecoration(
                      color: currentIndex == 0
                          ? kPrimary
                          : const Color(0xFFCCCCCC),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        "assets/icons/home.svg",
                        width: iconSize,
                        height: iconSize,
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String asset;
  final String label;
  final bool isSelected;
  final double iconSize;
  final VoidCallback onTap;

  const _NavItem({
    required this.asset,
    required this.label,
    required this.isSelected,
    required this.iconSize,
    required this.onTap,
  });

  static const Color kPrimary = Color(0xFF67AFAC);
  static const Color kUnselected = Color(0xFF555555);

  @override
  Widget build(BuildContext context) {
    final Color color = isSelected ? kPrimary : kUnselected;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              asset,
              width: iconSize,
              height: iconSize,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
